import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class AppUserService {
  AppUserService._();

  static final AppUserService instance = AppUserService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<AppUser?> getUserById(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) return null;
    return AppUser.fromFirestore(snapshot);
  }

  Future<AppUser?> getUserByStudentId(String studentId) async {
    final snapshot = await _users
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AppUser.fromFirestore(snapshot.docs.first);
  }

  Future<String> createOrUpdateUser(AppUser user) async {
    final docRef = _users.doc(user.uid);
    final snapshot = await docRef.get();

    final payload = user.toFirestore(useServerTimestamps: true);

    if (snapshot.exists) {
      await docRef.update(payload);
    } else {
      await docRef.set(payload);
    }

    return docRef.id;
  }

  Future<List<AppUser>> listUsers() async {
    final snapshot = await _users.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(AppUser.fromFirestore).toList();
  }

  Stream<List<AppUser>> streamUsers() {
    return _users
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppUser.fromFirestore).toList());
  }
}
