import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';

import '../models/application.dart';
import '../models/application_history.dart';
import '../models/audit_log.dart';
import '../models/user_model.dart';
import 'application_history_service.dart';
import 'application_service.dart';
import 'audit_log_service.dart';
import 'notification_service.dart';
import 'user_service.dart';

class CharacterCertificateStatus {
  static const String submitted = 'SUBMITTED';
  static const String correctionRequired = 'CORRECTION_REQUIRED';
  static const String resubmitted = 'RESUBMITTED';
  static const String officerReviewComplete = 'OFFICER_REVIEW_COMPLETE';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
  static const String certificateIssued = 'CERTIFICATE_ISSUED';

  static String timelineLabel(String status) => switch (status) {
        submitted => 'Submitted for Officer Review',
        correctionRequired => 'Resubmission Required',
        resubmitted => 'Resubmitted for Officer Review',
        officerReviewComplete => 'Sent to DSW Director',
        approved => 'Approved by Director',
        rejected => 'Rejected by Director',
        certificateIssued => 'Certificate Issued',
        _ => status,
      };

  static List<String> trackingTimeline(String currentStatus) {
    if (currentStatus == correctionRequired) {
      return [submitted, correctionRequired];
    }
    if (currentStatus == resubmitted) {
      return [submitted, correctionRequired, resubmitted];
    }
    if (currentStatus == officerReviewComplete) {
      return [submitted, officerReviewComplete];
    }
    if (currentStatus == approved) {
      return [submitted, officerReviewComplete, approved];
    }
    if (currentStatus == certificateIssued) {
      return [submitted, officerReviewComplete, approved, certificateIssued];
    }
    if (currentStatus == rejected) {
      return [submitted, officerReviewComplete, rejected];
    }
    return [submitted];
  }
}

class CharacterCertificateService {
  CharacterCertificateService._();
  static final CharacterCertificateService instance =
      CharacterCertificateService._();

  final ApplicationService _applicationService = ApplicationService.instance;

  Future<Application> submitCharacterCertificate({
    required String purpose,
    required String description,
    String? applicationId,
    List<Map<String, dynamic>> documents = const [],
  }) async {
    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null) throw StateError('No authenticated student found.');
    final profile = await UserService.instance.getUserById(actor.uid);
    if (profile == null ||
        StudentUser.normalizeRole(profile.role) != 'student') {
      throw StateError(
        'Only students can submit character certificate applications.',
      );
    }

    final application = Application(
      id: applicationId ?? '',
      studentUid: actor.uid,
      type: 'character_certificate',
      studentId: profile.studentId,
      status: CharacterCertificateStatus.submitted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      purpose: purpose,
      description: description,
      documents: documents,
    );

