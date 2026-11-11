class DesignApprovalLogModel {
  final String id;
  final String action; // APPROVE, REQUEST_REVISION
  final String? actorName;
  final String? note;
  final String createdAt;

  DesignApprovalLogModel({
    required this.id,
    required this.action,
    this.actorName,
    this.note,
    required this.createdAt,
  });

  factory DesignApprovalLogModel.fromJson(Map<String, dynamic> json) {
    return DesignApprovalLogModel(
      id: json['id']?.toString() ?? '',
      action: json['action'] ?? 'APPROVE',
      actorName: json['actorName'],
      note: json['note'],
      createdAt: json['createdAt'] != null
          ? json['createdAt'].toString().split('T')[0]
          : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'actorName': actorName,
      'note': note,
      'createdAt': createdAt,
    };
  }
}

class DesignModel {
  final String id;
  final String title;
  final String projectId;
  final String projectName;
  final String category; // FLOOR_PLAN, THREE_D_RENDER, CAD_DRAWING, ELEVATION, OTHER
  final String fileUrl;
  final String fileType;
  final String fileSize;
  final String version;
  final String? rootDesignId;
  final String approvalStatus; // PENDING, APPROVED, REVISION_REQUESTED
  final String uploadedBy;
  final String date;
  final List<DesignApprovalLogModel> approvalLogs;

  DesignModel({
    required this.id,
    required this.title,
    this.projectId = '',
    this.projectName = '',
    this.category = 'THREE_D_RENDER',
    this.fileUrl = '',
    this.fileType = 'PDF',
    this.fileSize = '1.0 MB',
    required this.version,
    this.rootDesignId,
    required this.approvalStatus,
    required this.uploadedBy,
    required this.date,
    this.approvalLogs = const [],
  });

  factory DesignModel.fromJson(Map<String, dynamic> json) {
    String pName = json['projectName'] ?? '';
    if (json['project'] != null && json['project']['name'] != null) {
      pName = json['project']['name'];
    }

    final rawLogs = json['approvalLogs'] as List? ?? json['approvalHistory'] as List? ?? [];
    final logs = rawLogs.map((e) => DesignApprovalLogModel.fromJson(e as Map<String, dynamic>)).toList();

    return DesignModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      projectId: json['projectId']?.toString() ?? '',
      projectName: pName.isNotEmpty ? pName : (json['projectId']?.toString() ?? ''),
      category: json['category'] ?? 'THREE_D_RENDER',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? 'PDF',
      fileSize: json['fileSize'] ?? '1.0 MB',
      version: json['version'] ?? 'v1.0',
      rootDesignId: json['rootDesignId']?.toString(),
      approvalStatus: json['approvalStatus'] ?? 'PENDING',
      uploadedBy: json['uploadedBy']?.toString() ?? 'Designer',
      date: json['createdAt'] != null
          ? json['createdAt'].toString().split('T')[0]
          : (json['date'] ?? ''),
      approvalLogs: logs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'projectId': projectId,
      'projectName': projectName,
      'category': category,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'version': version,
      'rootDesignId': rootDesignId,
      'approvalStatus': approvalStatus,
      'uploadedBy': uploadedBy,
      'date': date,
      'approvalLogs': approvalLogs.map((e) => e.toJson()).toList(),
    };
  }
}
