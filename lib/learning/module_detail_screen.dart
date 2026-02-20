import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import '../cors/ui_theme.dart';
import 'notes_dialog.dart';
import '../widgets/ai_disclaimer_banner.dart';

class ModuleDetailScreen extends StatefulWidget {
  final String title;
  final String trimester;
  final String type;
  final String? preloadedContent;

  const ModuleDetailScreen({
    super.key,
    required this.title,
    required this.trimester,
    required this.type,
    this.preloadedContent,
  });

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey _contentKey = GlobalKey();
  String? _content;
  bool _isLoading = false;
  String? _error;
  UserProfile? _userProfile;
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedContent != null) {
      _content = widget.preloadedContent;
    } else {
      _loadUserProfileAndContent();
    }
  }

  Future<void> _loadUserProfileAndContent() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _userProfile = await _databaseService.getUserProfile(userId);
    }
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.type == 'rights') {
        final result = await _functionsService.generateRightsContent(
          topic: widget.title,
        );
        setState(() {
          _content = result['content'];
          _isLoading = false;
        });
      } else {
        // Prepare user profile data for personalization
        Map<String, dynamic>? profileData;
        if (_userProfile != null) {
          profileData = {
            'chronicConditions': _userProfile!.chronicConditions,
            'healthLiteracyGoals': _userProfile!.healthLiteracyGoals,
            'insuranceType': _userProfile!.insuranceType,
            'providerPreferences': _userProfile!.providerPreferences,
            'educationLevel': _userProfile!.educationLevel,
          };
        }

        final result = await _functionsService.generateLearningContent(
          topic: widget.title,
          trimester: widget.trimester,
          moduleType: widget.type,
          userProfile: profileData,
        );
        setState(() {
          _content = result['content'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openNotesDialog({String? highlightedText}) {
    showDialog(
      context: context,
      builder: (context) => NotesDialog(
        preFilledText: highlightedText,
        moduleTitle: widget.title,
        moduleId: null, // Could be passed if we track module IDs
      ),
    );
  }

  void _handleTextSelection() {
    // Get selected text from clipboard (workaround for text selection)
    Clipboard.getData(Clipboard.kTextPlain).then((clipboardData) {
      if (clipboardData != null && clipboardData.text != null && clipboardData.text!.isNotEmpty) {
        setState(() {
          _selectedText = clipboardData.text;
        });
        _openNotesDialog(highlightedText: _selectedText);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Add Note',
            onPressed: () => _openNotesDialog(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading content...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading content',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadContent,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_content == null) {
      return const Center(child: Text('No content available'));
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trimester badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.trimester} Trimester',
                  style: const TextStyle(
                    color: AppTheme.brandPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // AI Disclaimer Banner (for AI-generated content)
              const AIDisclaimerBanner(
                customMessage: 'This content helps you understand your care.',
                customSubMessage: 'It does not replace medical advice from your provider.',
              ),
              const SizedBox(height: 16),
              
              // Content with markdown support and text selection
              _SelectableMarkdownWidget(
                content: _content!,
                onTextSelected: (selectedText) {
                  _openNotesDialog(highlightedText: selectedText);
                },
              ),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              
              // Review Section
              _ModuleReviewSection(moduleTitle: widget.title),
            ],
          ),
        ),
      ],
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

// Selectable markdown widget that allows text selection
class _SelectableMarkdownWidget extends StatefulWidget {
  final String content;
  final Function(String) onTextSelected;

  const _SelectableMarkdownWidget({
    required this.content,
    required this.onTextSelected,
  });

  @override
  State<_SelectableMarkdownWidget> createState() => _SelectableMarkdownWidgetState();
}

class _SelectableMarkdownWidgetState extends State<_SelectableMarkdownWidget> {
  String? _selectedText;

  String _stripMarkdown(String markdown) {
    // Simple markdown stripping for text selection
    return markdown
        .replaceAll(RegExp(r'^#+\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .replaceAll(RegExp(r'`(.*?)`'), r'$1')
        .replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    // Fix $1 formatting issue - replace $1 with proper section breaks
    final cleanedContent = widget.content.replaceAll('\$1', '\n\n---\n\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selectable text for highlighting (removed duplicate markdown display)
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
              _FormattedSelectableText(
                content: cleanedContent,
                onTextSelected: (text) {
                  widget.onTextSelected(text);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget that displays formatted text with proper section breaks and selectable text
class _FormattedSelectableText extends StatelessWidget {
  final String content;
  final Function(String) onTextSelected;

  const _FormattedSelectableText({
    required this.content,
    required this.onTextSelected,
  });

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
      } else if (line.startsWith('• ') || line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: SelectableText(
                    line.substring(2),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    selectionControls: _CustomTextSelectionControls(
                      onAddNote: (text) {
                        onTextSelected(text);
                      },
                    ),
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
            child: SelectableText(
              line,
              style: const TextStyle(fontSize: 16, height: 1.5),
              selectionControls: _CustomTextSelectionControls(
                onAddNote: (text) {
                  onTextSelected(text);
                },
              ),
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

// Custom text selection controls with "Add Note" option
class _CustomTextSelectionControls extends MaterialTextSelectionControls {
  final Function(String) onAddNote;

  _CustomTextSelectionControls({required this.onAddNote});

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    final selectedText = delegate.textEditingValue.selection.textInside(delegate.textEditingValue.text);
    return _CustomTextSelectionToolbar(
      globalEditableRegion: globalEditableRegion,
      textLineHeight: textLineHeight,
      selectionMidpoint: selectionMidpoint,
      endpoints: endpoints,
      delegate: delegate,
      clipboardStatus: clipboardStatus,
      selectedText: selectedText,
      onAddNote: (text) {
        onAddNote(text);
        delegate.hideToolbar();
      },
    );
  }
}

class _CustomTextSelectionToolbar extends StatelessWidget {
  final Rect globalEditableRegion;
  final double textLineHeight;
  final Offset selectionMidpoint;
  final List<TextSelectionPoint> endpoints;
  final TextSelectionDelegate delegate;
  final ValueListenable<ClipboardStatus>? clipboardStatus;
  final String selectedText;
  final Function(String) onAddNote;

  const _CustomTextSelectionToolbar({
    required this.globalEditableRegion,
    required this.textLineHeight,
    required this.selectionMidpoint,
    required this.endpoints,
    required this.delegate,
    this.clipboardStatus,
    required this.selectedText,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.tight(globalEditableRegion.size),
      child: CustomSingleChildLayout(
        delegate: _TextSelectionToolbarLayout(
          globalEditableRegion: globalEditableRegion,
          textLineHeight: textLineHeight,
          selectionMidpoint: selectionMidpoint,
          endpoints: endpoints,
        ),
        child: Material(
          elevation: 1.0,
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[850],
          child: Wrap(
            children: [
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                tooltip: 'Copy',
                onPressed: () {
                  delegate.copySelection(SelectionChangedCause.toolbar);
                  delegate.hideToolbar();
                },
              ),
              IconButton(
                icon: const Icon(Icons.note_add, color: Colors.white, size: 20),
                tooltip: 'Add Note',
                onPressed: () {
                  if (selectedText.isNotEmpty) {
                    onAddNote(selectedText);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.select_all, color: Colors.white, size: 20),
                tooltip: 'Select All',
                onPressed: () {
                  delegate.selectAll(SelectionChangedCause.toolbar);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextSelectionToolbarLayout extends SingleChildLayoutDelegate {
  final Rect globalEditableRegion;
  final double textLineHeight;
  final Offset selectionMidpoint;
  final List<TextSelectionPoint> endpoints;

  _TextSelectionToolbarLayout({
    required this.globalEditableRegion,
    required this.textLineHeight,
    required this.selectionMidpoint,
    required this.endpoints,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final toolbarHeight = childSize.height;
    final toolbarWidth = childSize.width;
    final double x = (selectionMidpoint.dx - (toolbarWidth / 2)).clamp(
      globalEditableRegion.left,
      globalEditableRegion.right - toolbarWidth,
    );
    final double y = (endpoints.first.point.dy - toolbarHeight - 8).clamp(
      globalEditableRegion.top,
      globalEditableRegion.bottom - toolbarHeight,
    );
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TextSelectionToolbarLayout oldDelegate) {
    return globalEditableRegion != oldDelegate.globalEditableRegion ||
        textLineHeight != oldDelegate.textLineHeight ||
        selectionMidpoint != oldDelegate.selectionMidpoint ||
        endpoints != oldDelegate.endpoints;
  }
}

