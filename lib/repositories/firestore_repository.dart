import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreRepository<T> {
  final FirebaseFirestore firestore;

  FirestoreRepository({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path);

  Future<T?> getById(String path, String id);

  Future<List<T>> getAll(
    String path, {
    String? orderBy,
    bool descending = false,
  });

  Future<void> create(String path, String id, Map<String, dynamic> data);

  Future<void> update(String path, String id, Map<String, dynamic> data);

  Future<void> delete(String path, String id);
}
