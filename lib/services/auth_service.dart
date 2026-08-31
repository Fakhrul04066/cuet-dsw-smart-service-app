import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'firebase_auth_service.dart';
import 'student_auth_mapper.dart';
import 'user_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService.instance;
  final UserService _userService = UserService.instance;

  Stream<User?> get authStateChanges => _firebaseAuthService.authStateChanges;

  User? get currentUser => _firebaseAuthService.currentUser;

  static String normalizeLoginRole(String? role) {
    final normalized = (role ?? '').trim().toLowerCase();
    if (normalized == 'student') {
      return 'student';
    }
    if (normalized == 'dsw_officer' ||
        normalized == 'officer' ||
        normalized == 'dsw officer' ||
        normalized == 'dsw-officer') {
      return 'dsw_officer';
    }
    if (normalized == 'dsw_director' ||
        normalized == 'director' ||
        normalized == 'dsw director' ||
        normalized == 'dsw-director') {
      return 'dsw_director';
    }
    return 'unknown';
  }

  static bool validateSelectedRole(String selectedRole, String actualRole) {
    final normalizedSelected = normalizeLoginRole(selectedRole);
    final normalizedActual = StudentUser.normalizeRole(actualRole);

    return normalizedSelected != 'unknown' &&
        normalizedSelected == normalizedActual;
  }

  static String roleDisplayName(String role) {
    switch (normalizeLoginRole(role)) {
      case 'student':
        return 'Student';
      case 'dsw_officer':
        return 'DSW Officer';
      case 'dsw_director':
        return 'DSW Director';
      default:
        return 'User';
    }
  }

  Future<StudentUser> signInWithSelectedRole({
    required String selectedRole,
    required String loginIdentifier,
    required String password,
  }) async {
    final normalizedRole = normalizeLoginRole(selectedRole);
    if (normalizedRole == 'unknown') {
      throw StateError('Please select a valid login role.');
    }

    final normalizedIdentifier = loginIdentifier.trim();
    if (normalizedIdentifier.isEmpty) {
      throw const FormatException('Login identifier is required.');
    }
    if (password.isEmpty) {
      throw const FormatException('Password is required.');
    }

    try {
      final resolvedEmail = normalizedRole == 'student'
          ? _resolveLoginEmail(normalizedIdentifier)
          : normalizedIdentifier;

      final credential = await _firebaseAuthService.loginWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw StateError('Authentication succeeded but no user was returned.');
      }

      final profile = await _userService.getUserById(firebaseUser.uid);
      if (profile == null) {
        await _userService.createUserProfileIfMissing(firebaseUser);
      }

      final finalProfile = await _userService.getUserById(firebaseUser.uid);
      if (finalProfile == null) {
        throw StateError('User profile document is missing.');
      }

      final actualRole = StudentUser.normalizeRole(finalProfile.role);
      if (actualRole != 'student' &&
          actualRole != 'dsw_officer' &&
          actualRole != 'dsw_director') {
        await _firebaseAuthService.logout();
        throw StateError('Unknown or invalid user role.');
      }

      if (!validateSelectedRole(normalizedRole, actualRole)) {
        await _firebaseAuthService.logout();
        throw StateError(
          'This account is not a ${roleDisplayName(normalizedRole)} account.',
        );
      }

      return finalProfile.copyWith(role: actualRole);
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthException(
        code: error.code,
        message: error.message ?? 'Authentication failed.',
      );
    }
  }

  Future<StudentUser> signInWithStudentIdOrEmail({
    required String studentIdentifier,
    required String password,
  }) async {
    return signInWithSelectedRole(
      selectedRole: 'student',
      loginIdentifier: studentIdentifier,
      password: password,
    );
  }

  Future<StudentUser?> getCurrentUserProfile() async {
    final user = _firebaseAuthService.currentUser;
    if (user == null) {
      return null;
    }

    var profile = await _userService.getUserById(user.uid);
    if (profile == null) {
      await _userService.createUserProfileIfMissing(user);
      profile = await _userService.getUserById(user.uid);
    }

    if (profile == null) {
      return null;
    }

    final normalizedRole = StudentUser.normalizeRole(profile.role);
    return profile.copyWith(role: normalizedRole);
  }

  Future<String> getCurrentRole() async {
    final profile = await getCurrentUserProfile();
    if (profile == null) {
      return 'unknown';
    }
    return StudentUser.normalizeRole(profile.role);
  }

  Future<void> signOut() async {
    await _firebaseAuthService.logout();
  }

  String _resolveLoginEmail(String identifier) {
    return StudentAuthMapper.resolveLoginEmail(identifier);
  }
}
