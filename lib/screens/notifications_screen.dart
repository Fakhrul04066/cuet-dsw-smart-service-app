import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/application_service.dart';
import '../services/complaint_service_data.dart';
import '../services/notification_service_data.dart';
import 'application_details_screen.dart';
import 'complaint_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        StreamBuilder<int>(
          stream: NotificationServiceData.instance.streamUnreadCount(),
          builder: (context, snapshot) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('Unread: ${snapshot.data ?? 0}')),
          ),
        ),
      ],
    ),
    body: StreamBuilder<List<AppNotification>>(
      stream: NotificationServiceData.instance
          .streamNotificationsForCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load notifications: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No notifications yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) =>
              _NotificationTile(notification: snapshot.data![index]),
        );
      },
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  Future<void> _open(BuildContext context) async {
    if (!notification.read) {
      await NotificationServiceData.instance.markAsRead(notification.id);
    }
    if (!context.mounted || notification.relatedId.isEmpty) return;
    if (notification.type.startsWith('complaint')) {
      final complaint = await ComplaintServiceData.instance.getComplaintById(
        notification.relatedId,
      );
      if (context.mounted && complaint != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailsScreen(complaint: complaint),
          ),
        );
      }
      return;
    }
    final application = await ApplicationService.instance.getApplicationById(
      notification.relatedId,
    );
    if (context.mounted && application != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationDetailsScreen(application: application),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: notification.read ? null : const Color(0xFFEAF1FF),
    child: ListTile(
      leading: Icon(
        notification.read
            ? Icons.notifications_none
            : Icons.notifications_active,
      ),
      title: Text(notification.title),
      subtitle: Text(
        '${notification.message}\n${notification.createdAt.toLocal()}',
      ),
      isThreeLine: true,
      trailing: notification.read
          ? null
          : TextButton(
              onPressed: () =>
                  NotificationServiceData.instance.markAsRead(notification.id),
              child: const Text('Mark read'),
            ),
      onTap: () => _open(context),
    ),
  );
}
