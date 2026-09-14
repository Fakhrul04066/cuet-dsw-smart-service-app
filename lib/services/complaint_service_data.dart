import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/complaint.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import 'service_request_ai_service.dart';
import 'user_service.dart';

class ComplaintServiceData {
  ComplaintServiceData._();
  static final ComplaintServiceData instance = ComplaintServiceData._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const statuses = [
    'SUBMITTED',
    'CORRECTION_REQUIRED',
    'RESUBMITTED',
    'OFFICER_REVIEW_COMPLETE',
    'RESOLVED',
  ];

  CollectionReference<Map<String, dynamic>> get _complaints =>
      _firestore.collection('complaints');

  Future<Complaint?> getComplaintById(String id) async {
    final snapshot = await _complaints.doc(id).get();
    return snapshot.exists ? Complaint.fromFirestore(snapshot) : null;
  }

  Stream<Complaint?> streamComplaintById(String id) =>
      _complaints.doc(id).snapshots().map(
            (doc) => doc.exists ? Complaint.fromFirestore(doc) : null,
          );

  Future<List<Complaint>> getAllComplaints() async {
    await _requireStaff();
    final snapshot =
        await _complaints.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(Complaint.fromFirestore).toList();
  }

  // Kept for compatibility. All DSW Officers now see every complaint.
  Future<List<Complaint>> getAssignedComplaintsForCurrentOfficer() async {
    await _requireRole('dsw_officer');
    final snapshot = await _complaints.get();
    final complaints = snapshot.docs.map(Complaint.fromFirestore).toList();
    complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return complaints;
  }

  Future<List<Complaint>> getComplaintsByStudentId(String studentId) async {
    final snapshot =
        await _complaints.where('studentId', isEqualTo: studentId).get();
    final complaints = snapshot.docs.map(Complaint.fromFirestore).toList();
    complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return complaints;
  }

  Future<List<Complaint>> getComplaintsByStudentUid(String studentUid) async {
    final snapshot =
        await _complaints.where('studentUid', isEqualTo: studentUid).get();
    final complaints = snapshot.docs.map(Complaint.fromFirestore).toList();
    complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return complaints;
  }

