import 'package:firebase_auth/firebase_auth.dart';

import '../models/application.dart';
import '../models/application_history.dart';
import '../models/audit_log.dart';
import '../models/user_model.dart';
import 'application_history_service.dart';
import 'application_service.dart';
import 'audit_log_service.dart';
import 'user_service.dart';

class CharacterCertificateStatus {
  static const String submitted = 'SUBMITTED';
  static const String officerReview = 'OFFICER_REVIEW';
  static const String correctionRequired = 'CORRECTION_REQUIRED';
  static const String officerApproved = 'OFFICER_APPROVED';
  static const String directorReview = 'DIRECTOR_REVIEW';
  static const String approved = 'APPROVED';
  static const String certificateIssued = 'CERTIFICATE_ISSUED';
  static const String rejected = 'REJECTED';

  static const List<String> ordered = [
    submitted,
    officerReview,
    correctionRequired,
    officerApproved,
    directorReview,
    approved,
    certificateIssued,
    rejected,
  ];

  static String timelineLabel(String status) {
    switch (status) {
      case submitted:
        return 'Submitted';
      case officerReview:
        return 'Officer Review';
      case correctionRequired:
        return 'Correction Required';
      case officerApproved:
        return 'Officer Approved';
      case directorReview:
        return 'Director Review';
      case approved:
        return 'Approved';
      case certificateIssued:
        return 'Certificate Issued';
      case rejected:
        return 'Rejected';
      default:
        return status;
    }
  }

  static List<String> trackingTimeline(String currentStatus) {
    final order = [
      submitted,
      officerReview,
      officerApproved,
      directorReview,
      approved,
      certificateIssued,
    ];

    final currentIndex = order.indexOf(currentStatus);
    if (currentIndex == -1) {
      return [
        submitted,
        officerReview,
        officerApproved,
        directorReview,
        approved,
        certificateIssued,
      ];
    }

    final result = <String>[];
    for (int index = 0; index < order.length; index++) {
      final value = order[index];
      result.add(value);
      if (index == currentIndex) {
        break;
      }
    }
    return result;
  }
}

class CharacterCertificateService {
  CharacterCertificateService._();

  static final CharacterCertificateService instance =
      CharacterCertificateService._();

  final ApplicationService _applicationService = ApplicationService.instance;

  static const Map<String, Set<String>> validTransitions = {
    CharacterCertificateStatus.submitted: {
      CharacterCertificateStatus.officerReview,
      CharacterCertificateStatus.correctionRequired,
      CharacterCertificateStatus.rejected,
    },
    CharacterCertificateStatus.officerReview: {
      CharacterCertificateStatus.correctionRequired,
      CharacterCertificateStatus.officerApproved,
      CharacterCertificateStatus.rejected,
    },
    CharacterCertificateStatus.correctionRequired: {
      CharacterCertificateStatus.officerReview,
      CharacterCertificateStatus.rejected,
    },
    CharacterCertificateStatus.officerApproved: {
      CharacterCertificateStatus.directorReview,
      CharacterCertificateStatus.rejected,
    },
    CharacterCertificateStatus.directorReview: {
      CharacterCertificateStatus.approved,
      CharacterCertificateStatus.rejected,
    },
    CharacterCertificateStatus.approved: {
      CharacterCertificateStatus.certificateIssued,
    },
    CharacterCertificateStatus.certificateIssued: <String>{},
    CharacterCertificateStatus.rejected: <String>{},
  };

  bool canTransition(String fromStatus, String toStatus) {
    return validTransitions[fromStatus]?.contains(toStatus) ?? false;
  }

  Future<Application> submitCharacterCertificate({
    required String purpose,
    required String description,
    List<Map<String, dynamic>> documents = const [],
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw StateError('No authenticated student found.');
    }

    final studentProfile = await UserService.instance.getUserById(
      currentUser.uid,
    );
    if (studentProfile == null) {
      throw StateError('Student profile not found.');
    }

    if (StudentUser.normalizeRole(studentProfile.role) != 'student') {
      throw StateError(
        'Only students can submit character certificate applications.',
      );
    }

    final application = Application(
      id: '',
      type: 'character_certificate',
      studentId: studentProfile.studentId,
      status: CharacterCertificateStatus.submitted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      purpose: purpose,
      description: description,
      documents: documents,
    );

    final applicationId = await _applicationService.createApplication(
      application,
    );
    final savedApplication = application.copyWith(id: applicationId);

    await _recordHistory(
      applicationId: applicationId,
      action: CharacterCertificateStatus.submitted,
      performedBy: currentUser.uid,
      comment: 'Student submitted the character certificate application.',
    );

    return savedApplication;
  }

