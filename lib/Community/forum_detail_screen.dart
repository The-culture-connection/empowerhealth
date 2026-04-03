import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';

class ForumDetailScreen extends StatelessWidget {
  final String title;
  const ForumDetailScreen({super.key, this.title = 'Forum'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppTheme.newUiAppBar(context, title: title),
      body: const Center(child: Text('Forum details go here.')),
    );
  }
}

