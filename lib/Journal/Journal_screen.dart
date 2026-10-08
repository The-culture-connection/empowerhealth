import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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

/// Quick check-in moods, in picker order. The picker shows the nature icon;
/// the emoji is still saved at the start of the entry so stored check-ins
/// keep the same format.
const List<({String emoji, String label, IconData icon})> _moods = [
  (emoji: '\u{1F60A}', label: 'Joyful', icon: Icons.wb_sunny_outlined),
  (emoji: '\u{1F60C}', label: 'Calm', icon: Icons.eco_outlined),
  (emoji: '\u{1F610}', label: 'Okay', icon: Icons.waves),
  (emoji: '\u{1F61F}', label: 'Worried', icon: Icons.cloud_outlined),
  (emoji: '\u{1F622}', label: 'Tearful', icon: Icons.water_drop_outlined),
];

/// The mood a saved check-in starts with (`emoji label`), if any.
({String emoji, String label, IconData icon})? _moodOf(String content) {
  for (final mood in _moods) {
    if (content.startsWith('${mood.emoji} ${mood.label}')) return mood;
  }
  return null;
}

/// Saved text without the leading mood emoji; the app shows moods as icons.
String _withoutMoodEmoji(String content) {
  final mood = _moodOf(content);
  return mood == null ? content : content.substring(mood.emoji.length + 1);
}

