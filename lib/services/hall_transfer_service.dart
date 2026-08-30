import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HallTransferService {
  HallTransferService._();

  static final HallTransferService instance = HallTransferService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _transfers =>
      _firestore.collection('hallTransfers');

  Future<String> submitHallTransfer({
    required String studentId,
    required String studentName,
    required String currentHall,
    required String preferredHall,
    required String reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated student found.');
    }

    final ref = _transfers.doc();
    final trackingNumber = await _generateTrackingNumber();
    final now = DateTime.now();

    final payload = {
      'id': ref.id,
      'trackingNumber': trackingNumber,
      'studentUid': user.uid,
      'studentId': studentId,
      'studentName': studentName,
      'currentHall': currentHall,
      'preferredHall': preferredHall,
      'reason': reason,
      'status': 'Submitted',
      'officialNote': '',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await ref.set(payload);
    await ref.collection('statusHistory').add({
      'status': 'Submitted',
      'note': 'Hall transfer request submitted by student.',
      'changedBy': user.uid,
      'changedAt': Timestamp.fromDate(now),
    });

    return trackingNumber;
  }

  Future<List<Map<String, dynamic>>> getStudentTransfers(String uid) async {
    final snapshot = await _transfers
        .where('studentUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getStatusHistory(String transferId) async {
    final snapshot = await _transfers
        .doc(transferId)
        .collection('statusHistory')
        .orderBy('changedAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String> _generateTrackingNumber() async {
    final now = DateTime.now();
    final year = now.year;
    final snapshot = await _transfers
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    var next = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastNumber =
          snapshot.docs.first.data()['trackingNumber'] as String?;
      if (lastNumber != null && lastNumber.startsWith('HT-')) {
        final value = lastNumber.split('-').last;
        if (int.tryParse(value) != null) {
          next = int.parse(value) + 1;
        }
      }
    }

    return 'HT-$year-${next.toString().padLeft(4, '0')}';
  }
}
