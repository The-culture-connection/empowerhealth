import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/step_scroll.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../auth/guest_guard.dart';
import 'journal_learning_note_opener.dart';

/// ICU `a` is AM/PM — never use raw `at` inside [DateFormat] patterns or `a` is misread (e.g. "PMt").
String _formatJournalCreatedAt(DateTime d) {
  return '${DateFormat('MMMM d, yyyy').format(d)} at ${DateFormat('h:mm a').format(d)}';
}

enum _JournalEntryMode { hub, quick, write }

/// What kind of reflection a `users/{uid}/notes` doc is, for the timeline
/// filter. Quick check-ins are tagged 'Feelings'; notes saved from a lesson
/// carry `isFromModule` / `moduleTitle`; everything else is a writing.
enum _ReflectionKind { checkIn, writing, learningNote }

enum _ReflectionFilter { all, checkIns, writings, learningNotes }

_ReflectionKind _reflectionKindOf(Map<String, dynamic> data) {
  final moduleTitle = data['moduleTitle'];
  if (data['isFromModule'] == true ||
      (moduleTitle is String && moduleTitle.trim().isNotEmpty)) {
    return _ReflectionKind.learningNote;
  }
  if (data['tag'] == 'Feelings') return _ReflectionKind.checkIn;
  return _ReflectionKind.writing;
}

bool _matchesReflectionFilter(_ReflectionKind kind, _ReflectionFilter filter) {
  switch (filter) {
    case _ReflectionFilter.all:
      return true;
    case _ReflectionFilter.checkIns:
      return kind == _ReflectionKind.checkIn;
    case _ReflectionFilter.writings:
      return kind == _ReflectionKind.writing;
    case _ReflectionFilter.learningNotes:
      return kind == _ReflectionKind.learningNote;
  }
}

/// Mood picker emojis. Also laid out offstage on web (see build) so CanvasKit
/// fetches its color-emoji fallback font before the picker is shown.
const String _moodEmojiWarmup = '😊😌😐😟😢';

