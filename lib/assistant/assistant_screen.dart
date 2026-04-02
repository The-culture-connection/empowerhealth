import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cors/ui_theme.dart';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../widgets/ai_disclaimer_banner.dart';

/// Firestore: `users/{uid}/assistant_messages`
const String _kAssistantMessages = 'assistant_messages';

const List<String> _kAcknowledgementLines = [
  'Got it — I\'m thinking that through for you.',
  'Thanks for sharing — give me just a moment.',
  'I\'m on it — pulling together a thoughtful reply.',
];

String _ackLineFor(String userMessage) {
  final i = userMessage.hashCode.abs() % _kAcknowledgementLines.length;
  return _kAcknowledgementLines[i];
}

class _ChatListEntry {
  final bool isDateHeader;
  final DateTime? day;
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;

  _ChatListEntry.date(this.day)
      : isDateHeader = true,
        doc = null;

  _ChatListEntry.message(this.doc)
      : isDateHeader = false,
        day = null;
}

List<_ChatListEntry> _flattenMessages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  final out = <_ChatListEntry>[];
  DateTime? lastDay;
  for (final doc in docs) {
    final data = doc.data();
    final ts = data['createdAt'];
    DateTime? created;
    if (ts is Timestamp) {
      created = ts.toDate();
    }
    if (created != null) {
      final day = DateTime(created.year, created.month, created.day);
      if (lastDay == null || day != lastDay) {
        lastDay = day;
        out.add(_ChatListEntry.date(day));
      }
    }
    out.add(_ChatListEntry.message(doc));
  }
  return out;
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _dotController;

  bool _isLoading = false;
  String _pendingAckLine = _kAcknowledgementLines[0];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  void _scheduleScrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showAIDisabledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('AI Features Disabled'),
        content: const Text(
          'AI features are disabled. Go to settings to enable this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/main',
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/privacy-center');
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to save your chat history.'),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
      return;
    }

    final aiEnabled = await _databaseService.areAIFeaturesEnabled(userId);
    if (!aiEnabled) {
      _showAIDisabledDialog();
      return;
    }

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _pendingAckLine = _ackLineFor(userMessage);
      _isLoading = true;
    });
    _scheduleScrollToBottom();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(_kAssistantMessages)
          .add({
        'role': 'user',
        'text': userMessage,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _scheduleScrollToBottom();

      final response = await _functionsService.simplifyText(
        text: userMessage,
        context:
            'You are a helpful AI assistant for EmpowerHealth, a maternal health app. Answer questions about pregnancy, maternal health, patient rights, and healthcare advocacy in a supportive, clear, and empowering way. Keep responses concise and at a 6th-8th grade reading level. Be warm, empathetic, and culturally sensitive.',
      );
      final assistantResponse = response['simplified'] ??
          response['simplifiedText'] ??
          "I'm here to help! How can I assist you today?";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(_kAssistantMessages)
          .add({
        'role': 'assistant',
        'text': assistantResponse as String,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        _scheduleScrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection(_kAssistantMessages)
              .add({
            'role': 'assistant',
            'text':
                "I'm having trouble right now. Please try again in a moment.",
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
        setState(() => _isLoading = false);
        _scheduleScrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _dotController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomPad = 20.0 + viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.surfaceCard, AppTheme.backgroundWarm],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Assistant',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ask me anything about your pregnancy, care, or rights',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your chat is saved to your account',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const AIDisclaimerBanner(
                  customMessage: 'This assistant helps you understand your care.',
                  customSubMessage: 'It does not replace your provider.',
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: userId == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Sign in to chat and keep your conversation history.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection(_kAssistantMessages)
                            .orderBy('createdAt', descending: false)
                            .limit(200)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final entries = _flattenMessages(docs);
                          final hasMessages =
                              entries.isNotEmpty || _isLoading;

                          if (!hasMessages) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF663399),
                                            Color(0xFF8855BB),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: const Icon(
                                        Icons.support_agent_rounded,
                                        size: 40,
                                        color: AppTheme.brandWhite,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'How can I help today?',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return _AssistantChatList(
                            scrollController: _scrollController,
                            entries: entries,
                            isLoading: _isLoading,
                            pendingAckLine: _pendingAckLine,
                            dotAnimation: _dotController,
                          );
                        },
                      ),
              ),

              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 140),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceInput,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.keyboard_hide,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () =>
                                  FocusScope.of(context).unfocus(),
                              tooltip: 'Dismiss keyboard',
                            ),
                          ),
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (!_isLoading) _sendMessage();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF663399),
                            Color(0xFF8855BB),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: AppTheme.brandWhite),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns [ListView] + auto-scroll when messages or loading state change (no side effects in [build]).
class _AssistantChatList extends StatefulWidget {
  final ScrollController scrollController;
  final List<_ChatListEntry> entries;
  final bool isLoading;
  final String pendingAckLine;
  final Animation<double> dotAnimation;

  const _AssistantChatList({
    required this.scrollController,
    required this.entries,
    required this.isLoading,
    required this.pendingAckLine,
    required this.dotAnimation,
  });

  @override
  State<_AssistantChatList> createState() => _AssistantChatListState();
}

class _AssistantChatListState extends State<_AssistantChatList> {
  @override
  void initState() {
    super.initState();
    _scrollAfterFrame();
  }

  @override
  void didUpdateWidget(covariant _AssistantChatList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.length != widget.entries.length ||
        oldWidget.isLoading != widget.isLoading) {
      _scrollAfterFrame();
    }
  }

  void _scrollAfterFrame() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = widget.scrollController;
      if (!c.hasClients) return;
      c.animateTo(
        c.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.entries.length + (widget.isLoading ? 1 : 0);

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 12,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (widget.isLoading && index == widget.entries.length) {
          return _AssistantAcknowledgementBubble(
            message: widget.pendingAckLine,
            dotAnimation: widget.dotAnimation,
          );
        }

        final entry = widget.entries[index];
        if (entry.isDateHeader) {
          return _DateDivider(day: entry.day!);
        }

        final doc = entry.doc!;
        final data = doc.data();
        final role = data['role'] as String? ?? 'assistant';
        final text = data['text'] as String? ?? '';
        final isUser = role == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: _MessageBubble(
            text: text,
            isUser: isUser,
          ),
        );
      },
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime day;

  const _DateDivider({required this.day});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    String label;
    if (day == today) {
      label = 'Today';
    } else if (day == yesterday) {
      label = 'Yesterday';
    } else {
      label =
          '${day.month}/${day.day}/${day.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MessageBubble({
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF663399) : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomRight: isUser ? const Radius.circular(4) : null,
          bottomLeft: !isUser ? const Radius.circular(4) : null,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isUser ? AppTheme.brandWhite : Colors.black87,
          fontSize: 15,
          height: 1.35,
        ),
      ),
    );
  }
}

/// Conversational “working on it” row with animated dots — replaces a bare spinner.
class _AssistantAcknowledgementBubble extends StatelessWidget {
  final String message;
  final Animation<double> dotAnimation;

  const _AssistantAcknowledgementBubble({
    required this.message,
    required this.dotAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppTheme.borderLighter.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: dotAnimation,
              builder: (context, _) {
                final t = dotAnimation.value;
                double opacity(int i) {
                  final phase = (t * 3 - i).clamp(0.0, 1.0);
                  return 0.25 + 0.75 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.brandPurple.withOpacity(opacity(i)),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
