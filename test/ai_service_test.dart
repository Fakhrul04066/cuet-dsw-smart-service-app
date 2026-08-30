import 'package:cuet_dsw_app/services/ai_assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI advisory service', () {
    test('character certificate form check flags missing fields', () {
      final result = GeminiAssistantService.instance.checkApplicationForm(
        applicationType: 'Character Certificate',
        formFields: {
          'studentName': 'Ayesha Rahman',
          'department': 'CSE',
        },
      );

      expect(result['complete'], isFalse);
      expect(result['missingFields'], isNotEmpty);
      expect(result['suggestions'], isA<List>());
      expect(result['unclearStatements'], isA<List>());
    });

    test('complaint triage returns a structured recommendation', () {
      final result = GeminiAssistantService.instance.triageComplaint(
        title: 'Water supply issue',
        description: 'The water has been off for three days in Hall A.',
        category: 'Hall Facilities',
      );

      expect(result['suggestedCategory'], isA<String>());
      expect(result['urgency'], isA<String>());
      expect(result['recommendedOffice'], isA<String>());
      expect(result['summary'], isA<String>());
    });

    test('AI recommendations remain advisory and never final', () {
      final formResult = GeminiAssistantService.instance.checkApplicationForm(
        applicationType: 'Hall Transfer',
        formFields: {'studentName': 'Rahim', 'reason': 'Family emergency'},
      );

      expect(formResult['complete'], isFalse);
      expect(GeminiAssistantService.advisoryNotice, contains('advisory'));
    });
  });
}
