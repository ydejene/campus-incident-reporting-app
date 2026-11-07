enum IncidentStatus {
  submitted('submitted', 'Submitted'),
  underReview('under_review', 'Under Review'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved'),
  rejected('rejected', 'Rejected');

  const IncidentStatus(this.value, this.label);

  final String value;
  final String label;

  static IncidentStatus fromString(String? value) {
    return IncidentStatus.values.firstWhere(
      (status) => status.value == value || status.name == value,
      orElse: () => IncidentStatus.submitted,
    );
  }
}