/// Mood emojis that saved check-ins open with. Laid out offstage on web (see
/// build) so CanvasKit fetches its color-emoji fallback font before an entry
/// that contains one is opened.
const String _moodEmojiWarmup = '\u{1F60A}\u{1F60C}\u{1F610}\u{1F61F}\u{1F622}';

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
          content: Text('Please enter some text before saving'),
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
            content: Text('Entry saved to journal!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: ${e.toString()}'),
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
            // The emoji is saved with the entry but never shown.
            content: Text('Feeling entry saved: $emoji $label'.replaceFirst('$emoji ', '')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving feeling: ${e.toString()}'),
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
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        // Equal-height tiles so the two choices line up when one subtitle wraps.
        IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _EntryMethodTile(
                icon: Icons.favorite_border,
                title: 'Quick check-in',
                subtitle: 'Mood + optional note',
                onTap: () => setState(() => _entryMode = _JournalEntryMode.quick),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EntryMethodTile(
                icon: Icons.edit_outlined,
                title: 'Write',
                subtitle: 'Longer reflection',
                onTap: _openWriteMode,
              ),
            ),
          ],
          ),
        ),
      ],
    );
  }

  /// Save + Cancel pair shared by the check-in and write cards.
  Widget _buildSaveCancelRow({
    required String saveLabel,
    required VoidCallback onSave,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandGold,
              foregroundColor: AppTheme.ink,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.ink,
                    ),
                  )
                : _OneLineButtonLabel(saveLabel),
          ),
        ),
        const SizedBox(width: 12),
        // Equal-width controls so Save and Cancel are balanced; labels
        // stay on one line (scaled down if needed at large text sizes).
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : _resetToHub,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const _OneLineButtonLabel('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCheckInCard() {
    final textTheme = Theme.of(context).textTheme;
    return HearthCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick check-in', style: textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('How are you feeling right now?', style: textTheme.bodyLarge),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final mood in _moods)
                Expanded(
                  child: _SelectableMoodChip(
                    icon: mood.icon,
                    label: mood.label,
                    selected: _quickMoodLabel == mood.label,
                    onTap: () => setState(() {
                      _quickMoodEmoji = mood.emoji;
                      _quickMoodLabel = mood.label;
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Add a note (optional)',
            style: textTheme.labelMedium?.copyWith(color: AppTheme.ink),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _quickNoteController,
            maxLines: 3,
            style: textTheme.bodyLarge?.copyWith(color: AppTheme.ink),
            decoration: const InputDecoration(
              hintText: 'Anything you\'d like to remember…',
              // Inset fill so the field reads as a well inside the card.
              fillColor: AppTheme.surfaceInset,
            ),
          ),
          const SizedBox(height: 18),
          _buildSaveCancelRow(
            saveLabel: 'Save check-in',
            onSave: _submitQuickCheckIn,
          ),
        ],
      ),
    );
  }

  Widget _buildWriteCard() {
    final textTheme = Theme.of(context).textTheme;
    return HearthCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Write', style: textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Start from a gentle prompt or write freely.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _writePrompts.map((p) {
              final sel = _writePrompt == p;
              return HearthChoiceChip(
                label: p,
                selected: sel,
                // Re-tapping the chosen prompt does nothing, so it never
                // wipes what has been written under it.
                onSelected: sel
                    ? null
                    : () {
                  setState(() {
                    _writePrompt = p;
                    _entryController.text = '$p\n\n';
                    _entryController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _entryController.text.length),
                    );
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _entryController,
            maxLines: 8,
            style: textTheme.bodyLarge?.copyWith(color: AppTheme.ink),
            decoration: const InputDecoration(
              hintText: 'How are you feeling today? Add whatever feels right…',
              // Inset fill so the field reads as a well inside the card.
              fillColor: AppTheme.surfaceInset,
            ),
          ),
          const SizedBox(height: 18),
          _buildSaveCancelRow(saveLabel: 'Save entry', onSave: _saveEntry),
        ],
      ),
    );
  }

  Widget _buildWarmEmptyReflections() {
    return HearthCard(
      padding: const EdgeInsets.all(22),
      child: SizedBox(
        width: double.infinity,
        child: Column(
        children: [
          const HearthIconChip(Icons.favorite_border),
          const SizedBox(height: 12),
          Text(
            'Your reflections will show up here',
            textAlign: TextAlign.center,
            style: hearthCardTitleStyle,
          ),
          const SizedBox(height: 6),
          Text(
            'There\'s no rush. Try a quick check-in above, or write a few words when you\'re ready.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        ),
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
        return HearthChoiceChip(
          label: option.value,
          selected: sel,
          primary: true,
          onSelected: sel
              ? null
              : () => setState(() => _reflectionFilter = option.key),
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
        style: Theme.of(context).textTheme.bodyMedium,
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
              const HearthTabHeader(
                title: 'Your journal',
                subtitle: 'A private space for how you feel',
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Compact privacy indicator (replaces the large card).
                          const Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _PrivatePill(label: 'Private to you'),
                          ),
                          const SizedBox(height: 24),
                          if (_entryMode == _JournalEntryMode.hub) ...[
                            _buildEntryMethodGrid(),
                          ] else if (_entryMode == _JournalEntryMode.quick) ...[
                            _buildQuickCheckInCard(),
                          ] else ...[
                            _buildWriteCard(),
                          ],
                          const SizedBox(height: 28),

                          const HearthSectionHeading('Recent reflections'),
                          const SizedBox(height: 14),

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
      // that download at app launch instead of when a saved check-in opens.
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
          embeddedInMainNav ? Colors.transparent : AppTheme.ground,
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
          _JournalShortcutButton(
            icon: Icons.favorite_border,
            color: AppTheme.brandPurpleMid,
            onTap: () => setState(() => _entryMode = _JournalEntryMode.quick),
          ),
          const SizedBox(height: 10),
          _JournalShortcutButton(
            icon: Icons.add,
            color: AppTheme.brandPurple,
            onTap: _openWriteMode,
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
      ),
    );
  }
}

/// "Private to you" pill under the journal header.
class _PrivatePill extends StatelessWidget {
  const _PrivatePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: AppTheme.surface,
        shape: StadiumBorder(side: BorderSide(color: AppTheme.borderWarm)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 15, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round floating shortcut on the hub (quick check-in / write). The ground
/// ring separates it from cards it floats over; Hearth keeps shadows for the
/// Support button only.
class _JournalShortcutButton extends StatelessWidget {
  const _JournalShortcutButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(
        side: BorderSide(color: AppTheme.ground, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: AppTheme.onPurple, size: 24),
        ),
      ),
    );
  }
}

class _EntryMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EntryMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HearthIconChip(icon),
          const SizedBox(height: 14),
          Text(title, style: hearthCardTitleStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: hearthCaptionStyle),
        ],
      ),
    );
  }
}

