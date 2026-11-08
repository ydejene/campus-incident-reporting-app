import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/authentication/application/auth_controller.dart';
import '../../../features/authentication/domain/models/user_role.dart';
import '../../dashboard/application/staff_dashboard_controller.dart';
import '../data/repositories/incident_repository.dart';
import '../domain/models/incident.dart';
import '../domain/models/incident_status.dart';
import 'incident_detail_controller.dart';
import 'recent_campus_incidents_provider.dart';

enum IncidentStatusUpdateStatus {
  idle,
  submitting,
  success,
  error,
}

class IncidentStatusUpdateState {
  const IncidentStatusUpdateState({
    this.status = IncidentStatusUpdateStatus.idle,
    this.errorMessage,
  });

  final IncidentStatusUpdateStatus status;
  final String? errorMessage;

  bool get isSubmitting => status == IncidentStatusUpdateStatus.submitting;
  bool get isSuccess => status == IncidentStatusUpdateStatus.success;
}

final incidentStatusUpdateControllerProvider = NotifierProvider<
    IncidentStatusUpdateController, IncidentStatusUpdateState>(
  IncidentStatusUpdateController.new,
);

class IncidentStatusUpdateController
    extends Notifier<IncidentStatusUpdateState> {
  @override
  IncidentStatusUpdateState build() => const IncidentStatusUpdateState();

  /// Updates incident status and commits the corresponding status history
  /// record atomically in Cloud Firestore.
  ///
  /// Enforces staff role authorization, status differentiation, and mandatory
  /// rejection explanation at the application layer.
  Future<bool> updateStatus({
    required Incident incident,
    required IncidentStatus newStatus,
    String? remarks,
  }) async {
    if (state.isSubmitting) return false;

    // Verify staff authorization
    final authState = ref.read(authControllerProvider);
    final profile = authState.profile;
    if (profile == null || profile.role != UserRole.staff) {
      state = const IncidentStatusUpdateState(
        status: IncidentStatusUpdateStatus.error,
        errorMessage:
            'Only verified campus staff are authorized to update incident status.',
      );
      return false;
    }

    // Validate non-identical status transition
    if (newStatus == incident.status) {
      state = IncidentStatusUpdateState(
        status: IncidentStatusUpdateStatus.error,
        errorMessage:
            'The incident is already marked as ${incident.status.label}.',
      );
      return false;
    }

    // Require non-empty explanation for rejection
    final trimmedRemarks = remarks?.trim();
    if (newStatus == IncidentStatus.rejected &&
        (trimmedRemarks == null || trimmedRemarks.isEmpty)) {
      state = const IncidentStatusUpdateState(
        status: IncidentStatusUpdateStatus.error,
        errorMessage:
            'An explanation is required when rejecting an incident report.',
      );
      return false;
    }

    state = const IncidentStatusUpdateState(
      status: IncidentStatusUpdateStatus.submitting,
    );

    try {
      final repository = ref.read(incidentRepositoryProvider);
      final staffDisplayName = profile.displayName.trim().isNotEmpty
          ? profile.displayName.trim()
          : (authState.user?.displayName?.trim() ?? 'Staff Member');

      await repository.updateIncidentStatus(
        incidentId: incident.id,
        previousStatus: incident.status,
        newStatus: newStatus,
        staffUid: profile.uid,
        staffDisplayName: staffDisplayName,
        remarks: trimmedRemarks,
      );

      // Invalidate providers to guarantee fresh incident details and metrics
      ref.invalidate(incidentDetailProvider(incident.id));
      ref.invalidate(staffDashboardControllerProvider);
      ref.invalidate(recentCampusIncidentsProvider);

      state = const IncidentStatusUpdateState(
        status: IncidentStatusUpdateStatus.success,
      );
      return true;
    } catch (e) {
      state = IncidentStatusUpdateState(
        status: IncidentStatusUpdateStatus.error,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  void reset() {
    state = const IncidentStatusUpdateState();
  }

  String _cleanErrorMessage(dynamic error) {
    final raw = error.toString();
    if (raw.contains('Exception: ')) {
      return raw.split('Exception: ').last.trim();
    }
    return raw;
  }
}
