import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../cors/ui_theme.dart';
import 'upload_visit_summary_screen.dart';
import 'visit_detail_screen.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import 'visit_summary_preview.dart';

class AppointmentsListScreen extends StatelessWidget {
  const AppointmentsListScreen({super.key});

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
          child: userId == null
              ? const Center(child: Text('Sign in to see visit summaries'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 672),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'My Visits',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w400,
                                          height: 1.3,
                                          letterSpacing: -0.28,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Summaries in plain language — newest first',
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.45,
                                          color: AppTheme.textMuted,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFB899D4),
                                        Color(0xFF9D7AB8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFB899D4)
                                            .withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: AppTheme.brandWhite,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (context) =>
                                              const UploadVisitSummaryScreen(),
                                        ),
                                      );
                                    },
                                    tooltip: 'Add visit summary',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Container(
                              padding: const EdgeInsets.all(22),
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
                                border: Border.all(
                                  color:
                                      AppTheme.borderLight.withOpacity(0.4),
                                ),
                                boxShadow: AppTheme.shadowSoft(
                                  opacity: 0.1,
                                  blur: 22,
                                  y: 6,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFF5EEE0),
                                          Color(0xFFEBE0D6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.favorite_border,
                                      color: Color(0xFFD4A574),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'You deserve to feel heard at every visit',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.05,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'These summaries help you understand what was discussed. They\'re written in simple language and organized to support you, not replace medical advice.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.45,
                                            color: AppTheme.textMuted,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
      return const Center(child: Text('Sign in to see visit summaries'));
    }
    return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('visit_summaries')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF663399),
                                      Color(0xFF8855BB),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Icon(
                                  Icons.medical_information_outlined,
                                  size: 40,
                                  color: AppTheme.brandWhite,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No visits yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'When you add a visit summary, it will show up here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFD4C5E0),
                                      Color(0xFFA89CB5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const UploadVisitSummaryScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add, color: AppTheme.brandWhite),
                                  label: const Text(
                                    'Add Visit Summary',
                                    style: TextStyle(color: AppTheme.brandWhite),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
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
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (latestDoc != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 20, bottom: 8),
                              child: Text(
                                'MOST RECENT VISIT',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      AppTheme.brandPurple.withOpacity(0.85),
                                ),
                              ),
                            ),
                            _MostRecentVisitCard(
                              doc: latestDoc,
                              onOpen: onOpenDetail,
                            ),
                          ],
                          Padding(
                            padding: EdgeInsets.only(
                              top: latestDoc != null ? 16 : 20,
                              bottom: 8,
                            ),
                            child: Text(
                              'PAST VISITS',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.brandPurple.withOpacity(0.85),
                              ),
                            ),
                          ),
                          if (pastDocs.isEmpty && latestDoc != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'No older visits yet.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ...pastDocs.map(
                            (doc) => _PastVisitListTile(
                              doc: doc,
                              onOpenDetail: onOpenDetail,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _PastVisitNotesFooter(),
                          const SizedBox(height: 8),
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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderLight.withOpacity(0.4),
        ),
        boxShadow: AppTheme.shadowSoft(
          opacity: 0.07,
          blur: 18,
          y: 3,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async => onOpen(doc.id, data),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.brandPurple.withOpacity(0.14),
                            AppTheme.brandPurple.withOpacity(0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: AppTheme.brandPurple.withOpacity(0.9),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateShort(appointmentDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.05,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _providerSubtitleLine(data),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (questions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: AppTheme.borderLight.withOpacity(0.45),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: Color(0xFFD4A574),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'QUESTIONS TO ASK',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brandPurple.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...questions.take(2).map(
                        (q) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD4A574),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  q,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderLight.withOpacity(0.35),
        ),
        boxShadow: AppTheme.shadowSoft(
          opacity: 0.07,
          blur: 18,
          y: 3,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            await onOpenDetail(doc.id, data);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.article_rounded,
                    color: AppTheme.brandPurple.withOpacity(0.85),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateShort(appointmentDate),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Visit summary · ${data['readingLevel'] ?? '6th grade reading level'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      if (preview != null && preview.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppTheme.textLightest,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PastVisitNotesFooter extends StatelessWidget {
  const _PastVisitNotesFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFAF7F3),
            Color(0xFFF5F0EB),
            Color(0xFFF0EAD8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderLight.withOpacity(0.4),
        ),
        boxShadow: AppTheme.shadowSoft(
          opacity: 0.08,
          blur: 20,
          y: 4,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.article_outlined,
              color: Color(0xFFD4A574),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes from past visits',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.05,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your visit history helps you track your journey and prepare for future appointments.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
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

