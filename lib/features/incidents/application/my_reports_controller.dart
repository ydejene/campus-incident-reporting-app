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
  int _currentRequestId = 0;
  String? _sessionUid;

  @override
  MyReportsState build() {
    // React to authenticated student session changes.
    // By selecting the student's UID, this notifier rebuilds only when a student signs in,
    // signs out, or switches accounts. Other auth mutations (e.g. profile display name updates)
    // within the same authenticated session do not trigger a rebuild or clear active filters.
    final currentStudentUid = ref.watch(
      authControllerProvider.select((authState) {
        if (authState.status == AuthStatus.authenticatedStudent) {
          return authState.user?.uid ?? authState.profile?.uid;
        }
        return null;
      }),
    );

    // Invalidate any in-flight requests from prior sessions and record active UID
    final requestId = ++_currentRequestId;
    _sessionUid = currentStudentUid;

    // When not authenticated as a student (logged out, staff, unverified, initial),
    // return a clean initial state with zero reports and no filters.
    if (currentStudentUid == null) {
      return const MyReportsState();
    }

    // A student session is active (fresh login or account switch).
    // Start with a clean state: status loading, empty reports, empty search, no status filter.
    Future.microtask(
      () => _fetchReportsForSession(currentStudentUid, requestId, isInitial: true),
    );

    return const MyReportsState(status: MyReportsStatus.loading);
  }

  /// Fetches reports for [uid] with verification that [requestId] and [uid]
  /// still match the active session before mutating state.
  Future<void> _fetchReportsForSession(
    String uid,
    int requestId, {
    bool isInitial = false,
  }) async {
    try {
      final repository = ref.read(incidentRepositoryProvider);
      final reports = await repository.fetchIncidentsByUser(uid);

      // Verify session and request token have not changed while awaiting Firestore.
      if (!_isRequestValid(uid, requestId)) return;

      state = state.copyWith(
        status: MyReportsStatus.success,
        reports: reports,
        clearError: true,
      );
    } catch (e) {
      // Discard errors from superseded or cancelled sessions.
      if (!_isRequestValid(uid, requestId)) return;

      state = state.copyWith(
        status: MyReportsStatus.error,
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  bool _isRequestValid(String uid, int requestId) {
    if (!ref.mounted) {
      return false;
    }
    if (_currentRequestId != requestId || _sessionUid != uid) {
      return false;
    }
    final currentAuth = ref.read(authControllerProvider);
    final activeUid = currentAuth.user?.uid ?? currentAuth.profile?.uid;
    if (currentAuth.status != AuthStatus.authenticatedStudent ||
        activeUid != uid) {
      return false;
    }
    return true;
  }

  /// Reloads reports created by the currently authenticated student (e.g. error retry).
  Future<void> loadReports() async {
    final authState = ref.read(authControllerProvider);
    final uid = authState.user?.uid ?? authState.profile?.uid;
    if (authState.status != AuthStatus.authenticatedStudent || uid == null) {
      state = state.copyWith(
        status: MyReportsStatus.error,
        errorMessage: 'Please sign in to view your reports.',
      );
      return;
    }

    final requestId = ++_currentRequestId;

    state = state.copyWith(
      status: MyReportsStatus.loading,
      clearError: true,
    );

    await _fetchReportsForSession(uid, requestId);
  }

  /// Refreshes personal report history within an active session, preserving
  /// existing search query and status filter selections.
  Future<void> refresh() async {
    final authState = ref.read(authControllerProvider);
    final uid = authState.user?.uid ?? authState.profile?.uid;
    if (authState.status != AuthStatus.authenticatedStudent || uid == null) {
      return;
    }

    final requestId = ++_currentRequestId;

    try {
      final repository = ref.read(incidentRepositoryProvider);
      final reports = await repository.fetchIncidentsByUser(uid);

      if (!_isRequestValid(uid, requestId)) return;

      // Preserve active filters and search query
      state = state.copyWith(
        status: MyReportsStatus.success,
        reports: reports,
        clearError: true,
      );
    } catch (e) {
      if (!_isRequestValid(uid, requestId)) return;

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

