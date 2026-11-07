import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_private_reporter.dart';

void main() {
  group('IncidentPrivateReporter', () {
    test('IncidentPrivateReporter serializes and deserializes correctly', () {
      final map = {
        'createdBy': 'user-123',
        'reporterEmail': 'student@alustudent.com',
        'reporterName': 'Campus Reporter',
      };

      final reporter = IncidentPrivateReporter.fromMap(map);

      expect(reporter.createdBy, 'user-123');
      expect(reporter.reporterEmail, 'student@alustudent.com');
      expect(reporter.reporterName, 'Campus Reporter');

      final serialized = reporter.toMap();
      expect(serialized['createdBy'], 'user-123');
      expect(serialized['reporterEmail'], 'student@alustudent.com');
      expect(serialized['reporterName'], 'Campus Reporter');
    });
  });
}

