import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/match_model.dart';

abstract class MatchRepository {
  Future<List<MatchModel>> getMyMatches({String? status, int page = 1, int size = 20});
  Future<MatchModel> getMatchDetail(String id);
  Future<MatchModel> updateMatchStatus(String id, String newStatus);
}

class MatchRepositoryImpl implements MatchRepository {
  final ApiClient apiClient;

  MatchRepositoryImpl({required this.apiClient});

  @override
  Future<List<MatchModel>> getMyMatches({String? status, int page = 1, int size = 20}) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await apiClient.get(
      ApiConstants.matches,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MatchModel> getMatchDetail(String id) async {
    final response = await apiClient.get('${ApiConstants.matches}/$id');
    return MatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MatchModel> updateMatchStatus(String id, String newStatus) async {
    final response = await apiClient.patch(
      '${ApiConstants.matches}/$id/status',
      data: {'status': newStatus},
    );
    return MatchModel.fromJson(response.data as Map<String, dynamic>);
  }
}

