import 'package:cloud_firestore/cloud_firestore.dart';

class LearningModule {
  final String id;
  final String title;
  final String topic;
  final String trimester;
  final String content;
  final String moduleType;
  final bool isAIGenerated;
  final DateTime createdAt;

  LearningModule({
    required this.id,
    required this.title,
    required this.topic,
    required this.trimester,
    required this.content,
    required this.moduleType,
    required this.isAIGenerated,
    required this.createdAt,
  });

  factory LearningModule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LearningModule(
      id: doc.id,
      title: data['title'] ?? data['topic'] ?? 'Untitled',
      topic: data['topic'] ?? '',
      trimester: data['trimester'] ?? 'general',
      content: data['content'] ?? '',
      moduleType: data['moduleType'] ?? 'general',
      isAIGenerated: data['generatedBy'] == 'ai',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'topic': topic,
      'trimester': trimester,
      'content': content,
      'moduleType': moduleType,
      'generatedBy': isAIGenerated ? 'ai' : 'banked',
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class VisitSummary {
  final String id;
  final String userId;
  final String summary;
  final String? originalNotes;
  final String? diagnoses;
  final String? medications;
  final String? emotionalFlags;
  final DateTime createdAt;

  VisitSummary({
    required this.id,
    required this.userId,
    required this.summary,
    this.originalNotes,
    this.diagnoses,
    this.medications,
    this.emotionalFlags,
    required this.createdAt,
  });

  factory VisitSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisitSummary(
      id: doc.id,
      userId: data['userId'] ?? '',
      summary: data['summary'] ?? '',
      originalNotes: data['originalNotes'],
      diagnoses: data['diagnoses'],
      medications: data['medications'],
      emotionalFlags: data['emotionalFlags'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class BirthPlan {
  final String id;
  final String userId;
  final String content;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  BirthPlan({
    required this.id,
    required this.userId,
    required this.content,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BirthPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BirthPlan(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['birthPlan'] ?? '',
      preferences: data['preferences'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

