import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_provider.dart';

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final client = ref.read(apiClientProvider);
    try {
      final res = await client.dio.get('${ApiConstants.searchUsers}?q=$query');
      if (res.data['success'] == true) {
        setState(() => _results = res.data['data']);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search people...',
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final user = _results[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user['full_name'] ?? user['username']),
                  subtitle: Text('@${user['username']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_add_alt_1),
                    onPressed: () async {
                      await ref.read(apiClientProvider).dio.post(
                        ApiConstants.sendFriendRequest,
                        data: {'receiver_id': user['id']},
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Friend request sent!')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
