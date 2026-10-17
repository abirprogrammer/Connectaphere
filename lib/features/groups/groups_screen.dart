import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../models/group.dart';
import '../auth/auth_provider.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: FutureBuilder(
        future: ref.read(apiClientProvider).dio.get(ApiConstants.groups),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Failed to load groups.'));
          }
          try {
            final res = snapshot.data!;
            final rawList = (res.data is Map && res.data['data'] is List) ? res.data['data'] as List : [];
            final groups = rawList.map((g) => Group.fromJson(g)).toList();

            if (groups.isEmpty) {
              return const Center(child: Text('No groups found.'));
            }

            return ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.group)),
                  title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${group.membersCount} members • ${group.privacy.toUpperCase()}'),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref.read(apiClientProvider).dio.post(ApiConstants.joinGroup, data: {'group_id': group.id});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join request sent!')));
                        }
                      } catch (_) {}
                    },
                    child: const Text('Join'),
                  ),
                );
              },
            );
          } catch (_) {
            return const Center(child: Text('Error loading groups'));
          }
        },
      ),
    );
  }
}
