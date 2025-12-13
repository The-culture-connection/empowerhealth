import 'package:flutter/material.dart';

class LearningModulesScreen extends StatelessWidget {
  const LearningModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/learningscreen.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.2)),
          ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _ModuleTile(title: 'Mindfulness Basics'),
              _ModuleTile(title: 'Coping Strategies'),
              _ModuleTile(title: 'Building Healthy Habits'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final String title;
  const _ModuleTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Tap to view'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}
