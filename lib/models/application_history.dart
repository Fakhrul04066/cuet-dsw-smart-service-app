import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationHistory {
  final String id;
  final String applicationId;
  final String action;
  final String performedBy;
  final String comment;
  final DateTime timestamp;

  const ApplicationHistory({
    required this.id,
    required this.applicationId,
    required this.action,
    required this.performedBy,
    required this.comment,
    required this.timestamp,
  });

  factory ApplicationHistory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return ApplicationHistory.fromMap(snapshot.data() ?? {}, id: snapshot.id);
  }

  factory ApplicationHistory.fromMap(Map<String, dynamic> data, {String? id}) {
    final now = DateTime.now();

    return ApplicationHistory(
      id: id ?? (data['id'] ?? '').toString(),
      applicationId: (data['applicationId'] ?? '').toString(),
      action: (data['action'] ?? '').toString(),
      performedBy: (data['performedBy'] ?? '').toString(),
      comment: (data['comment'] ?? '').toString(),
      timestamp: _toDateTime(data['timestamp'], fallback: now),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    return {
      'id': id,
      'applicationId': applicationId,
      'action': action,
      'performedBy': performedBy,
      'comment': comment,
      'timestamp': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(timestamp),
    };
  }

  ApplicationHistory copyWith({
    String? id,
    String? applicationId,
    String? action,
    String? performedBy,
    String? comment,
    DateTime? timestamp,
  }) {
    return ApplicationHistory(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      action: action ?? this.action,
      performedBy: performedBy ?? this.performedBy,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
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
