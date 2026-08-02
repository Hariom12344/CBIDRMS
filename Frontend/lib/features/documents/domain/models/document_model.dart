class DocumentModel {
  final String id;
  final String title;
  final String fileType; // PDF, IMAGE, CAD
  final String fileSize;
  final String uploadedAt;
  final String? fileUrl;

  DocumentModel({
    required this.id,
    required this.title,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    this.fileUrl,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      fileType: json['fileType'] ?? 'PDF',
      fileSize: json['fileSize'] ?? '0 KB',
      uploadedAt: json['uploadedAt'] ?? '',
      fileUrl: json['fileUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt,
      'fileUrl': fileUrl,
    };
  }
}
