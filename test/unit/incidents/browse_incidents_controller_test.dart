import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporting_app/features/incidents/application/browse_incidents_controller.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_category.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/models/incident_status.dart';

void main() {
  final now = DateTime(2026, 11, 7, 12, 0);

  final sampleIncidents = [
    Incident(
      id: 'inc-101',
      description: 'Air conditioning not working in auditorium',
      category: IncidentCategory.facilities,
      building: 'Auditorium Block',
      block: 'C',
      specificArea: 'Main Hall',
      createdBy: 'uid-1',
      status: IncidentStatus.submitted,
      createdAt: now,
      updatedAt: now,
    ),
    Incident(
      id: 'inc-102',
      description: 'WiFi disconnects every 5 minutes',
      category: IncidentCategory.internetTechnology,
      building: 'Residential Hall',
      block: 'A',
      specificArea: 'Floor 3 common room',
      createdBy: 'uid-2',
      status: IncidentStatus.underReview,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  group('BrowseIncidentsState', () {
    test('initial state has correct defaults', () {
      const state = BrowseIncidentsState();
      expect(state.status, BrowseIncidentsStatus.initial);
      expect(state.allIncidents, isEmpty);
      expect(state.searchQuery, isEmpty);
      expect(state.selectedCategory, isNull);
      expect(state.selectedStatus, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.hasMore, isFalse);
      expect(state.hasActiveFilter, isFalse);
      expect(state.filteredIncidents, isEmpty);
    });

    test('filteredIncidents reflects search query dynamically', () {
      final state = BrowseIncidentsState(
        status: BrowseIncidentsStatus.success,
        allIncidents: sampleIncidents,
        searchQuery: 'WiFi',
      );

      expect(state.hasActiveFilter, isTrue);
      expect(state.filteredIncidents.length, 1);
      expect(state.filteredIncidents.first.id, 'inc-102');
    });

    test('filteredIncidents reflects category filter', () {
      final state = BrowseIncidentsState(
        status: BrowseIncidentsStatus.success,
        allIncidents: sampleIncidents,
        selectedCategory: IncidentCategory.facilities,
      );

      expect(state.hasActiveFilter, isTrue);
      expect(state.filteredIncidents.length, 1);
      expect(state.filteredIncidents.first.id, 'inc-101');
    });

    test('filteredIncidents reflects status filter', () {
      final state = BrowseIncidentsState(
        status: BrowseIncidentsStatus.success,
        allIncidents: sampleIncidents,
        selectedStatus: IncidentStatus.underReview,
      );

      expect(state.hasActiveFilter, isTrue);
      expect(state.filteredIncidents.length, 1);
      expect(state.filteredIncidents.first.id, 'inc-102');
    });

    test('copyWith clearCategory and clearStatus clears active filters', () {
      final state = BrowseIncidentsState(
        status: BrowseIncidentsStatus.success,
        allIncidents: sampleIncidents,
        selectedCategory: IncidentCategory.facilities,
        selectedStatus: IncidentStatus.submitted,
        searchQuery: 'air conditioning',
      );

      expect(state.hasActiveFilter, isTrue);

      final cleared = state.copyWith(
        searchQuery: '',
        clearCategory: true,
        clearStatus: true,
      );

      expect(cleared.hasActiveFilter, isFalse);
      expect(cleared.searchQuery, isEmpty);
      expect(cleared.selectedCategory, isNull);
      expect(cleared.selectedStatus, isNull);
      expect(cleared.filteredIncidents.length, 2);
    });

    test('pagination prevents duplicate records when combining lists', () {
      final initialList = [sampleIncidents[0]];
      final incomingPage = [sampleIncidents[0], sampleIncidents[1]];

      final existingIds = initialList.map((i) => i.id).toSet();
      final deduplicated = incomingPage
          .where((inc) => !existingIds.contains(inc.id))
          .toList();

      final combined = [...initialList, ...deduplicated];

      expect(combined.length, 2);
      expect(combined.map((i) => i.id).toSet().length, 2);
    });
  });
}

