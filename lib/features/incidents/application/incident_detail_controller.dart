import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/domain/models/user_role.dart';
import '../data/repositories/incident_repository.dart';
import '../domain/models/incident.dart';
import '../domain/models/incident_private_reporter.dart';
import '../domain/models/incident_status_history.dart';

/// Bundle containing the incident record and its chronological status history.
class IncidentDetailData {
  const IncidentDetailData({
    required this.incident,
    required this.statusHistory,
  });

  final Incident incident;
  final List<IncidentStatusHistory> statusHistory;
}

/// Provides detailed incident data and status timeline by incident ID.
final incidentDetailProvider =
    FutureProvider.autoDispose.family<IncidentDetailData, String>(
  (ref, incidentId) async {
    final repository = ref.read(incidentRepositoryProvider);

    final incident = await repository.fetchIncidentById(incidentId);
    if (incident == null) {
      throw Exception('Incident report not found or has been removed.');
    }

    final history = await repository.fetchStatusHistory(incidentId);

    return IncidentDetailData(
      incident: incident,
      statusHistory: history,
    );
  },
);

/// Securely loads private reporter information strictly for authenticated staff members.
///
/// Returns `null` if the viewing user is not authorized staff.
final privateReporterProvider =
    FutureProvider.autoDispose.family<IncidentPrivateReporter?, String>(
  (ref, incidentId) async {
    final authState = ref.watch(authControllerProvider);
    if (authState.profile?.role != UserRole.staff) {
      return null;
    }

    final repository = ref.read(incidentRepositoryProvider);
    return repository.fetchPrivateReporter(incidentId);
  },
);


