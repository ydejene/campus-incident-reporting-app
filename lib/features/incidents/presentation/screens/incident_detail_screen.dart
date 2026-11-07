import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../application/incident_detail_controller.dart';
import '../../domain/models/incident.dart';
import '../../domain/models/incident_status_history.dart';

/// Screen displaying the complete information and status timeline of an incident.
///
/// Reusable from both Browse and My Reports destinations.
class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({
    super.key,
    required this.incidentId,
  });

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(incidentDetailProvider(incidentId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(
          variant: LogoVariant.fullHorizontal,
          height: 28,
        ),
      ),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.accent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load incident',
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(incidentDetailProvider(incidentId)),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => _IncidentDetailContent(
            incident: data.incident,
            statusHistory: data.statusHistory,
          ),
        ),
      ),
    );
  }
}

class _IncidentDetailContent extends StatelessWidget {
  const _IncidentDetailContent({
    required this.incident,
    required this.statusHistory,
  });

  final Incident incident;
  final List<IncidentStatusHistory> statusHistory;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasPhoto = incident.photoUrl != null && incident.photoUrl!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Category and Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  incident.category.label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              StatusBadge(status: incident.status, showIcon: true),
            ],
          ),
          const SizedBox(height: 16),

          // Incident Photograph (if attached)
          if (hasPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                width: double.infinity,
                color: AppColors.background,
                child: Image.network(
                  incident.photoUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      color: AppColors.background,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 140,
                      color: AppColors.background,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load incident photo',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Description Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident.description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Location Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Details',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.apartment_outlined,
                    label: 'Building',
                    value: incident.building,
                  ),
                  if (incident.block.trim().isNotEmpty) ...[
                    const Divider(height: 16),
                    _DetailRow(
                      icon: Icons.grid_view_outlined,
                      label: 'Block / Wing',
                      value: 'Block ${incident.block}',
                    ),
                  ],
                  const Divider(height: 16),
                  _DetailRow(
                    icon: Icons.place_outlined,
                    label: 'Specific Area',
                    value: incident.specificArea,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filing Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submission Information',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Submitted on',
                    value: DateTimeUtils.formatDateTime(incident.createdAt),
                  ),
                  const Divider(height: 16),
                  _DetailRow(
                    icon: Icons.update_outlined,
                    label: 'Last updated',
                    value: DateTimeUtils.formatDateTime(incident.updatedAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Status History Timeline
          Text(
            'Status History',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          if (statusHistory.isEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No status changes recorded yet. This incident is currently submitted and awaiting initial staff review.',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (int i = 0; i < statusHistory.length; i++) ...[
                      _TimelineTile(
                        history: statusHistory[i],
                        isLatest: i == statusHistory.length - 1,
                        isLast: i == statusHistory.length - 1,
                      ),
                      if (i < statusHistory.length - 1)
                        const Divider(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          // Privacy note
          Row(
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reporter identity and contact information remain private in campus-wide incident browsing.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.history,
    required this.isLatest,
    required this.isLast,
  });

  final IncidentStatusHistory history;
  final bool isLatest;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge(status: history.newStatus, showIcon: true),
            const SizedBox(width: 8),
            if (isLatest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Latest update',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              DateTimeUtils.formatDate(history.timestamp),
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          DateTimeUtils.formatDateTime(history.timestamp),
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        if (history.remarks != null && history.remarks!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.comment_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    history.remarks!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

