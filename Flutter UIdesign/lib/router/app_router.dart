import 'package:go_router/go_router.dart';

import '../screens/community_screen.dart';
import '../screens/home_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/learning_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/profile_screen.dart';
import '../shell/main_shell.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/learning',
            builder: (context, state) => const LearningScreen(),
            routes: [
              GoRoute(
                path: ':moduleId',
                builder: (context, state) => PlaceholderScreen(
                  title: 'Learning module',
                  subtitle: state.pathParameters['moduleId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/after-visit',
            builder: (context, state) => const PlaceholderScreen(title: 'After your visit'),
          ),
          GoRoute(
            path: '/birth-plan-builder',
            builder: (context, state) => const PlaceholderScreen(title: 'Birth plan builder'),
          ),
          GoRoute(
            path: '/birth-plan',
            builder: (context, state) => const PlaceholderScreen(title: 'Birth plan'),
            routes: [
              GoRoute(
                path: ':planId',
                builder: (context, state) => PlaceholderScreen(
                  title: 'Birth plan',
                  subtitle: state.pathParameters['planId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const PlaceholderScreen(title: 'New post'),
              ),
              GoRoute(
                path: ':postId',
                builder: (context, state) => PlaceholderScreen(
                  title: 'Discussion',
                  subtitle: 'Post ${state.pathParameters['postId']}',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/providers',
            builder: (context, state) => const PlaceholderScreen(title: 'Find providers'),
            routes: [
              GoRoute(
                path: 'search',
                builder: (context, state) => const PlaceholderScreen(title: 'Provider search'),
              ),
              GoRoute(
                path: 'results',
                builder: (context, state) => const PlaceholderScreen(title: 'Search results'),
              ),
              GoRoute(
                path: 'add',
                builder: (context, state) => const PlaceholderScreen(title: 'Add provider'),
              ),
              GoRoute(
                path: ':providerId',
                builder: (context, state) => PlaceholderScreen(
                  title: 'Provider profile',
                  subtitle: state.pathParameters['providerId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/symptom-check',
            builder: (context, state) => const PlaceholderScreen(title: 'Symptom check'),
          ),
          GoRoute(
            path: '/care-plan',
            builder: (context, state) => const PlaceholderScreen(title: 'My next steps'),
          ),
          GoRoute(
            path: '/care-check-in',
            builder: (context, state) => const PlaceholderScreen(title: 'Care check-in'),
          ),
          GoRoute(
            path: '/my-visits',
            builder: (context, state) => const PlaceholderScreen(title: 'My visits'),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (context, state) => const PlaceholderScreen(title: 'Upload visit summary'),
              ),
              GoRoute(
                path: ':visitId',
                builder: (context, state) => PlaceholderScreen(
                  title: 'Visit detail',
                  subtitle: state.pathParameters['visitId'],
                ),
                routes: [
                  GoRoute(
                    path: 'summary',
                    builder: (context, state) => PlaceholderScreen(
                      title: 'Visit summary',
                      subtitle: state.pathParameters['visitId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/know-your-rights',
            builder: (context, state) => const PlaceholderScreen(title: 'Know your rights'),
          ),
          GoRoute(
            path: '/pregnancy-journey',
            builder: (context, state) => const PlaceholderScreen(title: 'Pregnancy journey'),
          ),
        ],
      ),
    ],
  );
}
