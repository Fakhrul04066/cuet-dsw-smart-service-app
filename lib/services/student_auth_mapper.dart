class StudentAuthMapper {
  static const String demoDomain = '@demo.cuet-dsw.local';

  static bool isEmailLike(String value) {
    return value.trim().contains('@');
  }

  static bool isValidStudentId(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || isEmailLike(trimmed)) {
      return false;
    }

    return RegExp(r'^[0-9]{7}$').hasMatch(trimmed);
  }

  static String toFirebaseAuthEmail(String studentId) {
    final trimmed = studentId.trim();
    if (!isValidStudentId(trimmed)) {
      throw const FormatException(
        'Student ID must be a 7-digit number, for example 2104001.',
      );
    }

    return '$trimmed$demoDomain';
  }

  static String resolveLoginEmail(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Student ID or email is required.');
    }

    if (isEmailLike(trimmed)) {
      return trimmed;
    }

    if (isValidStudentId(trimmed)) {
      return toFirebaseAuthEmail(trimmed);
    }

    throw const FormatException(
      'Enter a valid Student ID (for example 2104001) or a valid email.',
    );
  }
}
