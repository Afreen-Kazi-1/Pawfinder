import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../providers/discovery_provider.dart';
import '../widgets/pet_report_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'public_report_detail_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(discoveryProvider.notifier).loadMore();
    }
  }

  void _openFilters() {
    final currentFilters = ref.read(discoveryProvider).filters;
    FilterBottomSheet.show(
      context,
      initialFilters: currentFilters,
      onApply: (updated) {
        ref.read(discoveryProvider.notifier).applyFilters(updated);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryProvider);
    final filters = state.filters;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Discover Pets'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filters.hasActiveFilters,
              child: const Icon(Icons.filter_list_rounded),
            ),
            tooltip: 'Filter & Sort',
            onPressed: _openFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search pets by name, breed, keywords...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(discoveryProvider.notifier).updateSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onSubmitted: (query) {
                      ref.read(discoveryProvider.notifier).updateSearch(query);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Quick Filter Segmented Buttons (All / Lost / Found)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildQuickTab(label: 'All', value: null, current: filters.reportType),
                const SizedBox(width: 8),
                _buildQuickTab(label: 'Lost Pets', value: 'LOST', current: filters.reportType),
                const SizedBox(width: 8),
                _buildQuickTab(label: 'Found Pets', value: 'FOUND', current: filters.reportType),
              ],
            ),
          ),

          // Active Filter Chips (if any)
          if (filters.hasActiveFilters) _buildActiveFilterChips(filters),

          const SizedBox(height: 4),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(discoveryProvider.notifier).refresh(),
              child: _buildBody(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DiscoveryState state) {
    if (state.isLoading) {
      return const Center(child: LoadingIndicator(message: 'Loading pet discoveries...'));
    }

    if (state.errorMessage != null && state.reports.isEmpty) {
      return Center(
        child: ErrorDisplay(
          message: state.errorMessage!,
          onRetry: () => ref.read(discoveryProvider.notifier).refresh(),
        ),
      );
    }

    if (state.reports.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          title: 'No reports found',
          message: 'Try adjusting your search criteria or removing active filters to see more results.',
          icon: Icons.search_off_rounded,
          actionText: 'Reset Filters',
          onAction: () {
            _searchController.clear();
            ref.read(discoveryProvider.notifier).clearFilters();
          },
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.reports.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.reports.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final report = state.reports[index];
        return PetReportCard(
          report: report,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicReportDetailScreen(report: report),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickTab({
    required String label,
    required String? value,
    required String? current,
  }) {
    final isSelected = current == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(discoveryProvider.notifier).updateReportType(value);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips(DiscoveryFilterState filters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (filters.animalType != null)
            _buildRemovableChip(
              label: 'Animal: ${filters.animalType}',
              onDeleted: () {
                ref.read(discoveryProvider.notifier).applyFilters(
                      filters.copyWith(clearAnimalType: true),
                    );
              },
            ),
          if (filters.breed != null && filters.breed!.isNotEmpty)
            _buildRemovableChip(
              label: 'Breed: ${filters.breed}',
              onDeleted: () {
                ref.read(discoveryProvider.notifier).applyFilters(
                      filters.copyWith(clearBreed: true),
                    );
              },
            ),
          if (filters.color != null && filters.color!.isNotEmpty)
            _buildRemovableChip(
              label: 'Color: ${filters.color}',
              onDeleted: () {
                ref.read(discoveryProvider.notifier).applyFilters(
                      filters.copyWith(clearColor: true),
                    );
              },
            ),
          if (filters.search != null && filters.search!.isNotEmpty)
            _buildRemovableChip(
              label: 'Query: "${filters.search}"',
              onDeleted: () {
                _searchController.clear();
                ref.read(discoveryProvider.notifier).applyFilters(
                      filters.copyWith(clearSearch: true),
                    );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRemovableChip({required String label, required VoidCallback onDeleted}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onDeleted,
        visualDensity: VisualDensity.compact,
        backgroundColor: AppColors.surfaceVariant,
      ),
    );
  }
}

