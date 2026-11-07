import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_category.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';

void main() {
  group('Incident, IncidentCategory, and IncidentStatus', () {
    test('IncidentCategory resolves standard categories and fallback', () {
      expect(IncidentCategory.fromString('facilities'), IncidentCategory.facilities);
      expect(IncidentCategory.fromString('water_supply'), IncidentCategory.waterSupply);
      expect(IncidentCategory.fromString('electricity'), IncidentCategory.electricity);
      expect(IncidentCategory.fromString('sanitation'), IncidentCategory.sanitation);
      expect(IncidentCategory.fromString('internet_technology'), IncidentCategory.internetTechnology);
      expect(IncidentCategory.fromString('safety_security'), IncidentCategory.safetySecurity);
      expect(IncidentCategory.fromString('other'), IncidentCategory.other);
      expect(IncidentCategory.fromString('unknown_category'), IncidentCategory.other);
    });

    test('IncidentStatus resolves approved lifecycle values', () {
      expect(IncidentStatus.fromString('submitted'), IncidentStatus.submitted);
      expect(IncidentStatus.fromString('under_review'), IncidentStatus.underReview);
      expect(IncidentStatus.fromString('in_progress'), IncidentStatus.inProgress);
      expect(IncidentStatus.fromString('resolved'), IncidentStatus.resolved);
      expect(IncidentStatus.fromString('rejected'), IncidentStatus.rejected);
      expect(IncidentStatus.fromString('unrecognized'), IncidentStatus.submitted);
    });

    test('Incident parses from map correctly and formats location', () {
      final now = DateTime(2026, 11, 7, 11, 30);
      final map = {
        'id': 'inc-001',
        'description': 'Water leak in 2nd floor restroom',
        'category': 'water_supply',
        'building': 'Main Campus',
        'block': 'B',
        'specificArea': 'Room 204 restroom',
        'createdBy': 'user-123',
        'status': 'submitted',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'photoUrl': 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        'photoPublicId': 'sample',
      };

      final incident = Incident.fromMap(map, id: 'inc-001');

      expect(incident.id, 'inc-001');
      expect(incident.description, 'Water leak in 2nd floor restroom');
      expect(incident.category, IncidentCategory.waterSupply);
      expect(incident.building, 'Main Campus');
      expect(incident.block, 'B');
      expect(incident.specificArea, 'Room 204 restroom');
      expect(incident.formattedLocation, 'Main Campus, Block B, Room 204 restroom');
      expect(incident.createdBy, 'user-123');
      expect(incident.status, IncidentStatus.submitted);
      expect(incident.photoUrl, 'https://res.cloudinary.com/demo/image/upload/sample.jpg');
      expect(incident.photoPublicId, 'sample');
      expect(incident.createdAt, now);
      expect(incident.updatedAt, now);

      final serialized = incident.toMap();
      expect(serialized['category'], 'water_supply');
      expect(serialized['status'], 'submitted');
      expect(serialized['building'], 'Main Campus');

      final firestoreMap = incident.toFirestore();
      expect(firestoreMap['category'], 'water_supply');
      expect(firestoreMap['status'], 'submitted');
    });

    test('Incident copyWith creates modified instance', () {
      final now = DateTime(2026, 11, 7, 11, 30);
      final incident = Incident(
        id: 'inc-001',
        description: 'Test description',
        category: IncidentCategory.facilities,
        building: 'Building A',
        block: '1',
        specificArea: 'Lobby',
        createdBy: 'user-123',
        status: IncidentStatus.submitted,
        createdAt: now,
        updatedAt: now,
      );

      final updated = incident.copyWith(
        status: IncidentStatus.inProgress,
        updatedAt: now.add(const Duration(hours: 1)),
      );

      expect(updated.status, IncidentStatus.inProgress);
      expect(updated.description, 'Test description');
      expect(incident == updated, isFalse);
    });
  });
}

