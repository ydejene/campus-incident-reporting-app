import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/application/auth_state.dart';
import '../data/repositories/incident_repository.dart';
import '../domain/models/incident.dart';
import '../domain/models/incident_status.dart';
import '../domain/services/incident_filter_service.dart';

enum MyReportsStatus {
  initial,
  loading,
  success,
  error,
}

class MyReportsState {
  const MyReportsState({
    this.status = MyReportsStatus.initial,
    this.reports = const [],
    this.searchQuery = '',
    this.selectedStatus,
    this.errorMessage,
  });

  final MyReportsStatus status;
  final List<Incident> reports;
  final String searchQuery;
  final IncidentStatus? selectedStatus;
  final String? errorMessage;

  bool get isLoading => status == MyReportsStatus.loading;

  bool get hasActiveFilter =>
      searchQuery.trim().isNotEmpty || selectedStatus != null;

  List<Incident> get filteredReports => IncidentFilterService.filterList(
        reports,
        query: searchQuery,
        status: selectedStatus,
      );

  MyReportsState copyWith({
    MyReportsStatus? status,
    List<Incident>? reports,
    String? searchQuery,
    IncidentStatus? selectedStatus,
    bool clearStatus = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyReportsState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus:
          clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final myReportsControllerProvider =
    NotifierProvider<MyReportsController, MyReportsState>(
  MyReportsController.new,
);

class MyReportsController extends Notifier<MyReportsState> {
  @override
  MyReportsState build() {
    Future.microtask(() => loadReports());
    return const MyReportsState();
  }

  /// Loads reports created by the currently authenticated student.
  Future<void> loadReports() async {
    state = state.copyWith(
      status: MyReportsStatus.loading,
      clearError: true,
    );

    final authState = ref.read(authControllerProvider);
    if (authState.status != AuthStatus.authenticatedStudent ||
        authState.user == null) {
      state = state.copyWith(
        status: MyReportsStatus.error,
        errorMessage: 'Please sign in to view your reports.',
      );
      return;
    }

    final uid = authState.user!.uid;

    try {
      final repository = ref.read(incidentRepositoryProvider);
      final reports = await repository.fetchIncidentsByUser(uid);

      state = state.copyWith(
        status: MyReportsStatus.success,
        reports: reports,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: MyReportsStatus.error,
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  /// Refreshes personal report history.
  Future<void> refresh() async {
    final authState = ref.read(authControllerProvider);
    if (authState.user == null) return;

    try {
      final repository = ref.read(incidentRepositoryProvider);
      final reports = await repository.fetchIncidentsByUser(authState.user!.uid);

      state = state.copyWith(
        status: MyReportsStatus.success,
        reports: reports,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(IncidentStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(selectedStatus: status);
    }
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearStatus: true,
    );
  }

  String _cleanErrorMessage(Object error) {
    final str = error.toString().toLowerCase();
    if (str.contains('permission-denied')) {
      return 'Permission denied. Please verify your account.';
    }
    if (str.contains('network') || str.contains('socketexception')) {
      return 'Network connection issue. Please check your internet connection.';
    }
    return 'Failed to load your reports. Please pull to refresh.';
  }
}

