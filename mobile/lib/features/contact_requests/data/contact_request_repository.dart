import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/contact_request_model.dart';

class ContactRequestRepository {
  final ApiClient _apiClient;

  ContactRequestRepository(this._apiClient);

  Future<ContactRequestModel> createContactRequest({
    required String reportId,
    String? message,
    String? senderContactInfo,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.contactRequests,
        data: {
          'report_id': reportId,
          if (message != null && message.isNotEmpty) 'message': message,
          if (senderContactInfo != null && senderContactInfo.isNotEmpty)
            'sender_contact_info': senderContactInfo,
        },
      );
      return ContactRequestModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<ContactRequestModel>> getContactRequests({
    String? filterType, // 'sent' or 'received'
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (filterType != null) queryParams['filter_type'] = filterType;
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.get(
        ApiConstants.contactRequests,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?) ?? [];
      return items
          .map((item) => ContactRequestModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ContactRequestModel> getContactRequestById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.contactRequests}/$id');
      return ContactRequestModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ContactRequestModel> updateStatus({
    required String id,
    required String status,
    String? receiverContactInfo,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.contactRequests}/$id/status',
        data: {
          'status': status,
          if (receiverContactInfo != null && receiverContactInfo.isNotEmpty)
            'receiver_contact_info': receiverContactInfo,
        },
      );
      return ContactRequestModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
