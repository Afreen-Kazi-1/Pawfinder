import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/abuse_report_model.dart';

class ModerationRepository {
  final ApiClient _apiClient;

  ModerationRepository(this._apiClient);

  Future<AbuseReportModel> submitAbuseReport({
    String? petReportId,
    String? reportedUserId,
    required String reason,
  }) async {
    try {
      final data = <String, dynamic>{'reason': reason};
      if (petReportId != null) data['pet_report_id'] = petReportId;
      if (reportedUserId != null) data['reported_user_id'] = reportedUserId;

      final response = await _apiClient.post(
        '/abuse-reports',
        data: data,
      );
      return AbuseReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<AbuseReportModel>> getAdminAbuseReports({
    String? status,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _apiClient.get(
        '/admin/abuse-reports',
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?) ?? [];
      return items.map((e) => AbuseReportModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AbuseReportModel> updateReportStatusAdmin({
    required String id,
    required String status,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/admin/abuse-reports/$id',
        data: {'status': status},
      );
      return AbuseReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

