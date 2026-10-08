import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/medical_sources.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../immediate_support/immediate_support_navigation.dart';
import '../widgets/ai_disclaimer_banner.dart';

/// Firestore: `users/{uid}/assistant_messages`
const String _kAssistantMessages = 'assistant_messages';

const List<String> _kAcknowledgementLines = [
  'Got it. I\'m thinking that through for you.',
  'Thanks for sharing. Give me just a moment.',
  'I\'m on it, pulling together a thoughtful reply.',
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
  const AssistantScreen({super.key, this.initialPrompt});

  /// Optional starter text (e.g. from home “Understand Your Care” cards).
  final String? initialPrompt;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  // keepScrollOffset: false — never restore a stale mid-thread offset on re-entry.
  // The chat list is reversed, so offset 0 is always the latest message.
  final ScrollController _scrollController =
      ScrollController(keepScrollOffset: false);
  final FocusNode _composerFocus = FocusNode();
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _dotController;

  bool _isLoading = false;
  String _pendingAckLine = _kAcknowledgementLines[0];

  /// Once dismissed, the AI Assistant intro stays hidden for future sessions.
  static const _introPrefsKey = 'assistant_intro_dismissed_v1';
  bool _introDismissed = false;

  /// "New conversation" marker (per user, on this device). Messages created
  /// before it stay saved in Firestore but are hidden from the visible thread
  /// unless the user taps "Show earlier messages".
  static const _conversationStartPrefsPrefix =
      'assistant_conversation_started_at_v1_';
  bool _conversationPrefsLoaded = false;
  DateTime? _conversationStartedAt;
  bool _showEarlierMessages = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialPrompt?.trim();
    if (seed != null && seed.isNotEmpty) {
      _messageController.text = seed;
    }
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _loadIntroDismissed();
    _loadConversationStart();
    _composerFocus.addListener(_onComposerFocusChanged);
  }

  void _onComposerFocusChanged() {
    if (!_composerFocus.hasFocus) return;
    // Keep the latest message visible once the keyboard has animated in.
    _scheduleScrollToBottom();
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _composerFocus.hasFocus) _scheduleScrollToBottom();
    });
  }

  String? get _conversationStartPrefsKey {
    final uid = _auth.currentUser?.uid;
    return uid == null ? null : '$_conversationStartPrefsPrefix$uid';
  }

  Future<void> _loadConversationStart() async {
    DateTime? startedAt;
    try {
      final key = _conversationStartPrefsKey;
      if (key != null) {
        final prefs = await SharedPreferences.getInstance();
        final ms = prefs.getInt(key);
        if (ms != null) {
          startedAt = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }
    } catch (_) {
      // Non-fatal: show the full thread.
    }
    if (!mounted) return;
    setState(() {
      _conversationStartedAt = startedAt;
      _conversationPrefsLoaded = true;
    });
  }

  Future<void> _confirmNewConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new conversation?'),
        content: const Text(
          'This clears the chat on screen so you can start fresh. '
          'Your earlier messages stay saved to your account. Tap '
          '"Show earlier messages" any time to see them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start new'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final now = DateTime.now();
    setState(() {
      _conversationStartedAt = now;
      _showEarlierMessages = false;
    });
    try {
      final key = _conversationStartPrefsKey;
      if (key != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(key, now.millisecondsSinceEpoch);
      }
    } catch (_) {
      // Non-fatal: the fresh thread still applies for this session.
    }
  }

  Query<Map<String, dynamic>> _messagesQuery(String userId) {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(_kAssistantMessages);
    final startedAt = _conversationStartedAt;
    if (startedAt != null && !_showEarlierMessages) {
      q = q.where(
        'createdAt',
        isGreaterThan: Timestamp.fromDate(startedAt),
      );
    }
    return q.orderBy('createdAt', descending: false).limit(200);
  }

  Future<void> _loadIntroDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_introPrefsKey) ?? false;
      if (mounted && dismissed) {
        setState(() => _introDismissed = true);
      }
    } catch (_) {
      // Non-fatal: default to showing the intro.
    }
  }

  Future<void> _dismissIntro() async {
    setState(() => _introDismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introPrefsKey, true);
    } catch (_) {
      // Non-fatal: it'll simply show again next session.
    }
  }

  /// The chat list is reversed, so the latest message lives at offset 0.
  void _scheduleScrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
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

  /// Disclaimer banner, sources and "Show earlier messages" / "New
  /// conversation" controls. Rendered as the top item of the scrollable
  /// conversation so they scroll away with the messages instead of taking
  /// fixed space above the chat.
  Widget _buildConversationHeader({
    required bool keyboardOpen,
    required bool signedIn,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // While typing, a compact disclaimer is pinned above the thread
        // instead (see build), so the full banner is not shown twice.
        if (!keyboardOpen)
          const AIDisclaimerBanner(
            customMessage: 'This assistant helps you understand your care.',
            customSubMessage: 'It does not replace your provider.',
          ),
        if (!_introDismissed && !keyboardOpen) ...[
          const _AssistantSourcesBar(),
          const SizedBox(height: 12),
        ],
        if (signedIn)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_conversationStartedAt != null && !_showEarlierMessages)
                TextButton.icon(
                  onPressed: () => setState(() => _showEarlierMessages = true),
                  icon: const Icon(Icons.history, size: 20),
                  label: const Text('Show earlier messages'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: const TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              TextButton.icon(
                onPressed: _isLoading ? null : _confirmNewConversation,
                icon: const Icon(Icons.add_comment_outlined, size: 20),
                label: const Text('New conversation'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.brandPurple,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: const TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  void dispose() {
    _dotController.dispose();
    _composerFocus.removeListener(_onComposerFocusChanged);
    _composerFocus.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    // The Scaffold below already resizes its body for the keyboard
    // (resizeToAvoidBottomInset), so the composer must NOT add viewInsets
    // again — doing so double-counted the keyboard and pushed the composer
    // off-screen with Bold Text / larger Dynamic Type.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    // The body SafeArea skips the bottom edge, so clear the home indicator
    // here. MediaQuery padding.bottom already drops to 0 while the keyboard
    // is up (it is reduced by viewInsets), so this never double-counts.
    final bottomPad = keyboardOpen
        ? 10.0
        : math.max(20.0, MediaQuery.paddingOf(context).bottom + 8);
    final conversationHeader = _buildConversationHeader(
      keyboardOpen: keyboardOpen,
      signedIn: userId != null,
    );

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.ground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'AI Assistant',
                              // Smaller while typing to leave room for the thread.
                              style: keyboardOpen
                                  ? textTheme.headlineMedium
                                  : textTheme.displaySmall,
                            ),
                          ),
                          if (!_introDismissed && !keyboardOpen) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Ask me anything about your care or what to do next',
                              style: textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your chat is saved to your account',
                              style: hearthCaptionStyle,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (!_introDismissed && !keyboardOpen)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'Dismiss intro',
                        color: AppTheme.textMuted,
                        constraints: const BoxConstraints.tightFor(
                          width: 44,
                          height: 44,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: _dismissIntro,
                      ),
                    Tooltip(
                      message: 'I need support right now',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => openImmediateSupport(
                            context,
                            entrySource: 'assistant',
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 52,
                              minHeight: 44,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.volunteer_activism_outlined,
                                    color: AppTheme.brandPurple,
                                    size: 22,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Support',
                                    style: TextStyle(
                                      fontFamily: AppTheme.sansFamily,
                                      fontSize: 12,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.brandPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    HearthCircleButton(
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // The full disclaimer banner, sources and conversation controls
              // live at the top of the scrollable conversation (see
              // [conversationHeader]) so they scroll away with the messages.
              // While typing, the banner is swapped for this compact pinned
              // version so the disclaimer is never hidden but the composer +
              // latest message stay visible above the keyboard.
              if (keyboardOpen)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: _CompactAssistantDisclaimer(),
                ),

              Expanded(
                child: userId == null
                    ? _AssistantStaticConversation(
                        header: conversationHeader,
                        child: Text(
                          'Sign in to chat and keep your conversation history.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      )
                    : !_conversationPrefsLoaded
                        ? _AssistantStaticConversation(
                            header: conversationHeader,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        // Keyed by the conversation window so "New
                        // conversation" / "Show earlier" get a fresh stream.
                        key: ValueKey(
                          '${_conversationStartedAt?.millisecondsSinceEpoch}'
                          '_$_showEarlierMessages',
                        ),
                        stream: _messagesQuery(userId).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return _AssistantStaticConversation(
                              header: conversationHeader,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final entries = _flattenMessages(docs);
                          final hasMessages =
                              entries.isNotEmpty || _isLoading;

                          if (!hasMessages) {
                            // Scrollable (with the header on top) so the
                            // empty state never overflows the short space
                            // left above the keyboard.
                            return _AssistantStaticConversation(
                                header: conversationHeader,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.brandPurple,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.headset_mic_outlined,
                                        size: 40,
                                        color: AppTheme.onPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'How can I help today?',
                                      style: textTheme.headlineMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                            );
                          }

                          return _AssistantChatList(
                            header: conversationHeader,
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
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(
                    top: BorderSide(color: AppTheme.borderWarm),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      // Pill composer on the page colour; it grows with
                      // longer messages up to the max height.
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 52,
                          maxHeight: 140,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceInset,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: AppTheme.borderWarm),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _composerFocus,
                          onTap: _scheduleScrollToBottom,
                          style: const TextStyle(
                            fontFamily: AppTheme.sansFamily,
                            fontSize: 15,
                            color: AppTheme.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                              18,
                              15,
                              4,
                              15,
                            ),
                            hintStyle: const TextStyle(
                              fontFamily: AppTheme.sansFamily,
                              fontSize: 15,
                              color: AppTheme.textMuted,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.keyboard_hide_outlined,
                                color: AppTheme.textMuted,
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
                    Material(
                      color: AppTheme.brandPurple,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send_outlined,
                            color: AppTheme.onPurple,
                            size: 22,
                          ),
                          onPressed: _isLoading ? null : _sendMessage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }
}

/// Non-chat states (signed out, loading, empty thread): the conversation
/// header on top with [child] below, all in one scroll view so nothing
/// overflows the short space left above the keyboard.
class _AssistantStaticConversation extends StatelessWidget {
  final Widget header;
  final Widget child;

  const _AssistantStaticConversation({
    required this.header,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        header,
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

/// Owns [ListView] + auto-scroll when messages or loading state change (no side effects in [build]).
class _AssistantChatList extends StatefulWidget {
  /// Disclaimer + conversation controls shown above the oldest message.
  final Widget header;
  final ScrollController scrollController;
  final List<_ChatListEntry> entries;
  final bool isLoading;
  final String pendingAckLine;
  final Animation<double> dotAnimation;

  const _AssistantChatList({
    required this.header,
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
  static const _headerKey = ValueKey<String>('assistant_conversation_header');

  @override
  void initState() {
    super.initState();
    // Always open on the latest message (offset 0 of the reversed list).
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = widget.scrollController;
      if (c.hasClients) c.jumpTo(0);
    });
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
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageItems = widget.entries.length + (widget.isLoading ? 1 : 0);
    // +1 for the header, which is the last item of the reversed list, i.e.
    // the very top of the conversation above the oldest message.
    final totalItems = messageItems + 1;

    // Reversed list: item 0 is the newest entry and the list is anchored to
    // the bottom, so re-entry and keyboard resizes always show the latest
    // message (no reliance on a lazily-estimated maxScrollExtent, which made
    // re-entry land mid-response). shrinkWrap + topCenter keeps short threads
    // top-aligned as before.
    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        controller: widget.scrollController,
        reverse: true,
        shrinkWrap: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 12,
        ),
        itemCount: totalItems,
        // Keep the header's element (and the sources bar's expanded state)
        // when new messages shift its index.
        findChildIndexCallback: (key) =>
            key == _headerKey ? messageItems : null,
        itemBuilder: (context, reversedIndex) {
          if (reversedIndex == messageItems) {
            return KeyedSubtree(key: _headerKey, child: widget.header);
          }
          final index = messageItems - 1 - reversedIndex;
          return _buildEntry(index);
        },
      ),
    );
  }

  Widget _buildEntry(int index) {
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
  }
}

/// One-line disclaimer shown while the keyboard is open (full banner otherwise).
class _CompactAssistantDisclaimer extends StatelessWidget {
  const _CompactAssistantDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.favorite_border, size: 14, color: AppTheme.brandPurple),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'This assistant helps you understand your care. '
            'It does not replace your provider.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: hearthCaptionStyle.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      ],
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
          const Expanded(child: Divider(color: AppTheme.borderWarm, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.sansFamily,
                fontSize: 12,
                height: 18 / 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppTheme.borderWarm, height: 1)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      // Assistant replies sit on lavender, which Hearth keeps for AI content.
      decoration: BoxDecoration(
        color: isUser ? AppTheme.brandPurple : AppTheme.lavender,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomRight: isUser ? const Radius.circular(4) : null,
          bottomLeft: !isUser ? const Radius.circular(4) : null,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.sansFamily,
          color: isUser ? AppTheme.onPurple : AppTheme.ink,
          fontSize: 15,
          height: 22 / 15,
        ),
      ),
    );
  }
}

/// Collapsible "Sources & References" bar shown under the AI disclaimer so the
/// assistant's health information is backed by easy-to-find citations to
/// trusted organizations (App Store Guideline 1.4.1).
class _AssistantSourcesBar extends StatefulWidget {
  const _AssistantSourcesBar();

  @override
  State<_AssistantSourcesBar> createState() => _AssistantSourcesBarState();
}

class _AssistantSourcesBarState extends State<_AssistantSourcesBar> {
  bool _expanded = false;

  Future<void> _open(MedicalSource source) async {
    bool ok;
    try {
      ok = await launchMedicalSource(source);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ${source.url}'),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = MedicalSources.defaults;
    return HearthCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined,
                        size: 20, color: AppTheme.brandPurple),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Sources & References',
                        style: TextStyle(
                          fontFamily: AppTheme.sansFamily,
                          fontSize: 15,
                          height: 22 / 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI answers are educational and based on guidance from these '
                    'trusted organizations. Always confirm with your provider.',
                    style: hearthCaptionStyle.copyWith(height: 19 / 13),
                  ),
                  const SizedBox(height: 6),
                  ...sources.map(
                    (s) => InkWell(
                      onTap: () => _open(s),
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.open_in_new,
                                  size: 16, color: AppTheme.brandPurple),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.organization,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.sansFamily,
                                    fontSize: 14,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.brandPurple,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.brandPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
        // Same lavender as assistant replies: this is the AI's turn.
        decoration: const BoxDecoration(
          color: AppTheme.lavender,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontFamily: AppTheme.sansFamily,
                color: AppTheme.ink,
                fontSize: 15,
                height: 22 / 15,
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
                          color: AppTheme.brandPurple
                              .withValues(alpha: opacity(i)),
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
