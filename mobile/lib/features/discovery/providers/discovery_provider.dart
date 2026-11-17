import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../reports/models/pet_report_model.dart';
import '../data/discovery_repository.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return DiscoveryRepositoryImpl(apiClient: client);
});

/// Filter state for discovery queries
class DiscoveryFilterState {
  final String? reportType; // null = all, 'LOST', 'FOUND'
  final String? animalType; // null = all, 'Dog', 'Cat', etc.
  final String? breed;
  final String? color;
  final String? search;
  final String? startDate;
  final String? endDate;
  final String sortBy;
  final String sortOrder;

  const DiscoveryFilterState({
    this.reportType,
    this.animalType,
    this.breed,
    this.color,
    this.search,
    this.startDate,
    this.endDate,
    this.sortBy = 'created_at',
    this.sortOrder = 'desc',
  });

  bool get hasActiveFilters =>
      (reportType != null && reportType!.isNotEmpty) ||
      (animalType != null && animalType!.isNotEmpty) ||
      (breed != null && breed!.isNotEmpty) ||
      (color != null && color!.isNotEmpty) ||
      (search != null && search!.isNotEmpty) ||
      (startDate != null && startDate!.isNotEmpty) ||
      (endDate != null && endDate!.isNotEmpty);

  DiscoveryFilterState copyWith({
    String? reportType,
    String? animalType,
    String? breed,
    String? color,
    String? search,
    String? startDate,
    String? endDate,
    String? sortBy,
    String? sortOrder,
    bool clearReportType = false,
    bool clearAnimalType = false,
    bool clearBreed = false,
    bool clearColor = false,
    bool clearSearch = false,
    bool clearDates = false,
  }) {
    return DiscoveryFilterState(
      reportType: clearReportType ? null : (reportType ?? this.reportType),
      animalType: clearAnimalType ? null : (animalType ?? this.animalType),
      breed: clearBreed ? null : (breed ?? this.breed),
      color: clearColor ? null : (color ?? this.color),
      search: clearSearch ? null : (search ?? this.search),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// UI state for the discovery listing
class DiscoveryState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<PetReportModel> reports;
  final int total;
  final int currentPage;
  final bool hasMore;
  final DiscoveryFilterState filters;

  const DiscoveryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.reports = const [],
    this.total = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.filters = const DiscoveryFilterState(),
  });

  DiscoveryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    List<PetReportModel>? reports,
    int? total,
    int? currentPage,
    bool? hasMore,
    DiscoveryFilterState? filters,
  }) {
    return DiscoveryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      reports: reports ?? this.reports,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filters: filters ?? this.filters,
    );
  }
}

class DiscoveryNotifier extends Notifier<DiscoveryState> {
  late final DiscoveryRepository _repo;

  @override
  DiscoveryState build() {
    _repo = ref.watch(discoveryRepositoryProvider);
    // Initial load
    Future.microtask(() => loadReports());
    return const DiscoveryState(isLoading: true);
  }

  Future<void> loadReports({DiscoveryFilterState? newFilters}) async {
    final activeFilters = newFilters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      filters: activeFilters,
    );

    try {
      final res = await _repo.discoverReports(
        reportType: activeFilters.reportType,
        animalType: activeFilters.animalType,
        breed: activeFilters.breed,
        color: activeFilters.color,
        search: activeFilters.search,
        startDate: activeFilters.startDate,
        endDate: activeFilters.endDate,
        sortBy: activeFilters.sortBy,
        sortOrder: activeFilters.sortOrder,
        page: 1,
        size: 20,
      );

      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        reports: res.items,
        total: res.total,
        currentPage: 1,
        hasMore: res.hasMore,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final res = await _repo.discoverReports(
        reportType: state.filters.reportType,
        animalType: state.filters.animalType,
        breed: state.filters.breed,
        color: state.filters.color,
        search: state.filters.search,
        startDate: state.filters.startDate,
        endDate: state.filters.endDate,
        sortBy: state.filters.sortBy,
        sortOrder: state.filters.sortOrder,
        page: nextPage,
        size: 20,
      );

      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        reports: [...state.reports, ...res.items],
        total: res.total,
        currentPage: nextPage,
        hasMore: res.hasMore,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void updateSearch(String query) {
    final newFilters = state.filters.copyWith(search: query.trim());
    loadReports(newFilters: newFilters);
  }

  void updateReportType(String? reportType) {
    final newFilters = state.filters.copyWith(
      reportType: reportType,
      clearReportType: reportType == null,
    );
    loadReports(newFilters: newFilters);
  }

  void applyFilters(DiscoveryFilterState filters) {
    loadReports(newFilters: filters);
  }

  void clearFilters() {
    loadReports(newFilters: const DiscoveryFilterState());
  }

  Future<void> refresh() async {
    await loadReports();
  }
}

final discoveryProvider =
    NotifierProvider<DiscoveryNotifier, DiscoveryState>(DiscoveryNotifier.new);

/// Nearby state provider for Location Discovery (Module 06)
class NearbyState {
  final bool isLoading;
  final String? errorMessage;
  final List<PublicPetReportModel> reports;
  final double currentRadiusKm;
  final double? latitude;
  final double? longitude;
  final bool permissionDenied;
  final bool serviceDisabled;

  const NearbyState({
    this.isLoading = false,
    this.errorMessage,
    this.reports = const [],
    this.currentRadiusKm = 10.0,
    this.latitude,
    this.longitude,
    this.permissionDenied = false,
    this.serviceDisabled = false,
  });

  NearbyState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<PublicPetReportModel>? reports,
    double? currentRadiusKm,
    double? latitude,
    double? longitude,
    bool? permissionDenied,
    bool? serviceDisabled,
  }) {
    return NearbyState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      reports: reports ?? this.reports,
      currentRadiusKm: currentRadiusKm ?? this.currentRadiusKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      serviceDisabled: serviceDisabled ?? this.serviceDisabled,
    );
  }
}

class NearbyNotifier extends Notifier<NearbyState> {
  late final DiscoveryRepository _repo;

  @override
  NearbyState build() {
    _repo = ref.watch(discoveryRepositoryProvider);
    return const NearbyState();
  }

  void setLocation({required double latitude, required double longitude}) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      permissionDenied: false,
      serviceDisabled: false,
    );
    loadNearby();
  }

  void setRadius(double radiusKm) {
    state = state.copyWith(currentRadiusKm: radiusKm);
    if (state.latitude != null && state.longitude != null) {
      loadNearby();
    }
  }

  void setPermissionDenied() {
    state = state.copyWith(permissionDenied: true, isLoading: false);
  }

  void setServiceDisabled() {
    state = state.copyWith(serviceDisabled: true, isLoading: false);
  }

  Future<void> loadNearby() async {
    final lat = state.latitude;
    final lng = state.longitude;
    if (lat == null || lng == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.getNearbyReports(
        latitude: lat,
        longitude: lng,
        radiusKm: state.currentRadiusKm,
      );

      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        reports: res.items,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final nearbyProvider =
    NotifierProvider<NearbyNotifier, NearbyState>(NearbyNotifier.new);

