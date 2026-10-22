import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/audit_log.dart';
import '../models/service_request.dart';
import '../models/user_model.dart';
import 'audit_log_service.dart';
import 'notification_service.dart';
import 'service_request_ai_service.dart';
import 'user_service.dart';

class ServiceRequestService {
  ServiceRequestService._();
  static final instance = ServiceRequestService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('service_requests');

  Future<String> submit(ServiceRequest request) async {
    ServiceRequest.validateSubmission(
      requestType: request.requestType,
      title: request.title,
      description: request.description,
    );
    final ref = _requests.doc(
      request.id.isEmpty ? _requests.doc().id : request.id,
    );
    await ref.set(request.toFirestore(useServerTimestamps: true));
    await _addHistory(
      ref.id,
      status: 'SUBMITTED',
      action: 'Request submitted',
      note: 'Student submitted the request for DSW Officer review.',
    );
    await NotificationService.instance.createNotification(
      userUid: request.studentUid,
      title: 'Request submitted',
      message:
          '${request.trackingNumber} was submitted and is now visible to DSW Officers.',
      type: 'service_request_status',
      referenceId: ref.id,
    );
    unawaited(_runAiEnrichment(ref.id, request));
    return ref.id;
  }

  Future<void> _runAiEnrichment(String id, ServiceRequest request) async {
    try {
      final ai = await ServiceRequestAiService.instance.analyzeRequest(
        requestType: request.requestType,
        title: request.title,
        description: request.description,
      );
      final duplicate = await _findDuplicate(
        request,
        excludeId: id,
        studentUid: request.studentUid,
      );

      String imageAssessment = '';
      for (final document in request.documents) {
        final path = document['storagePath']?.toString() ?? '';
        final mime = document['fileType']?.toString() ?? '';
        if (path.isNotEmpty && mime.startsWith('image/')) {
          imageAssessment =
              await ServiceRequestAiService.instance.analyzeStoredImage(
                storagePath: path,
                title: request.title,
                description: request.description,
              ) ??
              '';
          break;
        }
      }

      final fields = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (ai != null) {
        fields.addAll({
          'aiSummary': ai['summary'] ?? '',
          'aiSuggestedPriority': ai['priority'] ?? 'NORMAL',
          'aiPriorityReason': ai['priorityReason'] ?? '',
          'suggestedOffice': ai['suggestedOffice'] ?? '',
          'aiRiskTags': ai['riskTags'] ?? <String>[],
        });
      }
      if (duplicate != null) {
        fields.addAll({
          'aiDuplicateScore': duplicate.score,
          'aiDuplicateRequestId': duplicate.requestId,
          'aiDuplicateReason': duplicate.reason,
        });
      }
      if (imageAssessment.isNotEmpty) {
        fields['aiImageAssessment'] = imageAssessment;
      }
      await _requests.doc(id).update(fields);
    } catch (_) {
      // AI is advisory. Failure must never block the official workflow.
    }
  }

