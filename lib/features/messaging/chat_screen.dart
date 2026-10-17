import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../models/message.dart';
import '../auth/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String title;

  const ChatScreen({super.key, required this.conversationId, required this.title});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() async {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.get('${ApiConstants.messages}?conversation_id=${widget.conversationId}');
    if (response.data['success'] == true) {
      final rawList = response.data['data'] as List;
      if (mounted) {
        setState(() {
          _messages = rawList.map((m) => Message.fromJson(m)).toList();
        });
      }
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    final client = ref.read(apiClientProvider);
    await client.dio.post(ApiConstants.messages, data: {
      'conversation_id': widget.conversationId,
      'content': content,
    });
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => context.push('/call', extra: {'type': 'audio', 'conv_id': widget.conversationId}),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => context.push('/call', extra: {'type': 'video', 'conv_id': widget.conversationId}),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg.content, style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