/// One mood in the quick check-in picker: a nature icon in a circle over its
/// label. Selected moods get the warm tint and a purple ring.
class _SelectableMoodChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableMoodChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.brandPurple : AppTheme.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppTheme.tintWarm : AppTheme.ground,
                  border: Border.all(
                    color: selected ? AppTheme.brandPurple : AppTheme.borderWarm,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 6),
              // Five moods share one row, so long labels shrink rather than wrap.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
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

  IconData _kindIcon(
    ({String emoji, String label, IconData icon})? mood,
  ) {
    switch (kind) {
      case _ReflectionKind.checkIn:
        return mood?.icon ?? Icons.favorite_border;
      case _ReflectionKind.writing:
        return Icons.edit_outlined;
      case _ReflectionKind.learningNote:
        return Icons.menu_book_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = moduleTitle?.trim();
    // Check-ins show their mood as the nature icon, so the saved emoji is
    // left out of the preview and the full entry.
    final mood = kind == _ReflectionKind.checkIn ? _moodOf(content) : null;
    // Learning notes preview what the user wrote; fall back to the
    // highlighted passage when the note body is empty.
    final preview = mood != null
        ? content.substring(mood.emoji.length + 1)
        : content.trim().isEmpty && highlightedText != null
            ? highlightedText!
            : content;

    // Whole card is the tap target (incl. padding) and opens the full entry;
    // the preview below is clamped to keep the timeline scannable.
    return HearthCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showEntryDetail(context),
      padding: EdgeInsets.fromLTRB(16, 16, 16, _isLearningNote ? 6 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HearthIconChip(_kindIcon(mood)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact date ("Sep 26, 2026") + tag in a Wrap so the tag
                // drops to the next line instead of truncating the date
                // under Bold Text / larger Dynamic Type.
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppTheme.textMuted),
                          if (createdAt != null) ...[
                            const SizedBox(width: 5),
                            Text(
                              DateFormat.yMMMd().format(createdAt!),
                              style: hearthCaptionStyle,
                            ),
                          ],
                        ],
                      ),
                      if (isFeelingPrompt && prompt != null)
                        const HearthTag('feeling'),
                    ],
                  ),
                ),
                if (_isLearningNote && title != null && title.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.menu_book_outlined,
                            size: 14, color: AppTheme.brandPurple),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: hearthCaptionStyle.copyWith(
                            color: AppTheme.brandPurple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // Check-ins and writings lead with the mood or prompt, so
                  // they read as the card title; lesson notes read as body.
                  style: _isLearningNote
                      ? hearthCardBodyStyle
                      : const TextStyle(
                          fontFamily: AppTheme.sansFamily,
                          fontSize: 15,
                          height: 22 / 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
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
    );
  }

  void _showEntryDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EntryDetailDialog(
        entryId: entryId,
        content: _withoutMoodEmoji(content),
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
        foregroundColor: AppTheme.brandPurple,
        // Flush with the text above it, as in the card layout.
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: _opening
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.brandPurple,
              ),
            )
          : const Icon(Icons.arrow_forward, size: 18),
      label: const Text(
        'Open lesson',
        style: TextStyle(
          fontFamily: AppTheme.sansFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
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
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColoredBox(
              color: AppTheme.brandPurple,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Journal Entry',
                        style: TextStyle(
                          fontFamily: AppTheme.serifFamily,
                          fontSize: 22,
                          height: 28 / 22,
                          color: AppTheme.onPurple,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.onPurple),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFeelingPrompt && prompt != null) ...[
                      _DialogTintRow(
                        icon: Icons.psychology_outlined,
                        text: prompt!,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (moduleTitle != null) ...[
                      _DialogTintRow(
                        icon: Icons.menu_book_outlined,
                        text: 'From: $moduleTitle',
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
                      HearthCard(
                        radius: BorderRadius.circular(AppTheme.fieldRadius),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.format_quote,
                                    size: 18, color: AppTheme.brandPurple),
                                const SizedBox(width: 8),
                                Text(
                                  'Highlighted Text:',
                                  style: hearthCaptionStyle.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              highlightedText!,
                              style: hearthCardBodyStyle.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text('Your Notes:', style: hearthCardTitleStyle),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 15,
                        height: 24 / 15,
                        color: AppTheme.ink,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Created: ${_formatJournalCreatedAt(createdAt!)}',
                        style: hearthCaptionStyle.copyWith(
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

/// Warm-tint label row at the top of the entry dialog (prompt, source lesson).
class _DialogTintRow extends StatelessWidget {
  const _DialogTintRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.tintWarm,
        borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 18, color: AppTheme.brandPurple),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
