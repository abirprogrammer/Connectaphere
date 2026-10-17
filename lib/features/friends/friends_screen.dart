import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_provider.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Friend Requests'),
              Tab(text: 'All Friends'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestsTab(ref),
            _buildFriendsTab(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab(WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(apiClientProvider).dio.get(ApiConstants.pendingFriendRequests),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Failed to load friend requests.'));
        }
        try {
          final res = snapshot.data!;
          final requests = (res.data is Map && res.data['data'] is List) ? res.data['data'] as List : [];

          if (requests.isEmpty) {
            return const Center(child: Text('No pending friend requests'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(req['full_name'] ?? req['username'] ?? 'User'),
                subtitle: Text('@${req['username'] ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await ref.read(apiClientProvider).dio.post(
                            ApiConstants.respondFriendRequest,
                            data: {'request_id': req['request_id'], 'action': 'accept'},
                          );
                        } catch (_) {}
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await ref.read(apiClientProvider).dio.post(
                            ApiConstants.respondFriendRequest,
                            data: {'request_id': req['request_id'], 'action': 'reject'},
                          );
                        } catch (_) {}
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          );
        } catch (_) {
          return const Center(child: Text('Error loading requests'));
        }
      },
    );
  }

  Widget _buildFriendsTab(WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(apiClientProvider).dio.get(ApiConstants.listFriends),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Failed to load friends list.'));
        }
        try {
          final res = snapshot.data!;
          final friends = (res.data is Map && res.data['data'] is List) ? res.data['data'] as List : [];

          if (friends.isEmpty) {
            return const Center(child: Text('No friends added yet.'));
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(friend['full_name'] ?? friend['username'] ?? 'User'),
                subtitle: Text('@${friend['username'] ?? ''}'),
              );
            },
          );
        } catch (_) {
          return const Center(child: Text('Error loading friends'));
        }
      },
    );
  }
}
