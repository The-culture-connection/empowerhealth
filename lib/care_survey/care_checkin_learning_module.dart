import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Home/Learning Modules/learning_module_detail_screen.dart';
import '../cors/ui_theme.dart';
import '../services/database_service.dart';
import '../services/firebase_functions_service.dart';
import '../utils/pregnancy_utils.dart';

/// Generates (or reopens) a personalized learning module from a care check-in support tile.
Future<void> generateAndOpenCareCheckinLearningModule(
  BuildContext context, {
  required String topic,
  required String description,
  String? sourceActionId,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create a learning module.')),
      );
    }
    return;
  }

  final existing = await FirebaseFirestore.instance
      .collection('learning_tasks')
      .where('userId', isEqualTo: userId)
      .where('title', isEqualTo: topic)
      .where('sourceFeature', isEqualTo: 'care_checkin')
      .limit(1)
      .get();

  if (existing.docs.isNotEmpty) {
    final doc = existing.docs.first;
    final data = doc.data();
    final content = data['content'];
    final contentStr = content is String
        ? content
        : (content != null ? content.toString() : '');
    if (contentStr.trim().isNotEmpty && context.mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LearningModuleDetailScreen(
            title: topic,
            content: contentStr,
            icon: '📚',
            taskId: doc.id,
          ),
        ),
      );
      return;
    }
  }

  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.brandPurple),
            const SizedBox(height: 20),
            Text(
              'Creating your module…',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              topic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  try {
    final profile = await DatabaseService().getUserProfile(userId);
    final trimester = profile?.dueDate != null
        ? PregnancyUtils.calculateTrimester(profile!.dueDate)
        : 'First';

    Map<String, dynamic>? profileData;
    if (profile != null) {
      profileData = {
        'chronicConditions': profile.chronicConditions,
        'healthLiteracyGoals': profile.healthLiteracyGoals,
        'insuranceType': profile.insuranceType,
        'providerPreferences': profile.providerPreferences,
        'educationLevel': profile.educationLevel,
      };
    }

    final result = await FirebaseFunctionsService().generateLearningContent(
      topic: topic,
      trimester: trimester,
      moduleType: 'care_checkin',
      userProfile: profileData,
    );

    final content = result['content']?.toString() ?? '';
    if (content.trim().isEmpty) {
      throw Exception('No content returned');
    }

    final docRef = await FirebaseFirestore.instance.collection('learning_tasks').add({
      'userId': userId,
      'title': topic,
      'description': description,
      'trimester': trimester,
      'moduleType': 'care_checkin',
      'isGenerated': true,
      'content': content,
      'sourceFeature': 'care_checkin',
      if (sourceActionId != null) 'sourceActionId': sourceActionId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LearningModuleDetailScreen(
          title: topic,
          content: content,
          icon: '📚',
          taskId: docRef.id,
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create module: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
