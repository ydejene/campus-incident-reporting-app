import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/incident_repository.dart';
import '../data/services/cloudinary_service.dart';
import '../domain/models/incident_category.dart';
import '../domain/models/incident_private_reporter.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/application/auth_state.dart';

/// Describes the phase the submission form is currently in.
enum IncidentSubmissionStatus {
  initial,
  validating,
  uploading,
  submitting,
  success,
  error,
}

/// Immutable state for the incident submission form controller.
class IncidentSubmissionState {
  const IncidentSubmissionState({
    this.status = IncidentSubmissionStatus.initial,
    this.errorMessage,
    this.submittedIncidentId,
  });

  final IncidentSubmissionStatus status;
  final String? errorMessage;

  /// Non-null after a successful submission.
  final String? submittedIncidentId;

  bool get isLoading =>
      status == IncidentSubmissionStatus.validating ||
      status == IncidentSubmissionStatus.uploading ||
      status == IncidentSubmissionStatus.submitting;

  bool get isSuccess => status == IncidentSubmissionStatus.success;

  IncidentSubmissionState copyWith({
    IncidentSubmissionStatus? status,
    String? errorMessage,
    String? submittedIncidentId,
  }) {
    return IncidentSubmissionState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      submittedIncidentId: submittedIncidentId ?? this.submittedIncidentId,
    );
  }
}

final incidentSubmissionControllerProvider = NotifierProvider<
    IncidentSubmissionController, IncidentSubmissionState>(
  IncidentSubmissionController.new,
);

/// Controls the lifecycle of a student incident submission.
///
/// Separates the Cloudinary upload and Firestore write into discrete, labeled
/// phases so the UI can display meaningful progress. Firebase and Cloudinary
/// operations are kept entirely within this controller and the repositories it
/// delegates to.
class IncidentSubmissionController
    extends Notifier<IncidentSubmissionState> {
  @override
  IncidentSubmissionState build() => const IncidentSubmissionState();

  /// Submits a new incident report.
  ///
  /// If [imageFile] is provided, it is uploaded to Cloudinary first. If the
  /// upload succeeds the resulting URL and public ID are attached to the
  /// incident document. If the upload fails the error is surfaced and the
  /// submission is cancelled – no orphaned Cloudinary asset is created.
  ///
  /// If the Cloudinary upload succeeds but the Firestore write subsequently
  /// fails, the already-uploaded image cannot be automatically rolled back
  /// from the client. The error is reported clearly, and the orphaned asset
  /// is a known limitation documented in the README.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> submitIncident({
    required IncidentCategory category,
    required String description,
    required String building,
    required String block,
    required String specificArea,
    File? imageFile,
  }) async {
    // Guard: prevent concurrent submissions
    if (state.isLoading) return false;

    state = state.copyWith(
      status: IncidentSubmissionStatus.validating,
      errorMessage: null,
    );

    // Retrieve authenticated user
    final authState = ref.read(authControllerProvider);
    if (authState.status != AuthStatus.authenticatedStudent) {
      state = state.copyWith(
        status: IncidentSubmissionStatus.error,
        errorMessage:
            'You must be signed in as a verified student to submit a report.',
      );
      return false;
    }

    final uid = authState.user!.uid;
    final reporterEmail = authState.profile?.email ?? authState.user!.email ?? '';
    final reporterName =
        authState.profile?.displayName.isNotEmpty == true
            ? authState.profile!.displayName
            : authState.user!.displayName;

    // Optional Cloudinary image upload
    String? photoUrl;
    String? photoPublicId;

    if (imageFile != null) {
      state = state.copyWith(status: IncidentSubmissionStatus.uploading);

      try {
        final cloudinary = CloudinaryService();
        final result = await cloudinary.uploadImage(imageFile);
        photoUrl = result.secureUrl;
        photoPublicId = result.publicId;
      } on CloudinaryUploadException catch (e) {
        state = state.copyWith(
          status: IncidentSubmissionStatus.error,
          errorMessage: e.message,
        );
        return false;
      } catch (_) {
        state = state.copyWith(
          status: IncidentSubmissionStatus.error,
          errorMessage:
              'Image upload failed due to an unexpected error. Please try again.',
        );
        return false;
      }
    }

    // Firestore write
    state = state.copyWith(status: IncidentSubmissionStatus.submitting);

    try {
      final incident = IncidentRepository.buildNewIncident(
        createdBy: uid,
        category: category,
        description: description,
        building: building,
        block: block,
        specificArea: specificArea,
        photoUrl: photoUrl,
        photoPublicId: photoPublicId,
      );

      final privateReporter = IncidentPrivateReporter(
        createdBy: uid,
        reporterEmail: reporterEmail,
        reporterName: reporterName,
      );

      final repository = ref.read(incidentRepositoryProvider);
      final incidentId = await repository.submitIncident(
        incident: incident,
        privateReporter: privateReporter,
      );

      state = state.copyWith(
        status: IncidentSubmissionStatus.success,
        submittedIncidentId: incidentId,
      );
      return true;
    } on Exception catch (e) {
      final message = _mapFirestoreError(e);
      state = state.copyWith(
        status: IncidentSubmissionStatus.error,
        errorMessage: message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: IncidentSubmissionStatus.error,
        errorMessage: 'Submission failed due to an unexpected error. Please try again.',
      );
      return false;
    }
  }

  /// Resets the controller back to its initial state.
  void reset() {
    state = const IncidentSubmissionState();
  }

  String _mapFirestoreError(Exception error) {
    final str = error.toString().toLowerCase();

    if (str.contains('permission-denied') ||
        str.contains('insufficient permissions')) {
      return 'Permission denied. Please ensure your account is verified and try again.';
    }
    if (str.contains('unauthenticated')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (str.contains('network') ||
        str.contains('socketexception') ||
        str.contains('unavailable')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (str.contains('timeout')) {
      return 'The request timed out. Please check your connection and try again.';
    }

    return 'Failed to submit the report. Please try again.';
  }
}

