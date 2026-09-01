import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/application.dart';
import '../models/application_history.dart';
import 'application_history_service.dart';
import 'user_service.dart';

class ApplicationService {
  ApplicationService._();

  static final ApplicationService instance = ApplicationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('applications');

  Future<Application?> getApplicationById(String id) async {
    final snapshot = await _applications.doc(id).get();
    if (!snapshot.exists) return null;
    return Application.fromFirestore(snapshot);
  }

  Future<List<Application>> getApplicationsByStudentId(String studentId) async {
    final snapshot = await _applications
        .where('studentId', isEqualTo: studentId)
        .get();
    final applications = snapshot.docs.map(Application.fromFirestore).toList();
    applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return applications;
  }

  Future<List<Application>> getApplicationsByStatus(String status) async {
    final snapshot = await _applications
        .where('status', isEqualTo: status)
        .get();
    final applications = snapshot.docs.map(Application.fromFirestore).toList();
    applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return applications;
  }

  Future<String> createApplication(Application application) async {
    final docRef = _applications.doc(
      application.id.isEmpty ? _applications.doc().id : application.id,
    );
    final payload = application.toFirestore(useServerTimestamps: true);
    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  Future<void> updateWorkflowStatus(
    String id, {
    required String status,
    String? currentReviewer,
    String? officerComment,
    String? directorComment,
  }) async {
    // Workflow updates are intentionally narrow. In particular, do not write
    // studentUid/type/studentId/createdAt back to legacy demo documents while a
    // staff member is only changing status. This keeps the client payload in
    // exact sync with the Firestore rules' allowed changed fields.
    final fields = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (currentReviewer != null) {
      fields['currentReviewer'] = currentReviewer;
    }
    if (officerComment != null) {
      fields['officerComment'] = officerComment;
    }
    if (directorComment != null) {
      fields['directorComment'] = directorComment;
    }
    await _applications.doc(id).update(fields);
  }

  Future<void> deleteApplication(String id) async {
    await _applications.doc(id).delete();
  }

  Future<void> resubmitApplication(
    Application application, {
    required String purpose,
    required String description,
    String? currentHall,
    String? requestedHall,
    String? reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated student found.');
    final profile = await UserService.instance.getUserById(user.uid);
    if (profile == null || profile.studentId != application.studentId) {
      throw StateError('You can only resubmit your own application.');
    }
    if (application.status != 'CORRECTION_REQUIRED') {
      throw StateError(
        'Only applications requiring correction can be resubmitted.',
      );
    }
    if (application.type == 'character_certificate' &&
        (purpose.trim().isEmpty || description.trim().isEmpty)) {
      throw StateError('Purpose and description are required.');
    }
    if (application.type == 'hall_transfer' &&
        ((currentHall ?? '').trim().isEmpty ||
            (requestedHall ?? '').trim().isEmpty ||
            (reason ?? '').trim().isEmpty)) {
      throw StateError(
        'Current hall, requested hall, and reason are required.',
      );
    }
    final fields = <String, dynamic>{
      'status': 'OFFICER_REVIEW',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (application.type == 'character_certificate') {
      fields['purpose'] = purpose.trim();
      fields['description'] = description.trim();
    } else if (application.type == 'hall_transfer') {
      fields['currentHall'] =
          (currentHall ?? application.currentHall ?? '').trim();
      fields['requestedHall'] =
          (requestedHall ?? application.requestedHall ?? '').trim();
      fields['reason'] = (reason ?? application.reason ?? '').trim();
    }
    await _applications.doc(application.id).update(fields);
    await ApplicationHistoryService.instance.addHistoryEntry(
      ApplicationHistory(
        id: '',
        applicationId: application.id,
        action: 'STUDENT_RESUBMITTED',
        performedBy: user.uid,
        comment: 'Student resubmitted the application after correction.',
        timestamp: DateTime.now(),
      ),
    );
  }

  Stream<List<Application>> streamApplicationsForStudent(String studentId) {
    return _applications.where('studentId', isEqualTo: studentId).snapshots().map(
      (snapshot) {
        final applications = snapshot.docs
            .map(Application.fromFirestore)
            .toList();
        applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return applications;
      },
    );
  }

  Stream<List<Application>> streamAllApplications() {
    return _applications
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Application.fromFirestore).toList(),
        );
  }
}
