import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../cors/ui_theme.dart';
import '../learning/notes_dialog.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userId != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notes')
                .orderBy('createdAt', descending: true)
                .snapshots()
            : null,
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
                      Icons.book_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Journal Entries Yet',
                      style: AppTheme.responsiveTitleStyle(
                        context,
                        baseSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add notes from learning modules or create entries here',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
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
              
              return _EntryCard(
                entryId: doc.id,
                content: data['content'] ?? '',
                tag: data['tag'] ?? 'Untagged',
                moduleTitle: data['moduleTitle'],
                highlightedText: data['highlightedText'],
                createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                prompt: data['prompt'],
                isFeelingPrompt: data['isFeelingPrompt'] ?? false,
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'feeling',
            onPressed: () {
              _showFeelingPrompt(context);
            },
            backgroundColor: AppTheme.brandPurple.withOpacity(0.8),
            child: const Icon(Icons.favorite, color: Colors.white),
            tooltip: 'How are you feeling?',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'note',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const NotesDialog(),
              );
            },
            backgroundColor: AppTheme.brandPurple,
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Note',
          ),
        ],
      ),
    );
  }

  void _showFeelingPrompt(BuildContext context) {
    final feelingPrompts = [
      'How are you feeling today?',
      'What emotions are you experiencing right now?',
      'What made you smile today?',
      'What challenges are you facing?',
      'What are you grateful for today?',
      'How has your body been feeling?',
      'What support do you need right now?',
      'What are you looking forward to?',
    ];

    final randomPrompt = feelingPrompts[(DateTime.now().millisecondsSinceEpoch % feelingPrompts.length)];

    showDialog(
      context: context,
      builder: (context) => _FeelingPromptDialog(prompt: randomPrompt),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final String entryId;
  final String content;
  final String tag;
  final String? moduleTitle;
  final String? highlightedText;
  final DateTime? createdAt;
  final String? prompt;
  final bool isFeelingPrompt;

  const _EntryCard({
    required this.entryId,
    required this.content,
    required this.tag,
    this.moduleTitle,
    this.highlightedText,
    this.createdAt,
    this.prompt,
    this.isFeelingPrompt = false,
  });

  String _getTagIcon(String tag) {
    switch (tag) {
      case 'Question for provider':
        return '❓';
      case 'Update birth plan':
        return '📋';
      case 'Track a symptom':
        return '📊';
      case 'Emotional reflection':
        return '💭';
      default:
        return '📝';
    }
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'Question for provider':
        return Colors.blue;
      case 'Update birth plan':
        return Colors.purple;
      case 'Track a symptom':
        return Colors.orange;
      case 'Emotional reflection':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showEntryDetail(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag and date row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTagColor(tag).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getTagColor(tag).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getTagIcon(tag),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getTagColor(tag),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (createdAt != null)
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(createdAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              if (isFeelingPrompt && prompt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, size: 16, color: Colors.pink),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prompt!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.pink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (moduleTitle != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school, size: 16, color: AppTheme.brandPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'From: $moduleTitle',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.brandPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (highlightedText != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          highlightedText!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryDetail(BuildContext context) {
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
                    Text(
                      _getTagIcon(tag),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tag,
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
                      if (isFeelingPrompt && prompt != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.psychology, size: 16, color: Colors.pink),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  prompt!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.pink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (moduleTitle != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.brandPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.school, size: 16, color: AppTheme.brandPurple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'From: $moduleTitle',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.brandPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (highlightedText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.yellow.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.format_quote, size: 16, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Highlighted Text:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                highlightedText!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Your Notes:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Created: ${DateFormat('MMMM d, yyyy at h:mm a').format(createdAt!)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
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
      ),
    );
  }
}

class _FeelingPromptDialog extends StatefulWidget {
  final String prompt;

  const _FeelingPromptDialog({required this.prompt});

  @override
  State<_FeelingPromptDialog> createState() => _FeelingPromptDialogState();
}

class _FeelingPromptDialogState extends State<_FeelingPromptDialog> {
  final TextEditingController _responseController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _saveFeelingEntry() async {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please share your thoughts before saving'),
          backgroundColor: Colors.orange,
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .add({
        'content': _responseController.text.trim(),
        'tag': 'Emotional reflection',
        'prompt': widget.prompt,
        'isFeelingPrompt': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Feeling entry saved to journal!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving entry: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  const Icon(Icons.favorite, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'How are you feeling?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology, size: 20, color: Colors.pink),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.prompt,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.pink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _responseController,
                      decoration: InputDecoration(
                        labelText: 'Share your thoughts...',
                        hintText: 'Take a moment to reflect...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.brandPurple, width: 2),
                        ),
                      ),
                      maxLines: 8,
                      minLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.brandPurple,
                        side: const BorderSide(color: AppTheme.brandPurple),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveFeelingEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save to Journal'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
