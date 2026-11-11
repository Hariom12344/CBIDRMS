class ProjectTeamMemberModel {
  final int id;
  final int userId;
  final String? role;
  final String userName;
  final String userEmail;
  final String assignedAt;

  ProjectTeamMemberModel({
    required this.id,
    required this.userId,
    this.role,
    required this.userName,
    required this.userEmail,
    required this.assignedAt,
  });

  factory ProjectTeamMemberModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map ? json['user'] as Map<String, dynamic> : {};
    return ProjectTeamMemberModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      role: json['role']?.toString(),
      userName: userMap['fullName']?.toString() ?? json['userName']?.toString() ?? 'Team Member',
      userEmail: userMap['email']?.toString() ?? json['userEmail']?.toString() ?? '',
      assignedAt: json['assignedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'role': role,
      'userName': userName,
      'userEmail': userEmail,
      'assignedAt': assignedAt,
    };
  }
}

class ProjectStageModel {
  final int id;
  final String name;
  final String status; // pending, in_progress, done
  final String? startDate;
  final String? endDate;
  final int sortOrder;

  ProjectStageModel({
    required this.id,
    required this.name,
    required this.status,
    this.startDate,
    this.endDate,
    required this.sortOrder,
  });

  factory ProjectStageModel.fromJson(Map<String, dynamic> json) {
    return ProjectStageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] : int.tryParse(json['sortOrder']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'sortOrder': sortOrder,
    };
  }
}

class ProjectModel {
  final String id;
  final String name;
  final String clientName;
  final String designerName;
  final String startDate;
  final String endDate;
  final double budget;
  final String status; // PLANNING, ONGOING, COMPLETED, CANCELLED, ON_HOLD
  final double progress;
  final List<ProjectTeamMemberModel> assignedTeam;
  final List<ProjectStageModel> stages;

  ProjectModel({
    required this.id,
    required this.name,
    required this.clientName,
    required this.designerName,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.status,
    required this.progress,
    this.assignedTeam = const [],
    this.stages = const [],
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    var rawTeam = json['assignedTeam'];
    List<ProjectTeamMemberModel> parsedTeam = [];
    if (rawTeam is List) {
      parsedTeam = rawTeam.map((e) => ProjectTeamMemberModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    var rawStages = json['stages'];
    List<ProjectStageModel> parsedStages = [];
    if (rawStages is List) {
      parsedStages = rawStages.map((e) => ProjectStageModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return ProjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      clientName: json['clientName'] ?? '',
      designerName: json['designerName'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      budget: (json['budget'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'PLANNING',
      progress: (json['progress'] ?? 0.0).toDouble(),
      assignedTeam: parsedTeam,
      stages: parsedStages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'clientName': clientName,
      'designerName': designerName,
      'startDate': startDate,
      'endDate': endDate,
      'budget': budget,
      'status': status,
      'progress': progress,
      'assignedTeam': assignedTeam.map((e) => e.toJson()).toList(),
      'stages': stages.map((e) => e.toJson()).toList(),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? clientName,
    String? designerName,
    String? startDate,
    String? endDate,
    double? budget,
    String? status,
    double? progress,
    List<ProjectTeamMemberModel>? assignedTeam,
    List<ProjectStageModel>? stages,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      designerName: designerName ?? this.designerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      stages: stages ?? this.stages,
    );
  }
}