  Future<String> createComplaint(Complaint complaint) async {
    final docRef = _complaints.doc(
      complaint.id.isEmpty ? _complaints.doc().id : complaint.id,
    );
    await docRef.set(
      complaint.toFirestore(useServerTimestamps: true),
      SetOptions(merge: true),
    );
    await _addHistory(
      docRef.id,
      status: 'SUBMITTED',
      note: 'Complaint submitted by student for DSW Officer review.',
    );
    if (complaint.studentUid.isNotEmpty) {
      await NotificationService.instance.createNotification(
        userUid: complaint.studentUid,
        title: 'Complaint submitted',
        message: 'Your complaint is now visible to DSW Officers for review.',
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
      final summary = _safeText(decoded['summary']);
      final department = _safeText(decoded['suggestedDepartment']);
      if (summary == null || department == null) return null;
      return {
        'category': _normalizeCategory(decoded['category']),
        'priority': _normalizePriority(decoded['priority']),
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
      final duplicate = await _detectDuplicate(
        id,
        complaint,
        studentId: complaint.studentId,
      );
      final imageAssessment = await _imageAssessment(complaint);
      final fields = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (result != null) {
        fields.addAll({
          'aiSuggestedCategory': result['category'],
          'aiSuggestedPriority': result['priority']?.toUpperCase(),
          'aiSummary': result['summary'],
          'aiSuggestedDepartment': result['suggestedDepartment'],
        });
      }
      if (duplicate != null) {
        fields.addAll({
          'aiDuplicateScore': duplicate.$1,
          'aiDuplicateComplaintId': duplicate.$2,
          'aiDuplicateReason': duplicate.$3,
        });
      }
      if (imageAssessment.isNotEmpty) {
        fields['aiImageAssessment'] = imageAssessment;
      }
      await _complaints.doc(id).update(fields);
    } catch (_) {
      // Advisory AI must never block complaint submission.
    }
  }

  Future<void> analyzeComplaintForStaff(String id) async {
    await _requireStaff();
    final complaint = await getComplaintById(id);
    if (complaint == null) throw StateError('Complaint not found.');

    final result = await classifyComplaint(
      title: complaint.title,
      description: complaint.description,
    );
    final duplicate = await _detectDuplicate(id, complaint);
    final imageAssessment = await _imageAssessment(complaint);
    final fields = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (result != null) {
      fields.addAll({
        'aiSuggestedCategory': result['category'],
        'aiSuggestedPriority': result['priority']?.toUpperCase(),
        'aiSummary': result['summary'],
        'aiSuggestedDepartment': result['suggestedDepartment'],
      });
    }
    if (duplicate != null) {
      fields.addAll({
        'aiDuplicateScore': duplicate.$1,
        'aiDuplicateComplaintId': duplicate.$2,
        'aiDuplicateReason': duplicate.$3,
      });
    } else {
      fields.addAll({
        'aiDuplicateScore': 0.0,
        'aiDuplicateComplaintId': '',
        'aiDuplicateReason': 'No strong duplicate was found.',
      });
    }
    if (imageAssessment.isNotEmpty) {
      fields['aiImageAssessment'] = imageAssessment;
    }
    await _complaints.doc(id).update(fields);
  }

  Future<(double, String, String)?> _detectDuplicate(
    String id,
    Complaint complaint, {
    String? studentId,
  }) async {
    Query<Map<String, dynamic>> query = _complaints;
    if (studentId != null && studentId.isNotEmpty) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    final snapshot = await query.limit(100).get();
    final current = '${complaint.title} ${complaint.description}';
    Complaint? best;
    var bestScore = 0.0;
    for (final doc in snapshot.docs) {
      if (doc.id == id) continue;
      final candidate = Complaint.fromFirestore(doc);
      final score = _similarity(
        current,
        '${candidate.title} ${candidate.description}',
      );
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    if (best == null || bestScore < 0.28) return null;
    final ai = await ServiceRequestAiService.instance.assessDuplicate(
      currentText: current,
      candidateText: '${best.title} ${best.description}',
    );
    if (ai != null && ai['isDuplicate'] == true) {
      return (
        (ai['confidence'] as num?)?.toDouble() ?? bestScore,
        best.id,
        ai['reason']?.toString() ?? 'Potential duplicate complaint.',
      );
    }
    if (bestScore >= 0.72) {
      return (
        bestScore,
        best.id,
        'High text similarity with an existing complaint.',
      );
    }
    return null;
  }

  Future<String> _imageAssessment(Complaint complaint) async {
    for (final attachment in complaint.attachments) {
      final path = attachment['storagePath']?.toString() ?? '';
      final mime = attachment['fileType']?.toString() ?? '';
      if (path.isNotEmpty && mime.startsWith('image/')) {
        return await ServiceRequestAiService.instance.analyzeStoredImage(
              storagePath: path,
              title: complaint.title,
              description: complaint.description,
            ) ??
            '';
      }
    }
    return '';
  }

  double _similarity(String a, String b) {
    Set<String> tokens(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toSet();
    final left = tokens(a);
    final right = tokens(b);
    if (left.isEmpty || right.isEmpty) return 0;
    final union = left.union(right).length;
    return union == 0 ? 0 : left.intersection(right).length / union;
  }

  Future<void> requestCorrection(String id, {required String note}) async {
    await _requireRole('dsw_officer');
    final complaint = await _requireComplaint(id);
    if (complaint.status == 'CORRECTION_REQUIRED') return;
    _ensureStatus(complaint, ['SUBMITTED', 'RESUBMITTED']);
    if (note.trim().isEmpty) {
      throw StateError('Tell the student what information must be corrected.');
    }
    await _complaints.doc(id).update({
      'status': 'CORRECTION_REQUIRED',
      'correctionNote': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _safeHistory(
      id,
      status: 'CORRECTION_REQUIRED',
      note: note.trim(),
    );
    await _safeNotifyStudent(
      complaint,
      'A DSW Officer requested more information. Please correct and resubmit your complaint.',
    );
  }

  Future<void> completeOfficerReview(String id, {required String note}) async {
    await _requireRole('dsw_officer');
    final complaint = await _requireComplaint(id);
    if (complaint.status == 'OFFICER_REVIEW_COMPLETE') return;
    _ensureStatus(complaint, ['SUBMITTED', 'RESUBMITTED']);
    if (note.trim().isEmpty) {
      throw StateError('Add an officer review note.');
    }
    await _complaints.doc(id).update({
      'status': 'OFFICER_REVIEW_COMPLETE',
      'officerResponse': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _safeHistory(
      id,
      status: 'OFFICER_REVIEW_COMPLETE',
      note: note.trim(),
    );
    await _safeNotifyStudent(
      complaint,
      'Officer review is complete and your complaint has been sent to the DSW Director.',
    );
  }

  Future<void> resolveByDirector(String id, {required String note}) async {
    await _requireRole('dsw_director');
    final complaint = await _requireComplaint(id);
    if (complaint.status == 'RESOLVED') return;
    _ensureStatus(complaint, ['OFFICER_REVIEW_COMPLETE']);
    if (note.trim().isEmpty) {
      throw StateError('An official Director note is required.');
    }
    await _complaints.doc(id).update({
      'status': 'RESOLVED',
      'directorResponse': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _safeHistory(id, status: 'RESOLVED', note: note.trim());
    await _safeNotifyStudent(
      complaint,
      'Your complaint was resolved by the DSW Director.',
    );
  }

  Future<void> updateStaffFields(
    String id, {
    String? category,
    String? priority,
    String? officerResponse,
  }) async {
    await _requireRole('dsw_officer');
    final complaint = await _requireComplaint(id);
    if (!['SUBMITTED', 'RESUBMITTED'].contains(complaint.status)) {
      throw StateError(
        'Complaint details can only be reviewed before sending it to the Director.',
      );
    }
    final fields = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (category != null) fields['category'] = category;
    if (priority != null) fields['priority'] = priority;
    if (officerResponse != null) fields['officerResponse'] = officerResponse;
    await _complaints.doc(id).update(fields);
  }

  Future<void> resubmitComplaint(
    Complaint complaint, {
    required String title,
    required String description,
    required String category,
  }) async {
    final student = await _requireRole('student');
    if (complaint.studentUid != student.uid) {
      throw StateError('You can resubmit only your own complaint.');
    }
    if (complaint.status != 'CORRECTION_REQUIRED') {
      throw StateError('This complaint is not waiting for correction.');
    }
    if (title.trim().isEmpty || description.trim().isEmpty) {
      throw StateError('Title and description are required.');
    }
    if (!Complaint.categories.contains(category)) {
      throw StateError('Choose a valid complaint category.');
    }
    await _complaints.doc(complaint.id).update({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'status': 'RESUBMITTED',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addHistory(
      complaint.id,
      status: 'RESUBMITTED',
      note: 'Student corrected the complaint and resubmitted it.',
    );
  }

  Future<List<Map<String, dynamic>>> getStatusHistory(String id) async {
    final snapshot = await _complaints
        .doc(id)
        .collection('statusHistory')
        .orderBy('changedAt')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<Complaint>> streamComplaintsForStudent(String studentUid) =>
      _complaints.where('studentUid', isEqualTo: studentUid).snapshots().map(
        (snapshot) {
          final items = snapshot.docs.map(Complaint.fromFirestore).toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        },
      );

  Stream<List<Complaint>> streamAllComplaints() => _complaints
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Complaint.fromFirestore).toList());

  // Kept for compatibility. Officer visibility is no longer assignment-based.
  Stream<List<Complaint>> streamAssignedToOfficer(String uid) =>
      streamAllComplaints();

  Future<void> _addHistory(
    String id, {
    required String status,
    required String note,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await _complaints.doc(id).collection('statusHistory').add({
      'status': status,
      'note': note,
      'performedBy': uid,
      'changedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _notifyStudent(Complaint complaint, String message) async {
    if (complaint.studentUid.isEmpty) return;
    await NotificationService.instance.createNotification(
      userUid: complaint.studentUid,
      title: 'Complaint status updated',
      message: message,
      type: 'complaint_status',
      referenceId: complaint.id,
    );
  }

  Future<Complaint> _requireComplaint(String id) async {
    final complaint = await getComplaintById(id);
    if (complaint == null) throw StateError('Complaint not found.');
    return complaint;
  }

  Future<void> _safeHistory(
    String id, {
    required String status,
    required String note,
  }) async {
    try {
      await _addHistory(id, status: status, note: note);
    } catch (_) {
      // The complaint status update already succeeded.
    }
  }

  Future<void> _safeNotifyStudent(Complaint complaint, String message) async {
    try {
      await _notifyStudent(complaint, message);
    } catch (_) {
      // Notifications are secondary to the authoritative complaint status.
    }
  }

  void _ensureStatus(Complaint complaint, List<String> allowed) {
    if (!allowed.contains(complaint.status)) {
      throw StateError(
        'Action is not allowed while status is ${complaint.status}.',
      );
    }
  }

  Future<StudentUser> _requireRole(String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');
    final profile = await UserService.instance.getCurrentUserProfile();
    if (profile == null || StudentUser.normalizeRole(profile.role) != role) {
      throw StateError('This account is not authorized for this action.');
    }
    return profile;
  }

  Future<StudentUser> _requireStaff() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');
    final profile = await UserService.instance.getCurrentUserProfile();
    final role = profile == null ? '' : StudentUser.normalizeRole(profile.role);
    if (profile == null || !['dsw_officer', 'dsw_director'].contains(role)) {
      throw StateError('Only DSW staff can perform this action.');
    }
    return profile;
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
}
