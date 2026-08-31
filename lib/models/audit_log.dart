import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String actorId;
  final String actorRole;
  final String action;
  final String targetType;
  final String targetId;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  const AuditLog({
    required this.id,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.timestamp,
    this.details = const {},
  });

  factory AuditLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return AuditLog.fromMap(snapshot.data() ?? {}, id: snapshot.id);
  }

  factory AuditLog.fromMap(Map<String, dynamic> data, {String? id}) {
    final now = DateTime.now();

    return AuditLog(
      id: id ?? (data['id'] ?? '').toString(),
      actorId: (data['actorId'] ?? '').toString(),
      actorRole: (data['actorRole'] ?? '').toString(),
      action: (data['action'] ?? '').toString(),
      targetType: (data['targetType'] ?? '').toString(),
      targetId: (data['targetId'] ?? '').toString(),
      timestamp: _toDateTime(data['timestamp'], fallback: now),
      details: Map<String, dynamic>.from(data['details'] ?? const {}),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    return {
      'id': id,
      'actorId': actorId,
      'actorRole': actorRole,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'timestamp': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(timestamp),
      'details': details,
    };
  }

  AuditLog copyWith({
    String? id,
    String? actorId,
    String? actorRole,
    String? action,
    String? targetType,
    String? targetId,
    DateTime? timestamp,
    Map<String, dynamic>? details,
  }) {
    return AuditLog(
      id: id ?? this.id,
      actorId: actorId ?? this.actorId,
      actorRole: actorRole ?? this.actorRole,
      action: action ?? this.action,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
    );
  }

  static DateTime _toDateTime(dynamic value, {required DateTime fallback}) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return fallback;
  }
}
