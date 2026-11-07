import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/incident_repository.dart';
import '../domain/models/incident.dart';
import '../domain/models/incident_category.dart';
import '../domain/models/incident_status.dart';
import '../domain/services/incident_filter_service.dart';

enum BrowseIncidentsStatus {
  initial,
  loading,
  success,
  error,
}

/// State representing campus-wide incident discovery with pagination, search,
/// and filtering.
class BrowseIncidentsState {
  const BrowseIncidentsState({
    this.status = BrowseIncidentsStatus.initial,
    this.allIncidents = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.selectedStatus,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.lastDocument,
  });

  final BrowseIncidentsStatus status;
  final List<Incident> allIncidents;
  final String searchQuery;
  final IncidentCategory? selectedCategory;
  final IncidentStatus? selectedStatus;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final DocumentSnapshot? lastDocument;

  bool get isLoading => status == BrowseIncidentsStatus.loading;

  bool get hasActiveFilter =>
      searchQuery.trim().isNotEmpty ||
      selectedCategory != null ||
      selectedStatus != null;

  /// Returns the loaded incidents matching active search and filter criteria.
  List<Incident> get filteredIncidents => IncidentFilterService.filterList(
        allIncidents,
        query: searchQuery,
        category: selectedCategory,
        status: selectedStatus,
      );

  BrowseIncidentsState copyWith({
    BrowseIncidentsStatus? status,
    List<Incident>? allIncidents,
    String? searchQuery,
    IncidentCategory? selectedCategory,
    bool clearCategory = false,
    IncidentStatus? selectedStatus,
    bool clearStatus = false,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
    DocumentSnapshot? lastDocument,
  }) {
    return BrowseIncidentsState(
      status: status ?? this.status,
      allIncidents: allIncidents ?? this.allIncidents,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedStatus:
          clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

final browseIncidentsControllerProvider = NotifierProvider<
    BrowseIncidentsController, BrowseIncidentsState>(
  BrowseIncidentsController.new,
);

class BrowseIncidentsController extends Notifier<BrowseIncidentsState> {
  @override
  BrowseIncidentsState build() {
    Future.microtask(() => loadInitial());
    return const BrowseIncidentsState();
  }

  /// Loads the first page of campus-wide incidents from Firestore.
  Future<void> loadInitial() async {
    state = state.copyWith(
      status: BrowseIncidentsStatus.loading,
      clearError: true,
    );

    try {
      final repository = ref.read(incidentRepositoryProvider);
      final page = await repository.fetchRecentIncidents(limit: 20);

      state = state.copyWith(
        status: BrowseIncidentsStatus.success,
        allIncidents: page.incidents,
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: BrowseIncidentsStatus.error,
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  /// Loads the next page of incidents using Firestore document cursor.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDocument == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = ref.read(incidentRepositoryProvider);
      final page = await repository.fetchRecentIncidents(
        limit: 20,
        startAfter: state.lastDocument,
      );

      // Deduplicate by ID to prevent repeated items across pages
      final existingIds = state.allIncidents.map((i) => i.id).toSet();
      final newUnique = page.incidents
          .where((inc) => !existingIds.contains(inc.id))
          .toList();

      state = state.copyWith(
        allIncidents: [...state.allIncidents, ...newUnique],
        lastDocument: page.lastDocument ?? state.lastDocument,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Sets the active search keyword.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Sets or unsets the category filter.
  void setCategoryFilter(IncidentCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  /// Sets or unsets the status filter.
  void setStatusFilter(IncidentStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(selectedStatus: status);
    }
  }

  /// Resets both search query and active filters.
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearCategory: true,
      clearStatus: true,
    );
  }

  /// Refreshes the first page from Firestore while preserving search and filters.
  Future<void> refresh() async {
    try {
      final repository = ref.read(incidentRepositoryProvider);
      final page = await repository.fetchRecentIncidents(limit: 20);

      state = state.copyWith(
        status: BrowseIncidentsStatus.success,
        allIncidents: page.incidents,
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  String _cleanErrorMessage(Object error) {
    final str = error.toString().toLowerCase();
    if (str.contains('permission-denied')) {
      return 'Permission denied. Please verify your student login.';
    }
    if (str.contains('network') || str.contains('socketexception')) {
      return 'Network connection issue. Please check your internet connection.';
    }
    return 'Failed to load incidents. Please pull to refresh.';
  }
}

