import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../authentication/providers/auth_provider.dart';
import '../data/report_repository.dart';
import '../models/pet_report_model.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ReportRepositoryImpl(apiClient: client);
});

class ReportSubmissionState {
  final bool isSubmitting;
  final String? errorMessage;
  final PetReportModel? createdReport;

  const ReportSubmissionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.createdReport,
  });

  bool get hasError => errorMessage != null;
  bool get isSuccess => createdReport != null;
}

class ReportSubmissionNotifier extends Notifier<ReportSubmissionState> {
  late final ReportRepository _repository;

  @override
  ReportSubmissionState build() {
    _repository = ref.watch(reportRepositoryProvider);
    return const ReportSubmissionState();
  }

  Future<bool> submitReport({
    required Map<String, dynamic> reportData,
    List<XFile>? images,
  }) async {
    state = const ReportSubmissionState(isSubmitting: true);
    try {
      final report = await _repository.createReport(
        reportData: reportData,
        images: images,
      );
      if (!ref.mounted) return true;
      state = ReportSubmissionState(isSubmitting: false, createdReport: report);
      // Invalidate myReports to refresh the user's report list
      ref.invalidate(myReportsProvider);
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = ReportSubmissionState(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  void reset() {
    state = const ReportSubmissionState();
  }
}

final reportSubmissionProvider =
    NotifierProvider<ReportSubmissionNotifier, ReportSubmissionState>(
  ReportSubmissionNotifier.new,
);

class MyReportsFilter {
  final String? reportType;
  final String? status;

  const MyReportsFilter({this.reportType, this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyReportsFilter &&
          runtimeType == other.runtimeType &&
          reportType == other.reportType &&
          status == other.status;

  @override
  int get hashCode => reportType.hashCode ^ status.hashCode;
}

class MyReportsFilterNotifier extends Notifier<MyReportsFilter> {
  @override
  MyReportsFilter build() => const MyReportsFilter();

  void setFilter(MyReportsFilter filter) => state = filter;
}

final myReportsFilterProvider =
    NotifierProvider<MyReportsFilterNotifier, MyReportsFilter>(MyReportsFilterNotifier.new);

final myReportsProvider = FutureProvider<List<PetReportModel>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(myReportsFilterProvider);
  return await repo.getMyReports(
    reportType: filter.reportType,
    status: filter.status,
  );
});

