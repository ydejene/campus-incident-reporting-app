import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../application/my_reports_controller.dart';
import '../../domain/models/incident_status.dart';
import '../widgets/incident_card.dart';

class StudentMyReportsScreen extends ConsumerStatefulWidget {
  const StudentMyReportsScreen({super.key});

  @override
  ConsumerState<StudentMyReportsScreen> createState() =>
      _StudentMyReportsScreenState();
}

class _StudentMyReportsScreenState
    extends ConsumerState<StudentMyReportsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(myReportsControllerProvider.notifier).setSearchQuery(value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(myReportsControllerProvider.notifier).setSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(myReportsControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final filtered = reportsState.filteredReports;

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(
          variant: LogoVariant.fullHorizontal,
          height: 28,
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(myReportsControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Reports',
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personal report history & tracking',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (reportsState.reports.isNotEmpty) ...[
                        // Search Box
                        TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search your reports…',
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Status Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All Statuses'),
                                selected: reportsState.selectedStatus == null,
                                onSelected: (_) => ref
                                    .read(myReportsControllerProvider.notifier)
                                    .setStatusFilter(null),
                                selectedColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: reportsState.selectedStatus == null
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight:
                                      reportsState.selectedStatus == null
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: reportsState.selectedStatus == null
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              const SizedBox(width: 8),
                              for (final status in IncidentStatus.values) ...[
                                FilterChip(
                                  label: Text(status.label),
                                  selected:
                                      reportsState.selectedStatus == status,
                                  onSelected: (_) => ref
                                      .read(
                                          myReportsControllerProvider.notifier)
                                      .setStatusFilter(
                                        reportsState.selectedStatus == status
                                            ? null
                                            : status,
                                      ),
                                  selectedColor: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  checkmarkColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: reportsState.selectedStatus == status
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontWeight:
                                        reportsState.selectedStatus == status
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                    fontSize: 12,
                                  ),
                                  side: BorderSide(
                                    color: reportsState.selectedStatus == status
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),

              // Content based on state
              if (reportsState.isLoading && reportsState.reports.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (reportsState.status == MyReportsStatus.error &&
                  reportsState.reports.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 44,
                            color: AppColors.accent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load your reports',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            reportsState.errorMessage ?? 'Please try again.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(myReportsControllerProvider.notifier)
                                .loadReports(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reload'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (reportsState.reports.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.statusInProgressBg,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.folder_open_outlined,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reports submitted yet',
                            style: textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'When you report a campus maintenance or safety issue, your submission and its live resolution timeline will appear here.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/student/report'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Report an Issue'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_outlined,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No reports match your filters',
                            style: textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try clearing the search query or status filter.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              _clearSearch();
                              ref
                                  .read(myReportsControllerProvider.notifier)
                                  .clearFilters();
                            },
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Clear Filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final incident = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: IncidentCard(
                            incident: incident,
                            onTap: () =>
                                context.push('/incident/${incident.id}'),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),

              if (filtered.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Showing ${filtered.length} of ${reportsState.reports.length} personal reports',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'CampusCare • ${AppStrings.appTagline}',
                          style: textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
