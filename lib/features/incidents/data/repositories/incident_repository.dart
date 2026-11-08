import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/domain/models/staff_dashboard_statistics.dart';
import '../../domain/models/incident.dart';
import '../../domain/models/incident_private_reporter.dart';
import '../../domain/models/incident_status.dart';
import '../../domain/models/incident_category.dart';
import '../../domain/models/incident_status_history.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(firestore: FirebaseFirestore.instance);
});

/// Represents a single page of incidents with pagination metadata.
class IncidentPage {
  const IncidentPage({
    required this.incidents,
    this.lastDocument,
    required this.hasMore,
  });

  final List<Incident> incidents;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

/// Handles all Firestore persistence and retrieval for incident documents.
///
/// The public incident document does not contain private reporter contact
/// information. Reporter identity is stored in the separate
/// `incidents/{id}/private/reporter` sub-document, accessible only to
/// the reporter and authorized staff.
class IncidentRepository {
  IncidentRepository({required this.firestore});

  final FirebaseFirestore firestore;

  static const String _incidentsCollection = 'incidents';
  static const String _statusHistoryCollection = 'status_history';

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

    final incidentRef =
        firestore.collection(_incidentsCollection).doc();

    batch.set(incidentRef, incident.toFirestore());

    final privateRef = incidentRef.collection('private').doc('reporter');
    batch.set(privateRef, privateReporter.toFirestore());

    await batch.commit();

    return incidentRef.id;
  }

  /// Fetches a page of public campus-wide incidents, ordered newest first.
  ///
  /// Supports cursor-based pagination using [startAfter].
  Future<IncidentPage> fetchRecentIncidents({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = firestore
        .collection(_incidentsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final incidents = snapshot.docs
        .map((doc) => Incident.fromFirestore(doc))
        .toList();

    return IncidentPage(
      incidents: incidents,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
  }

  /// Returns all incidents submitted by [uid], ordered newest first.
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

  /// Fetches a single incident record by document [incidentId].
  Future<Incident?> fetchIncidentById(String incidentId) async {
    final doc =
        await firestore.collection(_incidentsCollection).doc(incidentId).get();
    if (!doc.exists) {
      return null;
    }
    return Incident.fromFirestore(doc);
  }

  /// Fetches the chronological status history for an incident.
  ///
  /// Ordered chronologically (oldest to newest) to display lifecycle progression.
  Future<List<IncidentStatusHistory>> fetchStatusHistory(
      String incidentId) async {
    final snapshot = await firestore
        .collection(_incidentsCollection)
        .doc(incidentId)
        .collection(_statusHistoryCollection)
        .orderBy('timestamp', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => IncidentStatusHistory.fromFirestore(doc))
        .toList();
  }

  /// Fetches aggregate counts of incidents across campus for the staff overview.
  ///
  /// Uses Firestore aggregation queries (`count().get()`) to guarantee accurate
  /// campus-wide counts without downloading complete document bodies.
  Future<StaffDashboardStatistics> fetchIncidentStatistics() async {
    final collection = firestore.collection(_incidentsCollection);

    final totalQuery = collection.count().get();
    final submittedQuery = collection
        .where('status', isEqualTo: IncidentStatus.submitted.value)
        .count()
        .get();
    final inProgressQuery = collection
        .where('status', isEqualTo: IncidentStatus.inProgress.value)
        .count()
        .get();
    final resolvedQuery = collection
        .where('status', isEqualTo: IncidentStatus.resolved.value)
        .count()
        .get();

    final results = await Future.wait([
      totalQuery,
      submittedQuery,
      inProgressQuery,
      resolvedQuery,
    ]);

    return StaffDashboardStatistics(
      totalIncidents: results[0].count ?? 0,
      submittedIncidents: results[1].count ?? 0,
      inProgressIncidents: results[2].count ?? 0,
      resolvedIncidents: results[3].count ?? 0,
    );
  }

  /// Fetches private reporter contact information if available and authorized.
  Future<IncidentPrivateReporter?> fetchPrivateReporter(
      String incidentId) async {
    final doc = await firestore
        .collection(_incidentsCollection)
        .doc(incidentId)
        .collection('private')
        .doc('reporter')
        .get();

    if (!doc.exists) {
      return null;
    }
    return IncidentPrivateReporter.fromFirestore(doc);
  }

  /// Atomically updates the incident status and creates an audit status-history
  /// document within a single Firestore batch write.
  ///
  /// Enforces atomic write consistency: neither the status update nor the
  /// history entry will be saved independently if the other fails.
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus previousStatus,
    required IncidentStatus newStatus,
    required String staffUid,
    String? staffDisplayName,
    String? remarks,
  }) async {
    final batch = firestore.batch();
    final incidentRef =
        firestore.collection(_incidentsCollection).doc(incidentId);

    final now = DateTime.now();

    batch.update(incidentRef, {
      'status': newStatus.value,
      'updatedAt': Timestamp.fromDate(now),
    });

    final historyRef =
        incidentRef.collection(_statusHistoryCollection).doc();

    final historyData = <String, dynamic>{
      'previousStatus': previousStatus.value,
      'newStatus': newStatus.value,
      'updatedBy': staffUid,
      if (staffDisplayName != null && staffDisplayName.trim().isNotEmpty)
        'updatedByName': staffDisplayName.trim(),
      'timestamp': Timestamp.fromDate(now),
      if (remarks != null && remarks.trim().isNotEmpty)
        'remarks': remarks.trim(),
    };

    batch.set(historyRef, historyData);

    await batch.commit();
  }

  /// Builds an [Incident] ready for initial submission.
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
