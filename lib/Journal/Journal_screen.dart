import 'package:flutter/material.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/jounralscreen.jpeg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.15)),
          ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _EntryCard(title: 'Gratitude', excerpt: '3 things I’m grateful for...'),
              _EntryCard(title: 'Mood Check-in', excerpt: 'Today I felt calmer after...'),
            ],
          ),
      ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final String title;
  final String excerpt;
  const _EntryCard({required this.title, required this.excerpt});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(excerpt),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}
