import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/features/incidents/application/incident_detail_controller.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_category.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status_history.dart';
import 'package:campus_incident_reporting_app/features/incidents/presentation/screens/incident_detail_screen.dart';

void main() {
  final now = DateTime(2026, 11, 7, 14, 0);

  final testIncident = Incident(
    id: 'inc-detail-01',
    description: 'Broken window latch in study room 302',
    category: IncidentCategory.facilities,
    building: 'Main Hall',
    block: 'C',
    specificArea: 'Study room 302',
    createdBy: 'test-user-uid',
    status: IncidentStatus.inProgress,
    createdAt: now,
    updatedAt: now.add(const Duration(hours: 2)),
  );

  group('IncidentDetailScreen', () {
    testWidgets('renders incident details and empty status history card',
        (WidgetTester tester) async {
      final mockData = IncidentDetailData(
        incident: testIncident.copyWith(status: IncidentStatus.submitted),
        statusHistory: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incidentDetailProvider('inc-detail-01')
                .overrideWith((ref) => Future.value(mockData)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const IncidentDetailScreen(incidentId: 'inc-detail-01'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify category and description
      expect(find.text('Facilities'), findsOneWidget);
      expect(
        find.text('Broken window latch in study room 302'),
        findsOneWidget,
      );

      // Verify location
      expect(find.text('Main Hall'), findsOneWidget);
      expect(find.text('Block C'), findsOneWidget);
      expect(find.text('Study room 302'), findsOneWidget);

      // Verify empty status history notice
      expect(
        find.text(
          'No status changes recorded yet. This incident is currently submitted and awaiting initial staff review.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders chronological status timeline and remarks',
        (WidgetTester tester) async {
      final historyEntries = [
        IncidentStatusHistory(
          id: 'hist-1',
          previousStatus: IncidentStatus.submitted,
          newStatus: IncidentStatus.underReview,
          updatedBy: 'staff-1',
          timestamp: now.add(const Duration(hours: 1)),
          remarks: 'Reviewed by maintenance team. Assigned to carpenter.',
        ),
        IncidentStatusHistory(
          id: 'hist-2',
          previousStatus: IncidentStatus.underReview,
          newStatus: IncidentStatus.inProgress,
          updatedBy: 'staff-2',
          timestamp: now.add(const Duration(hours: 2)),
          remarks: 'Technician currently on site repairing the latch.',
        ),
      ];

      final mockData = IncidentDetailData(
        incident: testIncident,
        statusHistory: historyEntries,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incidentDetailProvider('inc-detail-01')
                .overrideWith((ref) => Future.value(mockData)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const IncidentDetailScreen(incidentId: 'inc-detail-01'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify timeline entries and badges
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('In Progress'), findsAtLeastNWidgets(1));

      // Verify staff remarks are visible
      expect(
        find.text('Reviewed by maintenance team. Assigned to carpenter.'),
        findsOneWidget,
      );
      expect(
        find.text('Technician currently on site repairing the latch.'),
        findsOneWidget,
      );

      // Verify latest update indicator
      expect(find.text('Latest update'), findsOneWidget);
    });
  });
}

