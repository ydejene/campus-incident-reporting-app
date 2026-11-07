import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/datetime_utils.dart';
import 'incident_category.dart';
import 'incident_status.dart';

class Incident {
  const Incident({
    required this.id,
    required this.description,
    required this.category,
    required this.building,
    required this.block,
    required this.specificArea,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.photoUrl,
    this.photoPublicId,
  });

  final String id;
  final String description;
  final IncidentCategory category;
  final String building;
  final String block;
  final String specificArea;
  final String createdBy;
  final IncidentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;
  final String? photoUrl;
  final String? photoPublicId;

  String get formattedLocation {
    if (block.trim().isEmpty) {
      return '$building, $specificArea';
    }
    return '$building, Block $block, $specificArea';
  }

  factory Incident.fromMap(Map<String, dynamic> map, {String? id}) {
    return Incident(
      id: id ?? (map['id'] as String? ?? ''),
      description: map['description'] as String? ?? '',
      category: IncidentCategory.fromString(map['category'] as String?),
      building: map['building'] as String? ?? '',
      block: map['block'] as String? ?? '',
      specificArea: map['specificArea'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      status: IncidentStatus.fromString(map['status'] as String?),
      createdAt: DateTimeUtils.toDateTime(map['createdAt']),
      updatedAt: DateTimeUtils.toDateTime(map['updatedAt']),
      title: map['title'] as String?,
      photoUrl: map['photoUrl'] as String?,
      photoPublicId: map['photoPublicId'] as String?,
    );
  }

  factory Incident.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Incident.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'category': category.value,
      'building': building,
      'block': block,
      'specificArea': specificArea,
      'createdBy': createdBy,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (title != null) 'title': title,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoPublicId != null) 'photoPublicId': photoPublicId,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'category': category.value,
      'building': building,
      'block': block,
      'specificArea': specificArea,
      'createdBy': createdBy,
      'status': status.value,
      'createdAt': DateTimeUtils.toTimestamp(createdAt),
      'updatedAt': DateTimeUtils.toTimestamp(updatedAt),
      if (title != null) 'title': title,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoPublicId != null) 'photoPublicId': photoPublicId,
    };
  }

  Incident copyWith({
    String? id,
    String? description,
    IncidentCategory? category,
    String? building,
    String? block,
    String? specificArea,
    String? createdBy,
    IncidentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    String? photoUrl,
    String? photoPublicId,
  }) {
    return Incident(
      id: id ?? this.id,
      description: description ?? this.description,
      category: category ?? this.category,
      building: building ?? this.building,
      block: block ?? this.block,
      specificArea: specificArea ?? this.specificArea,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPublicId: photoPublicId ?? this.photoPublicId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Incident &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          description == other.description &&
          category == other.category &&
          building == other.building &&
          block == other.block &&
          specificArea == other.specificArea &&
          createdBy == other.createdBy &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          title == other.title &&
          photoUrl == other.photoUrl &&
          photoPublicId == other.photoPublicId;

  @override
  int get hashCode =>
      id.hashCode ^
      description.hashCode ^
      category.hashCode ^
      building.hashCode ^
      block.hashCode ^
      specificArea.hashCode ^
      createdBy.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      title.hashCode ^
      photoUrl.hashCode ^
      photoPublicId.hashCode;
}

