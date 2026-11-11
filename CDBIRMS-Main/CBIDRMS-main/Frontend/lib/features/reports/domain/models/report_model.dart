class ReportModel {
  final String id;
  final String type; // PROJECT, EXPENSE, PURCHASE, REVENUE, VENDOR, TEAM
  final String fromDate;
  final String toDate;
  final String? projectId;
  final String fileUrl;
  final String createdAt;

  ReportModel({
    required this.id,
    required this.type,
    required this.fromDate,
    required this.toDate,
    this.projectId,
    required this.fileUrl,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'PROJECT',
      fromDate: json['fromDate']?.toString() ?? '',
      toDate: json['toDate']?.toString() ?? '',
      projectId: json['projectId']?.toString(),
      fileUrl: json['fileUrl']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'fromDate': fromDate,
      'toDate': toDate,
      'projectId': projectId,
      'fileUrl': fileUrl,
      'createdAt': createdAt,
    };
  }
}

class ReportRequestModel {
  final String type;
  final String from;
  final String to;
  final String? projectId;

  ReportRequestModel({
    required this.type,
    required this.from,
    required this.to,
    this.projectId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'from': from,
      'to': to,
      if (projectId != null && projectId!.isNotEmpty) 'projectId': projectId,
    };
  }
}
