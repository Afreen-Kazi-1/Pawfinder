import 'pet_image_model.dart';

class PetReportModel {
  final String id;
  final String userId;
  final String reportType; // 'LOST' or 'FOUND'
  final String? petName;
  final String animalType;
  final String? breed;
  final String color;
  final String? gender;
  final String? approximateAge;
  final String distinguishingFeatures;
  final String description;
  final double latitude;
  final double longitude;
  final String locationLabel;
  final DateTime eventDatetime;
  final double? reward;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PetImageModel> images;

  const PetReportModel({
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
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    required this.eventDatetime,
    this.reward,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
  });

  bool get isLost => reportType.toUpperCase() == 'LOST';
  bool get isFound => reportType.toUpperCase() == 'FOUND';
  bool get isOpen => status == 'Open';

  static double? _asDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  factory PetReportModel.fromJson(Map<String, dynamic> json) {
    var rawImages = json['images'];
    List<PetImageModel> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages
          .map((img) => PetImageModel.fromJson(img as Map<String, dynamic>))
          .toList();
    }

    return PetReportModel(
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
      latitude: _asDouble(json['latitude']) ?? 0.0,
      longitude: _asDouble(json['longitude']) ?? 0.0,
      locationLabel: json['location_label'] as String,
      eventDatetime: DateTime.parse(json['event_datetime'] as String),
      reward: _asDouble(json['reward']),
      status: json['status'] as String? ?? 'Open',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      images: parsedImages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'report_type': reportType,
      'pet_name': petName,
      'animal_type': animalType,
      'breed': breed,
      'color': color,
      'gender': gender,
      'approximate_age': approximateAge,
      'distinguishing_features': distinguishingFeatures,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location_label': locationLabel,
      'event_datetime': eventDatetime.toIso8601String(),
      'reward': reward,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'images': images.map((img) => img.toJson()).toList(),
    };
  }

  PetReportModel copyWith({
    String? id,
    String? userId,
    String? reportType,
    String? petName,
    String? animalType,
    String? breed,
    String? color,
    String? gender,
    String? approximateAge,
    String? distinguishingFeatures,
    String? description,
    double? latitude,
    double? longitude,
    String? locationLabel,
    DateTime? eventDatetime,
    double? reward,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PetImageModel>? images,
  }) {
    return PetReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reportType: reportType ?? this.reportType,
      petName: petName ?? this.petName,
      animalType: animalType ?? this.animalType,
      breed: breed ?? this.breed,
      color: color ?? this.color,
      gender: gender ?? this.gender,
      approximateAge: approximateAge ?? this.approximateAge,
      distinguishingFeatures: distinguishingFeatures ?? this.distinguishingFeatures,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      eventDatetime: eventDatetime ?? this.eventDatetime,
      reward: reward ?? this.reward,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
    );
  }
}