/// Recent reflections shown under "All"; a type filter shows every match
/// among the most recent [_reflectionFetchLimit] notes.
const int _allReflectionsShown = 10;
const int _reflectionFetchLimit = 50;

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _quickNoteController = TextEditingController();
  final StepScrollController _scrollController = StepScrollController();
  bool _isSaving = false;
  _JournalEntryMode _entryMode = _JournalEntryMode.hub;
  String? _quickMoodEmoji;
  String? _quickMoodLabel;
  String? _writePrompt;
  _ReflectionFilter _reflectionFilter = _ReflectionFilter.all;
  // Cached so filter / mood taps (setState) don't resubscribe the
  // StreamBuilder and flash the loading spinner over the whole screen.
  Stream<QuerySnapshot>? _notesStream;
  String? _notesStreamUserId;
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!await requireAccount(context, action: 'save journal entries')) return;
    if (!mounted) return;
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
    if (!await requireAccount(context, action: 'save journal entries')) return;
    if (!mounted) return;
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
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                        : const _OneLineButtonLabel('Save check-in'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Equal-width controls so Save and Cancel are balanced; labels
              // stay on one line (scaled down if needed at large text sizes).
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _resetToHub,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    side: BorderSide(
                      color: AppTheme.borderLighter.withOpacity(0.5),
                    ),
                  ),
                  child: const _OneLineButtonLabel('Cancel'),
                ),
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
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                        : const _OneLineButtonLabel('Save entry'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _resetToHub,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textLight,
                    side: BorderSide(
                      color: AppTheme.borderLighter.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const _OneLineButtonLabel('Cancel'),
                ),
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
            'There\'s no rush. Try a quick check-in above, or write a few words when you\'re ready.',
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

  Stream<QuerySnapshot>? _notesStreamFor(String? userId) {
    if (userId == null) {
      _notesStream = null;
      _notesStreamUserId = null;
      return null;
    }
    if (_notesStream == null || _notesStreamUserId != userId) {
      _notesStreamUserId = userId;
      _notesStream = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .limit(_reflectionFetchLimit)
          .snapshots();
    }
    return _notesStream;
  }

  Widget _buildReflectionFilterChips() {
    const options = <_ReflectionFilter, String>{
      _ReflectionFilter.all: 'All',
      _ReflectionFilter.checkIns: 'Check-ins',
      _ReflectionFilter.writings: 'Writings',
      _ReflectionFilter.learningNotes: 'Learning notes',
    };
    // Wrap (not a horizontal scroller) so every option stays visible at
    // large text sizes on narrow phones.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((option) {
        final sel = _reflectionFilter == option.key;
        return ChoiceChip(
          label: Text(
            option.value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: sel ? AppTheme.brandWhite : AppTheme.textMuted,
            ),
          ),
          selected: sel,
          showCheckmark: false,
          onSelected: (value) {
            if (!value) return;
            setState(() => _reflectionFilter = option.key);
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
    );
  }

  Widget _buildEmptyFilteredReflections() {
    final message = switch (_reflectionFilter) {
      _ReflectionFilter.checkIns =>
        'No check-ins yet. Tap Quick check-in above to note how you feel.',
      _ReflectionFilter.writings =>
        'No writings yet. Tap Write above when you\'d like to reflect.',
      _ReflectionFilter.learningNotes =>
        'No learning notes yet. Notes you save while reading a lesson will show up here.',
      _ReflectionFilter.all => '',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w300,
          height: 1.45,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final embeddedInMainNav = MainNavigationScope.maybeOf(context) != null;
    // Switching between the hub, quick check-in and write steps shows the new
    // step from the top (the floating shortcuts work from anywhere in the list).
    _scrollController.syncStep(_entryMode);
    // With the shell's extendBody, padding.bottom = nav bar height while
    // viewPadding.bottom is only the home-indicator inset the nested
    // Scaffold already respects for FAB placement.
    final mq = MediaQuery.of(context);
    final fabNavLift = embeddedInMainNav
        ? (mq.padding.bottom - mq.viewPadding.bottom).clamp(0.0, 200.0)
        : 0.0;

    final content = SafeArea(
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
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A private space for how you feel',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _notesStreamFor(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final entries = snapshot.hasData
                        ? snapshot.data!.docs
                        : <QueryDocumentSnapshot>[];
                    final visibleEntries = <MapEntry<QueryDocumentSnapshot,
                        _ReflectionKind>>[];
                    for (final doc in entries) {
                      final data = doc.data() as Map<String, dynamic>;
                      final kind = _reflectionKindOf(data);
                      if (_matchesReflectionFilter(kind, _reflectionFilter)) {
                        visibleEntries.add(MapEntry(doc, kind));
                      }
                    }
                    final shownEntries =
                        _reflectionFilter == _ReflectionFilter.all
                            ? visibleEntries.take(_allReflectionsShown)
                            : visibleEntries;

                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact privacy indicator (replaces the large card).
                          Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 15, color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Private to you',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          else ...[
                            _buildReflectionFilterChips(),
                            const SizedBox(height: 16),
                            if (visibleEntries.isEmpty)
                              _buildEmptyFilteredReflections(),
                            ...shownEntries.map((entry) {
                              final doc = entry.key;
                              final data = doc.data() as Map<String, dynamic>;
                              return _EntryCard(
                                entryId: doc.id,
                                kind: entry.value,
                                content: data['content'] ?? '',
                                tag: data['tag'] ?? 'Untagged',
                                moduleTitle: data['moduleTitle'],
                                moduleId: data['moduleId']?.toString(),
                                highlightedText: data['highlightedText'],
                                createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                                prompt: data['prompt'],
                                isFeelingPrompt: data['isFeelingPrompt'] ?? false,
                              );
                            }),
                          ],
                          
                          // Clear the floating quick check-in / write buttons
                          // (2 x 56 + gap + margin) so the last reflection card
                          // and any save actions can scroll fully above them.
                          const SizedBox(height: 160),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );

    Widget body = embeddedInMainNav
        ? content
        : Stack(
            fit: StackFit.expand,
            children: [
              const AmbientBackground(),
              content,
            ],
          );
    if (kIsWeb) {
      // Flutter web (CanvasKit/skwasm) downloads its color-emoji fallback
      // font the first time an emoji is laid out, showing a tofu box until
      // it arrives. This screen is built eagerly in the main-nav
      // IndexedStack, so laying the mood emojis out offstage here starts
      // that download at app launch instead of when the picker opens.
      // iOS/Android use the system emoji font, so this is web-only.
      body = Stack(
        fit: StackFit.expand,
        children: [
          const Offstage(child: Text(_moodEmojiWarmup)),
          body,
        ],
      );
    }

    return Scaffold(
      backgroundColor:
          embeddedInMainNav ? Colors.transparent : AppTheme.backgroundWarm,
      body: body,
      // Shortcuts are only shown on the hub: inside the check-in / write cards
      // they duplicate the current mode and could cover Save / Cancel.
      floatingActionButton: _entryMode != _JournalEntryMode.hub
          ? null
          : Padding(
        // This nested Scaffold does not know about the shell's translucent
        // bottom nav (extendBody), so lift the buttons above it instead of
        // letting them sit on top of the tab bar.
        padding: EdgeInsets.only(bottom: fabNavLift),
        child: Column(
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
      ),
    );
  }
}

/// Single-line button label that scales down rather than wrapping at large
/// Dynamic Type / Bold Text sizes.
class _OneLineButtonLabel extends StatelessWidget {
  const _OneLineButtonLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(fontWeight: FontWeight.w300),
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
  final _ReflectionKind kind;
  final String content;
  final String tag;
  final String? moduleTitle;
  final String? moduleId;
  final String? highlightedText;
  final DateTime? createdAt;
  final String? prompt;
  final bool isFeelingPrompt;

  const _EntryCard({
    required this.entryId,
    required this.kind,
    required this.content,
    required this.tag,
    this.moduleTitle,
    this.moduleId,
    this.highlightedText,
    this.createdAt,
    this.prompt,
    this.isFeelingPrompt = false,
  });

  bool get _isLearningNote => kind == _ReflectionKind.learningNote;

  IconData get _kindIcon {
    switch (kind) {
      case _ReflectionKind.checkIn:
        return Icons.favorite;
      case _ReflectionKind.writing:
        return Icons.edit;
      case _ReflectionKind.learningNote:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = moduleTitle?.trim();
    // Learning notes preview what the user wrote; fall back to the
    // highlighted passage when the note body is empty.
    final preview = content.trim().isEmpty && highlightedText != null
        ? highlightedText!
        : content;

    // Whole card is the tap target (incl. padding) and opens the full entry;
    // the preview below is clamped to keep the timeline scannable.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEntryDetail(context),
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.borderLighter.withOpacity(0.5),
              ),
            ),
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
                  child: Icon(_kindIcon, color: AppTheme.brandWhite, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact date ("Sep 26, 2026") + tag in a Wrap so the tag
                      // drops to the next line instead of truncating the date
                      // under Bold Text / larger Dynamic Type.
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey[400]),
                              if (createdAt != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat.yMMMd().format(createdAt!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textLight,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (isFeelingPrompt && prompt != null)
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
                      ),
                      if (_isLearningNote && title != null && title.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.menu_book_outlined,
                                  size: 14, color: Color(0xFF663399)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF663399),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                          height: 1.5,
                        ),
                      ),
                      if (_isLearningNote)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _OpenLessonButton(
                            moduleId: moduleId,
                            moduleTitle: title,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        isLearningNote: _isLearningNote,
        // Uses the card's context: the dialog's own context is gone once it
        // pops itself before navigating to the lesson.
        onOpenLesson: () => openLearningNoteModule(
          context,
          moduleId: moduleId,
          moduleTitle: moduleTitle,
        ),
        highlightedText: highlightedText,
        createdAt: createdAt,
        prompt: prompt,
        isFeelingPrompt: isFeelingPrompt,
      ),
    );
  }
}

