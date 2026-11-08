/// Domain model capturing campus incident statistics for the staff overview.
class StaffDashboardStatistics {
  const StaffDashboardStatistics({
    required this.totalIncidents,
    required this.submittedIncidents,
    required this.inProgressIncidents,
    required this.resolvedIncidents,
  });

  /// Total count of all campus-wide incident reports.
  final int totalIncidents;

  /// Count of reports in 'submitted' status awaiting initial staff triage.
  final int submittedIncidents;

  /// Count of reports currently 'in_progress'.
  final int inProgressIncidents;

  /// Count of reports marked as 'resolved'.
  final int resolvedIncidents;

  /// Convenience constant for empty/initial states.
  static const empty = StaffDashboardStatistics(
    totalIncidents: 0,
    submittedIncidents: 0,
    inProgressIncidents: 0,
    resolvedIncidents: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffDashboardStatistics &&
          runtimeType == other.runtimeType &&
          totalIncidents == other.totalIncidents &&
          submittedIncidents == other.submittedIncidents &&
          inProgressIncidents == other.inProgressIncidents &&
          resolvedIncidents == other.resolvedIncidents;

  @override
  int get hashCode =>
      totalIncidents.hashCode ^
      submittedIncidents.hashCode ^
      inProgressIncidents.hashCode ^
      resolvedIncidents.hashCode;
}

