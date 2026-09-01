import 'package:firebase_auth/firebase_auth.dart';

import '../models/application.dart';
import '../models/application_history.dart';
import '../models/audit_log.dart';
import '../models/user_model.dart';
import 'application_history_service.dart';
import 'application_service.dart';
import 'audit_log_service.dart';
import 'user_service.dart';
import 'notification_service.dart';

class HallTransferStatus {
  static const String submitted = 'SUBMITTED';
  static const String officerReview = 'OFFICER_REVIEW';
  static const String correctionRequired = 'CORRECTION_REQUIRED';
  static const String officerApproved = 'OFFICER_APPROVED';
  static const String directorReview = 'DIRECTOR_REVIEW';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';

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
      case rejected:
        return 'Rejected';
      default:
        return status;
    }
  }

  static List<String> timeline(String status) {
    const steps = [
      submitted,
      officerReview,
      correctionRequired,
      officerApproved,
      directorReview,
      approved,
    ];
    final currentIndex = steps.indexOf(status);
    return currentIndex < 0 ? steps : steps.sublist(0, currentIndex + 1);
  }
}

class HallTransferService {
  HallTransferService._();

  static final HallTransferService instance = HallTransferService._();

  static const String applicationType = 'hall_transfer';

  final ApplicationService _applicationService = ApplicationService.instance;

  static const Map<String, Set<String>> _validTransitions = {
    HallTransferStatus.submitted: {
      HallTransferStatus.officerReview,
      HallTransferStatus.rejected,
    },
    HallTransferStatus.officerReview: {
      HallTransferStatus.correctionRequired,
      HallTransferStatus.officerApproved,
      HallTransferStatus.rejected,
    },
    HallTransferStatus.correctionRequired: {
      HallTransferStatus.officerReview,
      HallTransferStatus.rejected,
    },
    HallTransferStatus.officerApproved: {
      HallTransferStatus.directorReview,
      HallTransferStatus.rejected,
    },
    HallTransferStatus.directorReview: {
      HallTransferStatus.approved,
      HallTransferStatus.rejected,
    },
    HallTransferStatus.approved: <String>{},
    HallTransferStatus.rejected: <String>{},
  };

  Future<Application> submitHallTransfer({
    required String currentHall,
    required String requestedHall,
    required String reason,
    String? applicationId,
    List<Map<String, dynamic>> documents = const [],
  }) async {
    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null) {
      throw StateError('No authenticated student found.');
    }

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
    final saved = application.copyWith(id: id);

