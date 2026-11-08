import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../incidents/data/repositories/incident_repository.dart';
import '../../incidents/domain/models/incident.dart';
import '../domain/models/staff_dashboard_statistics.dart';

class StaffDashboardState {
  const StaffDashboardState({
    this.isLoading = false,
    this.statistics = StaffDashboardStatistics.empty,
    this.recentIncidents = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final StaffDashboardStatistics statistics;
  final List<Incident> recentIncidents;
  final String? errorMessage;

  StaffDashboardState copyWith({
    bool? isLoading,
    StaffDashboardStatistics? statistics,
    List<Incident>? recentIncidents,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StaffDashboardState(
      isLoading: isLoading ?? this.isLoading,
      statistics: statistics ?? this.statistics,
      recentIncidents: recentIncidents ?? this.recentIncidents,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final staffDashboardControllerProvider =
    NotifierProvider<StaffDashboardController, StaffDashboardState>(
  StaffDashboardController.new,
);

class StaffDashboardController extends Notifier<StaffDashboardState> {
  @override
  StaffDashboardState build() {
    Future.microtask(() => loadDashboard());
    return const StaffDashboardState(isLoading: true);
  }

  /// Loads campus-wide statistics and recent incidents in parallel.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(incidentRepositoryProvider);

      final statsFuture = repository.fetchIncidentStatistics();
      final recentFuture = repository.fetchRecentIncidents(limit: 5);

      final results = await Future.wait([statsFuture, recentFuture]);

      final stats = results[0] as StaffDashboardStatistics;
      final recentPage = results[1] as IncidentPage;

      state = state.copyWith(
        isLoading: false,
        statistics: stats,
        recentIncidents: recentPage.incidents,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  /// Pull-to-refresh action.
  Future<void> refresh() async {
    await loadDashboard();
  }

  String _cleanErrorMessage(dynamic error) {
    final raw = error.toString();
    if (raw.contains('Exception: ')) {
      return raw.split('Exception: ').last.trim();
    }
    return raw;
  }
}
