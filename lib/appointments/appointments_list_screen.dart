import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'upload_visit_summary_screen.dart';
import 'visit_detail_screen.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../immediate_support/widgets/immediate_support_home_card.dart';
import 'visit_summary_preview.dart';
import '../app_router.dart';
import '../cors/main_navigation_scope.dart';

class AppointmentsListScreen extends StatelessWidget {
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
          child: userId == null
              ? Center(
                  child: Text(
                    'Sign in to see visit summaries',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 672),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HearthPushedHeader(
                            title: 'My Visits',
                            subtitle: 'Summaries in plain language, newest first',
                            actions: [
                              _AddVisitButton(
                                tooltip: 'Add visit summary',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          const UploadVisitSummaryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: ImmediateSupportHomeCard(
                              entrySource: 'after_visit',
                              compact: true,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.favorite_border,
                                    color: AppTheme.brandPurple,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Plain-language summaries to support you. Not medical advice.',
                                    style: hearthCaptionStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _VisitSummariesList(
                            userId: userId,
                            onOpenDetail: (summaryId, data) async {
                              await logVisitSummaryViewed(summaryId);
                              if (!context.mounted) return;
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => VisitDetailScreen(
                                    summaryId: summaryId,
                                    data: data,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}

/// The header's add action: the one filled purple circle on this screen.
class _AddVisitButton extends StatelessWidget {
  const _AddVisitButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.brandPurple,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: const Icon(Icons.add, color: AppTheme.onPurple, size: 24),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

Future<void> logVisitSummaryViewed(String summaryId) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await DatabaseService().getUserProfile(uid);
    await AnalyticsService().logVisitSummaryViewed(
      summaryId: summaryId,
      userProfile: profile,
    );
  } catch (_) {}
}

class _VisitSummariesList extends StatelessWidget {
  const _VisitSummariesList({
    required this.userId,
    required this.onOpenDetail,
  });

  final String? userId;
  final Future<void> Function(String summaryId, Map<String, dynamic> data)
      onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Center(
        child: Text(
          'Sign in to see visit summaries',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('visit_summaries')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      final text = Theme.of(context).textTheme;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HearthIconChip(
                                Icons.add_box_outlined,
                                size: 80,
                                iconSize: 32,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No visits yet',
                                textAlign: TextAlign.center,
                                style: text.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'When you add an after-visit summary, it will show up here.',
                                textAlign: TextAlign.center,
                                style: text.bodyLarge,
                              ),
                              const SizedBox(height: 24),
                              HearthButton.primary(
                                expand: false,
                                icon: Icons.add,
                                label: 'Upload visit summary',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UploadVisitSummaryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Filter out duplicates - keep only the most recent summary per appointment date
                    final seenDates = <String>{};
                    final uniqueDocs = <DocumentSnapshot>[];
                    
                    for (final doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final appointmentDate = data['appointmentDate'];
                      
                      // Create a normalized date key for comparison
                      String dateKey = 'unknown';
                      if (appointmentDate != null) {
                        try {
                          DateTime dt;
                          if (appointmentDate is Timestamp) {
                            dt = appointmentDate.toDate();
                          } else if (appointmentDate is String) {
                            dt = DateTime.parse(appointmentDate);
                          } else {
                            continue; // Skip if we can't parse
                          }
                          // Normalize to start of day
                          final normalized = DateTime(dt.year, dt.month, dt.day);
                          dateKey = '${normalized.year}-${normalized.month}-${normalized.day}';
                        } catch (e) {
                          // If parsing fails, use document ID as key
                          dateKey = doc.id;
                        }
                      } else {
                        dateKey = doc.id;
                      }
                      
                      // Only add if we haven't seen this date before
                      // If we have, keep the one with the most recent createdAt
                      if (!seenDates.contains(dateKey)) {
                        seenDates.add(dateKey);
                        uniqueDocs.add(doc);
                      } else {
                        // Find the existing doc with this date and compare createdAt
                        final existingIndex = uniqueDocs.indexWhere((d) {
                          final dData = d.data() as Map<String, dynamic>;
                          final dDate = dData['appointmentDate'];
                          String dDateKey = 'unknown';
                          try {
                            DateTime dt;
                            if (dDate is Timestamp) {
                              dt = dDate.toDate();
                            } else if (dDate is String) {
                              dt = DateTime.parse(dDate);
                            } else {
                              return false;
                            }
                            final normalized = DateTime(dt.year, dt.month, dt.day);
                            dDateKey = '${normalized.year}-${normalized.month}-${normalized.day}';
                          } catch (e) {
                            return false;
                          }
                          return dDateKey == dateKey;
                        });
                        
                        if (existingIndex >= 0) {
                          final existingDoc = uniqueDocs[existingIndex];
                          final existingData = existingDoc.data() as Map<String, dynamic>;
                          final newData = data;
                          
                          // Compare createdAt - keep the most recent one
                          final existingCreated = existingData['createdAt'];
                          final newCreated = newData['createdAt'];
                          
                          DateTime? existingTime;
                          DateTime? newTime;
                          
                          if (existingCreated is Timestamp) {
                            existingTime = existingCreated.toDate();
                          }
                          if (newCreated is Timestamp) {
                            newTime = newCreated.toDate();
                          }
                          
                          // Replace if new one is more recent
                          if (newTime != null && existingTime != null && newTime.isAfter(existingTime)) {
                            uniqueDocs[existingIndex] = doc;
                          }
                        }
                      }
                    }
                    
                    // Sort by most recently summarized (createdAt), then appointment date
                    uniqueDocs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final ac = aData['createdAt'];
                      final bc = bData['createdAt'];
                      DateTime? aCreated;
                      DateTime? bCreated;
                      if (ac is Timestamp) aCreated = ac.toDate();
                      if (bc is Timestamp) bCreated = bc.toDate();
                      if (aCreated != null && bCreated != null) {
                        final c = bCreated.compareTo(aCreated);
                        if (c != 0) return c;
                      } else if (aCreated != null) {
                        return -1;
                      } else if (bCreated != null) {
                        return 1;
                      }

                      final aDate = aData['appointmentDate'];
                      final bDate = bData['appointmentDate'];
                      DateTime? aTime;
                      DateTime? bTime;
                      if (aDate is Timestamp) {
                        aTime = aDate.toDate();
                      } else if (aDate is String) {
                        try {
                          aTime = DateTime.parse(aDate);
                        } catch (e) {
                          aTime = DateTime(1970);
                        }
                      }
                      if (bDate is Timestamp) {
                        bTime = bDate.toDate();
                      } else if (bDate is String) {
                        try {
                          bTime = DateTime.parse(bDate);
                        } catch (e) {
                          bTime = DateTime(1970);
                        }
                      }
                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return bTime.compareTo(aTime);
                    });

                    final latestDoc =
                        uniqueDocs.isNotEmpty ? uniqueDocs.first : null;
                    final pastDocs = uniqueDocs.length > 1
                        ? uniqueDocs.sublist(1)
                        : <DocumentSnapshot>[];

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (latestDoc != null) ...[
                            const Padding(
                              padding: EdgeInsets.only(top: 24, bottom: 14),
                              child: HearthSectionHeading('Most recent visit'),
                            ),
                            _MostRecentVisitCard(
                              doc: latestDoc,
                              onOpen: onOpenDetail,
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.only(top: 24, bottom: 14),
                            child: HearthSectionHeading('Past visits'),
                          ),
                          if (pastDocs.isEmpty && latestDoc != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'No older visits yet.',
                                style: hearthCardBodyStyle,
                              ),
                            ),
                          ...pastDocs.map(
                            (doc) => _PastVisitListTile(
                              doc: doc,
                              onOpenDetail: onOpenDetail,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const _PastVisitNotesFooter(),
                        ],
                      ),
                    );
                  },
                );
  }
}

class _MostRecentVisitCard extends StatelessWidget {
  const _MostRecentVisitCard({
    required this.doc,
    required this.onOpen,
  });

  final DocumentSnapshot doc;
  final Future<void> Function(String summaryId, Map<String, dynamic> data)
      onOpen;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final appointmentDate = data['appointmentDate'];
    final questions = _questionsFromSummaryData(data);

    return HearthCard(
      onTap: () async => onOpen(doc.id, data),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HearthIconChip(Icons.calendar_today_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDateShort(appointmentDate),
                      style: _visitDateStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _providerSubtitleLine(data),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: hearthCaptionStyle.copyWith(
                        fontSize: 14,
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (questions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.borderWarm),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: AppTheme.brandPurple,
                ),
                SizedBox(width: 8),
                Text('Questions to ask', style: _cardLabelStyle),
              ],
            ),
            const SizedBox(height: 10),
            ...questions.take(2).map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Dot(color: AppTheme.brandGold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(q, style: hearthCardBodyStyle),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          _VisitLessonsSection(summaryId: doc.id),
        ],
      ),
    );
  }
}

/// Visit date on list cards: 17/24 bold ink.
const TextStyle _visitDateStyle = TextStyle(
  fontFamily: AppTheme.sansFamily,
  fontSize: 17,
  height: 24 / 17,
  fontWeight: FontWeight.w700,
  color: AppTheme.ink,
);

/// Small purple label inside a card ("Questions to ask").
const TextStyle _cardLabelStyle = TextStyle(
  fontFamily: AppTheme.sansFamily,
  fontSize: 13,
  height: 20 / 13,
  fontWeight: FontWeight.w700,
  color: AppTheme.brandPurple,
);

/// 6px bullet, nudged down to sit on the first line of 14/21 text.
class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: 6,
        height: 6,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Lessons the app generated from a visit summary, with a way to open them in
/// the Learn tab (bottom tabs visible). Hidden when the visit has none.
class _VisitLessonsSection extends StatefulWidget {
  const _VisitLessonsSection({required this.summaryId, this.compact = false});

