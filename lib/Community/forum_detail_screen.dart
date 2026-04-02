import 'package:flutter/material.dart';

class ForumDetailScreen extends StatelessWidget {
  final String title;
  const ForumDetailScreen({super.key, this.title = 'Forum'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Forum details go here.')),
    );
  }
}

