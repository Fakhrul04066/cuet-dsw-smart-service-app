import 'package:cuet_dsw_app/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('student user model', () {
    test('creates a student profile from Firestore data', () {
      final user = StudentUser.fromMap({
        'uid': 'abc123',
        'studentId': '1902010',
        'name': 'Ayesha Rahman',
        'email': 'ayesha@student.cuet.ac.bd',
        'phone': '+8801712345678',
        'department': 'CSE',
        'level': '4',
        'term': 'I',
        'role': 'student',
        'createdAt': 1710000000000,
        'updatedAt': 1710000000000,
      });

      expect(user.uid, 'abc123');
      expect(user.studentId, '1902010');
      expect(user.role, 'student');
      expect(user.levelTerm, 'Level 4 / Term I');
    });
  });
}
