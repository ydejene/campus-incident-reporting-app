import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../features/incidents/domain/models/incident_status.dart';

export '../../features/incidents/domain/models/incident_status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = false,
  });

  final IncidentStatus status;
  final bool showIcon;

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

  IconData get _icon {
    switch (status) {
      case IncidentStatus.submitted:
        return Icons.inbox_outlined;
      case IncidentStatus.underReview:
        return Icons.search_outlined;
      case IncidentStatus.inProgress:
        return Icons.autorenew_outlined;
      case IncidentStatus.resolved:
        return Icons.check_circle_outlined;
      case IncidentStatus.rejected:
        return Icons.cancel_outlined;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_icon, size: 14, color: _textColor),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              color: _textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
