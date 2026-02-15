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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Journal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A safe space for your thoughts and feelings',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: userId != null
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('notes')
                          .orderBy('createdAt', descending: true)
                          .limit(10)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final entries = snapshot.hasData ? snapshot.data!.docs : [];

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Today's Entry Section
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade50, Colors.pink.shade50],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.pink.shade100),
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
                                    Icon(Icons.auto_awesome, color: Colors.red.shade500, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Today's Entry",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Not sure where to start? Try a prompt:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    'How are you feeling today?',
                                    'What brought you peace this week?',
                                    'What concerns are on your mind?',
                                  ].map((prompt) => _PromptChip(
                                    text: prompt,
                                    onTap: () => _showFeelingPrompt(context, prompt),
                                  )).toList(),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: TextField(
                                    maxLines: 6,
                                    decoration: InputDecoration(
                                      hintText: "What's on your mind today?",
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                      hintStyle: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => const NotesDialog(),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF663399),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Text('Save Entry'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey[700],
                                        side: BorderSide(color: Colors.grey.shade200!),
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Mood Check Section
                          const Text(
                            'How are you feeling today?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _MoodButton(emoji: '😊', label: 'Joyful'),
                                _MoodButton(emoji: '😌', label: 'Calm'),
                                _MoodButton(emoji: '😐', label: 'Okay'),
                                _MoodButton(emoji: '😟', label: 'Worried'),
                                _MoodButton(emoji: '😢', label: 'Tearful'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Recent Reflections Section
                          const Text(
                            'Recent Reflections',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          if (entries.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No Journal Entries Yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add notes from learning modules or create entries here',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...entries.map((doc) {
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
                            }).toList(),
                          
                          const SizedBox(height: 24),

                          // Privacy Note
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade50, Colors.purple.shade50],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.blue.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.cloud_done, color: Colors.blue.shade600, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Your Private Space',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Your journal entries are private and encrypted. They're for you, and you can choose if you want to share specific entries with your care team.",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 100), // Space for FABs
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'feeling',
            onPressed: () => _showFeelingPrompt(context),
            backgroundColor: const Color(0xFF663399).withOpacity(0.8),
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
            backgroundColor: const Color(0xFF663399),
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Note',
          ),
        ],
      ),
    );
  }

  void _showFeelingPrompt(BuildContext context, [String? customPrompt]) {
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

    final prompt = customPrompt ?? feelingPrompts[(DateTime.now().millisecondsSinceEpoch % feelingPrompts.length)];

    showDialog(
      context: context,
      builder: (context) => _FeelingPromptDialog(prompt: prompt),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PromptChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String emoji;
  final String label;

  const _MoodButton({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
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
        onTap: () => _showEntryDetail(context),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF663399), Color(0xFFCBBEC9)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      if (createdAt != null)
                        Text(
                          DateFormat('MMMM d, yyyy').format(createdAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      if (isFeelingPrompt && prompt != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'feeling',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
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

  void _showEntryDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EntryDetailDialog(
        entryId: entryId,
        content: content,
        tag: tag,
        moduleTitle: moduleTitle,
        highlightedText: highlightedText,
        createdAt: createdAt,
        prompt: prompt,
        isFeelingPrompt: isFeelingPrompt,
      ),
    );
  }
}

class _EntryDetailDialog extends StatelessWidget {
  final String entryId;
  final String content;
  final String tag;
  final String? moduleTitle;
  final String? highlightedText;
  final DateTime? createdAt;
  final String? prompt;
  final bool isFeelingPrompt;

  const _EntryDetailDialog({
    required this.entryId,
    required this.content,
    required this.tag,
    this.moduleTitle,
    this.highlightedText,
    this.createdAt,
    this.prompt,
    this.isFeelingPrompt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                  const Text(
                    'Journal Entry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
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
                    if (isFeelingPrompt && prompt != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.psychology, size: 16, color: Colors.pink.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                prompt!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.pink.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (moduleTitle != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF663399).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school, size: 16, color: Color(0xFF663399)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'From: $moduleTitle',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF663399),
                                  fontWeight: FontWeight.w600,
                                ),
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
                          color: Colors.yellow.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.yellow.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.format_quote, size: 16, color: Colors.orange.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Highlighted Text:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                  const Icon(Icons.favorite, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'How are you feeling?',
                      style: TextStyle(
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade50, Colors.pink.shade50],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.pink.shade100),
                      ),
                      child: Text(
                        widget.prompt,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Share your thoughts:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _responseController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'Write your response here...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveFeelingEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF663399),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                            : const Text(
                                'Save Entry',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
