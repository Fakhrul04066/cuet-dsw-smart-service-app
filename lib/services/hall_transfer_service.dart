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

class HallTransferStatus {
  static const String submitted = 'SUBMITTED';
  static const String correctionRequired = 'CORRECTION_REQUIRED';
  static const String resubmitted = 'RESUBMITTED';
  static const String officerReviewComplete = 'OFFICER_REVIEW_COMPLETE';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';

  static String timelineLabel(String status) => switch (status) {
        submitted => 'Submitted for Officer Review',
        correctionRequired => 'Resubmission Required',
        resubmitted => 'Resubmitted for Officer Review',
        officerReviewComplete => 'Sent to DSW Director',
        approved => 'Approved by Director',
        rejected => 'Rejected by Director',
        _ => status,
      };

  static List<String> timeline(String status) {
    if (status == correctionRequired) {
      return [submitted, correctionRequired];
    }
    if (status == resubmitted) {
      return [submitted, correctionRequired, resubmitted];
    }
    if (status == officerReviewComplete) {
      return [submitted, officerReviewComplete];
    }
    if (status == approved) {
      return [submitted, officerReviewComplete, approved];
    }
    if (status == rejected) {
      return [submitted, officerReviewComplete, rejected];
    }
    return [submitted];
  }
}

class HallTransferService {
  HallTransferService._();
  static final HallTransferService instance = HallTransferService._();

  static const String applicationType = 'hall_transfer';

  final ApplicationService _applicationService = ApplicationService.instance;

  Future<Application> submitHallTransfer({
    required String currentHall,
    required String requestedHall,
    required String reason,
    String? applicationId,
    List<Map<String, dynamic>> documents = const [],
  }) async {
    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null) throw StateError('No authenticated student found.');
    final profile = await UserService.instance.getUserById(actor.uid);
    if (profile == null ||
        StudentUser.normalizeRole(profile.role) != 'student') {
      throw StateError('Only students can submit hall transfer requests.');
    }

    final application = Application(
      id: applicationId ?? '',
      studentUid: actor.uid,
      type: applicationType,
      studentId: profile.studentId,
      status: HallTransferStatus.submitted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      currentHall: currentHall,
      requestedHall: requestedHall,
      reason: reason,
      documents: documents,
    );

    final id = await _applicationService.createApplication(application);
    await _recordHistory(
      applicationId: id,
      action: HallTransferStatus.submitted,
      performedBy: actor.uid,
      comment: 'Student submitted the hall transfer request for Officer review.',
    );
    await NotificationService.instance.createNotification(
      userUid: actor.uid,
      title: 'Application submitted',
      message: 'Your hall transfer request is now visible to DSW Officers.',
      type: 'application_submitted',
      referenceId: id,
    );
    return application.copyWith(id: id);
  }

  Future<List<Application>> getOfficerQueue() async {
    await _requireRole('dsw_officer');
    final all = await _applicationService.getAllApplications();
    return all.where((item) => item.type == applicationType).toList();
  }

  Future<List<Application>> getDirectorQueue() async {
    await _requireRole('dsw_director');
    final all = await _applicationService.getAllApplications();
    return all.where((item) => item.type == applicationType).toList();
  }

  Future<Application> officerDecision({
    required String applicationId,
    required String decision,
    required String comment,
  }) async {
    final officer = await _requireRole('dsw_officer');
    final application = await _get(applicationId);

    final next = switch (decision) {
      'request_correction' => HallTransferStatus.correctionRequired,
      'complete_review' => HallTransferStatus.officerReviewComplete,
      _ => throw StateError('Unsupported officer action.'),
    };

    if (application.status == next) return application;

    _ensureStatus(application, [
      HallTransferStatus.submitted,
      HallTransferStatus.resubmitted,
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
      action: 'hall_transfer_officer_$decision',
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
    final application = await _get(applicationId);

    final next = switch (decision) {
      'approve' => HallTransferStatus.approved,
      'reject' => HallTransferStatus.rejected,
      _ => throw StateError('Unsupported Director decision.'),
    };

    if (application.status == next) return application;

    _ensureStatus(application, [HallTransferStatus.officerReviewComplete]);
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
      action: 'hall_transfer_director_$decision',
      comment: comment.trim(),
    );

    if (decision == 'approve') {
      try {
        await UserService.instance.updateStudentHallAfterApprovedTransfer(
          studentUid: application.studentUid,
          studentId: application.studentId,
          hall: application.requestedHall ?? '',
        );
      } catch (error) {
        // The Director decision has already been stored. Do not report the
        // whole approval as failed because a secondary profile sync failed.
        developer.log('HALL_TRANSFER_PROFILE_SYNC_FAILED: $error');
      }
    }

    return application.copyWith(
      status: next,
      currentReviewer: director.uid,
      directorComment: comment.trim(),
      updatedAt: DateTime.now(),
    );
  }

  Future<Application> _get(String id) async {
    final application = await _applicationService.getApplicationById(id);
    if (application == null || application.type != applicationType) {
      throw StateError('Hall transfer application not found.');
    }
    return application;
  }

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
      developer.log('HALL_TRANSFER_HISTORY_FAILED: $error');
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
      developer.log('HALL_TRANSFER_AUDIT_FAILED: $error');
    }

    if (application.studentUid.isNotEmpty) {
      try {
        await NotificationService.instance.createNotification(
          userUid: application.studentUid,
          title: 'Application status updated',
          message: 'Your hall transfer application is now $status.',
          type: 'application_status',
          referenceId: application.id,
        );
      } catch (error) {
        developer.log('HALL_TRANSFER_NOTIFICATION_FAILED: $error');
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