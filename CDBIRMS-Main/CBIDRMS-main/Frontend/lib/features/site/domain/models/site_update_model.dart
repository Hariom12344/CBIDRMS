class SiteUpdateModel {
  final String id;
  final String projectId;
  final String projectName;
  final dynamic supervisorId;
  final String supervisorName;
  final String updateDate;
  final String description;
  final String? issueReported;
  final String? issueSeverity; // LOW, MEDIUM, HIGH
  final List<String> photoUrls;

  SiteUpdateModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    this.supervisorId,
    required this.supervisorName,
    required this.updateDate,
    required this.description,
    this.issueReported,
    this.issueSeverity,
    this.photoUrls = const [],
  });

  factory SiteUpdateModel.fromJson(Map<String, dynamic> json) {
    List<String> photos = [];
    if (json['photoUrls'] != null) {
      if (json['photoUrls'] is List) {
        photos = List<String>.from(json['photoUrls']);
      } else if (json['photoUrls'] is String) {
        // If string representation
        photos = [json['photoUrls'] as String];
      }
    }

    String? issue = json['issueReported'];
    if (issue == 'None' || issue?.trim().isEmpty == true) {
      issue = null;
    }

    return SiteUpdateModel(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      projectName: json['projectName']?.toString() ?? 'Unknown Project',
      supervisorId: json['supervisorId'],
      supervisorName: json['supervisorName']?.toString() ?? 'Site Supervisor',
      updateDate: json['updateDate']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      issueReported: issue,
      issueSeverity: json['issueSeverity']?.toString(),
      photoUrls: photos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'projectName': projectName,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'updateDate': updateDate,
      'description': description,
      'issueReported': issueReported,
      'issueSeverity': issueSeverity,
      'photoUrls': photoUrls,
    };
  }
}
