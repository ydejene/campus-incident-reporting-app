import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/incident_repository.dart';
import '../domain/models/incident.dart';

/// Fetches the three most recent campus-wide incidents for the home screen preview.
///
/// Uses [FutureProvider.autoDispose] so the cache is released when the home
/// screen is no longer active, ensuring fresh data on each visit.
final recentCampusIncidentsProvider =
    FutureProvider.autoDispose<List<Incident>>((ref) async {
  final repository = ref.read(incidentRepositoryProvider);
  final page = await repository.fetchRecentIncidents(limit: 3);
  return page.incidents;
});

