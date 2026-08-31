import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/application_history.dart';

class ApplicationHistoryService {
  ApplicationHistoryService._();

  static final ApplicationHistoryService instance =
      ApplicationHistoryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _history =>
      _firestore.collection('application_history');

  Future<List<ApplicationHistory>> getHistoryForApplication(
    String applicationId,
  ) async {
    final snapshot = await _history
        .where('applicationId', isEqualTo: applicationId)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map(ApplicationHistory.fromFirestore).toList();
  }

  Future<String> addHistoryEntry(ApplicationHistory item) async {
    final docRef = _history.doc(item.id.isEmpty ? _history.doc().id : item.id);
    final payload = item.toFirestore(useServerTimestamps: true);
    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  Stream<List<ApplicationHistory>> streamHistoryForApplication(
    String applicationId,
  ) {
    return _history
        .where('applicationId', isEqualTo: applicationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ApplicationHistory.fromFirestore).toList(),
        );
  }
}
