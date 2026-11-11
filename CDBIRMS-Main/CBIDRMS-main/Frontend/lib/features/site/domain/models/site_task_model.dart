class SiteTaskModel {
  final String id;
  final String projectId;
  final String? projectName;
  final String title;
  final dynamic assignedTo;
  final String? assigneeName;
  final String status; // PENDING, IN_PROGRESS, DONE
  final String? dueDate;
  final String? linkedSiteUpdateId;

  SiteTaskModel({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.title,
    this.assignedTo,
    this.assigneeName,
    this.status = 'PENDING',
    this.dueDate,
    this.linkedSiteUpdateId,
  });

  factory SiteTaskModel.fromJson(Map<String, dynamic> json) {
    return SiteTaskModel(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      projectName: json['projectName']?.toString(),
      title: json['title']?.toString() ?? '',
      assignedTo: json['assignedTo'],
      assigneeName: json['assigneeName']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      dueDate: json['dueDate']?.toString(),
      linkedSiteUpdateId: json['linkedSiteUpdateId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'projectName': projectName,
      'title': title,
      'assignedTo': assignedTo,
      'assigneeName': assigneeName,
      'status': status,
      'dueDate': dueDate,
      'linkedSiteUpdateId': linkedSiteUpdateId,
    };
  }

  SiteTaskModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? title,
    dynamic assignedTo,
    String? assigneeName,
    String? status,
    String? dueDate,
    String? linkedSiteUpdateId,
  }) {
    return SiteTaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      title: title ?? this.title,
      assignedTo: assignedTo ?? this.assignedTo,
      assigneeName: assigneeName ?? this.assigneeName,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      linkedSiteUpdateId: linkedSiteUpdateId ?? this.linkedSiteUpdateId,
    );
  }
}
