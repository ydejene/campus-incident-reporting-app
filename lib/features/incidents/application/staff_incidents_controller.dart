import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/incident_repository.dart';
import '../domain/models/incident.dart';
import '../domain/models/incident_category.dart';
import '../domain/models/incident_status.dart';
import '../domain/services/incident_filter_service.dart';

enum StaffIncidentsStatus {
  initial,
  loading,
  success,
  error,
}

class StaffIncidentsState {
  const StaffIncidentsState({
    this.status = StaffIncidentsStatus.initial,
    this.allIncidents = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.selectedStatus,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.lastDocument,
  });

  final StaffIncidentsStatus status;
  final List<Incident> allIncidents;
  final String searchQuery;
  final IncidentCategory? selectedCategory;
  final IncidentStatus? selectedStatus;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final DocumentSnapshot? lastDocument;

  bool get isLoading => status == StaffIncidentsStatus.loading;

  bool get hasActiveFilter =>
      searchQuery.trim().isNotEmpty ||
      selectedCategory != null ||
      selectedStatus != null;

  List<Incident> get filteredIncidents => IncidentFilterService.filterList(
        allIncidents,
        query: searchQuery,
        category: selectedCategory,
        status: selectedStatus,
      );

  StaffIncidentsState copyWith({
    StaffIncidentsStatus? status,
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
    return StaffIncidentsState(
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

final staffIncidentsControllerProvider = NotifierProvider<
    StaffIncidentsController, StaffIncidentsState>(
  StaffIncidentsController.new,
);

class StaffIncidentsController extends Notifier<StaffIncidentsState> {
  @override
  StaffIncidentsState build() {
    Future.microtask(() => loadInitial());
    return const StaffIncidentsState();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      status: StaffIncidentsStatus.loading,
      clearError: true,
    );

    try {
      final repository = ref.read(incidentRepositoryProvider);
      final page = await repository.fetchRecentIncidents(limit: 20);

      state = state.copyWith(
        status: StaffIncidentsStatus.success,
        allIncidents: page.incidents,
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: StaffIncidentsStatus.error,
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

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

      final existingIds = state.allIncidents.map((i) => i.id).toSet();
      final newUnique =
          page.incidents.where((i) => !existingIds.contains(i.id)).toList();

      state = state.copyWith(
        isLoadingMore: false,
        allIncidents: [...state.allIncidents, ...newUnique],
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _cleanErrorMessage(e),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(IncidentCategory? category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void setStatus(IncidentStatus? status) {
    if (state.selectedStatus == status) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(selectedStatus: status);
    }
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearCategory: true,
      clearStatus: true,
    );
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  String _cleanErrorMessage(dynamic error) {
    final raw = error.toString();
    if (raw.contains('Exception: ')) {
      return raw.split('Exception: ').last.trim();
    }
    return raw;
  }
}