  final String summaryId;
  final bool compact;

  @override
  State<_VisitLessonsSection> createState() => _VisitLessonsSectionState();
}

class _VisitLessonsSectionState extends State<_VisitLessonsSection> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _lessons;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Equality filters only, so no composite index is needed.
      _lessons = FirebaseFirestore.instance
          .collection('learning_tasks')
          .where('userId', isEqualTo: uid)
          .where('visitSummaryId', isEqualTo: widget.summaryId)
          .snapshots();
    }
  }

  void _openLearn() {
    if (!MainNavigationScope.goToTab(context, MainNavigationScope.tabLearn)) {
      Navigator.pushNamed(context, Routes.learning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _lessons;
    if (stream == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final titles = (snapshot.data?.docs ?? const [])
            .map((d) => d.data())
            .where((d) => d['moduleType'] == 'visit_based' && d['isArchived'] != true)
            .map((d) => (d['title'] ?? '').toString().trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (titles.isEmpty) return const SizedBox.shrink();
        final count = titles.length == 1 ? '1 lesson' : '${titles.length} lessons';
        final openButton = HearthButton.text(
          onPressed: _openLearn,
          icon: Icons.school_outlined,
          label: 'Open in Learn',
        );
        if (widget.compact) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text('$count from this visit', style: hearthCaptionStyle),
                openButton,
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.borderWarm),
            const SizedBox(height: 14),
            const Text('Lessons from this visit', style: _cardLabelStyle),
            const SizedBox(height: 10),
            ...titles.take(3).map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(t, style: hearthCardBodyStyle),
                  ),
                ),
            if (titles.length > 3)
              Text('and ${titles.length - 3} more', style: hearthCaptionStyle),
            Align(alignment: Alignment.centerLeft, child: openButton),
          ],
        );
      },
    );
  }
}

