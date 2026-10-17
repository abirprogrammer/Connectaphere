import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../models/conversation.dart';
import '../auth/auth_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: FutureBuilder(
        future: ref.read(apiClientProvider).dio.get(ApiConstants.conversations),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Failed to load chats.'));
          }
          try {
            final res = snapshot.data!;
            final rawList = (res.data is Map && res.data['data'] is List) ? res.data['data'] as List : [];
            final conversations = rawList.map((c) => Conversation.fromJson(c)).toList();

            if (conversations.isEmpty) {
              return const Center(child: Text('No conversations yet. Start a chat with a friend!'));
            }

            return ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(conv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(conv.lastMessage ?? 'No messages yet', maxLines: 1),
                  trailing: conv.unreadCount > 0
                      ? CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.blue,
                          child: Text('${conv.unreadCount}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                        )
                      : null,
                  onTap: () => context.push('/chat/${conv.id}', extra: conv.name),
                );
              },
            );
          } catch (_) {
            return const Center(child: Text('Error loading chats'));
          }
        },
      ),
    );
  }
}
