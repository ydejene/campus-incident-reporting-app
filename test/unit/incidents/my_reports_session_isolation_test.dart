import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_controller.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';
import 'package:campus_incident_reporting_app/features/dashboard/domain/models/staff_dashboard_statistics.dart';
import 'package:campus_incident_reporting_app/features/incidents/application/my_reports_controller.dart';
import 'package:campus_incident_reporting_app/features/incidents/data/repositories/incident_repository.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_category.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_private_reporter.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status_history.dart';
import 'package:campus_incident_reporting_app/features/incidents/presentation/screens/student_my_reports_screen.dart';

class _FakeIncidentRepository implements IncidentRepository {
  final Map<String, List<Incident>> userIncidents = {};
  Completer<List<Incident>>? delayedCompleter;
  String? delayedUid;

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  Future<List<Incident>> fetchIncidentsByUser(String uid) async {
    if (delayedUid == uid && delayedCompleter != null) {
      return delayedCompleter!.future;
    }
    return List.from(userIncidents[uid] ?? []);
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

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus previousStatus,
    required IncidentStatus newStatus,
    required String staffUid,
    String? staffDisplayName,
    String? remarks,
  }) async {}
}

class _TestAuthController extends AuthController {
  _TestAuthController([AuthState? initial]) : _initial = initial ?? AuthState.unauthenticated();

  final AuthState _initial;

  @override
  AuthState build() => _initial;

