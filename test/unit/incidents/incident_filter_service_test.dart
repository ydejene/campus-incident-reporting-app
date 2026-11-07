import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_category.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/services/incident_filter_service.dart';

void main() {
  final now = DateTime(2026, 11, 7, 10, 0);

  final incident1 = Incident(
    id: 'inc-1',
    description: 'Broken water tap on second floor restroom',
    category: IncidentCategory.waterSupply,
    building: 'Innovation Hub',
    block: 'A',
    specificArea: '2nd floor east restroom',
    createdBy: 'student-uid-1',
    status: IncidentStatus.submitted,
    createdAt: now,
    updatedAt: now,
  );

  final incident2 = Incident(
    id: 'inc-2',
    description: 'Flickering fluorescent lights in library study pod',
    category: IncidentCategory.electricity,
    building: 'Learning Commons',
    block: 'B',
    specificArea: 'Study Pod 4',
    createdBy: 'student-uid-2',
    status: IncidentStatus.inProgress,
    createdAt: now.add(const Duration(hours: 1)),
    updatedAt: now.add(const Duration(hours: 2)),
  );

  final incident3 = Incident(
    id: 'inc-3',
    description: 'Trash can overflowing near cafeteria door',
    category: IncidentCategory.sanitation,
    building: 'Student Centre',
    block: '',
    specificArea: 'West entrance near cafeteria',
    createdBy: 'student-uid-1',
    status: IncidentStatus.resolved,
    createdAt: now.add(const Duration(hours: 3)),
    updatedAt: now.add(const Duration(hours: 4)),
  );

  final all = [incident1, incident2, incident3];

  group('IncidentFilterService – Search matching', () {
    test('empty or whitespace query matches all incidents', () {
      expect(IncidentFilterService.filterList(all, query: ''), equals(all));
      expect(IncidentFilterService.filterList(all, query: '   '), equals(all));
    });

    test('matches case-insensitively by description keywords', () {
      final results = IncidentFilterService.filterList(all, query: 'WATER TAP');
      expect(results.length, 1);
      expect(results.first.id, 'inc-1');
    });

    test('matches by category label', () {
      final results =
          IncidentFilterService.filterList(all, query: 'Electricity');
      expect(results.length, 1);
      expect(results.first.id, 'inc-2');
    });

    test('matches by building name', () {
      final results =
          IncidentFilterService.filterList(all, query: 'Innovation Hub');
      expect(results.length, 1);
      expect(results.first.id, 'inc-1');
    });

    test('matches by block identifier', () {
      final results = IncidentFilterService.filterList(all, query: 'Block B');
      expect(results.length, 1);
      expect(results.first.id, 'inc-2');
    });

    test('matches by specific area', () {
      final results =
          IncidentFilterService.filterList(all, query: 'Study Pod');
      expect(results.length, 1);
      expect(results.first.id, 'inc-2');
    });

    test('returns empty when no incident matches query', () {
      final results = IncidentFilterService.filterList(all, query: 'nonexistent keyword');
      expect(results, isEmpty);
    });
  });

  group('IncidentFilterService – Category and Status filtering', () {
    test('filters strictly by category', () {
      final results = IncidentFilterService.filterList(
        all,
        category: IncidentCategory.sanitation,
      );
      expect(results.length, 1);
      expect(results.first.id, 'inc-3');
    });

    test('filters strictly by status', () {
      final results = IncidentFilterService.filterList(
        all,
        status: IncidentStatus.inProgress,
      );
      expect(results.length, 1);
      expect(results.first.id, 'inc-2');
    });

    test('combines search query, category, and status filters', () {
      // Matching query and category and status
      final matching = IncidentFilterService.filterList(
        all,
        query: 'restroom',
        category: IncidentCategory.waterSupply,
        status: IncidentStatus.submitted,
      );
      expect(matching.length, 1);
      expect(matching.first.id, 'inc-1');

      // Matching query and category, but wrong status
      final wrongStatus = IncidentFilterService.filterList(
        all,
        query: 'restroom',
        category: IncidentCategory.waterSupply,
        status: IncidentStatus.resolved,
      );
      expect(wrongStatus, isEmpty);
    });
  });

  group('IncidentFilterService – Personal report ownership', () {
    test('filters incidents belonging to specific student UID', () {
      final student1Reports =
          all.where((inc) => inc.createdBy == 'student-uid-1').toList();
      expect(student1Reports.length, 2);
      expect(student1Reports.map((i) => i.id), containsAll(['inc-1', 'inc-3']));

      final student2Reports =
          all.where((inc) => inc.createdBy == 'student-uid-2').toList();
      expect(student2Reports.length, 1);
      expect(student2Reports.first.id, 'inc-2');
    });
  });
}