  Future<List<Application>> getStudentApplications() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const [];
    }

    final profile = await UserService.instance.getUserById(currentUser.uid);
    if (profile == null || profile.studentId.isEmpty) {
      return const [];
    }

    return _applicationService.getApplicationsByStudentId(profile.studentId);
  }

  Future<List<Application>> getOfficerQueue() async {
    final statuses = [
      CharacterCertificateStatus.submitted,
      CharacterCertificateStatus.officerReview,
      CharacterCertificateStatus.correctionRequired,
    ];

    final applications = <Application>[];
    for (final status in statuses) {
      final items = await _applicationService.getApplicationsByStatus(status);
      applications.addAll(
        items.where((item) => item.type == 'character_certificate'),
      );
    }

    applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return applications;
  }

  Future<List<Application>> getDirectorQueue() async {
    final statuses = [
      CharacterCertificateStatus.officerApproved,
      CharacterCertificateStatus.directorReview,
    ];

    final applications = <Application>[];
    for (final status in statuses) {
      final items = await _applicationService.getApplicationsByStatus(status);
      applications.addAll(
        items.where((item) => item.type == 'character_certificate'),
      );
    }

    applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return applications;
  }

  Future<Application> getApplicationById(String applicationId) async {
    final application = await _applicationService.getApplicationById(
      applicationId,
    );
    if (application == null) {
      throw StateError('Application not found.');
    }
    return application;
  }

  Future<Application> officerDecision({
    required String applicationId,
    required String decision,
    String? comment,
  }) async {
    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null) {
      throw StateError('No authenticated officer found.');
    }

    final application = await getApplicationById(applicationId);
    final actorProfile = await UserService.instance.getUserById(actor.uid);
    if (actorProfile == null) {
      throw StateError('Officer profile not found.');
    }

    if (StudentUser.normalizeRole(actorProfile.role) != 'dsw_officer') {
      throw StateError(
        'Only DSW officers can review character certificate applications.',
      );
    }

    final nextStatus = switch (decision) {
      'request_correction' => CharacterCertificateStatus.correctionRequired,
      'reject' => CharacterCertificateStatus.rejected,
      'approve' => CharacterCertificateStatus.officerApproved,
      _ => throw StateError('Unsupported officer decision.'),
    };

    _ensureValidTransition(application.status, nextStatus, 'DSW Officer');

    final updatedApplication = application.copyWith(
      status: nextStatus,
      officerComment: comment ?? application.officerComment,
      updatedAt: DateTime.now(),
    );

    await _applicationService.updateApplication(
      applicationId,
      updatedApplication,
    );

    await _recordHistory(
      applicationId: applicationId,
      action: nextStatus,
      performedBy: actor.uid,
      comment: comment ?? _officerDecisionMessage(decision),
    );

    await _recordAudit(
      actorId: actor.uid,
      actorRole: 'dsw_officer',
      action: 'character_certificate_officer_$decision',
      targetType: 'application',
      targetId: applicationId,
      details: {
        'applicationId': applicationId,
        'decision': decision,
        'fromStatus': application.status,
        'toStatus': nextStatus,
        'comment': comment ?? _officerDecisionMessage(decision),
      },
    );

    return updatedApplication;
  }

  Future<Application> directorDecision({
    required String applicationId,
    required String decision,
    String? comment,
  }) async {
    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null) {
      throw StateError('No authenticated director found.');
    }

    final application = await getApplicationById(applicationId);
    final actorProfile = await UserService.instance.getUserById(actor.uid);
    if (actorProfile == null) {
      throw StateError('Director profile not found.');
    }

    if (StudentUser.normalizeRole(actorProfile.role) != 'dsw_director') {
      throw StateError('Only DSW directors can make final decisions.');
    }

    final nextStatus = switch (decision) {
      'approve' => CharacterCertificateStatus.approved,
      'reject' => CharacterCertificateStatus.rejected,
      'issue_certificate' => CharacterCertificateStatus.certificateIssued,
      _ => throw StateError('Unsupported director decision.'),
    };

    _ensureValidTransition(application.status, nextStatus, 'DSW Director');

    final updatedApplication = application.copyWith(
      status: nextStatus,
      directorComment: comment ?? application.directorComment,
      updatedAt: DateTime.now(),
    );

    await _applicationService.updateApplication(
      applicationId,
      updatedApplication,
    );

    await _recordHistory(
      applicationId: applicationId,
      action: nextStatus,
      performedBy: actor.uid,
      comment: comment ?? _directorDecisionMessage(decision),
    );

    await _recordAudit(
      actorId: actor.uid,
      actorRole: 'dsw_director',
      action: 'character_certificate_director_$decision',
      targetType: 'application',
      targetId: applicationId,
      details: {
        'applicationId': applicationId,
        'decision': decision,
        'fromStatus': application.status,
        'toStatus': nextStatus,
        'comment': comment ?? _directorDecisionMessage(decision),
      },
    );

    return updatedApplication;
  }

  Future<Application> reviewApplicationForOfficer(String applicationId) async {
    final application = await getApplicationById(applicationId);
    if (application.status == CharacterCertificateStatus.submitted) {
      final updated = application.copyWith(
        status: CharacterCertificateStatus.officerReview,
        updatedAt: DateTime.now(),
      );
      await _applicationService.updateApplication(applicationId, updated);
      await _recordHistory(
        applicationId: applicationId,
        action: CharacterCertificateStatus.officerReview,
        performedBy: FirebaseAuth.instance.currentUser?.uid ?? 'system',
        comment: 'Application moved to officer review.',
      );
      return updated;
    }
    return application;
  }

  Future<Application> reviewApplicationForDirector(String applicationId) async {
    final application = await getApplicationById(applicationId);
    if (application.status == CharacterCertificateStatus.officerApproved) {
      final updated = application.copyWith(
        status: CharacterCertificateStatus.directorReview,
        updatedAt: DateTime.now(),
      );
      await _applicationService.updateApplication(applicationId, updated);
      await _recordHistory(
        applicationId: applicationId,
        action: CharacterCertificateStatus.directorReview,
        performedBy: FirebaseAuth.instance.currentUser?.uid ?? 'system',
        comment: 'Application moved to director review.',
      );
      return updated;
    }
    return application;
  }

  List<String> statusTimelineForApplication(String status) {
    return CharacterCertificateStatus.trackingTimeline(status);
  }

  void _ensureValidTransition(
    String fromStatus,
    String toStatus,
    String roleName,
  ) {
    if (!canTransition(fromStatus, toStatus)) {
      throw StateError(
        '$roleName cannot move from $fromStatus to $toStatus for character certificate applications.',
      );
    }
  }

  Future<void> _recordHistory({
    required String applicationId,
    required String action,
    required String performedBy,
    required String comment,
  }) async {
    final entry = ApplicationHistory(
      id: '',
      applicationId: applicationId,
      action: action,
      performedBy: performedBy,
      comment: comment,
      timestamp: DateTime.now(),
    );

    await ApplicationHistoryService.instance.addHistoryEntry(entry);
  }

  Future<void> _recordAudit({
    required String actorId,
    required String actorRole,
    required String action,
    required String targetType,
    required String targetId,
    required Map<String, dynamic> details,
  }) async {
    final log = AuditLog(
      id: '',
      actorId: actorId,
      actorRole: actorRole,
      action: action,
      targetType: targetType,
      targetId: targetId,
      timestamp: DateTime.now(),
      details: details,
    );

    await AuditLogService.instance.addAuditLog(log);
  }

  String _officerDecisionMessage(String decision) {
    switch (decision) {
      case 'request_correction':
        return 'Officer requested correction.';
      case 'reject':
        return 'Officer rejected the application.';
      case 'approve':
        return 'Officer approved the application.';
      default:
        return 'Officer updated the application.';
    }
  }

  String _directorDecisionMessage(String decision) {
    switch (decision) {
      case 'approve':
        return 'Director approved the application.';
      case 'reject':
        return 'Director rejected the application.';
      case 'issue_certificate':
        return 'Director issued the certificate.';
      default:
        return 'Director updated the application.';
    }
  }
}