  void signInStudent({
    required String uid,
    required String displayName,
    required String email,
  }) {
    final now = DateTime.now();
    state = AuthState(
      status: AuthStatus.authenticatedStudent,
      profile: UserProfile(
        uid: uid,
        displayName: displayName,
        email: email,
        role: UserRole.student,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> signOut() async {
    state = AuthState.unauthenticated();
  }
}

Incident _createIncident({
  required String id,
  required String createdBy,
  required String description,
  IncidentStatus status = IncidentStatus.submitted,
}) {
  final now = DateTime.now();
  return Incident(
    id: id,
    description: description,
    category: IncidentCategory.facilities,
    building: 'Hall A',
    block: '1',
    specificArea: 'Room 101',
    createdBy: createdBy,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _FakeIncidentRepository fakeRepo;
  late ProviderContainer container;

  _TestAuthController getAuth() =>
      container.read(authControllerProvider.notifier) as _TestAuthController;

  final studentAIncident1 = _createIncident(
    id: 'inc-a1',
    createdBy: 'student-a',
    description: 'Broken window in Hall A',
    status: IncidentStatus.submitted,
  );
  final studentAIncident2 = _createIncident(
    id: 'inc-a2',
    createdBy: 'student-a',
    description: 'Water leak in restroom',
    status: IncidentStatus.inProgress,
  );

  final studentBIncident1 = _createIncident(
    id: 'inc-b1',
    createdBy: 'student-b',
    description: 'Power outage in Library',
    status: IncidentStatus.resolved,
  );

  setUp(() {
    fakeRepo = _FakeIncidentRepository();
    fakeRepo.userIncidents['student-a'] = [studentAIncident1, studentAIncident2];
    fakeRepo.userIncidents['student-b'] = [studentBIncident1];

    container = ProviderContainer(
      overrides: [
        incidentRepositoryProvider.overrideWithValue(fakeRepo),
        authControllerProvider.overrideWith(_TestAuthController.new),
      ],
    );

    // Keep active listener so Notifier rebuilds eagerly on auth changes
    container.listen(myReportsControllerProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
  });

  group('MyReportsSessionIsolation — Controller State Lifecycle', () {
    test('unauthenticated state has empty reports and initial status', () {
      final state = container.read(myReportsControllerProvider);
      expect(state.status, MyReportsStatus.initial);
      expect(state.reports, isEmpty);
      expect(state.searchQuery, isEmpty);
      expect(state.selectedStatus, isNull);
    });

    test('Student A logs in and receives only Student A reports', () async {
      getAuth().signInStudent(
        uid: 'student-a',
        displayName: 'Student Alpha',
        email: 'alpha@alustudent.com',
      );

      // Allow microtask to execute
      await pumpEventQueue();

      final state = container.read(myReportsControllerProvider);
      expect(state.status, MyReportsStatus.success);
      expect(state.reports.length, 2);
      expect(state.reports.map((r) => r.id), containsAll(['inc-a1', 'inc-a2']));
      expect(state.reports.every((r) => r.createdBy == 'student-a'), isTrue);
      expect(state.selectedStatus, isNull);
      expect(state.searchQuery, isEmpty);
    });

    test('Student A signs out and state is immediately cleared', () async {
      getAuth().signInStudent(
        uid: 'student-a',
        displayName: 'Student Alpha',
        email: 'alpha@alustudent.com',
      );
      await pumpEventQueue();

      // Student A applies search and filter
      container.read(myReportsControllerProvider.notifier).setSearchQuery('broken');
      container
          .read(myReportsControllerProvider.notifier)
          .setStatusFilter(IncidentStatus.submitted);

      expect(container.read(myReportsControllerProvider).searchQuery, 'broken');
      expect(container.read(myReportsControllerProvider).selectedStatus,
          IncidentStatus.submitted);

      // Sign out
      await getAuth().signOut();

      final state = container.read(myReportsControllerProvider);
      expect(state.status, MyReportsStatus.initial);
      expect(state.reports, isEmpty);
      expect(state.searchQuery, isEmpty);
      expect(state.selectedStatus, isNull);
    });

    test('Student B logs in after Student A and sees only Student B reports',
        () async {
      getAuth().signInStudent(
        uid: 'student-a',
        displayName: 'Student Alpha',
        email: 'alpha@alustudent.com',
      );
      await pumpEventQueue();
      container.read(myReportsControllerProvider.notifier).setSearchQuery('leak');
      container
          .read(myReportsControllerProvider.notifier)
          .setStatusFilter(IncidentStatus.inProgress);

      // Sign out Student A
      await getAuth().signOut();

      // Sign in Student B
      getAuth().signInStudent(
        uid: 'student-b',
        displayName: 'Student Beta',
        email: 'beta@alustudent.com',
      );
      await pumpEventQueue();

      final stateB = container.read(myReportsControllerProvider);
      expect(stateB.status, MyReportsStatus.success);
      expect(stateB.reports.length, 1);
      expect(stateB.reports.first.id, 'inc-b1');
      expect(stateB.reports.first.createdBy, 'student-b');
      // Filters and search must be completely reset
      expect(stateB.selectedStatus, isNull);
      expect(stateB.searchQuery, isEmpty);
    });

    test('Same Student A signing back in receives a fresh clean session',
        () async {
      // 1. First session for Student A
      getAuth().signInStudent(
        uid: 'student-a',
        displayName: 'Student Alpha',
        email: 'alpha@alustudent.com',
      );
      await pumpEventQueue();

      container.read(myReportsControllerProvider.notifier).setSearchQuery('window');
      container
          .read(myReportsControllerProvider.notifier)
          .setStatusFilter(IncidentStatus.submitted);

      // 2. Sign out
      await getAuth().signOut();

      // 3. Same student signs back in
      getAuth().signInStudent(
        uid: 'student-a',
        displayName: 'Student Alpha',
        email: 'alpha@alustudent.com',
      );
      await pumpEventQueue();

      final freshState = container.read(myReportsControllerProvider);
      expect(freshState.status, MyReportsStatus.success);
      expect(freshState.reports.length, 2);
      expect(freshState.selectedStatus, isNull);
      expect(freshState.searchQuery, isEmpty);
    });

    test('pull-to-refresh within active session preserves active search and filters',
        () async {
      getAuth().signInStudent(
        uid: 'student-a',
        displayName: 'Student Alpha',
        email: 'alpha@alustudent.com',
      );
      await pumpEventQueue();

      final notifier = container.read(myReportsControllerProvider.notifier);
      notifier.setSearchQuery('leak');
      notifier.setStatusFilter(IncidentStatus.inProgress);

      // Perform refresh
      await notifier.refresh();

      final state = container.read(myReportsControllerProvider);
      expect(state.status, MyReportsStatus.success);
      expect(state.reports.length, 2);
      expect(state.searchQuery, 'leak');
      expect(state.selectedStatus, IncidentStatus.inProgress);
      expect(state.filteredReports.length, 1);
      expect(state.filteredReports.first.id, 'inc-a2');
    });

    test(
        'delayed response from Student A cannot overwrite Student B reports (race condition)',
        () async {
      final completerA = Completer<List<Incident>>();
      fakeRepo.delayedCompleter = completerA;
      fakeRepo.delayedUid = 'student-a';

      // 1. Student A starts loading reports
      getAuth().signInStudent(
        uid: 'student-a',
        displayName: 'Student Alpha',
        email: 'alpha@alustudent.com',
      );
      await pumpEventQueue();

      // Student A request is in-flight and loading
      expect(container.read(myReportsControllerProvider).isLoading, isTrue);

      // 2. Student A signs out before request finishes
      await getAuth().signOut();
      expect(container.read(myReportsControllerProvider).reports, isEmpty);

      // 3. Student B signs in immediately
      getAuth().signInStudent(
        uid: 'student-b',
        displayName: 'Student Beta',
        email: 'beta@alustudent.com',
      );
      await pumpEventQueue();

      // Student B's request completed with Student B's reports
      final stateB = container.read(myReportsControllerProvider);
      expect(stateB.reports.length, 1);
      expect(stateB.reports.first.id, 'inc-b1');

      // 4. Student A's delayed request finally resolves
      completerA.complete([studentAIncident1, studentAIncident2]);
      await pumpEventQueue();

      // Verify Student B's state was NOT overwritten by Student A's response
      final stateAfterDelayed = container.read(myReportsControllerProvider);
      expect(stateAfterDelayed.reports.length, 1);
      expect(stateAfterDelayed.reports.first.id, 'inc-b1');
      expect(stateAfterDelayed.reports.first.createdBy, 'student-b');
    });

    test('logout and loading transition never exposes previous account data',
        () async {
      getAuth().signInStudent(
        uid: 'student-a',
        displayName: 'Student Alpha',
        email: 'alpha@alustudent.com',
      );
      await pumpEventQueue();
      expect(container.read(myReportsControllerProvider).reports.isNotEmpty, isTrue);

      // Prepare delayed fetch for Student B
      final completerB = Completer<List<Incident>>();
      fakeRepo.delayedCompleter = completerB;
      fakeRepo.delayedUid = 'student-b';

      // Student A signs out
      await getAuth().signOut();
      expect(container.read(myReportsControllerProvider).reports, isEmpty);

      // Student B signs in (fetch pending)
      getAuth().signInStudent(
        uid: 'student-b',
        displayName: 'Student Beta',
        email: 'beta@alustudent.com',
      );

      final loadingState = container.read(myReportsControllerProvider);
      expect(loadingState.isLoading, isTrue);
      // Data must be empty, never Student A's data
      expect(loadingState.reports, isEmpty);

      // Complete Student B's load
      completerB.complete([studentBIncident1]);
      await pumpEventQueue();

      final finishedState = container.read(myReportsControllerProvider);
      expect(finishedState.reports.length, 1);
      expect(finishedState.reports.first.createdBy, 'student-b');
    });
  });

  group('StudentMyReportsScreen Widget — Account Switching UI Test', () {
    testWidgets(
        'switches accounts and renders exclusive reports and resets search/filter UI',
        (tester) async {
      // 1. Launch with Student A
      getAuth().signInStudent(
        uid: 'student-a',
        displayName: 'Student Alpha',
        email: 'alpha@alustudent.com',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentMyReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Student A's reports are visible
      expect(find.text('Broken window in Hall A'), findsOneWidget);
      expect(find.text('Water leak in restroom'), findsOneWidget);
      expect(find.text('Power outage in Library'), findsNothing);

      // Student A searches for "leak"
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'leak');
      await tester.pumpAndSettle();

      // Only the matching report is visible
      expect(find.text('Water leak in restroom'), findsOneWidget);
      expect(find.text('Broken window in Hall A'), findsNothing);

      // 2. Student A signs out
      await getAuth().signOut();
      await tester.pump();

      // 3. Student B signs in
      getAuth().signInStudent(
        uid: 'student-b',
        displayName: 'Student Beta',
        email: 'beta@alustudent.com',
      );
      await tester.pumpAndSettle();

      // Verify Student B's report is shown, and Student A's reports are gone
      expect(find.text('Power outage in Library'), findsOneWidget);
      expect(find.text('Broken window in Hall A'), findsNothing);
      expect(find.text('Water leak in restroom'), findsNothing);

      // Verify search text was automatically reset for the new session
      final textFieldWidget = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldWidget.controller?.text ?? '', isEmpty);

      // Verify "All Statuses" is selected
      final allStatusesChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'All Statuses'),
      );
      expect(allStatusesChip.selected, isTrue);
    });
  });
}
