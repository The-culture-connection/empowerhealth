import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../cors/ui_theme.dart';
import '../../learning/notes_dialog.dart';

class LearningModuleDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String icon;

  const LearningModuleDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Learning Module',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.note_add),
                      tooltip: 'Add Note',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => NotesDialog(
                            moduleTitle: title,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Selectable text for highlighting
                  Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 18, color: const Color(0xFF663399)),
                            const SizedBox(width: 8),
                            Text(
                              'Long-press text to highlight and add a note',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF663399),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _MarkdownStyleText(content: content, moduleTitle: title),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved to favorites!')),
                            );
                          },
                          icon: const Icon(Icons.bookmark_outline),
                          label: const Text('Save'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF663399),
                            side: const BorderSide(color: Color(0xFF663399)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard!')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF663399),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                      // Review Section
                      _ModuleReviewSection(moduleTitle: title),
                      const SizedBox(height: 24),
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

class _ModuleReviewSection extends StatefulWidget {
  final String moduleTitle;

  const _ModuleReviewSection({required this.moduleTitle});

  @override
  State<_ModuleReviewSection> createState() => _ModuleReviewSectionState();
}

class _ModuleReviewSectionState extends State<_ModuleReviewSection> {
  final TextEditingController _feedbackController = TextEditingController();
  int _preparationRating = 0;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_preparationRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate how prepared you felt'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await FirebaseFirestore.instance
          .collection('module_reviews')
          .add({
        'userId': userId,
        'moduleTitle': widget.moduleTitle,
        'feedback': _feedbackController.text.trim().isEmpty 
            ? null 
            : _feedbackController.text.trim(),
        'preparationRating': _preparationRating,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSubmitting = false;
        _hasSubmitted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Thank you for your feedback!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSubmitted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Thank you for your feedback!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Module Review',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.brandPurple,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How did this module help you learn?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _feedbackController,
          decoration: InputDecoration(
            hintText: 'Share your thoughts about how this module helped you...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.brandPurple, width: 2),
            ),
          ),
          maxLines: 4,
          minLines: 3,
        ),
        const SizedBox(height: 24),
        const Text(
          'How well prepared did you feel after this module?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() => _preparationRating = index + 1);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < _preparationRating ? Icons.star : Icons.star_border,
                  size: 40,
                  color: index < _preparationRating 
                      ? Colors.amber 
                      : Colors.grey,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _preparationRating == 0 
                ? 'Tap stars to rate'
                : '$_preparationRating out of 5 stars',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Submit Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}

class _MarkdownStyleText extends StatefulWidget {
  final String content;
  final String moduleTitle;

  const _MarkdownStyleText({required this.content, required this.moduleTitle});

  @override
  State<_MarkdownStyleText> createState() => _MarkdownStyleTextState();
}

class _MarkdownStyleTextState extends State<_MarkdownStyleText> {

  @override
  Widget build(BuildContext context) {
    // Fix $1 formatting issue - replace $1 with proper section breaks first
    final cleanedContent = widget.content.replaceAll('\$1', '\n\n---\n\n');
    final lines = cleanedContent.split('\n');
    final widgets = <Widget>[];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      
      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.substring(3),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPurple,
              ),
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              line.substring(4),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      } else if (line.startsWith('• ') || line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.trim() == '---' || line.trim().startsWith('---')) {
        // Section divider
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              thickness: 2,
              color: AppTheme.brandPurple,
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SelectableText(
              line,
              style: const TextStyle(fontSize: 16, height: 1.5),
              onSelectionChanged: (selection, cause) {
                if (selection.isValid && cause == SelectionChangedCause.longPress) {
                  final selectedText = line.substring(
                    selection.start.clamp(0, line.length),
                    selection.end.clamp(0, line.length),
                  ).trim();
                  if (selectedText.length > 3) {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Selected: ${selectedText.length > 40 ? selectedText.substring(0, 40) + "..." : selectedText}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                showDialog(
                                  context: context,
                                  builder: (context) => NotesDialog(
                                    preFilledText: selectedText,
                                    moduleTitle: widget.moduleTitle,
                                  ),
                                );
                              },
                              child: const Text('Add Note', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 5),
                        backgroundColor: AppTheme.brandPurple,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

