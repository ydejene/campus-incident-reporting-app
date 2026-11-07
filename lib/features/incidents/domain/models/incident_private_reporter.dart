import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentPrivateReporter {
  const IncidentPrivateReporter({
    required this.createdBy,
    required this.reporterEmail,
    this.reporterName,
  });

  final String createdBy;
  final String reporterEmail;
  final String? reporterName;

  factory IncidentPrivateReporter.fromMap(Map<String, dynamic> map) {
    return IncidentPrivateReporter(
      createdBy: map['createdBy'] as String? ?? '',
      reporterEmail: map['reporterEmail'] as String? ?? '',
      reporterName: map['reporterName'] as String?,
    );
  }

  factory IncidentPrivateReporter.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return IncidentPrivateReporter.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'createdBy': createdBy,
      'reporterEmail': reporterEmail,
      if (reporterName != null) 'reporterName': reporterName,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdBy': createdBy,
      'reporterEmail': reporterEmail,
      if (reporterName != null) 'reporterName': reporterName,
    };
  }

  IncidentPrivateReporter copyWith({
    String? createdBy,
    String? reporterEmail,
    String? reporterName,
  }) {
    return IncidentPrivateReporter(
      createdBy: createdBy ?? this.createdBy,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      reporterName: reporterName ?? this.reporterName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncidentPrivateReporter &&
          runtimeType == other.runtimeType &&
          createdBy == other.createdBy &&
          reporterEmail == other.reporterEmail &&
          reporterName == other.reporterName;

  @override
  int get hashCode =>
      createdBy.hashCode ^
      reporterEmail.hashCode ^
      (reporterName?.hashCode ?? 0);
}

