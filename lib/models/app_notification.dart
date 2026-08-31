import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String relatedId;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId = '',
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return AppNotification.fromMap(snapshot.data() ?? {}, id: snapshot.id);
  }

  factory AppNotification.fromMap(Map<String, dynamic> data, {String? id}) {
    final now = DateTime.now();

    return AppNotification(
      id: id ?? (data['id'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      relatedId: (data['relatedId'] ?? '').toString(),
      read: data['read'] == true,
      createdAt: _toDateTime(data['createdAt'], fallback: now),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'read': read,
      'createdAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? relatedId,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
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
