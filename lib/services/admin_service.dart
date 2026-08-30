import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';
import 'user_service.dart';

class AdminService {
  AdminService._();

  static final AdminService instance = AdminService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService.instance;

  Future<bool> canManageApplications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final profile = await _userService.getUserById(uid);
    return profile?.role == 'official' || profile?.role == 'admin';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamApplications(
    String collection,
  ) {
    return _firestore
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, int>> getSummary() async {
    final certificates = await _firestore
        .collection('characterCertificates')
        .get();
    final transfers = await _firestore.collection('hallTransfers').get();
    final complaints = await _firestore.collection('complaints').get();
    int countWhere(
      QuerySnapshot<Map<String, dynamic>> snapshot,
      String status,
    ) => snapshot.docs.where((doc) => doc.data()['status'] == status).length;

    return {
      'pendingCertificates':
          countWhere(certificates, 'Submitted') +
          countWhere(certificates, 'Under Review'),
      'pendingTransfers':
          countWhere(transfers, 'Submitted') +
          countWhere(transfers, 'Under Review'),
      'openComplaints': complaints.docs.where((doc) {
        final status = doc.data()['status'];
        return status != 'Resolved' && status != 'Closed';
      }).length,
      'confidentialComplaints': complaints.docs
          .where((doc) => doc.data()['isConfidential'] == true)
          .length,
      'resolvedComplaints': countWhere(complaints, 'Resolved'),
    };
  }

  Future<List<Map<String, dynamic>>> getStatusHistory(
    String collection,
    String id,
  ) async {
    final snapshot = await _firestore
        .collection(collection)
        .doc(id)
        .collection('statusHistory')
        .orderBy('changedAt')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> updateApplication({
    required String collection,
    required String id,
    required String trackingNumber,
    required String status,
    String note = '',
  }) async {
    if (!await canManageApplications()) {
      throw StateError('You are not authorized to manage applications.');
    }
    final actor = FirebaseAuth.instance.currentUser!;
    final profile = await _userService.getUserById(actor.uid);
    final now = Timestamp.now();
    final ref = _firestore.collection(collection).doc(id);
    final batch = _firestore.batch();
    batch.update(ref, {
      'status': status,
      'officialNote': note,
      'updatedAt': now,
    });
    batch.set(ref.collection('statusHistory').doc(), {
      'status': status,
      'note': note,
      'changedBy': actor.uid,
      'changedAt': now,
    });
    batch.set(_firestore.collection('auditLogs').doc(), {
      'actorUid': actor.uid,
      'actorName': profile?.name ?? actor.email ?? 'Official',
      'actorRole': profile?.role ?? 'official',
      'action': 'status_changed',
      'entityType': collection,
      'entityId': id,
      'trackingNumber': trackingNumber,
      'details': '$status${note.isEmpty ? '' : ': $note'}',
      'createdAt': now,
    });
    await batch.commit();

    final data = await ref.get();
    final studentUid = data.data()?['studentUid'] as String?;
    if (studentUid != null) {
      await NotificationService.instance.createNotification(
        userUid: studentUid,
        title: 'Application updated',
        message: '$trackingNumber is now $status.',
        type: 'application_status',
        referenceId: id,
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAuditLogs() {
    return _firestore
        .collection('auditLogs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
