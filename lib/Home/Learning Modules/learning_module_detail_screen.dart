import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      appBar: AppBar(
        title: Row(
          children: [
            Text(icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content display
            _MarkdownStyleText(content: content),
            
            const SizedBox(height: 16),
            // Selectable text for highlighting
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.highlight, size: 18, color: AppTheme.brandPurple),
                      const SizedBox(width: 8),
                      Text(
                        'Long-press text below to highlight and add a note',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    onSelectionChanged: (selection, cause) {
                      if (selection.isValid && cause == SelectionChangedCause.longPress) {
                        final selectedText = content.substring(
                          selection.start.clamp(0, content.length),
                          selection.end.clamp(0, content.length),
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
                                          moduleTitle: title,
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
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Save to favorites
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved to favorites!')),
                      );
                    },
                    icon: const Icon(Icons.bookmark_outline),
                    label: const Text('Save'),
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
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkdownStyleText extends StatelessWidget {
  final String content;

  const _MarkdownStyleText({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
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
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: const TextStyle(fontSize: 16, height: 1.5),
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

