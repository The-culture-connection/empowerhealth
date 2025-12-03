import 'package:flutter/material.dart';

class JournalEntryScreen extends StatelessWidget {
  const JournalEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Journal Entry')),
      body: const Center(child: Text('Start writing...')),
    );
  }
}

