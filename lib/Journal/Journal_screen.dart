import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../cors/ui_theme.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';

/// ICU `a` is AM/PM — never use raw `at` inside [DateFormat] patterns or `a` is misread (e.g. "PMt").
String _formatJournalCreatedAt(DateTime d) {
  return '${DateFormat('MMMM d, yyyy').format(d)} at ${DateFormat('h:mm a').format(d)}';
}

enum _JournalEntryMode { hub, quick, write }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _quickNoteController = TextEditingController();
  bool _isSaving = false;
  _JournalEntryMode _entryMode = _JournalEntryMode.hub;
  String? _quickMoodEmoji;
  String? _quickMoodLabel;
  String? _writePrompt;
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();

  static const List<String> _writePrompts = [
    'How are you feeling today?',
    'What brought you peace this week?',
    'What concerns are on your mind?',
    'What are you grateful for right now?',
    'What do you want to remember about this moment?',
  ];

  @override
  void initState() {
    super.initState();
    _trackScreenView();
  }

  Future<void> _trackScreenView() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProfile = await _databaseService.getUserProfile(userId);
        await _analytics.logScreenView(
          screenName: 'journal',
          feature: 'journal',
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking journal screen view: $e');
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _quickNoteController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_entryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📝 Please enter some text before saving'),
          backgroundColor: AppTheme.brandGold,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final data = <String, dynamic>{
        'content': _entryController.text.trim(),
        'tag': 'Journal entry',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (_writePrompt != null && _writePrompt!.isNotEmpty) {
        data['prompt'] = _writePrompt;
        data['isFeelingPrompt'] = true;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .add(data);

      // Track journal entry creation
      try {
        final analytics = AnalyticsService();
        final databaseService = DatabaseService();
        final userProfile = await databaseService.getUserProfile(userId);
        await analytics.logJournalEntryCreated(
          entryLength: _entryController.text.length,
          userProfile: userProfile,
        );
      } catch (e) {
        print('Error tracking journal entry creation: $e');
      }

      if (mounted) {
        _entryController.clear();
        _writePrompt = null;
        setState(() => _entryMode = _JournalEntryMode.hub);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Entry saved to journal!'),
            backgroundColor: AppTheme.brandTurquoise,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving entry: ${e.toString()}'),
            backgroundColor: AppTheme.brandPurple,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveFeelingEntry(
    String emoji,
    String label, {
    String? extraNote,
    String prompt = 'How are you feeling today?',
  }) async {
    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final note = extraNote?.trim() ?? '';
      final content = note.isEmpty
          ? '$emoji $label'
          : '$emoji $label\n\n$note';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .add({
        'content': content,
        'tag': 'Feelings',
        'prompt': prompt,
        'isFeelingPrompt': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Track journal mood selection
      try {
        final analytics = AnalyticsService();
        final databaseService = DatabaseService();
        final userProfile = await databaseService.getUserProfile(userId);
        await analytics.logJournalMoodSelected(
          moodType: label,
          userProfile: userProfile,
        );
      } catch (e) {
        print('Error tracking journal mood selection: $e');
      }

      if (mounted) {
        setState(() {
          _entryMode = _JournalEntryMode.hub;
          _quickMoodEmoji = null;
          _quickMoodLabel = null;
          _quickNoteController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Feeling entry saved: $emoji $label'),
            backgroundColor: AppTheme.brandTurquoise,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving feeling: ${e.toString()}'),
            backgroundColor: AppTheme.brandPurple,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitQuickCheckIn() async {
    if (_quickMoodEmoji == null || _quickMoodLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap a mood to save your check-in'),
          backgroundColor: AppTheme.brandGold,
        ),
      );
      return;
    }
    await _saveFeelingEntry(
      _quickMoodEmoji!,
      _quickMoodLabel!,
      extraNote: _quickNoteController.text,
    );
  }

  void _resetToHub() {
    setState(() {
      _entryMode = _JournalEntryMode.hub;
      _quickMoodEmoji = null;
      _quickMoodLabel = null;
      _quickNoteController.clear();
      _writePrompt = null;
      _entryController.clear();
    });
  }

  void _openWriteMode() {
    setState(() {
      _entryMode = _JournalEntryMode.write;
      _writePrompt = _writePrompts.first;
      _entryController.text = '${_writePrompts.first}\n\n';
    });
  }

  Widget _buildWelcomingIntroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5EEE0),
            Color(0xFFFAF8F4),
            Color(0xFFEBE0D6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E0F0).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF663399).withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a moment to check in with yourself — a quick mood tap or a longer reflection both count.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w300,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryMethodGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose how you\'d like to journal:',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _EntryMethodTile(
                icon: Icons.sentiment_satisfied_alt_outlined,
                iconGradient: const [Color(0xFFD4A574), Color(0xFFE0B589)],
                title: 'Quick check-in',
                subtitle: 'Mood + optional note',
                onTap: () => setState(() => _entryMode = _JournalEntryMode.quick),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EntryMethodTile(
                icon: Icons.edit_outlined,
                iconGradient: const [Color(0xFF663399), Color(0xFF8855BB)],
                title: 'Write',
                subtitle: 'Longer reflection',
                onTap: _openWriteMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCheckInCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF7FB), Color(0xFFF9F5FB)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.borderLightest.withOpacity(0.5)),
        boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 18, y: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sentiment_satisfied_alt_outlined,
                  color: AppTheme.brandGold, size: 22),
              const SizedBox(width: 8),
              Text(
                'Quick check-in',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'How are you feeling right now?',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _SelectableMoodChip(
                emoji: '😊',
                label: 'Joyful',
                selected: _quickMoodLabel == 'Joyful',
                onTap: () => setState(() {
                  _quickMoodEmoji = '😊';
                  _quickMoodLabel = 'Joyful';
                }),
              ),
              _SelectableMoodChip(
                emoji: '😌',
                label: 'Calm',
                selected: _quickMoodLabel == 'Calm',
                onTap: () => setState(() {
                  _quickMoodEmoji = '😌';
                  _quickMoodLabel = 'Calm';
                }),
              ),
              _SelectableMoodChip(
                emoji: '😐',
                label: 'Okay',
                selected: _quickMoodLabel == 'Okay',
                onTap: () => setState(() {
                  _quickMoodEmoji = '😐';
                  _quickMoodLabel = 'Okay';
                }),
              ),
              _SelectableMoodChip(
                emoji: '😟',
                label: 'Worried',
                selected: _quickMoodLabel == 'Worried',
                onTap: () => setState(() {
                  _quickMoodEmoji = '😟';
                  _quickMoodLabel = 'Worried';
                }),
              ),
              _SelectableMoodChip(
                emoji: '😢',
                label: 'Tearful',
                selected: _quickMoodLabel == 'Tearful',
                onTap: () => setState(() {
                  _quickMoodEmoji = '😢';
                  _quickMoodLabel = 'Tearful';
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Add a note (optional)',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _quickNoteController,
            maxLines: 3,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w300,
            ),
            decoration: InputDecoration(
              hintText: 'Anything you\'d like to remember…',
              hintStyle: TextStyle(color: AppTheme.textBarelyVisible),
              filled: true,
              fillColor: AppTheme.surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: AppTheme.borderLighter.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: AppTheme.borderLighter.withOpacity(0.5)),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4A574), Color(0xFFE0B589)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A574).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submitQuickCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppTheme.brandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.brandWhite,
                            ),
                          )
                        : const Text(
                            'Save check-in',
                            style: TextStyle(fontWeight: FontWeight.w300),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isSaving ? null : _resetToHub,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  side: BorderSide(
                    color: AppTheme.borderLighter.withOpacity(0.5),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w300)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWriteCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF7FB), Color(0xFFF9F5FB)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.borderLightest.withOpacity(0.5)),
        boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 18, y: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_outlined, color: AppTheme.brandPurple, size: 22),
              const SizedBox(width: 8),
              Text(
                'Write',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Start from a gentle prompt or write freely.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _writePrompts.map((p) {
              final sel = _writePrompt == p;
              return FilterChip(
                label: Text(
                  p,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: sel ? AppTheme.brandWhite : AppTheme.textMuted,
                  ),
                ),
                selected: sel,
                showCheckmark: false,
                onSelected: (value) {
                  if (!value) return;
                  setState(() {
                    _writePrompt = p;
                    _entryController.text = '$p\n\n';
                    _entryController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _entryController.text.length),
                    );
                  });
                },
                selectedColor: const Color(0xFF663399),
                backgroundColor: AppTheme.surfaceCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: sel
                        ? const Color(0xFF663399)
                        : AppTheme.borderLighter.withOpacity(0.5),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.borderLighter.withOpacity(0.5),
              ),
            ),
            child: TextField(
              controller: _entryController,
              maxLines: 8,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w300,
              ),
              decoration: InputDecoration(
                hintText: 'How are you feeling today? Add whatever feels right…',
                hintStyle: TextStyle(
                  color: AppTheme.textBarelyVisible,
                  fontWeight: FontWeight.w300,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.gradientBeigeStart, AppTheme.textLightest],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.textLightest.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppTheme.brandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandWhite),
                            ),
                          )
                        : const Text(
                            'Save entry',
                            style: TextStyle(fontWeight: FontWeight.w300),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isSaving ? null : _resetToHub,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textLight,
                  side: BorderSide(
                    color: AppTheme.borderLighter.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w300)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarmEmptyReflections() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEBE4F3).withOpacity(0.45),
            const Color(0xFFF5F0F8).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderLighter.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite_border, size: 36, color: AppTheme.textLightest),
          const SizedBox(height: 12),
          Text(
            'Your reflections will show up here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There\'s no rush — try a quick check-in above, or write a few words when you\'re ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundWarm,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header (matching NewUI)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your journal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A safe space for your thoughts and feelings',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: userId != null
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('notes')
                          .orderBy('createdAt', descending: true)
                          .limit(10)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final entries = snapshot.hasData ? snapshot.data!.docs : [];

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Privacy Notice (matching NewUI)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFEBE4F3), // #ebe4f3
                                  Color(0xFFF5F0F8), // #f5f0f8
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppTheme.borderLighter.withOpacity(0.5),
                              ),
                              boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 18, y: 4),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: AppTheme.textLightest,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Your journal is private. Only you can see what you write here.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textMuted,
                                          fontWeight: FontWeight.w300,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildWelcomingIntroCard(),
                          const SizedBox(height: 20),
                          if (_entryMode == _JournalEntryMode.hub) ...[
                            _buildEntryMethodGrid(),
                          ] else if (_entryMode == _JournalEntryMode.quick) ...[
                            _buildQuickCheckInCard(),
                          ] else ...[
                            _buildWriteCard(),
                          ],
                          const SizedBox(height: 28),

                          // Recent Reflections Section (matching NewUI)
                          const Text(
                            'Recent reflections',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (entries.isEmpty)
                            _buildWarmEmptyReflections()
                          else
                            ...entries.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return _EntryCard(
                                entryId: doc.id,
                                content: data['content'] ?? '',
                                tag: data['tag'] ?? 'Untagged',
                                moduleTitle: data['moduleTitle'],
                                highlightedText: data['highlightedText'],
                                createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                                prompt: data['prompt'],
                                isFeelingPrompt: data['isFeelingPrompt'] ?? false,
                              );
                            }).toList(),
                          
                          const SizedBox(height: 24),
                          const SizedBox(height: 100), // Space for FABs
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandPurple.withOpacity(0.8),
                  AppTheme.gradientPurpleEnd.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandPurple.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => setState(() => _entryMode = _JournalEntryMode.quick),
                child: const Icon(Icons.favorite, color: AppTheme.brandWhite, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.gradientPurpleStart, AppTheme.gradientPurpleEnd],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandPurple.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: _openWriteMode,
                child: const Icon(Icons.add, color: AppTheme.brandWhite, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryMethodTile extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EntryMethodTile({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE8E0F0).withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF663399).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: iconGradient),
                  boxShadow: [
                    BoxShadow(
                      color: iconGradient[0].withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppTheme.brandWhite, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableMoodChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableMoodChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFD4A574), Color(0xFFE0B589)],
                )
              : null,
          color: selected ? null : AppTheme.surfaceCard.withOpacity(0.9),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.borderLighter.withOpacity(0.5),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4A574).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: selected ? AppTheme.brandWhite : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final String entryId;
  final String content;
  final String tag;
  final String? moduleTitle;
  final String? highlightedText;
  final DateTime? createdAt;
  final String? prompt;
  final bool isFeelingPrompt;

  const _EntryCard({
    required this.entryId,
    required this.content,
    required this.tag,
    this.moduleTitle,
    this.highlightedText,
    this.createdAt,
    this.prompt,
    this.isFeelingPrompt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.borderLighter.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showEntryDetail(context),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.gradientBeigeStart, AppTheme.gradientBeigeEnd],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.favorite, color: AppTheme.brandWhite, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      if (createdAt != null)
                        Text(
                          DateFormat('MMMM d, yyyy').format(createdAt!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLightest,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      if (isFeelingPrompt && prompt != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'feeling',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                      height: 1.5,
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

  void _showEntryDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EntryDetailDialog(
        entryId: entryId,
        content: content,
        tag: tag,
        moduleTitle: moduleTitle,
        highlightedText: highlightedText,
        createdAt: createdAt,
        prompt: prompt,
        isFeelingPrompt: isFeelingPrompt,
      ),
    );
  }
}

class _EntryDetailDialog extends StatelessWidget {
  final String entryId;
  final String content;
  final String tag;
  final String? moduleTitle;
  final String? highlightedText;
  final DateTime? createdAt;
  final String? prompt;
  final bool isFeelingPrompt;

  const _EntryDetailDialog({
    required this.entryId,
    required this.content,
    required this.tag,
    this.moduleTitle,
    this.highlightedText,
    this.createdAt,
    this.prompt,
    this.isFeelingPrompt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryActionGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Journal Entry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.brandWhite,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.brandWhite),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFeelingPrompt && prompt != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.psychology, size: 16, color: Colors.pink.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                prompt!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.pink.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (moduleTitle != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF663399).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school, size: 16, color: Color(0xFF663399)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'From: $moduleTitle',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF663399),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (highlightedText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.yellow.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.format_quote, size: 16, color: AppTheme.brandGold),
                                const SizedBox(width: 8),
                                Text(
                                  'Highlighted Text:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.brandTerracotta,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              highlightedText!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Your Notes:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Created: ${_formatJournalCreatedAt(createdAt!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
