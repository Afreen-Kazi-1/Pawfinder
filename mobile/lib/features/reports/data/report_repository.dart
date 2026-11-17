import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/pet_report_model.dart';
import '../models/pet_image_model.dart';

abstract class ReportRepository {
  Future<PetReportModel> createReport({
    required Map<String, dynamic> reportData,
    List<XFile>? images,
  });

  Future<PetReportModel> getReport(String id);

  Future<List<PetReportModel>> getMyReports({
    int page = 1,
    int size = 50,
    String? reportType,
    String? status,
  });

  Future<PetReportModel> updateReport({
    required String id,
    required Map<String, dynamic> updateData,
  });

  Future<PetReportModel> updateStatus({
    required String id,
    required String newStatus,
  });

  Future<void> deleteReport(String id);

  Future<List<PetImageModel>> uploadImages({
    required String reportId,
    required List<XFile> images,
  });

  Future<void> deleteImage(String imageId);
}

class ReportRepositoryImpl implements ReportRepository {
  final ApiClient apiClient;

  ReportRepositoryImpl({required this.apiClient});

  @override
  Future<PetReportModel> createReport({
    required Map<String, dynamic> reportData,
    List<XFile>? images,
  }) async {
    final response = await apiClient.post(
      ApiConstants.reports,
      data: reportData,
    );

    final report = PetReportModel.fromJson(response.data as Map<String, dynamic>);

    // If images are provided, upload them sequentially/concurrently
    if (images != null && images.isNotEmpty) {
      try {
        final uploadedImages = await uploadImages(
          reportId: report.id,
          images: images,
        );
        return report.copyWith(images: uploadedImages);
      } catch (e, st) {
        debugPrint('[ReportRepository] Image upload failed for ${report.id}: $e\n$st');
        Error.throwWithStackTrace(
          Exception('Report was created, but photo upload failed: $e'),
          st,
        );
      }
    }

    return report;
  }

  @override
  Future<PetReportModel> getReport(String id) async {
    final response = await apiClient.get('${ApiConstants.reports}/$id');
    return PetReportModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<PetReportModel>> getMyReports({
    int page = 1,
    int size = 50,
    String? reportType,
    String? status,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (reportType != null && reportType.isNotEmpty) params['report_type'] = reportType;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await apiClient.get(
      ApiConstants.myReports,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((item) => PetReportModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PetReportModel> updateReport({
    required String id,
    required Map<String, dynamic> updateData,
  }) async {
    final response = await apiClient.put(
      '${ApiConstants.reports}/$id',
      data: updateData,
    );
    return PetReportModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PetReportModel> updateStatus({
    required String id,
    required String newStatus,
  }) async {
    final response = await apiClient.patch(
      '${ApiConstants.reports}/$id/status',
      data: {'status': newStatus},
    );
    return PetReportModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteReport(String id) async {
    await apiClient.delete('${ApiConstants.reports}/$id');
  }

  @override
  Future<List<PetImageModel>> uploadImages({
    required String reportId,
    required List<XFile> images,
  }) async {
    final formData = FormData();
    for (final img in images) {
      final bytes = await img.readAsBytes();
      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            bytes,
            filename: img.name.isNotEmpty ? img.name : 'pet_image.jpg',
            contentType: MediaType('image', _mimeSubtype(img.name)),
          ),
        ),
      );
    }

    final response = await apiClient.post(
      '${ApiConstants.reports}/$reportId/images',
      data: formData,
    );

    debugPrint('[ReportRepository] Upload images response: ${response.statusCode}');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => PetImageModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static String _mimeSubtype(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      case 'gif':
        return 'gif';
      default:
        return 'jpeg';
    }
  }

  @override
  Future<void> deleteImage(String imageId) async {
    await apiClient.delete('/images/$imageId');
  }
}
