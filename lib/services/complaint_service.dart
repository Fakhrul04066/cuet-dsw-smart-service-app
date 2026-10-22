import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComplaintService {
  ComplaintService._();

  static final ComplaintService instance = ComplaintService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _complaints =>
      _firestore.collection('complaints');

  static void validateSubmission({
    required String category,
    required String title,
    required String description,
    required String assignedOffice,
    required String urgency,
  }) {
    if (category.trim().isEmpty) {
      throw StateError('Please select a complaint category.');
    }
    if (title.trim().isEmpty) {
      throw StateError('A complaint title is required.');
    }
    if (description.trim().length < 20) {
      throw StateError(
        'Enter at least 20 characters describing the complaint.',
      );
    }
    if (assignedOffice.trim().isEmpty) {
      throw StateError('Please select an assigned office.');
    }
    if (urgency.trim().isEmpty) {
      throw StateError('Please select an urgency level.');
    }
  }

  Future<String> submitComplaint({
    required String category,
    required String title,
    required String description,
    required bool isConfidential,
    required String assignedOffice,
    required String urgency,
  }) async {
    validateSubmission(
      category: category,
      title: title,
      description: description,
      assignedOffice: assignedOffice,
      urgency: urgency,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated student found.');
    }

    final ref = _complaints.doc();
    final trackingNumber = await _generateTrackingNumber();
    final now = DateTime.now();

    final payload = {
      'id': ref.id,
      'trackingNumber': trackingNumber,
      'studentUid': user.uid,
      'studentId': user.email?.split('@').first ?? '',
      'category': category.trim(),
      'title': title.trim(),
      'description': description.trim(),
      'isConfidential': isConfidential,
      'status': 'Submitted',
      'assignedOffice': assignedOffice.trim(),
      'urgency': urgency.trim(),
      'resolutionNote': '',
      'feedback': '',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await ref.set(payload);
    await ref.collection('statusHistory').add({
      'status': 'Submitted',
      'note': 'Complaint submitted by student.',
      'changedBy': user.uid,
      'changedAt': Timestamp.fromDate(now),
    });

    return trackingNumber;
  }

  Future<List<Map<String, dynamic>>> getStudentComplaints(String uid) async {
    final snapshot = await _complaints
        .where('studentUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getStatusHistory(
    String complaintId,
  ) async {
    final snapshot = await _complaints
        .doc(complaintId)
        .collection('statusHistory')
        .orderBy('changedAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String> _generateTrackingNumber() async {
    final now = DateTime.now();
    final year = now.year;
    final snapshot = await _complaints
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    var next = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastNumber =
          snapshot.docs.first.data()['trackingNumber'] as String?;
      if (lastNumber != null && lastNumber.startsWith('CMP-')) {
        final value = lastNumber.split('-').last;
        if (int.tryParse(value) != null) {
          next = int.parse(value) + 1;
        }
      }
    }

    return 'CMP-$year-${next.toString().padLeft(4, '0')}';
  }
}
