import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum IncidentStatus {
  submitted('Submitted'),
  underReview('Under Review'),
  inProgress('In Progress'),
  resolved('Resolved'),
  rejected('Rejected');

  const IncidentStatus(this.label);
  final String label;
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  final IncidentStatus status;

  Color get _backgroundColor {
    switch (status) {
      case IncidentStatus.submitted:
        return AppColors.statusSubmittedBg;
      case IncidentStatus.underReview:
        return AppColors.statusUnderReviewBg;
      case IncidentStatus.inProgress:
        return AppColors.statusInProgressBg;
      case IncidentStatus.resolved:
        return AppColors.statusResolvedBg;
      case IncidentStatus.rejected:
        return AppColors.statusRejectedBg;
    }
  }

  Color get _textColor {
    switch (status) {
      case IncidentStatus.submitted:
        return AppColors.statusSubmittedText;
      case IncidentStatus.underReview:
        return AppColors.statusUnderReviewText;
      case IncidentStatus.inProgress:
        return AppColors.statusInProgressText;
      case IncidentStatus.resolved:
        return AppColors.statusResolvedText;
      case IncidentStatus.rejected:
        return AppColors.statusRejectedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

