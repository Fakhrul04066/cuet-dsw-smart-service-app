import 'package:cloud_firestore/cloud_firestore.dart';

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
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(AppNotification.fromFirestore).toList();
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
    await _notifications.doc(id).update({'read': true});
  }

  Stream<List<AppNotification>> streamNotificationsForUser(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AppNotification.fromFirestore).toList(),
        );
  }
}
