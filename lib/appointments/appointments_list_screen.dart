import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../cors/ui_theme.dart';
import 'upload_visit_summary_screen.dart';

class AppointmentsListScreen extends StatelessWidget {
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Visits'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadVisitSummaryScreen(),
                ),
              );
            },
            tooltip: 'Add Visit Summary',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('visit_summaries')
            .orderBy('appointmentDate', descending: true)
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
                    const Icon(
                      Icons.medical_information_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Visit Summaries Yet',
                      style: AppTheme.responsiveTitleStyle(
                        context,
                        baseSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload your first appointment summary to get started',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UploadVisitSummaryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Visit Summary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final appointmentDate = data['appointmentDate'];
              final summary = data['summary'] as String?;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _showSummaryDialog(context, data);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.brandPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.medical_information,
                                color: AppTheme.brandPurple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Visit on ${_formatDate(appointmentDate)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['readingLevel'] ?? '6th grade level',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        if (summary != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _extractPreviewText(summary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown date';
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.month}/${dt.day}/${dt.year}';
    }
    if (date is String) {
      try {
        final dt = DateTime.parse(date);
        return '${dt.month}/${dt.day}/${dt.year}';
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }

  String _extractActionsToTake(String? summary) {
    if (summary == null) return 'No actions available';
    
    // Extract the "Actions To Take" section from markdown
    final actionsMatch = RegExp(r'## Actions To Take\n(.*?)(?=\n## |$)', dotAll: true)
        .firstMatch(summary);
    
    if (actionsMatch != null) {
      return actionsMatch.group(1)?.trim() ?? 'No actions available';
    }
    
    // Fallback: return first paragraph or section
    final lines = summary.split('\n');
    final firstSection = lines.takeWhile((line) => 
      !line.startsWith('##') || line.startsWith('## Actions To Take')
    ).join('\n');
    
    return firstSection.isNotEmpty ? firstSection : 'No actions available';
  }

  bool _hasActionsToTake(String? summary) {
    if (summary == null) return false;
    return summary.contains('## Actions To Take');
  }

  String _extractPreviewText(String? summary) {
    if (summary == null) return '';
    
    // Try to extract "How Your Baby Is Doing" section (shown on card in image)
    final babyMatch = RegExp(r'## How Your Baby Is Doing\n(.*?)(?=\n## |$)', dotAll: true)
        .firstMatch(summary);
    if (babyMatch != null) {
      final content = babyMatch.group(1)?.trim() ?? '';
      // Return first sentence or first 100 characters
      final firstSentence = content.split('.').first;
      if (firstSentence.length > 0 && firstSentence.length < 100) {
        return firstSentence + '.';
      }
      return content.length > 100 ? content.substring(0, 100) + '...' : content;
    }
    
    // Fallback: get first non-header line
    final lines = summary.split('\n');
    for (final line in lines) {
      if (line.trim().isNotEmpty && !line.startsWith('#')) {
        return line.trim();
      }
    }
    
    return summary.split('\n').first.replaceAll('#', '').trim();
  }

  void _showSummaryDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.brandPurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_information, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Visit on ${_formatDate(data['appointmentDate'])}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Actions To Take Section
                      if (data['summary'] != null) ...[
                        const Text(
                          'Actions To Take',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MarkdownBody(
                          data: _extractActionsToTake(data['summary']),
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 15, height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Suggested Learning Topics Section
                      if (data['learningModules'] != null && 
                          (data['learningModules'] as List).isNotEmpty) ...[
                        const Text(
                          'Suggested Learning Topics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...((data['learningModules'] as List).asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final module = entry.value as Map<String, dynamic>;
                          final title = module['title'] ?? 'Learning Topic';
                          final reason = module['reason'] ?? module['description'] ?? 'This is important based on your visit.';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '$index. $title ($reason)',
                              style: const TextStyle(fontSize: 15, height: 1.6),
                            ),
                          );
                        })),
                      ],
                      
                      // Full Summary (if Actions To Take section not found)
                      if (data['summary'] != null && 
                          !_hasActionsToTake(data['summary'])) ...[
                        const SizedBox(height: 16),
                        MarkdownBody(
                          data: data['summary'],
                          styleSheet: MarkdownStyleSheet(
                            h2: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandPurple,
                            ),
                            h3: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            p: const TextStyle(fontSize: 15, height: 1.6),
                            listBullet: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.brandPurple,
                            ),
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
      ),
    );
  }
}

