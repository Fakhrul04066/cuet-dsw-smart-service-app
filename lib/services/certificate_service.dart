import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CertificateService {
  CertificateService._();

  static final CertificateService instance = CertificateService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _certificates =>
      _firestore.collection('characterCertificates');

  Future<String> submitCertificate({
    required String studentId,
    required String studentName,
    required String department,
    required String level,
    required String term,
    required String email,
    required String phone,
    required String purpose,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated student found.');
    }

    final ref = _certificates.doc();
    final trackingNumber = await _generateTrackingNumber();
    final now = DateTime.now();

    final payload = {
      'id': ref.id,
      'trackingNumber': trackingNumber,
      'studentUid': user.uid,
      'studentId': studentId,
      'studentName': studentName,
      'department': department,
      'level': level,
      'term': term,
      'email': email,
      'phone': phone,
      'purpose': purpose,
      'status': 'Submitted',
      'officialNote': '',
      'approvedCertificateUrl': '',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await ref.set(payload);
    await ref.collection('statusHistory').add({
      'status': 'Submitted',
      'note': 'Application submitted by student.',
      'changedBy': user.uid,
      'changedAt': Timestamp.fromDate(now),
    });

    return trackingNumber;
  }

  Future<List<Map<String, dynamic>>> getStudentCertificates(String uid) async {
    final snapshot = await _certificates
        .where('studentUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getStatusHistory(
    String certificateId,
  ) async {
    final snapshot = await _certificates
        .doc(certificateId)
        .collection('statusHistory')
        .orderBy('changedAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String> _generateTrackingNumber() async {
    final now = DateTime.now();
    final year = now.year;
    final snapshot = await _certificates
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    var next = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastNumber =
          snapshot.docs.first.data()['trackingNumber'] as String?;
      if (lastNumber != null && lastNumber.startsWith('CC-')) {
        final value = lastNumber.split('-').last;
        if (int.tryParse(value) != null) {
          next = int.parse(value) + 1;
        }
      }
    }

    return 'CC-$year-${next.toString().padLeft(4, '0')}';
  }
}
