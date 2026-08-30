import 'package:cloud_firestore/cloud_firestore.dart';

class StudentUser {
  final String uid;
  final String studentId;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String level;
  final String term;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentUser({
    required this.uid,
    required this.studentId,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.level,
    required this.term,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  String get levelTerm => 'Level $level / Term $term';

  factory StudentUser.empty(String uid) {
    final now = DateTime.now();
    return StudentUser(
      uid: uid,
      studentId: '',
      name: '',
      email: '',
      phone: '',
      department: '',
      level: '',
      term: '',
      role: 'student',
      createdAt: now,
      updatedAt: now,
    );
  }

  factory StudentUser.fromMap(Map<String, dynamic> data, {String? uid}) {
    final resolvedUid = uid ?? (data['uid'] ?? '').toString();
    final now = DateTime.now();

    return StudentUser(
      uid: resolvedUid,
      studentId: (data['studentId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      department: (data['department'] ?? '').toString(),
      level: (data['level'] ?? '').toString(),
      term: (data['term'] ?? '').toString(),
      role: (data['role'] ?? 'student').toString(),
      createdAt: _toDateTime(data['createdAt'], fallback: now),
      updatedAt: _toDateTime(data['updatedAt'], fallback: now),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'studentId': studentId,
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'level': level,
      'term': term,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
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
