import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/feed/create_post_screen.dart';
import '../features/stories/story_view_screen.dart';
import '../features/stories/create_story_screen.dart';
import '../features/reels/reels_screen.dart';
import '../features/friends/friends_screen.dart';
import '../features/friends/search_users_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/messaging/conversations_screen.dart';
import '../features/messaging/chat_screen.dart';
import '../features/calls/call_screen.dart';
import '../features/groups/groups_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/settings/settings_screen.dart';
import '../models/story.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/create-post',
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/create-story',
      builder: (context, state) => const CreateStoryScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchUsersScreen(),
    ),
    GoRoute(
      path: '/conversations',
      builder: (context, state) => const ConversationsScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final title = state.extra as String? ?? 'Chat';
        return ChatScreen(conversationId: id, title: title);
      },
    ),
    GoRoute(
      path: '/call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final type = extra?['type'] ?? 'video';
        return CallScreen(callType: type);
      },
    ),
    GoRoute(
      path: '/story-view',
      builder: (context, state) {
        final group = state.extra as UserStoryGroup;
        return StoryViewScreen(group: group);
      },
    ),
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/feed',
          builder: (context, state) => const FeedScreen(),
        ),
        GoRoute(
          path: '/reels',
          builder: (context, state) => const ReelsScreen(),
        ),
        GoRoute(
          path: '/friends',
          builder: (context, state) => const FriendsScreen(),
        ),
        GoRoute(
          path: '/groups',
          builder: (context, state) => const GroupsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.ondemand_video), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/feed')) return 0;
    if (location.startsWith('/reels')) return 1;
    if (location.startsWith('/friends')) return 2;
    if (location.startsWith('/groups')) return 3;
    if (location.startsWith('/notifications')) return 4;
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/feed');
        break;
      case 1:
        context.go('/reels');
        break;
      case 2:
        context.go('/friends');
        break;
      case 3:
        context.go('/groups');
        break;
      case 4:
        context.go('/notifications');
        break;
      case 5:
        context.go('/profile');
        break;
    }
  }
}
