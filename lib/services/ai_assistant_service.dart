class GeminiAssistantService {
  GeminiAssistantService._();

  static const String advisoryNotice =
      'AI suggestions are advisory. Please verify all information before submission.';

  static final GeminiAssistantService instance = GeminiAssistantService._();

  Map<String, dynamic> checkApplicationForm({
    required String applicationType,
    required Map<String, dynamic> formFields,
  }) {
    try {
      final normalized = <String, dynamic>{
        for (final entry in formFields.entries)
          entry.key: entry.value?.toString().trim() ?? '',
      };

      final missingFields = <String>[];
      final unclearStatements = <String>[];
      final possibleInconsistencies = <String>[];
      final suggestions = <String>[];

      final requiredFields = _requiredFieldsFor(applicationType);
      for (final field in requiredFields) {
        final value = normalized[field] ?? '';
        if (value.isEmpty) {
          missingFields.add(field);
        }
      }

      final descriptionFields = [
        'purpose',
        'reason',
        'statement',
        'details',
        'justification',
      ];
      for (final field in descriptionFields) {
        final value = normalized[field] ?? '';
        if (value.isNotEmpty && value.length < 12) {
          unclearStatements.add(
            'The "$field" field is very brief. Add more details for review.',
          );
        }
      }

      final studentName = normalized['studentName'] ?? '';
      final studentId = normalized['studentId'] ?? '';
      final department = normalized['department'] ?? '';
      final currentHall = normalized['currentHall'] ?? '';
      final preferredHall = normalized['preferredHall'] ?? '';
      if (currentHall.isNotEmpty &&
          preferredHall.isNotEmpty &&
          currentHall.toLowerCase() == preferredHall.toLowerCase()) {
        possibleInconsistencies.add(
          'Current hall and preferred hall appear to be the same.',
        );
      }
      if (studentName.isNotEmpty &&
          studentId.isNotEmpty &&
          studentId.length < 5 &&
          studentName.contains(studentId) == false) {
        suggestions.add(
          'Check whether the student ID was entered in the correct format.',
        );
      }
      if (department.isNotEmpty && department.length < 3) {
        suggestions.add('Confirm the department name before submitting.');
      }
      if (missingFields.isNotEmpty) {
        suggestions.add(
          'Complete the missing fields before final submission to reduce delays.',
        );
      }
      if (unclearStatements.isEmpty && missingFields.isEmpty) {
        suggestions.add('The form appears to be mostly complete.');
      }
      if (suggestions.isEmpty) {
        suggestions.add(
          'No major issues detected from the current information.',
        );
      }

      return {
        'complete': missingFields.isEmpty && unclearStatements.isEmpty,
        'missingFields': missingFields,
        'unclearStatements': unclearStatements,
        'possibleInconsistencies': possibleInconsistencies,
        'suggestions': suggestions,
        'advisoryNotice': advisoryNotice,
      };
    } catch (_) {
      return {
        'complete': true,
        'missingFields': const <String>[],
        'unclearStatements': const <String>[
          'AI assistance is currently unavailable.',
        ],
        'possibleInconsistencies': const <String>[],
        'suggestions': const <String>[
          'AI assistance is currently unavailable. You may continue manually.',
        ],
        'advisoryNotice': advisoryNotice,
      };
    }
  }

  Map<String, dynamic> triageComplaint({
    required String title,
    required String description,
    String? category,
  }) {
    try {
      final normalizedTitle = title.trim();
      final normalizedDescription = description.trim();
      final normalizedCategory = (category ?? '').trim();
      final combined = '$normalizedTitle $normalizedDescription'.toLowerCase();

      String suggestedCategory = normalizedCategory.isNotEmpty
          ? normalizedCategory
          : _guessCategory(combined);
      String urgency = _guessUrgency(combined);
      String recommendedOffice = _recommendOffice(suggestedCategory);
      final summary = _buildSummary(suggestedCategory, normalizedTitle);
      final similarIssueHint =
          'This is an advisory triage only. No exact duplicate search is performed in this prototype.';

      return {
        'suggestedCategory': suggestedCategory,
        'summary': summary,
        'urgency': urgency,
        'recommendedOffice': recommendedOffice,
        'similarIssueHint': similarIssueHint,
        'advisoryNotice': advisoryNotice,
      };
    } catch (_) {
      return {
        'suggestedCategory': category ?? 'Administrative',
        'summary':
            'AI complaint triage is currently unavailable. Please review the issue manually.',
        'urgency': 'Medium',
        'recommendedOffice': 'DSW Office',
        'similarIssueHint':
            'AI complaint triage is currently unavailable. No exact duplicate check is available.',
        'advisoryNotice': advisoryNotice,
      };
    }
  }

  List<String> _requiredFieldsFor(String applicationType) {
    switch (applicationType.toLowerCase()) {
      case 'character certificate':
        return [
          'studentName',
          'studentId',
          'department',
          'level',
          'term',
          'email',
          'phone',
          'purpose',
        ];
      case 'hall transfer':
        return [
          'studentName',
          'studentId',
          'currentHall',
          'preferredHall',
          'reason',
        ];
      default:
        return ['studentName', 'studentId'];
    }
  }

  String _guessCategory(String combined) {
    if (combined.contains('water') ||
        combined.contains('electric') ||
        combined.contains('hall') ||
        combined.contains('room')) {
      return 'Hall Facilities';
    }
    if (combined.contains('class') ||
        combined.contains('exam') ||
        combined.contains('course') ||
        combined.contains('academic')) {
      return 'Academic';
    }
    if (combined.contains('harass') ||
        combined.contains('safety') ||
        combined.contains('security') ||
        combined.contains('threat')) {
      return 'Harassment / Safety';
    }
    if (combined.contains('medical') ||
        combined.contains('welfare') ||
        combined.contains('health')) {
      return 'Student Welfare';
    }
    return 'Administrative';
  }

  String _guessUrgency(String combined) {
    if (combined.contains('urgent') ||
        combined.contains('emergency') ||
        combined.contains('danger') ||
        combined.contains('unsafe') ||
        combined.contains('medical') ||
        combined.contains('fire') ||
        combined.contains('threat')) {
      return 'High';
    }
    if (combined.contains('delay') ||
        combined.contains('broken') ||
        combined.contains('repeated') ||
        combined.contains('three days') ||
        combined.contains('without')) {
      return 'Medium';
    }
    return 'Low';
  }

  String _recommendOffice(String category) {
    switch (category) {
      case 'Hall Facilities':
        return 'Hall Management Office';
      case 'Academic':
        return 'Academic Affairs Office';
      case 'Student Welfare':
        return 'Student Welfare Office';
      case 'Harassment / Safety':
        return 'Student Safety & Discipline Office';
      default:
        return 'DSW Administration Office';
    }
  }

  String _buildSummary(String category, String title) {
    final trimmedTitle = title.trim();
    final base = trimmedTitle.isEmpty ? 'Complaint' : trimmedTitle;
    return '$base appears to fit the $category category and should be reviewed by the relevant office.';
  }
}
