import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status_history.dart';

void main() {
  group('IncidentStatusHistory', () {
    test('IncidentStatusHistory parses from map and serializes accurately', () {
      final now = DateTime(2026, 11, 7, 14, 0);
      final map = {
        'id': 'hist-001',
        'previousStatus': 'submitted',
        'newStatus': 'under_review',
        'updatedBy': 'staff-456',
        'timestamp': now.toIso8601String(),
        'remarks': 'Assigned to campus facilities maintenance team',
      };

      final history = IncidentStatusHistory.fromMap(map, id: 'hist-001');

      expect(history.id, 'hist-001');
      expect(history.previousStatus, IncidentStatus.submitted);
      expect(history.newStatus, IncidentStatus.underReview);
      expect(history.updatedBy, 'staff-456');
      expect(history.timestamp, now);
      expect(history.remarks, 'Assigned to campus facilities maintenance team');

      final serialized = history.toMap();
      expect(serialized['previousStatus'], 'submitted');
      expect(serialized['newStatus'], 'under_review');
      expect(serialized['updatedBy'], 'staff-456');
      expect(serialized['remarks'], 'Assigned to campus facilities maintenance team');
    });

    test('IncidentStatusHistory handles initial submission without previousStatus', () {
      final now = DateTime(2026, 11, 7, 14, 0);
      final map = {
        'id': 'hist-000',
        'newStatus': 'submitted',
        'updatedBy': 'student-123',
        'timestamp': now.toIso8601String(),
      };

      final history = IncidentStatusHistory.fromMap(map, id: 'hist-000');

      expect(history.previousStatus, isNull);
      expect(history.newStatus, IncidentStatus.submitted);
      expect(history.remarks, isNull);
    });
  });
}

