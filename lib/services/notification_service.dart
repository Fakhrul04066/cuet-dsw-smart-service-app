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

    return _notifications
        .where('userUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), id: doc.id))
              .toList(),
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

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }
}
