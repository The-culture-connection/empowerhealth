import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/communityscreen.jpeg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.2)),
          ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _ForumCard(title: 'Daily Wins', posts: 124),
              _ForumCard(title: 'Coping Tips', posts: 88),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForumCard extends StatelessWidget {
  final String title;
  final int posts;
  const _ForumCard({required this.title, required this.posts});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$posts posts'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}
