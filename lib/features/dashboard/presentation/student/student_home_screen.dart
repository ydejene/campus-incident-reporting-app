import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../incidents/application/recent_campus_incidents_provider.dart';
import '../../../incidents/presentation/widgets/incident_card.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    final displayName = authState.profile?.displayName.trim().isNotEmpty == true
        ? authState.profile!.displayName.trim()
        : (authState.user?.displayName?.trim().isNotEmpty == true
            ? authState.user!.displayName!.trim()
            : 'ALU Student');

    final isDefault = displayName == 'ALU Student';
    final greetingName = isDefault ? displayName : displayName.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(
          variant: LogoVariant.fullHorizontal,
          height: 28,
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            onPressed: () => context.go('/student/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $greetingName',
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Report campus facility or safety issues, track maintenance progress in real time, and help keep ALU campus functional.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prominent Action Card: Report an Issue
              Card(
                color: AppColors.primary,
                child: InkWell(
                  onTap: () => context.go('/student/report'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add_alert_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Quick Report',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Report a Campus Issue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Spotted broken facilities, water leaks, power outages, or security concerns? File a report for immediate staff review.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Start report',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Navigation Shortcuts
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => context.go('/student/browse'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.statusUnderReviewBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.search_outlined,
                                  color: AppColors.statusUnderReviewText,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Browse',
                                style: textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Campus reports',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => context.go('/student/my-reports'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.statusSubmittedBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.folder_outlined,
                                  color: AppColors.statusSubmittedText,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'My Reports',
                                style: textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track your filings',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Campus Reports Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Campus Reports',
                    style: textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go('/student/browse'),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _RecentCampusReports(textTheme: textTheme),
              const SizedBox(height: 24),

              // How CampusCare Works Guidance
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How CampusCare Works',
                            style: textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _WorkflowStep(
                        step: '1',
                        title: 'Submit Report',
                        description:
                            'Select category, specify building and block, and describe the issue.',
                      ),
                      const SizedBox(height: 10),
                      _WorkflowStep(
                        step: '2',
                        title: 'Staff Review',
                        description:
                            'Authorized campus staff reviews the report and updates progress.',
                      ),
                      const SizedBox(height: 10),
                      _WorkflowStep(
                        step: '3',
                        title: 'Track Resolution',
                        description:
                            'Follow status updates and staff remarks in real time.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'CampusCare • ${AppStrings.appTagline}',
                style: textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentCampusReports extends ConsumerWidget {
  const _RecentCampusReports({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentCampusIncidentsProvider);

    return recentAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: LinearProgressIndicator()),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppColors.accent, size: 32),
              const SizedBox(height: 8),
              Text(
                'Could not load recent reports',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(recentCampusIncidentsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (incidents) {
        if (incidents.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.statusInProgressBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.inbox_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No campus reports yet',
                    style: textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No incidents have been reported on campus. Be the first to flag a facility or safety issue.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final incident in incidents)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: IncidentCard(
                  incident: incident,
                  onTap: () => context.push('/incident/${incident.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
