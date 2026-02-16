import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds mock posts into Firestore for development/demo purposes
/// Call this function once to populate the community_posts collection
Future<void> seedMockPosts() async {
  final firestore = FirebaseFirestore.instance;
  
  // Check if posts already exist
  final existingPosts = await firestore
      .collection('community_posts')
      .limit(1)
      .get();
  
  if (existingPosts.docs.isNotEmpty) {
    // Posts already exist, don't seed again
    return;
  }

  final mockPosts = [
    {
      'userId': 'mock_user_1',
      'authorName': 'Maya K.',
      'title': 'First time feeling movement - is this normal?',
      'content': 'I\'m 18 weeks pregnant and just felt my baby move for the first time! It feels like little flutters or bubbles. Is this normal? I\'m so excited but also want to make sure everything is okay.',
      'category': 'Questions',
      'likes': ['mock_user_2', 'mock_user_3'],
      'replies': [
        {
          'userId': 'mock_user_2',
          'authorName': 'Jennifer R.',
          'content': 'Yes, that\'s completely normal! Those flutters are called "quickening" and usually happens between 16-22 weeks. It\'s such an amazing feeling!',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
        },
        {
          'userId': 'mock_user_3',
          'authorName': 'Sarah M.',
          'content': 'I felt my first movements around 18 weeks too! It\'s such a special moment. The movements will get stronger and more frequent as your pregnancy progresses.',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))),
        },
      ],
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
    },
    {
      'userId': 'mock_user_2',
      'authorName': 'Jennifer R.',
      'title': 'My unmedicated birth story - you CAN do this!',
      'content': 'I just wanted to share my positive unmedicated birth experience to encourage anyone who is considering it. I gave birth 3 weeks ago and while it was intense, I felt so empowered and in control. Having a supportive birth team made all the difference. I used breathing techniques, movement, and a birth pool. You are stronger than you know!',
      'category': 'Birth Stories',
      'likes': ['mock_user_1', 'mock_user_3', 'mock_user_4', 'mock_user_5'],
      'replies': [
        {
          'userId': 'mock_user_4',
          'authorName': 'Amara T.',
          'content': 'Thank you so much for sharing! I\'m planning an unmedicated birth and this gives me so much hope and confidence.',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 4))),
        },
        {
          'userId': 'mock_user_5',
          'authorName': 'Keisha L.',
          'content': 'This is beautiful! I had a similar experience and it was the most empowering moment of my life. Congratulations!',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
        },
      ],
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
      'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
    },
    {
      'userId': 'mock_user_3',
      'authorName': 'Sarah M.',
      'title': 'Anxiety about upcoming glucose test',
      'content': 'I have my glucose test next week and I\'m feeling really anxious about it. I\'ve heard it can make you feel nauseous and I\'m worried about the results. Has anyone else felt this way? Any tips for getting through it?',
      'category': 'Support',
      'likes': ['mock_user_1', 'mock_user_2'],
      'replies': [
        {
          'userId': 'mock_user_1',
          'authorName': 'Maya K.',
          'content': 'I was nervous too! The drink is very sweet but it\'s over quickly. I brought something to distract myself and that helped. You\'ve got this!',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        },
        {
          'userId': 'mock_user_6',
          'authorName': 'Lisa P.',
          'content': 'I had mine last month. The drink wasn\'t as bad as I expected, and the staff was really understanding. Remember, if the results come back high, it\'s manageable and you\'re not alone.',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 20))),
        },
      ],
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    },
    {
      'userId': 'mock_user_4',
      'authorName': 'Amara T.',
      'title': 'Finding a doula who looks like me',
      'content': 'I\'ve been searching for a doula in my area and I really want to work with someone who shares my cultural background and understands my experiences. Does anyone have recommendations for finding a doula who is a person of color? I\'m in the Oakland area.',
      'category': 'Resources',
      'likes': ['mock_user_1', 'mock_user_2', 'mock_user_3', 'mock_user_5'],
      'replies': [
        {
          'userId': 'mock_user_5',
          'authorName': 'Keisha L.',
          'content': 'I found my doula through the Black Mamas Matter Alliance directory. They have a great resource list! Also check out local birth centers - many have diverse doula networks.',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1, hours: 12))),
        },
        {
          'userId': 'mock_user_7',
          'authorName': 'Destiny W.',
          'content': 'I\'m a doula in Oakland! Feel free to reach out. Representation matters so much in birth work, and I\'d be happy to connect you with other amazing doulas of color in the area.',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1, hours: 8))),
        },
      ],
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    },
  ];

  // Add all mock posts
  final batch = firestore.batch();
  for (final post in mockPosts) {
    final docRef = firestore.collection('community_posts').doc();
    batch.set(docRef, post);
  }
  
  await batch.commit();
}
