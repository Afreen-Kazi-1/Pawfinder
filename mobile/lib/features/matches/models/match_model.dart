import '../../reports/models/pet_report_model.dart';

class MatchModel {
  final String id;
  final String lostReportId;
  final String foundReportId;
  final double matchScore;
  final String matchCategory; // 'High potential match', 'Possible match'
  final Map<String, dynamic> matchReasons;
  final String status; // 'Suggested', 'Relevant', 'Dismissed', 'Resolved'
  final DateTime createdAt;
  final DateTime updatedAt;
  final PetReportModel? lostReport;
  final PetReportModel? foundReport;

  const MatchModel({
    required this.id,
    required this.lostReportId,
    required this.foundReportId,
    required this.matchScore,
    required this.matchCategory,
    required this.matchReasons,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lostReport,
    this.foundReport,
  });

  bool get isHighPotential => matchScore >= 80.0;
  bool get isRelevant => status == 'Relevant';
  bool get isDismissed => status == 'Dismissed';
  bool get isResolved => status == 'Resolved';

  static double? _asDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      lostReportId: json['lost_report_id'] as String,
      foundReportId: json['found_report_id'] as String,
      matchScore: _asDouble(json['match_score']) ?? 0.0,
      matchCategory: json['match_category'] as String,
      matchReasons: (json['match_reasons'] as Map<String, dynamic>?) ?? {},
      status: json['status'] as String? ?? 'Suggested',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lostReport: json['lost_report'] != null
          ? PetReportModel.fromJson(json['lost_report'] as Map<String, dynamic>)
          : null,
      foundReport: json['found_report'] != null
          ? PetReportModel.fromJson(json['found_report'] as Map<String, dynamic>)
          : null,
    );
  }

  MatchModel copyWith({
    String? status,
  }) {
    return MatchModel(
      id: id,
      lostReportId: lostReportId,
      foundReportId: foundReportId,
      matchScore: matchScore,
      matchCategory: matchCategory,
      matchReasons: matchReasons,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lostReport: lostReport,
      foundReport: foundReport,
    );
  }
}

