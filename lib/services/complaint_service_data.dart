import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../models/complaint.dart';
import 'notification_service.dart';

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

  Future<List<Complaint>> getAllComplaints() async {
    final snapshot = await _complaints
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(Complaint.fromFirestore).toList();
  }

  Future<List<Complaint>> getComplaintsByStudentId(String studentId) async {
    final snapshot = await _complaints
        .where('studentId', isEqualTo: studentId)
        .get();
    final complaints = snapshot.docs.map(Complaint.fromFirestore).toList();
    complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return complaints;
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
    final uid = complaint.studentUid;
    if (uid.isNotEmpty) {
      await NotificationService.instance.createNotification(
        userUid: uid,
        title: 'Complaint submitted',
        message: 'Your complaint was submitted for review.',
        type: 'complaint_submitted',
        referenceId: docRef.id,
      );
    }
    unawaited(_classifyAndStore(docRef.id, complaint));
    return docRef.id;
  }

  Future<Map<String, String>?> classifyComplaint({
    required String title,
    required String description,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );
      final response = await model.generateContent([
        Content.text(
          '''Classify this student complaint. Return JSON only with exactly these string keys: category, priority, summary, suggestedDepartment.
Allowed categories: ${Complaint.categories.join(', ')}.
Allowed priorities: low, medium, high, urgent.
Do not approve, reject, resolve, or make any administrative decision.
Title: $title
Description: $description''',
        ),
      ]);
      final decoded = jsonDecode(response.text ?? '{}');
      if (decoded is! Map) return null;
      final category = _normalizeCategory(decoded['category']);
      final priority = _normalizePriority(decoded['priority']);
      final summary = _safeText(decoded['summary']);
      final department = _safeText(decoded['suggestedDepartment']);
      if (summary == null || department == null) return null;
      return {
        'category': category,
        'priority': priority,
        'summary': summary,
        'suggestedDepartment': department,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _classifyAndStore(String id, Complaint complaint) async {
    try {
      final result = await classifyComplaint(
        title: complaint.title,
        description: complaint.description,
      );
      if (result == null) return;
      await _complaints.doc(id).update({
        'aiSuggestedCategory': result['category'],
        'aiSuggestedPriority': result['priority'],
        'aiSummary': result['summary'],
        'aiSuggestedDepartment': result['suggestedDepartment'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static String _normalizeCategory(dynamic value) {
    final text = value?.toString().trim().toLowerCase();
    for (final category in Complaint.categories) {
      if (category.toLowerCase() == text) return category;
    }
    return 'Other';
  }

  static String _normalizePriority(dynamic value) {
    final text = value?.toString().trim().toLowerCase();
    return ['low', 'medium', 'high', 'urgent'].contains(text)
        ? text!
        : 'medium';
  }

  static String? _safeText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
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
    final complaint = await getComplaintById(id);
    if (complaint != null && complaint.studentUid.isNotEmpty) {
      await NotificationService.instance.createNotification(
        userUid: complaint.studentUid,
        title: 'Complaint status updated',
        message: 'Your complaint is now $status.',
        type: 'complaint_status',
        referenceId: id,
      );
    }
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
    return _complaints.where('studentId', isEqualTo: studentId).snapshots().map(
      (snapshot) {
        final complaints = snapshot.docs.map(Complaint.fromFirestore).toList();
        complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return complaints;
      },
    );
  }

  Stream<List<Complaint>> streamAllComplaints() {
    return _complaints
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Complaint.fromFirestore).toList());
  }
}
