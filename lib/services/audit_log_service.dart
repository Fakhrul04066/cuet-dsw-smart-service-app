import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/audit_log.dart';

class AuditLogService {
  AuditLogService._();

  static final AuditLogService instance = AuditLogService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection('audit_logs');

  Future<String> addAuditLog(AuditLog log) async {
    final docRef = _auditLogs.doc(
      log.id.isEmpty ? _auditLogs.doc().id : log.id,
    );
    final payload = log.toFirestore(useServerTimestamps: true);
    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  Future<List<AuditLog>> getRecentLogs() async {
    final snapshot = await _auditLogs
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map(AuditLog.fromFirestore).toList();
  }

  Stream<List<AuditLog>> streamRecentLogs() {
    return _auditLogs
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AuditLog.fromFirestore).toList());
  }
}
