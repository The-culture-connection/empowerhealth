import 'package:flutter/material.dart';

import '../../design_system/background.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Community'),
      ),
      body: DSBackground(
        imagePath: 'assets/images/bg3.png',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest threads',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Ask questions, share experience, and support one another.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                Expanded(
                  child: ListView.builder(
                    itemCount: _communityTopics.length,
                    itemBuilder: (context, index) {
                      final topic = _communityTopics[index];
                      return DS.messageTile(
                        title: topic.title,
                        subtitle: topic.preview,
                        avatarText: topic.authorInitials,
                        onTap: () {
                          // TODO: navigate to conversation
                        },
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${topic.replies} replies',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityTopic {
  final String title;
  final String preview;
  final String authorInitials;
  final int replies;

  const _CommunityTopic({
    required this.title,
    required this.preview,
    required this.authorInitials,
    required this.replies,
  });
}

const List<_CommunityTopic> _communityTopics = [
  _CommunityTopic(
    title: 'Preparing for Week 32 appointments',
    preview:
        'Hey everyone! What should I expect at the week 32 visit? Any questions I should ask?',
    authorInitials: 'JD',
    replies: 12,
  ),
  _CommunityTopic(
    title: 'Pelvic floor exercises that actually help',
    preview:
        'Sharing the routine my physiotherapist gave me — it\'s been a lifesaver!',
    authorInitials: 'KP',
    replies: 8,
  ),
  _CommunityTopic(
    title: 'Hospital bag checklist',
    preview:
        'First-time mama here. What are the absolute must-haves you packed and were happy you did?',
    authorInitials: 'LS',
    replies: 15,
  ),
  _CommunityTopic(
    title: 'Working with doulas',
    preview:
        'Thinking about hiring a doula but unsure about costs and what to look for. Advice appreciated!',
    authorInitials: 'TR',
    replies: 9,
  ),
];