    final id = await _applicationService.createApplication(application);
    await _recordHistory(
      applicationId: id,
      action: CharacterCertificateStatus.submitted,
      performedBy: actor.uid,
      comment:
          'Student submitted the character certificate application for Officer review.',
    );
    await NotificationService.instance.createNotification(
      userUid: actor.uid,
      title: 'Application submitted',
      message:
          'Your character certificate application is now visible to DSW Officers.',
      type: 'application_submitted',
      referenceId: id,
    );
    return application.copyWith(id: id);
  }

  Future<List<Application>> getStudentApplications() async {
    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null) return const [];
    final profile = await UserService.instance.getUserById(actor.uid);
    if (profile == null) return const [];
    return _applicationService.getApplicationsByStudentUid(actor.uid);
  }

  Future<List<Application>> getOfficerQueue() async {
    await _requireRole('dsw_officer');
    final all = await _applicationService.getAllApplications();
    return all
        .where((item) => item.type == 'character_certificate')
        .toList();
  }

  Future<List<Application>> getDirectorQueue() async {
    await _requireRole('dsw_director');
    final all = await _applicationService.getAllApplications();
    return all
        .where((item) => item.type == 'character_certificate')
        .toList();
  }

  Future<Application> getApplicationById(String applicationId) async {
    final application =
        await _applicationService.getApplicationById(applicationId);
    if (application == null || application.type != 'character_certificate') {
      throw StateError('Character certificate application not found.');
    }
    return application;
  }

  Future<Application> officerDecision({
    required String applicationId,
    required String decision,
    required String comment,
  }) async {
    final officer = await _requireRole('dsw_officer');
    final application = await getApplicationById(applicationId);

    final next = switch (decision) {
      'request_correction' => CharacterCertificateStatus.correctionRequired,
      'complete_review' => CharacterCertificateStatus.officerReviewComplete,
      _ => throw StateError('Unsupported officer action.'),
    };

    // A quick double tap or a delayed UI refresh must not turn a successful
    // workflow update into a false error. Repeating the same action is a no-op.
    if (application.status == next) return application;

    _ensureStatus(application, [
      CharacterCertificateStatus.submitted,
      CharacterCertificateStatus.resubmitted,
    ]);
    if (comment.trim().isEmpty) {
      throw StateError('A review note is required.');
    }

    await _applicationService.updateWorkflowStatus(
      applicationId,
      status: next,
      currentReviewer: officer.uid,
      officerComment:
          decision == 'complete_review' ? comment.trim() : null,
      correctionNote:
          decision == 'request_correction' ? comment.trim() : null,
    );
    await _afterStaffTransition(
      application: application,
      actor: officer,
      actorRole: 'dsw_officer',
      status: next,
      action: 'character_certificate_officer_$decision',
      comment: comment.trim(),
    );
    return application.copyWith(
      status: next,
      currentReviewer: officer.uid,
      officerComment: decision == 'complete_review'
          ? comment.trim()
          : application.officerComment,
      correctionNote: decision == 'request_correction'
          ? comment.trim()
          : application.correctionNote,
      updatedAt: DateTime.now(),
    );
  }

  Future<Application> directorDecision({
    required String applicationId,
    required String decision,
    String? comment,
  }) async {
    final director = await _requireRole('dsw_director');
    final application = await getApplicationById(applicationId);

    if (decision == 'issue_certificate') {
      if (application.status == CharacterCertificateStatus.certificateIssued) {
        return application;
      }
      _ensureStatus(application, [CharacterCertificateStatus.approved]);
      final effectiveComment = (comment ?? '').trim().isEmpty
          ? 'Director issued the certificate.'
          : comment!.trim();
      await _applicationService.updateWorkflowStatus(
        applicationId,
        status: CharacterCertificateStatus.certificateIssued,
        currentReviewer: director.uid,
        directorComment: effectiveComment,
      );
      await _afterStaffTransition(
        application: application,
        actor: director,
        actorRole: 'dsw_director',
        status: CharacterCertificateStatus.certificateIssued,
        action: 'character_certificate_certificate_issued',
        comment: effectiveComment,
      );
      return application.copyWith(
        status: CharacterCertificateStatus.certificateIssued,
        currentReviewer: director.uid,
        directorComment: effectiveComment,
        updatedAt: DateTime.now(),
      );
    }

    final next = switch (decision) {
      'approve' => CharacterCertificateStatus.approved,
      'reject' => CharacterCertificateStatus.rejected,
      _ => throw StateError('Unsupported Director decision.'),
    };

    if (application.status == next) return application;

    _ensureStatus(
      application,
      [CharacterCertificateStatus.officerReviewComplete],
    );
    if ((comment ?? '').trim().isEmpty) {
      throw StateError('An official Director note is required.');
    }

    await _applicationService.updateWorkflowStatus(
      applicationId,
      status: next,
      currentReviewer: director.uid,
      directorComment: comment!.trim(),
    );
    await _afterStaffTransition(
      application: application,
      actor: director,
      actorRole: 'dsw_director',
      status: next,
      action: 'character_certificate_director_$decision',
      comment: comment.trim(),
    );
    return application.copyWith(
      status: next,
      currentReviewer: director.uid,
      directorComment: comment.trim(),
      updatedAt: DateTime.now(),
    );
  }

  List<String> statusTimelineForApplication(String status) =>
      CharacterCertificateStatus.trackingTimeline(status);

  Future<StudentUser> _requireRole(String expectedRole) async {
    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null) throw StateError('No authenticated user found.');
    final profile = await UserService.instance.getUserById(actor.uid);
    if (profile == null ||
        StudentUser.normalizeRole(profile.role) != expectedRole) {
      throw StateError('This account is not authorized for this action.');
    }
    return profile;
  }

  void _ensureStatus(Application application, List<String> allowed) {
    if (!allowed.contains(application.status)) {
      throw StateError(
        'Action is not allowed while status is ${application.status}.',
      );
    }
  }

  Future<void> _afterStaffTransition({
    required Application application,
    required StudentUser actor,
    required String actorRole,
    required String status,
    required String action,
    required String comment,
  }) async {
    try {
      await _recordHistory(
        applicationId: application.id,
        action: status,
        performedBy: actor.uid,
        comment: comment,
      );
    } catch (error) {
      // The status update is authoritative. A secondary history failure must
      // not make the already-completed decision look unsuccessful.
      developer.log('APPLICATION_HISTORY_FAILED: $error');
    }
    try {
      await AuditLogService.instance.addAuditLog(
        AuditLog(
          id: '',
          actorId: actor.uid,
          actorRole: actorRole,
          action: action,
          targetType: 'application',
          targetId: application.id,
          timestamp: DateTime.now(),
          details: {
            'fromStatus': application.status,
            'toStatus': status,
            'comment': comment,
          },
        ),
      );
    } catch (error) {
      developer.log('APPLICATION_AUDIT_FAILED: $error');
    }
    if (application.studentUid.isNotEmpty) {
      try {
        await NotificationService.instance.createNotification(
          userUid: application.studentUid,
          title: 'Application status updated',
          message: 'Your character certificate application is now $status.',
          type: 'application_status',
          referenceId: application.id,
        );
      } catch (error) {
        developer.log('APPLICATION_NOTIFICATION_FAILED: $error');
      }
    }
  }

  Future<void> _recordHistory({
    required String applicationId,
    required String action,
    required String performedBy,
    required String comment,
  }) =>
      ApplicationHistoryService.instance.addHistoryEntry(
        ApplicationHistory(
          id: '',
          applicationId: applicationId,
          action: action,
          performedBy: performedBy,
          comment: comment,
          timestamp: DateTime.now(),
        ),
      );
}
