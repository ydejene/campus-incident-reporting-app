import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../application/browse_incidents_controller.dart';
import '../../domain/models/incident_category.dart';
import '../../domain/models/incident_status.dart';
import '../widgets/incident_card.dart';

class StudentBrowseScreen extends ConsumerStatefulWidget {
  const StudentBrowseScreen({super.key});

  @override
  ConsumerState<StudentBrowseScreen> createState() =>
      _StudentBrowseScreenState();
}

class _StudentBrowseScreenState extends ConsumerState<StudentBrowseScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref
        .read(browseIncidentsControllerProvider.notifier)
        .setSearchQuery(value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref
        .read(browseIncidentsControllerProvider.notifier)
        .setSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final browseState = ref.watch(browseIncidentsControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final filtered = browseState.filteredIncidents;

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
              ref.read(browseIncidentsControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              // Header & Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse Campus Incidents',
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Discover and track community-reported facility, safety, and maintenance issues across ALU campus.',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Box
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText:
                              'Search description, category, building, area…',
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
                      const SizedBox(height: 12),

                      // Category Filter Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All Categories'),
                              selected: browseState.selectedCategory == null,
                              onSelected: (_) => ref
                                  .read(browseIncidentsControllerProvider.notifier)
                                  .setCategoryFilter(null),
                              selectedColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: browseState.selectedCategory == null
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: browseState.selectedCategory == null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: browseState.selectedCategory == null
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            const SizedBox(width: 8),
                            for (final cat in IncidentCategory.values) ...[
                              FilterChip(
                                label: Text(cat.label),
                                selected: browseState.selectedCategory == cat,
                                onSelected: (_) => ref
                                    .read(browseIncidentsControllerProvider
                                        .notifier)
                                    .setCategoryFilter(
                                      browseState.selectedCategory == cat
                                          ? null
                                          : cat,
                                    ),
                                selectedColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: browseState.selectedCategory == cat
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight:
                                      browseState.selectedCategory == cat
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: browseState.selectedCategory == cat
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status Filter Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All Statuses'),
                              selected: browseState.selectedStatus == null,
                              onSelected: (_) => ref
                                  .read(browseIncidentsControllerProvider.notifier)
                                  .setStatusFilter(null),
                              selectedColor:
                                  AppColors.secondary.withValues(alpha: 0.15),
                              checkmarkColor: AppColors.secondary,
                              labelStyle: TextStyle(
                                color: browseState.selectedStatus == null
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                                fontWeight: browseState.selectedStatus == null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: browseState.selectedStatus == null
                                    ? AppColors.secondary
                                    : AppColors.border,
                              ),
                            ),
                            const SizedBox(width: 8),
                            for (final status in IncidentStatus.values) ...[
                              FilterChip(
                                label: Text(status.label),
                                selected: browseState.selectedStatus == status,
                                onSelected: (_) => ref
                                    .read(browseIncidentsControllerProvider
                                        .notifier)
                                    .setStatusFilter(
                                      browseState.selectedStatus == status
                                          ? null
                                          : status,
                                    ),
                                selectedColor:
                                    AppColors.secondary.withValues(alpha: 0.15),
                                checkmarkColor: AppColors.secondary,
                                labelStyle: TextStyle(
                                  color: browseState.selectedStatus == status
                                      ? AppColors.secondary
                                      : AppColors.textPrimary,
                                  fontWeight:
                                      browseState.selectedStatus == status
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: browseState.selectedStatus == status
                                      ? AppColors.secondary
                                      : AppColors.border,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),

                      // Active Filter Bar & Counter
                      if (browseState.hasActiveFilter) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Showing ${filtered.length} of ${browseState.allIncidents.length} loaded reports',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                _clearSearch();
                                ref
                                    .read(browseIncidentsControllerProvider
                                        .notifier)
                                    .clearFilters();
                              },
                              icon: const Icon(Icons.filter_alt_off, size: 14),
                              label: const Text('Clear Filters'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Content based on state
              if (browseState.isLoading && browseState.allIncidents.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (browseState.status == BrowseIncidentsStatus.error &&
                  browseState.allIncidents.isEmpty)
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
                            'Failed to load reports',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            browseState.errorMessage ?? 'Please try again.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(browseIncidentsControllerProvider.notifier)
                                .loadInitial(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reload'),
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
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.statusUnderReviewBg,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.search_off_outlined,
                              color: AppColors.statusUnderReviewText,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            browseState.hasActiveFilter
                                ? 'No matching reports found'
                                : 'No campus incidents reported yet',
                            style: textTheme.titleSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            browseState.hasActiveFilter
                                ? 'Try adjusting your search terms or clearing the selected filters.'
                                : 'When students submit reports, they will be listed here.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (browseState.hasActiveFilter) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                _clearSearch();
                                ref
                                    .read(browseIncidentsControllerProvider
                                        .notifier)
                                    .clearFilters();
                              },
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Clear All Filters'),
                            ),
                          ],
                          if (browseState.hasMore) ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => ref
                                  .read(browseIncidentsControllerProvider
                                      .notifier)
                                  .loadMore(),
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Load More from Server'),
                            ),
                          ],
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
                            onTap: () => context.push('/incident/${incident.id}'),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),

              // Pagination Load More Controls
              if (filtered.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        if (browseState.isLoadingMore) ...[
                          const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Loading additional reports…',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ] else if (browseState.hasMore) ...[
                          OutlinedButton.icon(
                            onPressed: () => ref
                                .read(browseIncidentsControllerProvider.notifier)
                                .loadMore(),
                            icon: const Icon(Icons.arrow_downward, size: 16),
                            label: const Text('Load More Reports'),
                          ),
                        ] else ...[
                          Text(
                            'All ${browseState.allIncidents.length} loaded reports displayed',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
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
