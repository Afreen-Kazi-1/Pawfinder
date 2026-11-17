import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<NotificationListModel> getNotifications({
    bool? isRead,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      if (isRead != null) queryParams['is_read'] = isRead;

      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: queryParams,
      );
      return NotificationListModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<NotificationModel> markAsRead(String id) async {
    try {
      final response = await _apiClient.patch('${ApiConstants.notifications}/$id/read');
      return NotificationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> markAllAsRead() async {
    try {
      final response = await _apiClient.patch('${ApiConstants.notifications}/read-all');
      final data = response.data as Map<String, dynamic>;
      return data['updated_count'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

