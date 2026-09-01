import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Stream<List<NotificationModel>> streamNotificationsForCurrentUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return _notifications.where('userUid', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), id: doc.id))
          .toList();
      notifications.sort(
        (a, b) => (b.createdAt ?? Timestamp(0, 0)).compareTo(
          a.createdAt ?? Timestamp(0, 0),
        ),
      );
      return notifications;
    });
  }

  Stream<int> streamUnreadCount() {
    return streamNotificationsForCurrentUser().map(
      (items) => items.where((item) => !item.isRead).length,
    );
  }

  Future<void> createNotification({
    required String userUid,
    required String title,
    required String message,
    required String type,
    String? referenceId,
  }) async {
    final now = DateTime.now();
    await _notifications.add({
      'id': '',
      'userUid': userUid,
      'title': title,
      'message': message,
      'type': type,
      'referenceId': referenceId ?? '',
      'isRead': false,
      'createdAt': Timestamp.fromDate(now),
    });
  }

  Future<void> createForCurrentUserIfMissing({
    required String title,
    required String message,
    required String type,
    required String referenceId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final existing = await _notifications
        .where('userUid', isEqualTo: uid)
        .get();
    final alreadyExists = existing.docs.any((doc) {
      final data = doc.data();
      return data['type'] == type && data['referenceId'] == referenceId;
    });
    if (!alreadyExists) {
      await createNotification(
        userUid: uid,
        title: title,
        message: message,
        type: type,
        referenceId: referenceId,
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }
}
