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

  Future<void> updateApplication(String id, Application application) async {
    final payload = application
        .copyWith(updatedAt: DateTime.now())
        .toFirestore(useServerTimestamps: true);
    await _applications.doc(id).update(payload);
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
    final fields = <String, dynamic>{
      'purpose': purpose,
      'description': description,
      'status': 'OFFICER_REVIEW',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (application.type == 'hall_transfer') {
      fields['currentHall'] = currentHall ?? application.currentHall ?? '';
      fields['requestedHall'] =
          requestedHall ?? application.requestedHall ?? '';
      fields['reason'] = reason ?? application.reason ?? '';
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
    return _applications
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Application.fromFirestore).toList(),
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
