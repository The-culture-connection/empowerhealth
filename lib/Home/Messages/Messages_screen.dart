import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/helpinghead.jpeg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.2)),
          ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _MessageTile(name: 'Coach Maya', last: 'How are you feeling today?'),
              _MessageTile(name: 'Peer Group', last: 'New resources shared in the group.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final String name;
  final String last;
  const _MessageTile({required this.name, required this.last});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(last),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}
