import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HearthPushedHeader(title: 'Messages'),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/helpinghead.jpeg', fit: BoxFit.cover),
                  // Same strength as the old 20% black wash over the photo.
                  Container(color: AppTheme.ink.withValues(alpha: 0.2)),
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: const [
                      _MessageTile(name: 'Coach Maya', last: 'How are you feeling today?'),
                      _MessageTile(name: 'Peer Group', last: 'New resources shared in the group.'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HearthRowCard(
        icon: Icons.person_outline,
        title: name,
        subtitle: last,
        onTap: () {},
      ),
    );
  }
}
