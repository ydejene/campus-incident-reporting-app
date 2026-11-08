import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/features/incidents/application/staff_incidents_controller.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_category.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';
import 'package:campus_incident_reporting_app/features/incidents/presentation/screens/staff_incidents_screen.dart';

class _MockStaffIncidentsController extends StaffIncidentsController {
  _MockStaffIncidentsController(this._initialState);

  final StaffIncidentsState _initialState;

  @override
  StaffIncidentsState build() => _initialState;
}

List<Incident> _sampleStaffIncidents() {
  final now = DateTime.now();
  return [
    Incident(
      id: 'staff-inc-1',
      description: 'Power socket sparked in library',
      category: IncidentCategory.electricity,
      building: 'Library Block',
      block: 'A',
      specificArea: 'Study zone 2',
      createdBy: 'student-alpha',
      status: IncidentStatus.submitted,
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now.subtract(const Duration(hours: 1)),
    ),
    Incident(
      id: 'staff-inc-2',
      description: 'Bathroom sink overflowing',
      category: IncidentCategory.sanitation,
      building: 'Dormitory East',
      block: 'B',
      specificArea: 'Floor 1 restroom',
      createdBy: 'student-beta',
      status: IncidentStatus.inProgress,
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    ),
    Incident(
      id: 'staff-inc-3',
      description: 'WiFi access point disconnected',
      category: IncidentCategory.internetTechnology,
      building: 'Main Hall',
      block: 'C',
      specificArea: 'Cafeteria',
      createdBy: 'student-gamma',
      status: IncidentStatus.resolved,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(hours: 4)),
    ),
  ];
}

Widget _buildStaffIncidentsScreen({
  required StaffIncidentsState state,
  GoRouter? router,
}) {
  final overrides = [
    staffIncidentsControllerProvider.overrideWith(
      () => _MockStaffIncidentsController(state),
    ),
  ];

  if (router != null) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const StaffIncidentsScreen(),
    ),
  );
}

void main() {
  group('StaffIncidentsScreen', () {
    testWidgets('renders header, search bar, and filter chips', (tester) async {
      await tester.pumpWidget(
        _buildStaffIncidentsScreen(
          state: const StaffIncidentsState(
            status: StaffIncidentsStatus.success,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Incident Management'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Search description, area, building...'),
        findsOneWidget,
      );
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('All Statuses'), findsOneWidget);
    });

    testWidgets('renders all campus-wide incidents', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildStaffIncidentsScreen(
          state: StaffIncidentsState(
            status: StaffIncidentsStatus.success,
            allIncidents: _sampleStaffIncidents(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Power socket sparked in library'), findsOneWidget);
      expect(find.text('Bathroom sink overflowing'), findsOneWidget);
      expect(find.text('WiFi access point disconnected'), findsOneWidget);
    });

    testWidgets('filters incidents by search keywords', (tester) async {
      await tester.pumpWidget(
        _buildStaffIncidentsScreen(
          state: StaffIncidentsState(
            status: StaffIncidentsStatus.success,
            allIncidents: _sampleStaffIncidents(),
            searchQuery: 'sparked',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Power socket sparked in library'), findsOneWidget);
      expect(find.text('Bathroom sink overflowing'), findsNothing);
      expect(find.text('WiFi access point disconnected'), findsNothing);
    });

    testWidgets('filters incidents by category', (tester) async {
      await tester.pumpWidget(
        _buildStaffIncidentsScreen(
          state: StaffIncidentsState(
            status: StaffIncidentsStatus.success,
            allIncidents: _sampleStaffIncidents(),
            selectedCategory: IncidentCategory.sanitation,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bathroom sink overflowing'), findsOneWidget);
      expect(find.text('Power socket sparked in library'), findsNothing);
    });

    testWidgets('filters incidents by status', (tester) async {
      await tester.pumpWidget(
        _buildStaffIncidentsScreen(
          state: StaffIncidentsState(
            status: StaffIncidentsStatus.success,
            allIncidents: _sampleStaffIncidents(),
            selectedStatus: IncidentStatus.resolved,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WiFi access point disconnected'), findsOneWidget);
      expect(find.text('Power socket sparked in library'), findsNothing);
    });

    testWidgets('shows active filter banner and Clear filters action',
        (tester) async {
      await tester.pumpWidget(
        _buildStaffIncidentsScreen(
          state: StaffIncidentsState(
            status: StaffIncidentsStatus.success,
            allIncidents: _sampleStaffIncidents(),
            selectedStatus: IncidentStatus.submitted,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active filters applied'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
    });

    testWidgets('renders empty state when no incidents match active filters',
        (tester) async {
      await tester.pumpWidget(
        _buildStaffIncidentsScreen(
          state: StaffIncidentsState(
            status: StaffIncidentsStatus.success,
            allIncidents: _sampleStaffIncidents(),
            searchQuery: 'nonexistent keyword xyz',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No matching incidents'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);
    });

    testWidgets('tapping an incident card navigates to /incident/:id',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? openedId;
      final router = GoRouter(
        initialLocation: '/staff/incidents',
        routes: [
          GoRoute(
            path: '/staff/incidents',
            builder: (context, state) => const StaffIncidentsScreen(),
          ),
          GoRoute(
            path: '/incident/:id',
            builder: (context, state) {
              openedId = state.pathParameters['id'];
              return Scaffold(body: Text('Detail $openedId'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _buildStaffIncidentsScreen(
          state: StaffIncidentsState(
            status: StaffIncidentsStatus.success,
            allIncidents: _sampleStaffIncidents(),
          ),
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      final firstCard = find.text('Power socket sparked in library');
      await tester.ensureVisible(firstCard);
      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      expect(openedId, 'staff-inc-1');
      expect(find.text('Detail staff-inc-1'), findsOneWidget);
    });
  });
}