/// "Open lesson" action for journal notes taken inside a learning module.
class _OpenLessonButton extends StatefulWidget {
  final String? moduleId;
  final String? moduleTitle;
  final VoidCallback? onPressedOverride;

  const _OpenLessonButton({
    this.moduleId,
    this.moduleTitle,
    this.onPressedOverride,
  });

  @override
  State<_OpenLessonButton> createState() => _OpenLessonButtonState();
}

class _OpenLessonButtonState extends State<_OpenLessonButton> {
  bool _opening = false;

  Future<void> _open() async {
    if (widget.onPressedOverride != null) {
      widget.onPressedOverride!();
      return;
    }
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await openLearningNoteModule(
        context,
        moduleId: widget.moduleId,
        moduleTitle: widget.moduleTitle,
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _opening ? null : _open,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF663399),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: _opening
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF663399),
              ),
            )
          : const Icon(Icons.arrow_forward, size: 18),
      label: const Text(
        'Open lesson',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _EntryDetailDialog extends StatelessWidget {
  final String entryId;
  final String content;
  final String tag;
  final String? moduleTitle;
  final bool isLearningNote;
  final VoidCallback? onOpenLesson;
  final String? highlightedText;
  final DateTime? createdAt;
  final String? prompt;
  final bool isFeelingPrompt;

  const _EntryDetailDialog({
    required this.entryId,
    required this.content,
    required this.tag,
    this.moduleTitle,
    this.isLearningNote = false,
    this.onOpenLesson,
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
                      if (isLearningNote && onOpenLesson != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _OpenLessonButton(
                            onPressedOverride: () {
                              Navigator.of(context).pop();
                              onOpenLesson!();
                            },
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
