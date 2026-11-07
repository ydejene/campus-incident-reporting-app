import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/datetime_utils.dart';
import 'incident_status.dart';

class IncidentStatusHistory {
  const IncidentStatusHistory({
    required this.id,
    required this.newStatus,
    required this.updatedBy,
    required this.timestamp,
    this.previousStatus,
    this.remarks,
  });

  final String id;
  final IncidentStatus? previousStatus;
  final IncidentStatus newStatus;
  final String updatedBy;
  final DateTime timestamp;
  final String? remarks;

  factory IncidentStatusHistory.fromMap(Map<String, dynamic> map, {String? id}) {
    return IncidentStatusHistory(
      id: id ?? (map['id'] as String? ?? ''),
      previousStatus: map['previousStatus'] != null
          ? IncidentStatus.fromString(map['previousStatus'] as String?)
          : null,
      newStatus: IncidentStatus.fromString(map['newStatus'] as String?),
      updatedBy: map['updatedBy'] as String? ?? '',
      timestamp: DateTimeUtils.toDateTime(map['timestamp']),
      remarks: map['remarks'] as String?,
    );
  }

  factory IncidentStatusHistory.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return IncidentStatusHistory.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (previousStatus != null) 'previousStatus': previousStatus!.value,
      'newStatus': newStatus.value,
      'updatedBy': updatedBy,
      'timestamp': timestamp.toIso8601String(),
      if (remarks != null) 'remarks': remarks,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (previousStatus != null) 'previousStatus': previousStatus!.value,
      'newStatus': newStatus.value,
      'updatedBy': updatedBy,
      'timestamp': DateTimeUtils.toTimestamp(timestamp),
      if (remarks != null) 'remarks': remarks,
    };
  }

  IncidentStatusHistory copyWith({
    String? id,
    IncidentStatus? previousStatus,
    IncidentStatus? newStatus,
    String? updatedBy,
    DateTime? timestamp,
    String? remarks,
  }) {
    return IncidentStatusHistory(
      id: id ?? this.id,
      previousStatus: previousStatus ?? this.previousStatus,
      newStatus: newStatus ?? this.newStatus,
      updatedBy: updatedBy ?? this.updatedBy,
      timestamp: timestamp ?? this.timestamp,
      remarks: remarks ?? this.remarks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncidentStatusHistory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          previousStatus == other.previousStatus &&
          newStatus == other.newStatus &&
          updatedBy == other.updatedBy &&
          timestamp == other.timestamp &&
          remarks == other.remarks;

  @override
  int get hashCode =>
      id.hashCode ^
      previousStatus.hashCode ^
      newStatus.hashCode ^
      updatedBy.hashCode ^
      timestamp.hashCode ^
      remarks.hashCode;
}

