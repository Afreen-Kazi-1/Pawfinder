class AbuseReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String? petReportId;
  final String reason;
  final String status; // 'pending', 'under_review', 'resolved', 'dismissed'
  final DateTime createdAt;
  final String? reporterName;
  final String? reportedUserName;
  final String? petName;

  AbuseReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.petReportId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporterName,
    this.reportedUserName,
    this.petName,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isUnderReview => status.toLowerCase() == 'under_review';
  bool get isResolved => status.toLowerCase() == 'resolved';
  bool get isDismissed => status.toLowerCase() == 'dismissed';

  factory AbuseReportModel.fromJson(Map<String, dynamic> json) {
    String? rName;
    if (json['reporter'] != null && json['reporter'] is Map) {
      rName = json['reporter']['name'] as String?;
    }

    String? ruName;
    if (json['reported_user'] != null && json['reported_user'] is Map) {
      ruName = json['reported_user']['name'] as String?;
    }

    String? pName;
    if (json['pet_report'] != null && json['pet_report'] is Map) {
      pName = json['pet_report']['pet_name'] as String?;
    }

    return AbuseReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reportedUserId: json['reported_user_id'] as String,
      petReportId: json['pet_report_id'] as String?,
      reason: json['reason'] as String,
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      createdAt: DateTime.parse(json['created_at'] as String),
      reporterName: rName,
      reportedUserName: ruName,
      petName: pName,
    );
  }
}

