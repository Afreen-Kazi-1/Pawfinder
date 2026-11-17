import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/providers/auth_provider.dart';
import '../data/match_repository.dart';
import '../models/match_model.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return MatchRepositoryImpl(apiClient: client);
});

class MatchesState {
  final bool isLoading;
  final String? errorMessage;
  final List<MatchModel> matches;
  final String?
  activeFilter; // null (all), 'Suggested', 'Relevant', 'Dismissed', 'Resolved'

  const MatchesState({
    this.isLoading = false,
    this.errorMessage,
    this.matches = const [],
    this.activeFilter,
  });

  List<MatchModel> get filteredMatches => activeFilter == null
      ? matches
      : matches
            .where(
              (match) =>
                  match.status.toLowerCase() == activeFilter!.toLowerCase(),
            )
            .toList();

  MatchesState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<MatchModel>? matches,
    String? activeFilter,
    bool clearFilter = false,
  }) {
    return MatchesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      matches: matches ?? this.matches,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
    );
  }
}

class MatchesNotifier extends Notifier<MatchesState> {
  late final MatchRepository _repo;

  @override
  MatchesState build() {
    _repo = ref.watch(matchRepositoryProvider);
    Future.microtask(() => loadMatches());
    return const MatchesState(isLoading: true);
  }

  Future<void> loadMatches() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final items = await _repo.getMyMatches();
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, matches: items);
    } catch (e, st) {
      debugPrint('[MatchesProvider] loadMatches error: $e\n$st');
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateStatus(String matchId, String newStatus) async {
    try {
      final updated = await _repo.updateMatchStatus(matchId, newStatus);
      if (!ref.mounted) return;
      final updatedList = state.matches
          .map((m) => m.id == matchId ? updated : m)
          .toList();
      state = state.copyWith(matches: updatedList);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void setFilter(String? status) {
    state = state.copyWith(activeFilter: status, clearFilter: status == null);
  }

  Future<void> refresh() async {
    await loadMatches();
  }
}

final matchesProvider = NotifierProvider<MatchesNotifier, MatchesState>(
  MatchesNotifier.new,
);
