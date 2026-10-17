import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../models/notification.dart';
import '../auth/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder(
        future: ref.read(apiClientProvider).dio.get(ApiConstants.notifications),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Failed to load notifications.'));
          }
          try {
            final res = snapshot.data!;
            final rawList = (res.data is Map && res.data['data'] is List) ? res.data['data'] as List : [];
            final notifications = rawList.map((n) => AppNotification.fromJson(n)).toList();

            if (notifications.isEmpty) {
              return const Center(child: Text('No notifications yet.'));
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.notifications)),
                  title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${notif.actorFullName} ${notif.body}'),
                  tileColor: notif.isRead ? null : Colors.blue.withValues(alpha: 0.05),
                );
              },
            );
          } catch (_) {
            return const Center(child: Text('Error loading notifications'));
          }
        },
      ),
    );
  }
}
