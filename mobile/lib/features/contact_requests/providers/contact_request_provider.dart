import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/providers/auth_provider.dart';
import '../data/contact_request_repository.dart';
import '../models/contact_request_model.dart';

final contactRequestRepositoryProvider = Provider<ContactRequestRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ContactRequestRepository(apiClient);
});

enum ContactRequestTab { received, sent }

class ContactRequestsState {
  final bool isLoading;
  final String? errorMessage;
  final List<ContactRequestModel> requests;
  final ContactRequestTab activeTab;

  const ContactRequestsState({
    this.isLoading = false,
    this.errorMessage,
    this.requests = const [],
    this.activeTab = ContactRequestTab.received,
  });

  ContactRequestsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ContactRequestModel>? requests,
    ContactRequestTab? activeTab,
  }) {
    return ContactRequestsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      requests: requests ?? this.requests,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

class ContactRequestsNotifier extends Notifier<ContactRequestsState> {
  late final ContactRequestRepository _repository;

  @override
  ContactRequestsState build() {
    _repository = ref.watch(contactRequestRepositoryProvider);
    Future.microtask(() => loadRequests());
    return const ContactRequestsState();
  }

  void setTab(ContactRequestTab tab) {
    if (state.activeTab != tab) {
      state = state.copyWith(activeTab: tab);
      loadRequests();
    }
  }

  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final filterType = state.activeTab == ContactRequestTab.received ? 'received' : 'sent';
      final list = await _repository.getContactRequests(filterType: filterType);
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, requests: list);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> acceptRequest(String id, {String? receiverContactInfo}) async {
    try {
      final updated = await _repository.updateStatus(
        id: id,
        status: 'accepted',
        receiverContactInfo: receiverContactInfo,
      );
      if (!ref.mounted) return true;
      state = state.copyWith(
        requests: state.requests.map((r) => r.id == id ? updated : r).toList(),
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> rejectRequest(String id) async {
    try {
      final updated = await _repository.updateStatus(
        id: id,
        status: 'rejected',
      );
      if (!ref.mounted) return true;
      state = state.copyWith(
        requests: state.requests.map((r) => r.id == id ? updated : r).toList(),
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> cancelRequest(String id) async {
    try {
      final updated = await _repository.updateStatus(
        id: id,
        status: 'cancelled',
      );
      if (!ref.mounted) return true;
      state = state.copyWith(
        requests: state.requests.map((r) => r.id == id ? updated : r).toList(),
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final contactRequestsProvider =
    NotifierProvider<ContactRequestsNotifier, ContactRequestsState>(() {
  return ContactRequestsNotifier();
});
