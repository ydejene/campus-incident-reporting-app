import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/incident.dart';
import '../../domain/models/incident_private_reporter.dart';
import '../../domain/models/incident_status.dart';
import '../../domain/models/incident_category.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(firestore: FirebaseFirestore.instance);
});

/// Handles all Firestore persistence for incident documents.
///
/// The public incident document does not contain private reporter contact
/// information. Reporter identity is stored in the separate
/// `incidents/{id}/private/reporter` sub-document, accessible only to
/// the reporter and authorized staff.
class IncidentRepository {
  IncidentRepository({required this.firestore});

  final FirebaseFirestore firestore;

  static const String _incidentsCollection = 'incidents';

  /// Persists a new incident and its private reporter sub-document
  /// in a single Firestore batch write.
  ///
  /// [incident] must have [IncidentStatus.submitted] as its initial status
  /// and [incident.createdBy] must match [privateReporter.createdBy].
  Future<String> submitIncident({
    required Incident incident,
    required IncidentPrivateReporter privateReporter,
  }) async {
    final batch = firestore.batch();

    // Generate a Firestore document ID for the new incident
    final incidentRef =
        firestore.collection(_incidentsCollection).doc();

    // Public incident document – no reporter contact information
    batch.set(incidentRef, incident.toFirestore());

    // Private reporter sub-document – accessible only to reporter and staff
    final privateRef = incidentRef.collection('private').doc('reporter');
    batch.set(privateRef, privateReporter.toFirestore());

    await batch.commit();

    return incidentRef.id;
  }

  /// Returns all incidents submitted by [uid], ordered by creation time
  /// (newest first).
  Future<List<Incident>> fetchIncidentsByUser(String uid) async {
    final snapshot = await firestore
        .collection(_incidentsCollection)
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Incident.fromFirestore(doc))
        .toList();
  }

  /// Builds an [Incident] ready for initial submission.
  ///
  /// The caller is responsible for setting [photoUrl] and [photoPublicId]
  /// if an image was successfully uploaded to Cloudinary beforehand.
  static Incident buildNewIncident({
    required String createdBy,
    required IncidentCategory category,
    required String description,
    required String building,
    required String block,
    required String specificArea,
    String? photoUrl,
    String? photoPublicId,
  }) {
    final now = DateTime.now();
    return Incident(
      id: '',
      description: description.trim(),
      category: category,
      building: building.trim(),
      block: block.trim(),
      specificArea: specificArea.trim(),
      createdBy: createdBy,
      status: IncidentStatus.submitted,
      createdAt: now,
      updatedAt: now,
      photoUrl: photoUrl,
      photoPublicId: photoPublicId,
    );
  }
}