class _PastVisitListTile extends StatelessWidget {
  const _PastVisitListTile({
    required this.doc,
    required this.onOpenDetail,
  });

  final DocumentSnapshot doc;
  final Future<void> Function(String summaryId, Map<String, dynamic> data)
      onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final appointmentDate = data['appointmentDate'];
    final preview = previewLineFromVisitSummary(data);

    return HearthCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () async {
        await onOpenDetail(doc.id, data);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HearthIconChip(Icons.description_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateShort(appointmentDate),
                  style: _visitDateStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  'Visit summary · ${data['readingLevel'] ?? '6th grade reading level'}',
                  style: hearthCaptionStyle,
                ),
                if (preview != null && preview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: hearthCardBodyStyle,
                  ),
                ],
                _VisitLessonsSection(summaryId: doc.id, compact: true),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _PastVisitNotesFooter extends StatelessWidget {
  const _PastVisitNotesFooter();

  @override
  Widget build(BuildContext context) {
    return const HearthFeatureCard(
      padding: EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HearthIconChip(Icons.description_outlined, tone: HearthChipTone.surface),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notes from past visits', style: hearthCardTitleStyle),
                SizedBox(height: 4),
                Text(
                  'Your visit history helps you track your journey and prepare for future appointments.',
                  style: hearthCardBodyStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _questionsFromSummaryData(Map<String, dynamic> data) {
  final sd = data['summaryData'];
  if (sd is! Map<String, dynamic>) return [];
  final q = sd['questionsToAsk'];
  if (q is List) {
    return q
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList();
  }
  if (q is String && q.trim().isNotEmpty) {
    return [q.trim()];
  }
  return [];
}

String _providerSubtitleLine(Map<String, dynamic> data) {
  final sd = data['summaryData'];
  if (sd is Map<String, dynamic>) {
    for (final key in ['providerName', 'doctorName', 'clinicianName']) {
      final v = sd[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
  }
  final top = data['providerName'];
  if (top != null && top.toString().trim().isNotEmpty) {
    return top.toString().trim();
  }
  final rl = data['readingLevel'] ?? '6th grade reading level';
  return 'Visit summary · $rl';
}

/// Compact date for list rows (less calendar-heavy than long-form).
String _formatDateShort(dynamic date) {
  if (date == null) return 'Date not set';
  if (date is Timestamp) {
    return DateFormat('MMM d, yyyy').format(date.toDate());
  }
  if (date is String) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (e) {
      return date;
    }
  }
  return date.toString();
}

