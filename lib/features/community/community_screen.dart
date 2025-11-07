import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample community messages
    final messages = [
      {
        'author': 'Sarah M.',
        'message': 'Just finished my first physical therapy session. Feeling optimistic!',
        'time': '5 min ago',
        'likes': 12,
        'comments': 3,
      },
      {
        'author': 'John D.',
        'message': 'Looking for recommendations for a good orthopedic surgeon in the area.',
        'time': '1 hour ago',
        'likes': 8,
        'comments': 15,
      },
      {
        'author': 'Emily R.',
        'message': 'Thank you all for the support during my recovery journey. This community is amazing!',
        'time': '3 hours ago',
        'likes': 45,
        'comments': 12,
      },
      {
        'author': 'Michael B.',
        'message': 'Has anyone tried the new meditation app recommended by Dr. Smith?',
        'time': '5 hours ago',
        'likes': 6,
        'comments': 8,
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Fixed background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightBackground,
                    AppTheme.lightMuted,
                  ],
                ),
              ),
            ),
          ),
          
          // Scrollable content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      const Text(
                        'Community',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Create Post Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.lightPrimary,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      // Open create post dialog
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingM,
                                        vertical: AppTheme.spacingS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightMuted,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall,
                                        ),
                                      ),
                                      child: Text(
                                        'Share your thoughts...',
                                        style: TextStyle(
                                          color: AppTheme.lightForeground.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        DS.gapL,
                        
                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All Posts'),
                                selected: true,
                                onSelected: (value) {},
                                selectedColor: AppTheme.lightPrimary.withOpacity(0.2),
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              FilterChip(
                                label: const Text('Questions'),
                                selected: false,
                                onSelected: (value) {},
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              FilterChip(
                                label: const Text('Success Stories'),
                                selected: false,
                                onSelected: (value) {},
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              FilterChip(
                                label: const Text('Support'),
                                selected: false,
                                onSelected: (value) {},
                              ),
                            ],
                          ),
                        ),
                        
                        DS.gapL,
                        
                        // Messages Feed
                        ...messages.map((message) => Card(
                              margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                              child: Padding(
                                padding: const EdgeInsets.all(AppTheme.spacingL),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppTheme.lightAccent,
                                          child: Text(
                                            message['author'].toString()[0],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppTheme.spacingM),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message['author'].toString(),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                message['time'].toString(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.lightForeground.withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.more_vert),
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                    
                                    DS.gapM,
                                    
                                    // Message Content
                                    Text(
                                      message['message'].toString(),
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    
                                    DS.gapM,
                                    
                                    // Actions
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(Icons.favorite_border, size: 20),
                                          label: Text('${message['likes']}'),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.spacingM,
                                            ),
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(Icons.comment_outlined, size: 20),
                                          label: Text('${message['comments']}'),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.spacingM,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(Icons.share_outlined, size: 20),
                                          label: const Text('Share'),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.spacingM,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create new post
        },
        backgroundColor: AppTheme.lightPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
