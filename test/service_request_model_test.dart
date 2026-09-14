import 'package:cuet_dsw_app/models/service_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceRequest', () {
    test('supports the six business service categories and lifecycle', () {
      expect(ServiceRequest.requestTypes.length, 6);
      expect(ServiceRequest.statuses, [
        'SUBMITTED',
        'CORRECTION_REQUIRED',
        'RESUBMITTED',
        'OFFICER_REVIEW_COMPLETE',
        'APPROVED',
        'REJECTED',
        'RESOLVED',
      ]);
    });

    test('keeps AI predicted priority separate from operational priority', () {
      final request = ServiceRequest.fromMap({
        'id': 'req-1',
        'trackingNumber': 'DSW-2026-0000001',
        'studentUid': 'uid-1',
        'studentId': '2204001',
        'studentName': 'Test Student',
        'requestType': 'financial_assistance',
        'title': 'Financial support request',
        'description': 'Supporting information for this request.',
        'status': 'SUBMITTED',
        'priority': 'NORMAL',
        'aiSuggestedPriority': 'HIGH',
        'createdAt': 1700000000000,
        'updatedAt': 1700000000000,
      });

      expect(request.priority, 'NORMAL');
      expect(request.aiSuggestedPriority, 'HIGH');
      expect(request.requestTypeLabel, 'Financial assistance request');
    });
  });
}
