import 'package:cuet_dsw_app/services/complaint_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComplaintService validation', () {
    test('rejects incomplete and whitespace-only submissions', () {
      expect(
        () => ComplaintService.validateSubmission(
          category: ' ',
          title: 'Water issue',
          description: 'A sufficiently detailed complaint description.',
          assignedOffice: 'Hall Office',
          urgency: 'Medium',
        ),
        throwsStateError,
      );
      expect(
        () => ComplaintService.validateSubmission(
          category: 'Hall Facilities',
          title: ' ',
          description: 'A sufficiently detailed complaint description.',
          assignedOffice: 'Hall Office',
          urgency: 'Medium',
        ),
        throwsStateError,
      );
      expect(
        () => ComplaintService.validateSubmission(
          category: 'Hall Facilities',
          title: 'Water issue',
          description: 'Too short',
          assignedOffice: 'Hall Office',
          urgency: 'Medium',
        ),
        throwsStateError,
      );
    });

    test('accepts complete complaint submissions', () {
      expect(
        () => ComplaintService.validateSubmission(
          category: 'Hall Facilities',
          title: 'Water supply issue',
          description: 'Water has been unavailable in Hall A for three days.',
          assignedOffice: 'Hall Management Office',
          urgency: 'High',
        ),
        returnsNormally,
      );
    });
  });
}
