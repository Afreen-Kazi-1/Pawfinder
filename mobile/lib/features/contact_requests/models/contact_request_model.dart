class ContactUserSummary {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? profileImageUrl;

  ContactUserSummary({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.profileImageUrl,
  });

  factory ContactUserSummary.fromJson(Map<String, dynamic> json) {
    return ContactUserSummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }
}

class ContactReportSummary {
  final String id;
  final String reportType;
  final String? petName;
  final String animalType;
  final String? breed;
  final String status;
  final String? primaryImageUrl;

  ContactReportSummary({
    required this.id,
    required this.reportType,
    this.petName,
    required this.animalType,
    this.breed,
    required this.status,
    this.primaryImageUrl,
  });

  factory ContactReportSummary.fromJson(Map<String, dynamic> json) {
    return ContactReportSummary(
      id: json['id'] as String,
      reportType: json['report_type'] as String? ?? 'LOST',
      petName: json['pet_name'] as String?,
      animalType: json['animal_type'] as String? ?? 'Pet',
      breed: json['breed'] as String?,
      status: json['status'] as String? ?? 'Open',
      primaryImageUrl: json['primary_image_url'] as String?,
    );
  }
}

class ContactRequestModel {
  final String id;
  final String reportId;
  final String senderId;
  final String receiverId;
  final String? message;
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? senderContactInfo;
  final String? receiverContactInfo;
  final ContactUserSummary sender;
  final ContactUserSummary receiver;
  final ContactReportSummary? report;

  ContactRequestModel({
    required this.id,
    required this.reportId,
    required this.senderId,
    required this.receiverId,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.senderContactInfo,
    this.receiverContactInfo,
    required this.sender,
    required this.receiver,
    this.report,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory ContactRequestModel.fromJson(Map<String, dynamic> json) {
    return ContactRequestModel(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      message: json['message'] as String?,
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      senderContactInfo: json['sender_contact_info'] as String?,
      receiverContactInfo: json['receiver_contact_info'] as String?,
      sender: ContactUserSummary.fromJson(json['sender'] as Map<String, dynamic>),
      receiver: ContactUserSummary.fromJson(json['receiver'] as Map<String, dynamic>),
      report: json['report'] != null
          ? ContactReportSummary.fromJson(json['report'] as Map<String, dynamic>)
          : null,
    );
  }
}

