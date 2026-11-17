import '../../../core/constants/api_constants.dart';

class PetImageModel {
  final String id;
  final String reportId;
  final String imageUrl;
  final String storagePath;
  final DateTime uploadedAt;

  const PetImageModel({
    required this.id,
    required this.reportId,
    required this.imageUrl,
    required this.storagePath,
    required this.uploadedAt,
  });

  static String resolveUrl(String rawUrl) {
    if (rawUrl.isEmpty) return rawUrl;

    final apiUri = Uri.parse(ApiConstants.baseUrl);
    final backendPath = apiUri.path.replaceFirst(RegExp(r'/api/?$'), '');
    final backendUri = apiUri.replace(path: backendPath);
    final imageUri = Uri.tryParse(rawUrl);
    if (imageUri == null) return rawUrl;

    if (imageUri.hasScheme) {
      const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
      if (localHosts.contains(imageUri.host)) {
        return imageUri
            .replace(
              scheme: backendUri.scheme,
              userInfo: backendUri.userInfo,
              host: backendUri.host,
              port: backendUri.hasPort ? backendUri.port : null,
            )
            .toString();
      }
      return imageUri.toString();
    }

    return backendUri.resolveUri(imageUri).toString();
  }

  factory PetImageModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['image_url'] as String? ?? '';
    return PetImageModel(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      imageUrl: resolveUrl(rawUrl),
      storagePath: json['storage_path'] as String? ?? '',
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'image_url': imageUrl,
      'storage_path': storagePath,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
