import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../reports/models/pet_report_model.dart';
import '../../reports/models/pet_image_model.dart';

/// Result wrapper for paginated discovery responses.
class DiscoveryResult {
  final List<PetReportModel> items;
  final int total;
  final int page;
  final int size;

  const DiscoveryResult({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  bool get hasMore => page * size < total;
}

/// Public report model for nearby/map queries (with privacy-conscious approximate coordinates and optional distance).
class PublicPetReportModel {
  final String id;
  final String userId;
  final String reportType;
  final String? petName;
  final String animalType;
  final String? breed;
  final String color;
  final String? gender;
  final String? approximateAge;
  final String distinguishingFeatures;
  final String description;
  final double approxLatitude;
  final double approxLongitude;
  final String locationLabel;
  final DateTime eventDatetime;
  final double? reward;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PetImageModel> images;
  final double? distanceKm;

  const PublicPetReportModel({
    required this.id,
    required this.userId,
    required this.reportType,
    this.petName,
    required this.animalType,
    this.breed,
    required this.color,
    this.gender,
    this.approximateAge,
    required this.distinguishingFeatures,
    required this.description,
    required this.approxLatitude,
    required this.approxLongitude,
    required this.locationLabel,
    required this.eventDatetime,
    this.reward,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.distanceKm,
  });

  bool get isLost => reportType.toUpperCase() == 'LOST';
  bool get isFound => reportType.toUpperCase() == 'FOUND';

  static double? _asDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  factory PublicPetReportModel.fromJson(Map<String, dynamic> json) {
    var rawImages = json['images'];
    List<PetImageModel> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages
          .map((img) => PetImageModel.fromJson(img as Map<String, dynamic>))
          .toList();
    }

    return PublicPetReportModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reportType: json['report_type'] as String,
      petName: json['pet_name'] as String?,
      animalType: json['animal_type'] as String,
      breed: json['breed'] as String?,
      color: json['color'] as String,
      gender: json['gender'] as String?,
      approximateAge: json['approximate_age'] as String?,
      distinguishingFeatures: json['distinguishing_features'] as String? ?? '',
      description: json['description'] as String? ?? '',
      approxLatitude: _asDouble(json['approx_latitude']) ?? 0.0,
      approxLongitude: _asDouble(json['approx_longitude']) ?? 0.0,
      locationLabel: json['location_label'] as String,
      eventDatetime: DateTime.parse(json['event_datetime'] as String),
      reward: _asDouble(json['reward']),
      status: json['status'] as String? ?? 'Open',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      images: parsedImages,
      distanceKm: _asDouble(json['distance_km']),
    );
  }
}

/// Paginated result wrapper for nearby public reports.
class NearbyResult {
  final List<PublicPetReportModel> items;
  final int total;
  final int page;
  final int size;

  const NearbyResult({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  bool get hasMore => page * size < total;
}

abstract class DiscoveryRepository {
  Future<DiscoveryResult> discoverReports({
    String? reportType,
    String? animalType,
    String? breed,
    String? color,
    String? search,
    String? startDate,
    String? endDate,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    int page = 1,
    int size = 20,
  });

  Future<NearbyResult> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String? reportType,
    String? animalType,
    int page = 1,
    int size = 20,
  });

  Future<List<PublicPetReportModel>> getMapReports({
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? reportType,
    String? animalType,
  });
}

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final ApiClient apiClient;

  DiscoveryRepositoryImpl({required this.apiClient});

  @override
  Future<DiscoveryResult> discoverReports({
    String? reportType,
    String? animalType,
    String? breed,
    String? color,
    String? search,
    String? startDate,
    String? endDate,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    int page = 1,
    int size = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (reportType != null && reportType.isNotEmpty) params['report_type'] = reportType;
    if (animalType != null && animalType.isNotEmpty) params['animal_type'] = animalType;
    if (breed != null && breed.isNotEmpty) params['breed'] = breed;
    if (color != null && color.isNotEmpty) params['color'] = color;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (startDate != null && startDate.isNotEmpty) params['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) params['end_date'] = endDate;

    final response = await apiClient.get(
      ApiConstants.discovery,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((e) => PetReportModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return DiscoveryResult(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      size: data['size'] as int,
    );
  }

  @override
  Future<NearbyResult> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String? reportType,
    String? animalType,
    int page = 1,
    int size = 20,
  }) async {
    final params = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
      'page': page,
      'size': size,
    };
    if (reportType != null && reportType.isNotEmpty) params['report_type'] = reportType;
    if (animalType != null && animalType.isNotEmpty) params['animal_type'] = animalType;

    final response = await apiClient.get(
      ApiConstants.discoveryNearby,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((e) => PublicPetReportModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return NearbyResult(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      size: data['size'] as int,
    );
  }

  @override
  Future<List<PublicPetReportModel>> getMapReports({
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? reportType,
    String? animalType,
  }) async {
    final params = <String, dynamic>{};
    if (latitude != null) params['latitude'] = latitude;
    if (longitude != null) params['longitude'] = longitude;
    if (radiusKm != null) params['radius_km'] = radiusKm;
    if (reportType != null && reportType.isNotEmpty) params['report_type'] = reportType;
    if (animalType != null && animalType.isNotEmpty) params['animal_type'] = animalType;

    final response = await apiClient.get(
      ApiConstants.discoveryMap,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((e) => PublicPetReportModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return items;
  }
}
