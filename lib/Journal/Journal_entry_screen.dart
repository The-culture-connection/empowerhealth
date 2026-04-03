import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';

class JournalEntryScreen extends StatelessWidget {
  const JournalEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppTheme.newUiAppBar(context, title: 'New Journal Entry'),
      body: const Center(child: Text('Start writing...')),
    );
  }
}

