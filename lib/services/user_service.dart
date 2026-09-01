import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserService {
  UserService._();

  static final UserService instance = UserService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<StudentUser?> getCurrentUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return getUserById(uid);
  }

  Future<StudentUser?> getUserById(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return StudentUser.fromMap(snapshot.data()!, uid: snapshot.id);
  }

  Future<StudentUser?> getUserByStudentId(String studentId) async {
    final snapshot = await _users
        .where('studentId', isEqualTo: studentId.trim())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    return StudentUser.fromMap(doc.data(), uid: doc.id);
  }

  Future<void> createUserProfileIfMissing(User user) async {
    final docRef = _users.doc(user.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      return;
    }

    final now = DateTime.now();
    final profile = StudentUser(
      uid: user.uid,
      studentId: '',
      name: user.displayName ?? user.email?.split('@').first ?? 'Student',
      email: user.email ?? '',
      phone: '',
      department: '',
      batch: '',
      hall: '',
      role: 'student',
      createdAt: now,
      updatedAt: now,
      level: '',
      term: '',
    );

    await docRef.set(profile.toMap());
  }

  Future<void> updateProfile({
    required String uid,
    String? studentId,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? batch,
    String? hall,
    String? profileImageUrl,
    String? role,
    String? level,
    String? term,
  }) async {
    final existing = await getUserById(uid);
    final next = existing ?? StudentUser.empty(uid);

    final safeRole = role == null
        ? next.role
        : StudentUser.validateStudentRegistrationRole(role) ?? next.role;

    final profile = StudentUser(
      uid: next.uid,
      studentId: studentId ?? next.studentId,
      name: name ?? next.name,
      email: email ?? next.email,
      phone: phone ?? next.phone,
      department: department ?? next.department,
      batch: batch ?? next.batch,
      hall: hall ?? next.hall,
      role: safeRole,
      profileImageUrl: profileImageUrl ?? next.profileImageUrl,
      createdAt: next.createdAt,
      updatedAt: DateTime.now(),
      level: level ?? next.level,
      term: term ?? next.term,
    );

    await _users.doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }
  Future<void> updateOwnPhone({
    required String uid,
    required String phone,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw StateError('You can update only your own profile.');
    }

    await _users.doc(uid).update({
      'phone': phone.trim(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateStudentHallAfterApprovedTransfer({
    required String studentUid,
    required String studentId,
    required String hall,
  }) async {
    final normalizedHall = hall.trim();
    if (normalizedHall.isEmpty) {
      throw StateError('Approved hall transfer is missing the requested hall.');
    }

    var targetUid = studentUid.trim();
    if (targetUid.isEmpty) {
      final profile = await getUserByStudentId(studentId);
      targetUid = profile?.uid ?? '';
    }

    if (targetUid.isEmpty) {
      throw StateError('Could not find the student profile for hall update.');
    }

    await _users.doc(targetUid).update({
      'hall': normalizedHall,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

}
