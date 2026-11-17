import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/providers/auth_provider.dart';
import '../data/moderation_repository.dart';
import '../models/abuse_report_model.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ModerationRepository(apiClient);
});

class ModerationState {
  final bool isLoading;
  final String? errorMessage;
  final List<AbuseReportModel> reports;
  final String? statusFilter;

  const ModerationState({
    this.isLoading = false,
    this.errorMessage,
    this.reports = const [],
    this.statusFilter,
  });

  ModerationState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<AbuseReportModel>? reports,
    String? statusFilter,
    bool clearFilter = false,
  }) {
    return ModerationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      reports: reports ?? this.reports,
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class ModerationNotifier extends Notifier<ModerationState> {
  late final ModerationRepository _repository;

  @override
  ModerationState build() {
    _repository = ref.watch(moderationRepositoryProvider);
    return const ModerationState();
  }

  void setFilter(String? status) {
    state = state.copyWith(statusFilter: status, clearFilter: status == null);
    loadReports();
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getAdminAbuseReports(status: state.statusFilter);
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, reports: list);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      final updated = await _repository.updateReportStatusAdmin(id: id, status: status);
      if (!ref.mounted) return true;
      state = state.copyWith(
        reports: state.reports.map((r) => r.id == id ? updated : r).toList(),
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final moderationProvider =
    NotifierProvider<ModerationNotifier, ModerationState>(() {
  return ModerationNotifier();
});

