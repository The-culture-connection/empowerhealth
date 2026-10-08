import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Home/Learning Modules/birth_labor_education_topics.dart';
import '../Home/Learning Modules/learning_module_detail_screen.dart';
import '../app_router.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../pregnancy_loss/pregnancy_loss_learning_topics.dart';

/// Opens the lesson a journal learning note was taken from.
///
/// Notes saved from a lesson (see `NotesDialog`) store `moduleTitle` and,
/// when the lesson knew it, `moduleId` (the `learning_tasks` doc id, or a
/// static topic id). Older notes and some entry points only have the title,
/// so resolution falls back in order:
///   1. static topics (birth & labor, pregnancy loss) by id or title
///   2. `learning_tasks/{moduleId}` owned by the user
///   3. the user's `learning_tasks` with a matching title
///   4. the Learn tab, with a gentle message
Future<void> openLearningNoteModule(
  BuildContext context, {
  String? moduleId,
  String? moduleTitle,
}) async {
  final id = moduleId?.trim();
  final title = moduleTitle?.trim();

  for (final topic in birthLaborEducationTopics) {
    if ((id != null && id.isNotEmpty && topic.id == id) ||
        (title != null && title.isNotEmpty && topic.title == title)) {
      openBirthLaborTopic(context, topic);
      return;
    }
  }
  for (final topic in kPregnancyLossLearningTopics) {
    if ((id != null && id.isNotEmpty && topic.id == id) ||
        (title != null && title.isNotEmpty && topic.title == title)) {
      openPregnancyLossLearningTopic(context, topic);
      return;
    }
  }

  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    try {
      final tasks = FirebaseFirestore.instance.collection('learning_tasks');
      DocumentSnapshot<Map<String, dynamic>>? match;

      if (id != null && id.isNotEmpty) {
        try {
          final doc = await tasks.doc(id).get();
          if (doc.exists && doc.data()?['userId'] == userId) match = doc;
        } catch (_) {
          // Not a learning_tasks id (or not readable); try the title next.
        }
      }

      if (match == null && title != null && title.isNotEmpty) {
        final query = await tasks
            .where('userId', isEqualTo: userId)
            .where('title', isEqualTo: title)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) match = query.docs.first;
      }

      final data = match?.data();
      if (match != null && data != null) {
        final content = _contentToMarkdown(data['content']);
        if (content.trim().isNotEmpty) {
          if (!context.mounted) return;
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => LearningModuleDetailScreen(
                title: (data['title'] ?? title ?? 'Lesson').toString(),
                content: content,
                // Same books emoji as before, escaped: the detail screen
                // still receives it as its icon value.
                icon: '\u{1F4DA}',
                taskId: match!.id,
              ),
            ),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Error opening lesson from journal note: $e');
    }
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'We couldn\'t find that lesson. Here\'s your Learn library instead.',
      ),
      backgroundColor: AppTheme.brandPurple,
    ),
  );
  if (!MainNavigationScope.goToTab(context, MainNavigationScope.tabLearn)) {
    Navigator.pushNamed(context, Routes.learning);
  }
}

/// Mirrors the Learn list's Map -> markdown formatting for generated modules
/// whose `content` was stored as a structured map.
String _contentToMarkdown(dynamic content) {
  if (content is String) return content;
  if (content is! Map) return content?.toString() ?? '';

  const sections = <String, String>{
    'whatThisIs': 'What This Is',
    'whyItMatters': 'Why It Matters for Your Health',
    'whatToExpect': 'What to Expect',
    'whatYouCanAsk': 'What You Can Ask or Say',
    'risksOptionsAlternatives': 'Risks, Options, and Alternatives',
    'whenToSeekHelp': 'When to Seek Medical Help',
    'empowermentConnection': 'How This Connects to Your Empowerment',
    'keyPoints': 'Key Points',
    'yourRights': 'Your Rights',
    'insuranceNotes': 'Insurance Notes',
  };

  final buffer = StringBuffer();
  sections.forEach((key, heading) {
    final value = content[key];
    if (value == null) return;
    var text = value is List
        ? value.map((e) => '• $e').join('\n')
        : value.toString();
    text = text.trim();
    if (text.isEmpty) return;
    buffer
      ..writeln('## $heading')
      ..writeln(text)
      ..writeln();
  });
  return buffer.isEmpty ? content.toString() : buffer.toString();
}
