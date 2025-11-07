import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'General';
  
  // Sample feedback history
  final List<Map<String, dynamic>> _feedbackHistory = [
    {
      'title': 'App Performance Issue',
      'type': 'Bug Report',
      'status': 'In Progress',
      'date': '2 days ago',
    },
    {
      'title': 'Great new feature request',
      'type': 'Feature Request',
      'status': 'Under Review',
      'date': '1 week ago',
    },
    {
      'title': 'Love the new UI design!',
      'type': 'General',
      'status': 'Resolved',
      'date': '2 weeks ago',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fixed background image
          Positioned.fill(
            child: Image.asset(
              DS.feedbackBackground,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.lightBackground,
                        AppTheme.lightMuted,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Light overlay for readability
          Positioned.fill(
            child: Container(
              color: AppTheme.lightBackground.withOpacity(0.7),
            ),
          ),
          
          // Scrollable content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      const Text(
                        'Feedback',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Feedback Form Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Send Us Your Feedback',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  DS.gapS,
                                  const Text(
                                    'We value your input and strive to improve',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  DS.gapL,
                                  
                                  // Feedback Type Dropdown
                                  DropdownButtonFormField<String>(
                                    value: _selectedType,
                                    decoration: const InputDecoration(
                                      labelText: 'Feedback Type',
                                      prefixIcon: Icon(Icons.category_outlined),
                                    ),
                                    items: [
                                      'General',
                                      'Bug Report',
                                      'Feature Request',
                                      'Complaint',
                                      'Compliment',
                                    ].map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedType = value!;
                                      });
                                    },
                                  ),
                                  DS.gapL,
                                  
                                  // Title Field
                                  TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      labelText: 'Title',
                                      prefixIcon: Icon(Icons.title),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a title';
                                      }
                                      return null;
                                    },
                                  ),
                                  DS.gapL,
                                  
                                  // Message Field
                                  TextFormField(
                                    controller: _messageController,
                                    decoration: const InputDecoration(
                                      labelText: 'Message',
                                      prefixIcon: Icon(Icons.message_outlined),
                                      alignLabelWithHint: true,
                                    ),
                                    maxLines: 5,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your message';
                                      }
                                      return null;
                                    },
                                  ),
                                  DS.gapXL,
                                  
                                  // Submit Button
                                  DS.cta(
                                    'Submit Feedback',
                                    icon: Icons.send,
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        // Submit feedback
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Feedback submitted successfully!'),
                                            backgroundColor: AppTheme.success,
                                          ),
                                        );
                                        _titleController.clear();
                                        _messageController.clear();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        DS.gapXL,
                        
                        // Feedback History Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Feedback History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        DS.gapM,
                        
                        // Feedback History List
                        ..._feedbackHistory.map((feedback) => Card(
                              margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(feedback['status']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getTypeIcon(feedback['type']),
                                    color: _getStatusColor(feedback['status']),
                                  ),
                                ),
                                title: Text(
                                  feedback['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(feedback['status'])
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            feedback['status'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _getStatusColor(feedback['status']),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          feedback['date'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.lightForeground.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () {},
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return AppTheme.warning;
      case 'Resolved':
        return AppTheme.success;
      case 'Under Review':
        return AppTheme.lightPrimary;
      default:
        return AppTheme.lightForeground;
    }
  }
  
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Bug Report':
        return Icons.bug_report;
      case 'Feature Request':
        return Icons.lightbulb_outline;
      case 'Complaint':
        return Icons.warning_outlined;
      case 'Compliment':
        return Icons.favorite_outline;
      default:
        return Icons.feedback_outlined;
    }
  }
}
