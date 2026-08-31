import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? studentId;
  final String role;
  final String? phone;
  final String? department;
  final String? batch;
  final String? hall;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.studentId,
    this.role = 'student',
    this.phone,
    this.department,
    this.batch,
    this.hall,
    this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return AppUser.fromMap(snapshot.data() ?? {}, uid: snapshot.id);
  }

  factory AppUser.fromMap(Map<String, dynamic> data, {String? uid}) {
    final now = DateTime.now();
    return AppUser(
      uid: uid ?? (data['uid'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      studentId: _stringOrNull(data['studentId']),
      role: (data['role'] ?? 'student').toString(),
      phone: _stringOrNull(data['phone']),
      department: _stringOrNull(data['department']),
      batch: _stringOrNull(data['batch']),
      hall: _stringOrNull(data['hall']),
      createdAt: _toDateTime(data['createdAt'], fallback: now),
      updatedAt: _toDateTime(data['updatedAt'], fallback: now),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    final created = createdAt ?? DateTime.now();
    final updated = updatedAt ?? DateTime.now();

    return {
      'uid': uid,
      'email': email,
      'name': name,
      'studentId': studentId,
      'role': role,
      'phone': phone,
      'department': department,
      'batch': batch,
      'hall': hall,
      'createdAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(created),
      'updatedAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updated),
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? studentId,
    String? role,
    String? phone,
    String? department,
    String? batch,
    String? hall,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      batch: batch ?? this.batch,
      hall: hall ?? this.hall,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString();
    return stringValue.isEmpty ? null : stringValue;
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
