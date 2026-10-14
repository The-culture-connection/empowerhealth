import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Home/Learning Modules/birth_labor_education_topics.dart';
import '../appointments/appointments_list_screen.dart';
import '../appointments/visit_detail_screen.dart';
import '../resources/open_app_resource.dart';

/// Opens the newest visit summary (questions to ask), or [AppointmentsListScreen] if none.
Future<void> openActiveVisitSummaryForPrepare(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    if (!context.mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AppointmentsListScreen(),
      ),
    );
    return;
  }

  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('visit_summaries')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .get();

  if (!context.mounted) return;

  if (snap.docs.isNotEmpty) {
    final doc = snap.docs.first;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => VisitDetailScreen(
          summaryId: doc.id,
          data: doc.data(),
        ),
      ),
    );
    return;
  }

  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => const AppointmentsListScreen(),
    ),
  );
}

BirthLaborEducationTopic? birthLaborTopicById(String id) {
  for (final t in birthLaborEducationTopics) {
    if (t.id == id) return t;
  }
  return null;
}

void openBirthLaborTopicById(BuildContext context, String topicId) {
  final topic = birthLaborTopicById(topicId);
  if (topic != null) {
    openBirthLaborTopic(context, topic);
    return;
  }
  openBirthLaborTopic(context, birthLaborEducationTopics.first);
}

Future<void> launchCareCheckinExternalUrl(BuildContext context, String url) async {
  await launchAppExternalUrl(context, url);
}

Future<void> openVisitSummariesList(BuildContext context) async {
  if (!context.mounted) return;
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => const AppointmentsListScreen(),
    ),
  );
}