    await _recordHistory(
      applicationId: id,
      action: HallTransferStatus.submitted,
      performedBy: actor.uid,
      comment: 'Student submitted the hall transfer request.',
    );
    await NotificationService.instance.createNotification(
      userUid: actor.uid,
      title: 'Application submitted',
      message: 'Your hall transfer application was submitted.',
      type: 'application_submitted',
      referenceId: id,
    );
    return saved;
  }

  Future<List<Application>> getOfficerQueue() async {
    final applications = <Application>[];
    for (final status in [
      HallTransferStatus.submitted,
      HallTransferStatus.officerReview,
      HallTransferStatus.correctionRequired,
    ]) {
      final items = await _applicationService.getApplicationsByStatus(status);
      applications.addAll(items.where((item) => item.type == applicationType));
    }
    applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return applications;
  }

  Future<List<Application>> getDirectorQueue() async {
    final applications = <Application>[];
    for (final status in [
      HallTransferStatus.officerApproved,
      HallTransferStatus.directorReview,
    ]) {
      final items = await _applicationService.getApplicationsByStatus(status);
      applications.addAll(items.where((item) => item.type == applicationType));
    }
    applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return applications;
  }

  Future<Application> reviewForOfficer(String applicationId) async {
    final actor = await _staff('dsw_officer');
    final application = await _get(applicationId);
    if (application.status != HallTransferStatus.submitted &&
        application.status != HallTransferStatus.correctionRequired) {
      return application;
    }
    return _changeStatus(
      application,
      HallTransferStatus.officerReview,
      'Officer moved the hall transfer request to review.',
      'review',
      actor: actor,
      actorRole: 'dsw_officer',
    );
  }

  Future<Application> officerDecision({
    required String applicationId,
    required String decision,
    String? comment,
  }) async {
    if ((decision == 'request_correction' || decision == 'reject') &&
        (comment == null || comment.trim().isEmpty)) {
      throw StateError('A reason is required for this officer decision.');
    }
    final actor = await _staff('dsw_officer');
    final application = await _get(applicationId);
    final nextStatus = switch (decision) {
      'request_correction' => HallTransferStatus.correctionRequired,
      'approve' => HallTransferStatus.officerApproved,
      'reject' => HallTransferStatus.rejected,
      _ => throw StateError('Unsupported officer decision.'),
    };
    _ensureTransition(application.status, nextStatus, 'DSW Officer');
    return _changeStatus(
      application,
      nextStatus,
      comment ?? 'Officer updated the hall transfer request.',
      'officer_$decision',
      actor: actor,
      actorRole: 'dsw_officer',
    );
  }

  Future<Application> reviewForDirector(String applicationId) async {
    final actor = await _staff('dsw_director');
    final application = await _get(applicationId);
    if (application.status != HallTransferStatus.officerApproved) {
      return application;
    }
    return _changeStatus(
      application,
      HallTransferStatus.directorReview,
      'Director moved the hall transfer request to review.',
      'review',
      actor: actor,
      actorRole: 'dsw_director',
    );
  }

  Future<Application> directorDecision({
    required String applicationId,
    required String decision,
    String? comment,
  }) async {
    if (decision == 'reject' && (comment == null || comment.trim().isEmpty)) {
      throw StateError('A reason is required for this director decision.');
    }
    final actor = await _staff('dsw_director');
    final application = await _get(applicationId);
    final nextStatus = switch (decision) {
      'approve' => HallTransferStatus.approved,
      'reject' => HallTransferStatus.rejected,
      _ => throw StateError('Unsupported director decision.'),
    };
    _ensureTransition(application.status, nextStatus, 'DSW Director');
    return _changeStatus(
      application,
      nextStatus,
      comment ?? 'Director updated the hall transfer request.',
      'director_$decision',
      actor: actor,
      actorRole: 'dsw_director',
    );
  }

  Future<Application> _get(String id) async {
    final application = await _applicationService.getApplicationById(id);
    if (application == null || application.type != applicationType) {
      throw StateError('Hall transfer application not found.');
    }
    return application;
  }

  Future<UserIdentity> _staff(String expectedRole) async {
    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null) throw StateError('No authenticated staff user found.');
    final profile = await UserService.instance.getUserById(actor.uid);
    if (profile == null ||
        StudentUser.normalizeRole(profile.role) != expectedRole) {
      throw StateError('This account is not authorized for this action.');
    }
    return UserIdentity(actor.uid);
  }

  Future<Application> _changeStatus(
    Application application,
    String status,
    String comment,
    String auditAction, {
    UserIdentity? actor,
    String? actorRole,
  }) async {
    final updated = application.copyWith(
      status: status,
      officerComment: actorRole == 'dsw_officer'
          ? comment
          : application.officerComment,
      directorComment: actorRole == 'dsw_director'
          ? comment
          : application.directorComment,
      updatedAt: DateTime.now(),
    );
    await _applicationService.updateApplication(application.id, updated);
    final actorId =
        actor?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'system';
    await _recordHistory(
      applicationId: application.id,
      action: status,
      performedBy: actorId,
      comment: comment,
    );
    if (application.studentUid.isNotEmpty) {
      await NotificationService.instance.createNotification(
        userUid: application.studentUid,
        title: 'Application status updated',
        message: 'Your hall transfer application is now $status.',
        type: 'application_status',
        referenceId: application.id,
      );
    }
    if (actor != null && actorRole != null) {
      await AuditLogService.instance.addAuditLog(
        AuditLog(
          id: '',
          actorId: actor.uid,
          actorRole: actorRole,
          action: 'hall_transfer_$auditAction',
          targetType: 'application',
          targetId: application.id,
          timestamp: DateTime.now(),
          details: {
            'applicationId': application.id,
            'fromStatus': application.status,
            'toStatus': status,
            'comment': comment,
          },
        ),
      );
    }
    return updated;
  }

  Future<void> _recordHistory({
    required String applicationId,
    required String action,
    required String performedBy,
    required String comment,
  }) async {
    await ApplicationHistoryService.instance.addHistoryEntry(
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

  void _ensureTransition(String from, String to, String role) {
    if (!(_validTransitions[from]?.contains(to) ?? false)) {
      throw StateError('$role cannot move from $from to $to.');
    }
  }
}

class UserIdentity {
  final String uid;

  const UserIdentity(this.uid);
}
