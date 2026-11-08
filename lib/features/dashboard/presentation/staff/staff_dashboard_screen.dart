import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../incidents/presentation/widgets/incident_card.dart';
import '../../application/staff_dashboard_controller.dart';
import '../../domain/models/staff_dashboard_statistics.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final dashboardState = ref.watch(staffDashboardControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    final displayName = authState.profile?.displayName.trim().isNotEmpty == true
        ? authState.profile!.displayName.trim()
        : (authState.user?.displayName?.trim().isNotEmpty == true
            ? authState.user!.displayName!.trim()
            : 'Campus Staff');

    final email = authState.profile?.email ?? authState.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(
          variant: LogoVariant.fullHorizontal,
          height: 28,
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_outlined, color: AppColors.textPrimary),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(staffDashboardControllerProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Staff Identity Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: textTheme.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Staff Admin',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section Title: Campus Incident Metrics
                Text(
                  'Campus Incident Overview',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (dashboardState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (dashboardState.errorMessage != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.accent,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Unable to load incident statistics',
                            style: textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => ref
                                .read(staffDashboardControllerProvider.notifier)
                                .loadDashboard(),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _StatisticsGrid(stats: dashboardState.statistics),
                ],

                const SizedBox(height: 20),

                // Primary Action: Navigate to Full Incident Management
                Card(
                  color: AppColors.primary,
                  child: InkWell(
                    onTap: () => context.push('/staff/incidents'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.fact_check_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Manage Campus Incidents',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Review queue, filter categories, and update resolution progress.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Incidents Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Reports',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/staff/incidents'),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (dashboardState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: LinearProgressIndicator()),
                  )
                else if (dashboardState.recentIncidents.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.statusSubmittedBg,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.done_all,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No incidents reported yet',
                            style: textTheme.titleSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Campus incident reports submitted by students will appear here for staff review and management.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final incident in dashboardState.recentIncidents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: IncidentCard(
                            incident: incident,
                            onTap: () =>
                                context.push('/incident/${incident.id}'),
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 32),
                Text(
                  'CampusCare Staff Portal • ${AppStrings.appTagline}',
                  style: textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.stats});

  final StaffDashboardStatistics stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Reports',
                count: stats.totalIncidents,
                icon: Icons.format_list_bulleted,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                textColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Awaiting Review',
                count: stats.submittedIncidents,
                icon: Icons.inbox_outlined,
                backgroundColor: AppColors.statusSubmittedBg,
                textColor: AppColors.statusSubmittedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'In Progress',
                count: stats.inProgressIncidents,
                icon: Icons.timelapse_outlined,
                backgroundColor: AppColors.statusInProgressBg,
                textColor: AppColors.statusInProgressText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Resolved',
                count: stats.resolvedIncidents,
                icon: Icons.check_circle_outline,
                backgroundColor: AppColors.statusResolvedBg,
                textColor: AppColors.statusResolvedText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: textColor),
                const Spacer(),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
