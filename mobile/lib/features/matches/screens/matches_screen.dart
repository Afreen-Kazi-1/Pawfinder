import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../providers/match_provider.dart';
import '../widgets/match_card.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Potential Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(matchesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (All / Suggested / Relevant / Resolved)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    ref,
                    label: 'All',
                    value: null,
                    current: state.activeFilter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    ref,
                    label: 'Suggested',
                    value: 'Suggested',
                    current: state.activeFilter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    ref,
                    label: 'Relevant',
                    value: 'Relevant',
                    current: state.activeFilter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    ref,
                    label: 'Dismissed',
                    value: 'Dismissed',
                    current: state.activeFilter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    ref,
                    label: 'Resolved',
                    value: 'Resolved',
                    current: state.activeFilter,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Matches List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(matchesProvider.notifier).refresh(),
              child: _buildBody(context, ref, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, MatchesState state) {
    final matches = state.filteredMatches;

    if (state.isLoading && matches.isEmpty && state.matches.isEmpty) {
      return const Center(
        child: LoadingIndicator(message: 'Loading potential matches...'),
      );
    }

    if (state.errorMessage != null && state.matches.isEmpty) {
      return Center(
        child: ErrorDisplay(
          message: state.errorMessage!,
          onRetry: () => ref.read(matchesProvider.notifier).refresh(),
        ),
      );
    }

    if (matches.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          title: state.activeFilter == null
              ? 'No matches found'
              : 'No ${state.activeFilter} matches',
          message: state.activeFilter == null
              ? 'When our matching engine finds possible matches for your lost or found pets, they will appear here.'
              : 'There are no ${state.activeFilter?.toLowerCase()} matches yet. Select All to see every potential match.',
          icon: Icons.auto_awesome_outlined,
          actionText: 'Refresh',
          onAction: () => ref.read(matchesProvider.notifier).refresh(),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return MatchCard(
          match: match,
          onMarkRelevant: () {
            ref
                .read(matchesProvider.notifier)
                .updateStatus(match.id, 'Relevant');
          },
          onDismiss: () {
            ref
                .read(matchesProvider.notifier)
                .updateStatus(match.id, 'Dismissed');
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
    WidgetRef ref, {
    required String label,
    required String? value,
    required String? current,
  }) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(matchesProvider.notifier).setFilter(value);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
