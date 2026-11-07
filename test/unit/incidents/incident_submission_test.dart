import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporting_app/features/incidents/application/incident_submission_controller.dart';
import 'package:campus_incident_reporting_app/features/incidents/data/repositories/incident_repository.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_category.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';

void main() {
  group('IncidentSubmissionState', () {
    test('initial state has initial status and no loading', () {
      const state = IncidentSubmissionState();
      expect(state.status, IncidentSubmissionStatus.initial);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.submittedIncidentId, isNull);
    });

    test('isLoading is true during validating, uploading, and submitting', () {
      for (final loadingStatus in [
        IncidentSubmissionStatus.validating,
        IncidentSubmissionStatus.uploading,
        IncidentSubmissionStatus.submitting,
      ]) {
        final state =
            IncidentSubmissionState(status: loadingStatus);
        expect(state.isLoading, isTrue,
            reason: '$loadingStatus should be a loading state');
      }
    });

    test('isLoading is false for initial, success, and error', () {
      for (final nonLoadingStatus in [
        IncidentSubmissionStatus.initial,
        IncidentSubmissionStatus.success,
        IncidentSubmissionStatus.error,
      ]) {
        final state =
            IncidentSubmissionState(status: nonLoadingStatus);
        expect(state.isLoading, isFalse,
            reason: '$nonLoadingStatus should not be a loading state');
      }
    });

    test('isSuccess is only true for success status', () {
      expect(
        const IncidentSubmissionState(
                status: IncidentSubmissionStatus.success)
            .isSuccess,
        isTrue,
      );
      expect(
        const IncidentSubmissionState(
                status: IncidentSubmissionStatus.error)
            .isSuccess,
        isFalse,
      );
    });

    test('copyWith preserves unchanged fields', () {
      const original = IncidentSubmissionState(
        status: IncidentSubmissionStatus.uploading,
        submittedIncidentId: 'inc-abc',
      );

      final copy = original.copyWith(
        status: IncidentSubmissionStatus.submitting,
      );

      expect(copy.status, IncidentSubmissionStatus.submitting);
      expect(copy.submittedIncidentId, 'inc-abc');
      expect(copy.errorMessage, isNull);
    });

    test('copyWith clears errorMessage to null', () {
      const withError = IncidentSubmissionState(
        status: IncidentSubmissionStatus.error,
        errorMessage: 'Something went wrong',
      );

      final cleared =
          withError.copyWith(status: IncidentSubmissionStatus.initial);
      expect(cleared.errorMessage, isNull);
    });
  });

  group('IncidentRepository.buildNewIncident', () {
    test('builds incident with correct initial values', () {
      final incident = IncidentRepository.buildNewIncident(
        createdBy: 'uid-student-01',
        category: IncidentCategory.waterSupply,
        description: 'Water leak on second floor.',
        building: 'Innovation Hub',
        block: 'A',
        specificArea: 'Restroom, 2nd floor',
      );

      expect(incident.createdBy, 'uid-student-01');
      expect(incident.category, IncidentCategory.waterSupply);
      expect(incident.description, 'Water leak on second floor.');
      expect(incident.building, 'Innovation Hub');
      expect(incident.block, 'A');
      expect(incident.specificArea, 'Restroom, 2nd floor');
      expect(incident.status, IncidentStatus.submitted);
      expect(incident.photoUrl, isNull);
      expect(incident.photoPublicId, isNull);
      expect(incident.id, isEmpty);
    });

    test('trims whitespace from text fields', () {
      final incident = IncidentRepository.buildNewIncident(
        createdBy: 'uid-student-02',
        category: IncidentCategory.electricity,
        description: '  Flickering lights in lab.  ',
        building: '  Library  ',
        block: ' B ',
        specificArea: '  Computer Lab  ',
      );

      expect(incident.description, 'Flickering lights in lab.');
      expect(incident.building, 'Library');
      expect(incident.block, 'B');
      expect(incident.specificArea, 'Computer Lab');
    });

    test('attaches Cloudinary photo fields when provided', () {
      final incident = IncidentRepository.buildNewIncident(
        createdBy: 'uid-student-03',
        category: IncidentCategory.sanitation,
        description: 'Overflowing waste bin near cafeteria.',
        building: 'Student Centre',
        block: 'C',
        specificArea: 'Cafeteria entrance',
        photoUrl: 'https://res.cloudinary.com/dvod3pvz/image/upload/sample.jpg',
        photoPublicId: 'campuscare_1234567890_sample',
      );

      expect(incident.photoUrl,
          'https://res.cloudinary.com/dvod3pvz/image/upload/sample.jpg');
      expect(incident.photoPublicId, 'campuscare_1234567890_sample');
    });

    test('createdAt and updatedAt are equal on a new incident', () {
      final incident = IncidentRepository.buildNewIncident(
        createdBy: 'uid-student-04',
        category: IncidentCategory.facilities,
        description: 'Broken bench outside block B.',
        building: 'Commons',
        block: 'B',
        specificArea: 'Outdoor seating area',
      );

      // Allow a small margin since both are set from DateTime.now()
      final delta = incident.updatedAt.difference(incident.createdAt).abs();
      expect(delta.inSeconds, lessThan(2));
    });

    test('toFirestore map does not contain reporter contact information', () {
      final incident = IncidentRepository.buildNewIncident(
        createdBy: 'uid-student-05',
        category: IncidentCategory.internetTechnology,
        description: 'Wi-Fi is down in the library study area.',
        building: 'Library',
        block: 'A',
        specificArea: 'Third floor study zone',
      );

      final firestoreMap = incident.toFirestore();

      expect(firestoreMap.containsKey('reporterEmail'), isFalse);
      expect(firestoreMap.containsKey('reporterName'), isFalse);
      expect(firestoreMap.containsKey('email'), isFalse);
      // Verify required Firestore rule fields are present
      expect(firestoreMap['createdBy'], 'uid-student-05');
      expect(firestoreMap['status'], 'submitted');
    });

    test('all required Firestore rule fields are present in toFirestore output', () {
      final incident = IncidentRepository.buildNewIncident(
        createdBy: 'uid-test',
        category: IncidentCategory.safetySecurity,
        description: 'Suspicious individual near the gate.',
        building: 'Main Gate',
        block: '',
        specificArea: 'Entrance area',
      );

      final map = incident.toFirestore();

      for (final field in [
        'description', 'category', 'building', 'block',
        'specificArea', 'createdBy', 'status', 'createdAt', 'updatedAt',
      ]) {
        expect(map.containsKey(field), isTrue,
            reason: 'toFirestore() must include "$field"');
      }
    });
  });

  group('Incident model – form submission scenario', () {
    test('Incident with optional photo round-trips through toMap/fromMap', () {
      final now = DateTime(2026, 11, 7, 12, 0);
      final incident = Incident(
        id: 'inc-999',
        description: 'Cracked floor tile.',
        category: IncidentCategory.facilities,
        building: 'Academic Block',
        block: 'D',
        specificArea: 'Ground floor corridor',
        createdBy: 'uid-abc',
        status: IncidentStatus.submitted,
        createdAt: now,
        updatedAt: now,
        photoUrl: 'https://res.cloudinary.com/dvod3pvz/image/upload/v1/cc_img.jpg',
        photoPublicId: 'campuscare_cc_img',
      );

      final map = incident.toMap();
      final restored = Incident.fromMap(map, id: 'inc-999');

      expect(restored.photoUrl, incident.photoUrl);
      expect(restored.photoPublicId, incident.photoPublicId);
      expect(restored.status, IncidentStatus.submitted);
      expect(restored.createdBy, 'uid-abc');
    });

    test('Incident without photo omits photo fields from toFirestore', () {
      final now = DateTime(2026, 11, 7, 12, 0);
      final incident = Incident(
        id: 'inc-no-photo',
        description: 'Broken AC unit.',
        category: IncidentCategory.electricity,
        building: 'Lecture Hall',
        block: 'B',
        specificArea: 'Room 101',
        createdBy: 'uid-xyz',
        status: IncidentStatus.submitted,
        createdAt: now,
        updatedAt: now,
      );

      final map = incident.toFirestore();

      expect(map.containsKey('photoUrl'), isFalse);
      expect(map.containsKey('photoPublicId'), isFalse);
    });
  });
}

