import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/complaint.dart';

class ComplaintServiceData {
  ComplaintServiceData._();

  static final ComplaintServiceData instance = ComplaintServiceData._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const statuses = [
    'SUBMITTED',
    'OFFICER_REVIEW',
    'IN_PROGRESS',
    'RESOLVED',
    'CLOSED',
  ];

  CollectionReference<Map<String, dynamic>> get _complaints =>
      _firestore.collection('complaints');

  Future<Complaint?> getComplaintById(String id) async {
    final snapshot = await _complaints.doc(id).get();
    if (!snapshot.exists) return null;
    return Complaint.fromFirestore(snapshot);
  }

  Future<List<Complaint>> getComplaintsByStudentId(String studentId) async {
    final snapshot = await _complaints
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(Complaint.fromFirestore).toList();
  }

  Future<String> createComplaint(Complaint complaint) async {
    final docRef = _complaints.doc(
      complaint.id.isEmpty ? _complaints.doc().id : complaint.id,
    );
    final payload = complaint.toFirestore(useServerTimestamps: true);
    await docRef.set(payload, SetOptions(merge: true));
    await docRef.collection('statusHistory').add({
      'status': complaint.status,
      'note': 'Complaint submitted by student.',
      'changedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateComplaint(String id, Complaint complaint) async {
    final payload = complaint
        .copyWith(updatedAt: DateTime.now())
        .toFirestore(useServerTimestamps: true);
    await _complaints.doc(id).update(payload);
  }

  Future<void> updateComplaintStatus(
    String id, {
    required String status,
    String note = '',
  }) async {
    if (!statuses.contains(status)) {
      throw ArgumentError('Invalid complaint status: $status');
    }
    final ref = _complaints.doc(id);
    await _firestore.runTransaction((transaction) async {
      transaction.update(ref, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(ref.collection('statusHistory').doc(), {
        'status': status,
        'note': note,
        'changedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateStaffFields(
    String id, {
    String? category,
    String? priority,
    String? officerResponse,
  }) async {
    final fields = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (category != null) fields['category'] = category;
    if (priority != null) fields['priority'] = priority;
    if (officerResponse != null) fields['officerResponse'] = officerResponse;
    await _complaints.doc(id).update(fields);
  }

  Future<List<Map<String, dynamic>>> getStatusHistory(String id) async {
    final snapshot = await _complaints
        .doc(id)
        .collection('statusHistory')
        .orderBy('changedAt')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> deleteComplaint(String id) async {
    await _complaints.doc(id).delete();
  }

  Stream<List<Complaint>> streamComplaintsForStudent(String studentId) {
    return _complaints
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Complaint.fromFirestore).toList());
  }

  Stream<List<Complaint>> streamAllComplaints() {
    return _complaints
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Complaint.fromFirestore).toList());
  }
}
