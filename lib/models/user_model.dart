import 'package:cloud_firestore/cloud_firestore.dart';

class StudentUser {
  final String uid;
  final String studentId;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String batch;
  final String hall;
  final String role;
  final String profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String level;
  final String term;

  const StudentUser({
    required this.uid,
    required this.studentId,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    this.batch = '',
    this.hall = '',
    required this.role,
    this.profileImageUrl = '',
    required this.createdAt,
    required this.updatedAt,
    this.level = '',
    this.term = '',
  });

  String get levelTerm =>
      level.isEmpty && term.isEmpty ? 'Not set' : 'Level $level / Term $term';

  static String normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == 'dsw_officer' ||
        normalized == 'dsw director' ||
        normalized == 'dsw-director') {
      return 'dsw_officer';
    }
    if (normalized == 'dsw_director' || normalized == 'director') {
      return 'dsw_director';
    }
    if (normalized == 'student' || normalized == 'user') {
      return 'student';
    }
    return 'unknown';
  }

  static String? validateStudentRegistrationRole(String role) {
    final normalized = normalizeRole(role);
    if (normalized == 'student' || normalized == 'unknown') {
      return normalized == 'unknown' ? 'student' : normalized;
    }
    return null;
  }

  StudentUser copyWith({
    String? uid,
    String? studentId,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? batch,
    String? hall,
    String? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? level,
    String? term,
  }) {
    return StudentUser(
      uid: uid ?? this.uid,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      batch: batch ?? this.batch,
      hall: hall ?? this.hall,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      level: level ?? this.level,
      term: term ?? this.term,
    );
  }

  factory StudentUser.empty(String uid) {
    final now = DateTime.now();
    return StudentUser(
      uid: uid,
      studentId: '',
      name: '',
      email: '',
      phone: '',
      department: '',
      batch: '',
      hall: '',
      role: 'student',
      createdAt: now,
      updatedAt: now,
      level: '',
      term: '',
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
      batch: (data['batch'] ?? '').toString(),
      hall: (data['hall'] ?? '').toString(),
      role: normalizeRole((data['role'] ?? 'student').toString()),
      profileImageUrl: (data['profileImageUrl'] ?? '').toString(),
      createdAt: _toDateTime(data['createdAt'], fallback: now),
      updatedAt: _toDateTime(data['updatedAt'], fallback: now),
      level: (data['level'] ?? '').toString(),
      term: (data['term'] ?? '').toString(),
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
      'batch': batch,
      'hall': hall,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'level': level,
      'term': term,
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
