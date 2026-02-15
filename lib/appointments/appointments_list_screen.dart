import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../cors/ui_theme.dart';
import 'upload_visit_summary_screen.dart';

class AppointmentsListScreen extends StatelessWidget {
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'After Visit Summary',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your visit explained in simple terms',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
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
              ),

              // Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
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
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF663399), Color(0xFF8855BB)],
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Icon(
                                  Icons.medical_information_outlined,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No Visit Summaries Yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload your first appointment summary to get started',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
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
                                  backgroundColor: const Color(0xFF663399),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final appointmentDate = data['appointmentDate'];
                        final summaryData = data['summary'];
                        final summary = summaryData is String ? summaryData : (summaryData is Map ? summaryData.toString() : null);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              _showSummaryDialog(context, data);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.medical_information,
                                        color: Colors.blue.shade500,
                                        size: 20,
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
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data['readingLevel'] ?? '6th grade level',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                                  ],
                                ),
                                if (summary != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _extractPreviewText(summary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown date';
    if (date is Timestamp) {
      final dt = date.toDate();
      return DateFormat('MMMM d, yyyy').format(dt);
    }
    if (date is String) {
      try {
        final dt = DateTime.parse(date);
        if (date.contains('T')) {
          final dateOnly = date.split('T')[0];
          final parts = dateOnly.split('-');
          if (parts.length == 3) {
            return DateFormat('MMMM d, yyyy').format(DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])));
          }
        }
        return DateFormat('MMMM d, yyyy').format(dt);
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }

  String _formatSummaryFromMap(Map<String, dynamic> summaryMap) {
    final buffer = StringBuffer();
    
    if (summaryMap['howBabyIsDoing'] != null) {
      buffer.writeln('## How Your Baby Is Doing');
      buffer.writeln(summaryMap['howBabyIsDoing']);
      buffer.writeln();
    }
    
    if (summaryMap['howYouAreDoing'] != null) {
      buffer.writeln('## How You Are Doing');
      buffer.writeln(summaryMap['howYouAreDoing']);
      buffer.writeln();
    }
    
    if (summaryMap['nextSteps'] != null) {
      buffer.writeln('## Actions To Take');
      buffer.writeln(summaryMap['nextSteps']);
      buffer.writeln();
    }
    
    if (summaryMap['followUpInstructions'] != null) {
      buffer.writeln(summaryMap['followUpInstructions']);
      buffer.writeln();
    }
    
    if (summaryMap['keyMedicalTerms'] != null && 
        summaryMap['keyMedicalTerms'] is List) {
      buffer.writeln('## Key Medical Terms Explained');
      for (final term in summaryMap['keyMedicalTerms'] as List) {
        if (term is Map) {
          buffer.writeln('**${term['term']}**: ${term['explanation']}');
        }
      }
      buffer.writeln();
    }
    
    if (summaryMap['questionsToAsk'] != null && 
        summaryMap['questionsToAsk'] is List) {
      buffer.writeln('## Questions to Ask at Your Next Visit');
      for (int i = 0; i < (summaryMap['questionsToAsk'] as List).length; i++) {
        buffer.writeln('${i + 1}. ${summaryMap['questionsToAsk'][i]}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  String _extractActionsToTake(String? summary) {
    if (summary == null) return 'No actions available';
    
    final actionsMatch = RegExp(r'## Actions To Take\n(.*?)(?=\n## |$)', dotAll: true)
        .firstMatch(summary);
    
    if (actionsMatch != null) {
      return actionsMatch.group(1)?.trim() ?? 'No actions available';
    }
    
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
    
    final babyMatch = RegExp(r'## How Your Baby Is Doing\n(.*?)(?=\n## |$)', dotAll: true)
        .firstMatch(summary);
    if (babyMatch != null) {
      final content = babyMatch.group(1)?.trim() ?? '';
      final firstSentence = content.split('.').first;
      if (firstSentence.length > 0 && firstSentence.length < 100) {
        return firstSentence + '.';
      }
      return content.length > 100 ? content.substring(0, 100) + '...' : content;
    }
    
    final lines = summary.split('\n');
    for (final line in lines) {
      if (line.trim().isNotEmpty && !line.startsWith('#')) {
        return line.trim();
      }
    }
    
    return summary.split('\n').first.replaceAll('#', '').trim();
  }

  void _showSummaryDialog(BuildContext context, Map<String, dynamic> data) {
    final summaryData = data['summary'];
    final summaryString = summaryData is String 
        ? summaryData 
        : (summaryData is Map 
            ? (data['summaryData'] is Map 
                ? _formatSummaryFromMap(data['summaryData'] as Map<String, dynamic>)
                : summaryData.toString())
            : null);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF663399), Color(0xFF8855BB)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (summaryString != null) ...[
                        const Text(
                          'Actions To Take',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF663399),
                          ),
                        ),
                        const SizedBox(height: 8),
                        MarkdownBody(
                          data: _extractActionsToTake(summaryString),
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 15, height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      if (data['learningModules'] != null && 
                          (data['learningModules'] as List).isNotEmpty) ...[
                        const Text(
                          'Suggested Learning Topics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF663399),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...((data['learningModules'] as List).asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final module = entry.value as Map<String, dynamic>;
                          final title = module['title'] ?? 'Learning Topic';
                          final reason = module['reason'] ?? module['description'] ?? 'This is important based on your visit.';
                          final hasContent = module['content'] != null;
                          
                          if (!hasContent) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF663399)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '$index. $title (Generating...)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '$index. $title ($reason)',
                              style: const TextStyle(fontSize: 15, height: 1.6),
                            ),
                          );
                        })),
                      ] else if (data['summary'] != null && 
                          (data['learningModules'] == null || (data['learningModules'] as List).isEmpty)) ...[
                        const Text(
                          'Suggested Learning Topics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF663399),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF663399)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Generating personalized learning topics...',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      if (summaryString != null && 
                          !_hasActionsToTake(summaryString)) ...[
                        const SizedBox(height: 16),
                        MarkdownBody(
                          data: summaryString,
                          styleSheet: MarkdownStyleSheet(
                            h2: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF663399),
                            ),
                            h3: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            p: const TextStyle(fontSize: 15, height: 1.6),
                            listBullet: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF663399),
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
