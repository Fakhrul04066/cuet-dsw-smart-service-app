import 'package:cuet_dsw_app/services/auth_service.dart';
import 'package:cuet_dsw_app/services/student_auth_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentAuthMapper', () {
    test('maps a 7-digit student id to a deterministic demo auth email', () {
      expect(
        StudentAuthMapper.toFirebaseAuthEmail('2104001'),
        '2104001@demo.cuet-dsw.local',
      );
      expect(
        StudentAuthMapper.toFirebaseAuthEmail('1902010'),
        '1902010@demo.cuet-dsw.local',
      );
    });

    test('accepts valid student ids and rejects invalid formats', () {
      expect(StudentAuthMapper.isValidStudentId('2104001'), isTrue);
      expect(StudentAuthMapper.isValidStudentId('1902010'), isTrue);
      expect(StudentAuthMapper.isValidStudentId('ABC1234'), isFalse);
      expect(StudentAuthMapper.isValidStudentId('21040'), isFalse);
      expect(StudentAuthMapper.isValidStudentId('2104001@demo.com'), isFalse);
    });

    test('resolves a login identifier without querying Firestore', () {
      expect(
        StudentAuthMapper.resolveLoginEmail('2104001'),
        '2104001@demo.cuet-dsw.local',
      );
      expect(
        StudentAuthMapper.resolveLoginEmail('officer1@demo.com'),
        'officer1@demo.com',
      );
    });

    test('role checks must use the authoritative Firestore role only', () {
      expect(AuthService.validateSelectedRole('student', 'student'), isTrue);
      expect(
        AuthService.validateSelectedRole('student', 'dsw_officer'),
        isFalse,
      );
      expect(
        AuthService.validateSelectedRole('dsw_director', 'dsw_officer'),
        isFalse,
      );
      expect(
        AuthService.validateSelectedRole('dsw_officer', 'dsw_officer'),
        isTrue,
      );
    });
  });
}
