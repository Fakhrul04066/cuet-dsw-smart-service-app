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
      level: '',
      term: '',
      role: 'student',
      createdAt: now,
      updatedAt: now,
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
    String? level,
    String? term,
  }) async {
    final existing = await getUserById(uid);
    final next = existing ?? StudentUser.empty(uid);

    final profile = StudentUser(
      uid: next.uid,
      studentId: studentId ?? next.studentId,
      name: name ?? next.name,
      email: email ?? next.email,
      phone: phone ?? next.phone,
      department: department ?? next.department,
      level: level ?? next.level,
      term: term ?? next.term,
      role: next.role,
      createdAt: next.createdAt,
      updatedAt: DateTime.now(),
    );

    await _users.doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }
}
