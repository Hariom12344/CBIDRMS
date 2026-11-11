class DocumentModel {
  final String id;
  final String title;
  final String projectId;
  final String category; // CONTRACT, FLOOR_PLAN, INVOICE, REFERENCE, OTHER
  final String fileType; // PDF, IMAGE, CAD, OTHER
  final String fileSize;
  final String uploadedAt;
  final String? fileUrl;
  final int? uploadedBy;
  final int? companyId;

  DocumentModel({
    required this.id,
    required this.title,
    this.projectId = '',
    this.category = 'OTHER',
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    this.fileUrl,
    this.uploadedBy,
    this.companyId,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      projectId: json['projectId']?.toString() ?? '',
      category: json['category'] ?? 'OTHER',
      fileType: json['fileType'] ?? 'PDF',
      fileSize: json['fileSize'] ?? '0 KB',
      uploadedAt: json['createdAt'] != null
          ? json['createdAt'].toString().split('T')[0]
          : (json['uploadedAt'] ?? ''),
      fileUrl: json['fileUrl'],
      uploadedBy: json['uploadedBy'] is int ? json['uploadedBy'] : null,
      companyId: json['companyId'] is int ? json['companyId'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'projectId': projectId,
      'category': category,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt,
      'fileUrl': fileUrl,
      'uploadedBy': uploadedBy,
      'companyId': companyId,
    };
  }
}
