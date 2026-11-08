import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_controller.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';
import 'package:campus_incident_reporting_app/features/dashboard/domain/models/staff_dashboard_statistics.dart';
import 'package:campus_incident_reporting_app/features/incidents/application/incident_status_update_controller.dart';
import 'package:campus_incident_reporting_app/features/incidents/data/repositories/incident_repository.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_category.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_private_reporter.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status_history.dart';

class _FakeIncidentRepository implements IncidentRepository {
  bool updateCalled = false;
  String? lastIncidentId;
  IncidentStatus? lastPreviousStatus;
  IncidentStatus? lastNewStatus;
  String? lastStaffUid;
  String? lastStaffDisplayName;
  String? lastRemarks;
  bool shouldThrow = false;

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus previousStatus,
    required IncidentStatus newStatus,
    required String staffUid,
    String? staffDisplayName,
    String? remarks,
  }) async {
    if (shouldThrow) {
      throw Exception('Firestore write failed');
    }
    updateCalled = true;
    lastIncidentId = incidentId;
    lastPreviousStatus = previousStatus;
    lastNewStatus = newStatus;
    lastStaffUid = staffUid;
    lastStaffDisplayName = staffDisplayName;
    lastRemarks = remarks;
  }

  @override
  Future<String> submitIncident({
    required Incident incident,
    required IncidentPrivateReporter privateReporter,
  }) async =>
      'fake-id';

  @override
  Future<IncidentPage> fetchRecentIncidents({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async =>
      const IncidentPage(incidents: [], hasMore: false);

  @override
  Future<List<Incident>> fetchIncidentsByUser(String uid) async => [];

  @override
  Future<Incident?> fetchIncidentById(String incidentId) async => null;

  @override
  Future<List<IncidentStatusHistory>> fetchStatusHistory(
          String incidentId) async =>
      [];

  @override
  Future<StaffDashboardStatistics> fetchIncidentStatistics() async =>
      StaffDashboardStatistics.empty;

  @override
  Future<IncidentPrivateReporter?> fetchPrivateReporter(
          String incidentId) async =>
      null;
}

class _MockStaffAuthController extends AuthController {
  _MockStaffAuthController({this.role = UserRole.staff});

  final UserRole role;

  @override
  AuthState build() {
    final now = DateTime.now();
    return AuthState(
      status: role == UserRole.staff
          ? AuthStatus.authenticatedStaff
          : AuthStatus.authenticatedStudent,
      profile: UserProfile(
        uid: 'staff-user-99',
        displayName: 'Campus Staff User',
        email: 'staff@alueducation.com',
        role: role,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _MockUnauthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  final now = DateTime(2026, 11, 7, 10, 0);
  final sampleIncident = Incident(
    id: 'inc-status-01',
    description: 'Broken handrail in stairs',
    category: IncidentCategory.facilities,
    building: 'Hall B',
    block: '2',
    specificArea: 'Staircase East',
    createdBy: 'student-author-id',
    status: IncidentStatus.submitted,
    createdAt: now,
    updatedAt: now,
  );

  group('IncidentStatusUpdateController', () {
    test('successful status update commits atomically with correct staff metadata',
        () async {
      final fakeRepo = _FakeIncidentRepository();
      final container = ProviderContainer(
        overrides: [
          incidentRepositoryProvider.overrideWithValue(fakeRepo),
          authControllerProvider.overrideWith(() => _MockStaffAuthController()),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(incidentStatusUpdateControllerProvider.notifier);

      final success = await controller.updateStatus(
        incident: sampleIncident,
        newStatus: IncidentStatus.underReview,
        remarks: 'Assigned to operations team',
      );

      expect(success, isTrue);
      expect(fakeRepo.updateCalled, isTrue);
      expect(fakeRepo.lastIncidentId, 'inc-status-01');
      expect(fakeRepo.lastPreviousStatus, IncidentStatus.submitted);
      expect(fakeRepo.lastNewStatus, IncidentStatus.underReview);
      expect(fakeRepo.lastStaffUid, 'staff-user-99');
      expect(fakeRepo.lastStaffDisplayName, 'Campus Staff User');
      expect(fakeRepo.lastRemarks, 'Assigned to operations team');

      final state = container.read(incidentStatusUpdateControllerProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isSubmitting, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('rejection requires non-empty explanation', () async {
      final fakeRepo = _FakeIncidentRepository();
      final container = ProviderContainer(
        overrides: [
          incidentRepositoryProvider.overrideWithValue(fakeRepo),
          authControllerProvider.overrideWith(() => _MockStaffAuthController()),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(incidentStatusUpdateControllerProvider.notifier);

      // Attempt rejection without remarks
      final resultWithoutRemarks = await controller.updateStatus(
        incident: sampleIncident,
        newStatus: IncidentStatus.rejected,
        remarks: '   ',
      );

      expect(resultWithoutRemarks, isFalse);
      expect(fakeRepo.updateCalled, isFalse);
      var state = container.read(incidentStatusUpdateControllerProvider);
      expect(state.status, IncidentStatusUpdateStatus.error);
      expect(
        state.errorMessage,
        'An explanation is required when rejecting an incident report.',
      );

      // Attempt rejection with valid explanation
      final resultWithRemarks = await controller.updateStatus(
        incident: sampleIncident,
        newStatus: IncidentStatus.rejected,
        remarks: 'Duplicate report already logged under #45.',
      );

      expect(resultWithRemarks, isTrue);
      expect(fakeRepo.updateCalled, isTrue);
      expect(fakeRepo.lastNewStatus, IncidentStatus.rejected);
      expect(
        fakeRepo.lastRemarks,
        'Duplicate report already logged under #45.',
      );
    });

    test('rejection of transition to same status is prevented', () async {
      final fakeRepo = _FakeIncidentRepository();
      final container = ProviderContainer(
        overrides: [
          incidentRepositoryProvider.overrideWithValue(fakeRepo),
          authControllerProvider.overrideWith(() => _MockStaffAuthController()),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(incidentStatusUpdateControllerProvider.notifier);

      final result = await controller.updateStatus(
        incident: sampleIncident,
        newStatus: IncidentStatus.submitted, // Identical to current status
      );

      expect(result, isFalse);
      expect(fakeRepo.updateCalled, isFalse);
      final state = container.read(incidentStatusUpdateControllerProvider);
      expect(state.status, IncidentStatusUpdateStatus.error);
      expect(
        state.errorMessage,
        'The incident is already marked as Submitted.',
      );
    });

    test('student role is denied from updating incident status', () async {
      final fakeRepo = _FakeIncidentRepository();
      final container = ProviderContainer(
        overrides: [
          incidentRepositoryProvider.overrideWithValue(fakeRepo),
          authControllerProvider.overrideWith(
            () => _MockStaffAuthController(role: UserRole.student),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(incidentStatusUpdateControllerProvider.notifier);

      final result = await controller.updateStatus(
        incident: sampleIncident,
        newStatus: IncidentStatus.inProgress,
      );

      expect(result, isFalse);
      expect(fakeRepo.updateCalled, isFalse);
      final state = container.read(incidentStatusUpdateControllerProvider);
      expect(state.status, IncidentStatusUpdateStatus.error);
      expect(
        state.errorMessage,
        'Only verified campus staff are authorized to update incident status.',
      );
    });

    test('unauthenticated user is denied from updating incident status',
        () async {
      final fakeRepo = _FakeIncidentRepository();
      final container = ProviderContainer(
        overrides: [
          incidentRepositoryProvider.overrideWithValue(fakeRepo),
          authControllerProvider.overrideWith(
            () => _MockUnauthenticatedAuthController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(incidentStatusUpdateControllerProvider.notifier);

      final result = await controller.updateStatus(
        incident: sampleIncident,
        newStatus: IncidentStatus.inProgress,
      );

      expect(result, isFalse);
      expect(fakeRepo.updateCalled, isFalse);
      final state = container.read(incidentStatusUpdateControllerProvider);
      expect(state.status, IncidentStatusUpdateStatus.error);
    });

    test('repository failure sets error state and returns false', () async {
      final fakeRepo = _FakeIncidentRepository()..shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          incidentRepositoryProvider.overrideWithValue(fakeRepo),
          authControllerProvider.overrideWith(() => _MockStaffAuthController()),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(incidentStatusUpdateControllerProvider.notifier);

      final result = await controller.updateStatus(
        incident: sampleIncident,
        newStatus: IncidentStatus.inProgress,
      );

      expect(result, isFalse);
      final state = container.read(incidentStatusUpdateControllerProvider);
      expect(state.status, IncidentStatusUpdateStatus.error);
      expect(state.errorMessage, contains('Firestore write failed'));
      expect(state.isSuccess, isFalse);
    });
  });
}