  Future<_DuplicateMatch?> _findDuplicate(
    ServiceRequest request, {
    required String excludeId,
    String? studentUid,
  }) async {
    Query<Map<String, dynamic>> query = _requests.where(
      'requestType',
      isEqualTo: request.requestType,
    );
    if (studentUid != null && studentUid.isNotEmpty) {
      query = query.where('studentUid', isEqualTo: studentUid);
    }

    final snapshot = await query.limit(50).get();
    final current = '${request.title} ${request.description}';
    ServiceRequest? best;
    var bestScore = 0.0;
    for (final doc in snapshot.docs) {
      if (doc.id == excludeId) continue;
      final candidate = ServiceRequest.fromFirestore(doc);
      final score = _textSimilarity(
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
      return _DuplicateMatch(
        requestId: best.id,
        score: (ai['confidence'] as num?)?.toDouble() ?? bestScore,
        reason: ai['reason']?.toString() ?? 'Potential duplicate request.',
      );
    }
    if (bestScore >= 0.72) {
      return _DuplicateMatch(
        requestId: best.id,
        score: bestScore,
        reason: 'High text similarity with an existing request.',
      );
    }
    return null;
  }

  double _textSimilarity(String a, String b) {
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

  Future<void> analyzeRequestForStaff(String requestId) async {
    await _requireStaff();
    final request = await getById(requestId);
    if (request == null) throw StateError('Request not found.');

    final ai = await ServiceRequestAiService.instance.analyzeRequest(
      requestType: request.requestType,
      title: request.title,
      description: request.description,
    );
    final duplicate = await _findDuplicate(request, excludeId: requestId);

    String imageAssessment = '';
    for (final document in request.documents) {
      final path = document['storagePath']?.toString() ?? '';
      final mime = document['fileType']?.toString() ?? '';
      if (path.isNotEmpty && mime.startsWith('image/')) {
        imageAssessment =
            await ServiceRequestAiService.instance.analyzeStoredImage(
              storagePath: path,
              title: request.title,
              description: request.description,
            ) ??
            '';
        break;
      }
    }

    final fields = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (ai != null) {
      fields.addAll({
        'aiSummary': ai['summary'] ?? '',
        'aiSuggestedPriority': ai['priority'] ?? 'NORMAL',
        'aiPriorityReason': ai['priorityReason'] ?? '',
        'suggestedOffice': ai['suggestedOffice'] ?? '',
        'aiRiskTags': ai['riskTags'] ?? <String>[],
      });
    }
    if (duplicate != null) {
      fields.addAll({
        'aiDuplicateScore': duplicate.score,
        'aiDuplicateRequestId': duplicate.requestId,
        'aiDuplicateReason': duplicate.reason,
      });
    } else {
      fields.addAll({
        'aiDuplicateScore': 0.0,
        'aiDuplicateRequestId': '',
        'aiDuplicateReason': '',
      });
    }
    if (imageAssessment.isNotEmpty) {
      fields['aiImageAssessment'] = imageAssessment;
    }
    await _requests.doc(requestId).update(fields);
  }

  Future<void> requestCorrection(
    String requestId, {
    required String note,
  }) async {
    await _requireRole('dsw_officer');
    if (note.trim().isEmpty) {
      throw StateError('Tell the student what information must be corrected.');
    }
    await _transition(
      requestId,
      expectedStatuses: const ['SUBMITTED', 'RESUBMITTED'],
      nextStatus: 'CORRECTION_REQUIRED',
      action: 'Officer requested resubmission',
      note: note.trim(),
      extra: {'correctionNote': note.trim()},
    );
  }

  Future<void> completeOfficerReview(
    String requestId, {
    required String note,
  }) async {
    await _requireRole('dsw_officer');
    if (note.trim().isEmpty) {
      throw StateError(
        'Add an officer review note before sending the request to the Director.',
      );
    }
    await _transition(
      requestId,
      expectedStatuses: const ['SUBMITTED', 'RESUBMITTED'],
      nextStatus: 'OFFICER_REVIEW_COMPLETE',
      action: 'Officer review completed',
      note: note.trim(),
      extra: {'officerReviewNote': note.trim()},
    );
  }

  Future<void> resubmit({
    required String requestId,
    required String title,
    required String description,
  }) async {
    final profile = await _requireRole('student');
    final current = await getById(requestId);
    if (current == null) throw StateError('Request not found.');
    if (current.studentUid != profile.uid) {
      throw StateError('You can resubmit only your own request.');
    }
    if (current.status != 'CORRECTION_REQUIRED') {
      throw StateError('This request is not waiting for resubmission.');
    }
    if (title.trim().isEmpty || description.trim().length < 20) {
      throw StateError(
        'Enter a title and at least 20 characters of description.',
      );
    }

    await _requests.doc(requestId).update({
      'title': title.trim(),
      'description': description.trim(),
      'status': 'RESUBMITTED',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addHistory(
      requestId,
      status: 'RESUBMITTED',
      action: 'Student resubmitted request',
      note: 'Student corrected the requested information and resubmitted.',
    );
  }

  Future<void> finalDecision(
    String requestId, {
    required String decision,
    required String note,
  }) async {
    await _requireRole('dsw_director');
    const allowedDecisions = ['APPROVED', 'REJECTED', 'RESOLVED'];
    if (!allowedDecisions.contains(decision)) {
      throw StateError('Unsupported final decision: $decision');
    }
    if (note.trim().isEmpty) {
      throw StateError('An official Director note is required.');
    }

    final extra = <String, dynamic>{'resolutionNote': note.trim()};
    if (decision == 'RESOLVED') {
      extra['resolvedAt'] = FieldValue.serverTimestamp();
    }
    await _transition(
      requestId,
      expectedStatuses: const ['OFFICER_REVIEW_COMPLETE'],
      nextStatus: decision,
      action: 'Director final decision: $decision',
      note: note.trim(),
      extra: extra,
    );
  }

  Future<void> _transition(
    String requestId, {
    required List<String> expectedStatuses,
    required String nextStatus,
    required String action,
    String note = '',
    Map<String, dynamic> extra = const {},
  }) async {
    final before = await getById(requestId);
    if (before == null) throw StateError('Request not found.');

    // Repeating an action that already succeeded is a no-op. This protects
    // against quick double taps and delayed UI refreshes.
    if (before.status == nextStatus) return;

    if (!expectedStatuses.contains(before.status)) {
      throw StateError(
        'Invalid workflow transition: ${before.status} → $nextStatus',
      );
    }

    await _requests.doc(requestId).update({
      'status': nextStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      ...extra,
    });
    try {
      await _addHistory(
        requestId,
        status: nextStatus,
        action: action,
        note: note,
      );
    } catch (_) {
      // Status is already authoritative; history is secondary.
    }
    await _writeAuditLog(
      requestId: requestId,
      action: action,
      fromStatus: before.status,
      toStatus: nextStatus,
    );

    try {
      await NotificationService.instance.createNotification(
        userUid: before.studentUid,
        title: 'Request updated',
        message: '${before.trackingNumber} is now ${_labelStatus(nextStatus)}.',
        type: 'service_request_status',
        referenceId: requestId,
      );
    } catch (_) {
      // Notification failure must not make a completed workflow action fail.
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

  Future<void> _writeAuditLog({
    required String requestId,
    required String action,
    required String fromStatus,
    required String toStatus,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final profile = await UserService.instance.getCurrentUserProfile();
      if (profile == null) return;
      final role = StudentUser.normalizeRole(profile.role);
      if (!['dsw_officer', 'dsw_director'].contains(role)) return;
      await AuditLogService.instance.addAuditLog(
        AuditLog(
          id: '',
          actorId: user.uid,
          actorRole: role,
          action: action,
          targetType: 'service_request',
          targetId: requestId,
          timestamp: DateTime.now(),
          details: {'fromStatus': fromStatus, 'toStatus': toStatus},
        ),
      );
    } catch (_) {
      // Audit logging must not make a completed workflow action look failed.
    }
  }

  Future<void> _addHistory(
    String requestId, {
    required String status,
    required String action,
    String note = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await _requests.doc(requestId).collection('history').add({
      'status': status,
      'action': action,
      'note': note,
      'performedBy': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<ServiceRequest?> getById(String id) async {
    final doc = await _requests.doc(id).get();
    return doc.exists ? ServiceRequest.fromFirestore(doc) : null;
  }

  Stream<ServiceRequest?> streamById(String id) => _requests
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? ServiceRequest.fromFirestore(doc) : null);

  Stream<List<ServiceRequest>> streamForStudent(String uid) => _requests
      .where('studentUid', isEqualTo: uid)
      .snapshots()
      .map(_sortedRequests);

  Stream<List<ServiceRequest>> streamAll() =>
      _requests.snapshots().map(_sortedRequests);

  // Kept for compatibility with older UI code. Every officer now sees all
  // requests, so this intentionally returns the full staff stream.
  Stream<List<ServiceRequest>> streamAssignedToOfficer(String uid) =>
      streamAll();

  List<ServiceRequest> _sortedRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final items = snapshot.docs.map(ServiceRequest.fromFirestore).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<List<Map<String, dynamic>>> history(String requestId) async {
    final snapshot = await _requests
        .doc(requestId)
        .collection('history')
        .orderBy('timestamp')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  String buildTrackingNumber() {
    final now = DateTime.now();
    final suffix = now.microsecondsSinceEpoch.toString();
    return 'DSW-${now.year}-${suffix.substring(suffix.length - 7)}';
  }

  static String _labelStatus(String status) => switch (status) {
    'SUBMITTED' => 'Submitted for Officer Review',
    'CORRECTION_REQUIRED' => 'Resubmission Required',
    'RESUBMITTED' => 'Resubmitted for Officer Review',
    'OFFICER_REVIEW_COMPLETE' => 'Sent to DSW Director',
    'APPROVED' => 'Approved',
    'REJECTED' => 'Rejected',
    'RESOLVED' => 'Resolved',
    _ => status,
  };
}

class _DuplicateMatch {
  final String requestId;
  final double score;
  final String reason;

  const _DuplicateMatch({
    required this.requestId,
    required this.score,
    required this.reason,
  });
}
