import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../application/staff_incidents_controller.dart';
import '../../domain/models/incident_category.dart';
import '../../domain/models/incident_status.dart';
import '../widgets/incident_card.dart';

class StaffIncidentsScreen extends ConsumerStatefulWidget {
  const StaffIncidentsScreen({super.key});

  @override
  ConsumerState<StaffIncidentsScreen> createState() =>
      _StaffIncidentsScreenState();
}

class _StaffIncidentsScreenState extends ConsumerState<StaffIncidentsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref
        .read(staffIncidentsControllerProvider.notifier)
        .setSearchQuery(value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref
        .read(staffIncidentsControllerProvider.notifier)
        .setSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffIncidentsControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final filtered = staffState.filteredIncidents;

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
              ref.read(staffIncidentsControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              // Page Header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Incident Management',
                            style: textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review campus reports, inspect details, and update resolution lifecycle.',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search input
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search description, area, building...',
                          prefixIcon: const Icon(
                            Icons.search,
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
                      const SizedBox(height: 14),

                      // Category Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: const Text('All Categories'),
                                selected: staffState.selectedCategory == null,
                                onSelected: (_) {
                                  ref
                                      .read(
                                          staffIncidentsControllerProvider
                                              .notifier)
                                      .setCategory(null);
                                },
                              ),
                            ),
                            ...IncidentCategory.values.map((cat) {
                              final isSelected =
                                  staffState.selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(cat.label),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    ref
                                        .read(
                                            staffIncidentsControllerProvider
                                                .notifier)
                                        .setCategory(cat);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: const Text('All Statuses'),
                                selected: staffState.selectedStatus == null,
                                onSelected: (_) {
                                  ref
                                      .read(
                                          staffIncidentsControllerProvider
                                              .notifier)
                                      .setStatus(null);
                                },
                              ),
                            ),
                            ...IncidentStatus.values.map((st) {
                              final isSelected =
                                  staffState.selectedStatus == st;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(st.label),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    ref
                                        .read(
                                            staffIncidentsControllerProvider
                                                .notifier)
                                        .setStatus(st);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      // Active Filter Indicator & Reset
                      if (staffState.hasActiveFilter) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Active filters applied',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(
                                        staffIncidentsControllerProvider
                                            .notifier)
                                    .clearFilters();
                              },
                              icon: const Icon(Icons.close, size: 14),
                              label: const Text('Clear filters'),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Content based on state
              if (staffState.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (staffState.status == StaffIncidentsStatus.error)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.accent,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load incidents',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          staffState.errorMessage ?? 'An error occurred',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(staffIncidentsControllerProvider.notifier)
                              .loadInitial(),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 48,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.statusInProgressBg,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.search_off_outlined,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          staffState.hasActiveFilter
                              ? 'No matching incidents'
                              : 'No campus incidents reported',
                          style: textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          staffState.hasActiveFilter
                              ? 'Try adjusting your search keywords or clearing active filters.'
                              : 'When students submit reports across campus, they will appear in this review queue.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (staffState.hasActiveFilter) ...[
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(
                                      staffIncidentsControllerProvider
                                          .notifier)
                                  .clearFilters();
                            },
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final incident = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
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

              // Pagination Load More
              if (!staffState.isLoading && staffState.hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Center(
                      child: staffState.isLoadingMore
                          ? const CircularProgressIndicator()
                          : TextButton.icon(
                              onPressed: () => ref
                                  .read(
                                      staffIncidentsControllerProvider
                                          .notifier)
                                  .loadMore(),
                              icon: const Icon(Icons.arrow_downward, size: 16),
                              label: const Text('Load More Incidents'),
                            ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

