import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_notification.dart';

class NotificationServiceData {
  NotificationServiceData._();

  static final NotificationServiceData instance = NotificationServiceData._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Future<AppNotification?> getNotificationById(String id) async {
    final snapshot = await _notifications.doc(id).get();
    if (!snapshot.exists) return null;
    return AppNotification.fromFirestore(snapshot);
  }

  Future<List<AppNotification>> getNotificationsForUser(String userId) async {
    final snapshot = await _notifications
        .where('userUid', isEqualTo: userId)
        .get();
    final notifications = snapshot.docs
        .map(AppNotification.fromFirestore)
        .toList();
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  Future<String> createNotification(AppNotification notification) async {
    final docRef = _notifications.doc(
      notification.id.isEmpty ? _notifications.doc().id : notification.id,
    );
    final payload = notification.toFirestore(useServerTimestamps: true);
    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  Future<void> markAsRead(String id) async {
    await _notifications.doc(id).update({'isRead': true});
  }

  Stream<List<AppNotification>> streamNotificationsForUser(String userId) {
    return _notifications.where('userUid', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final notifications = snapshot.docs
          .map(AppNotification.fromFirestore)
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  Stream<List<AppNotification>> streamNotificationsForCurrentUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return streamNotificationsForUser(uid);
  }

  Stream<int> streamUnreadCount() => streamNotificationsForCurrentUser().map(
    (items) => items.where((item) => !item.read).length,
  );
}
