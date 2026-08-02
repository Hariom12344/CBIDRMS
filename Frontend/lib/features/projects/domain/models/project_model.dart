class ProjectModel {
  final String id;
  final String name;
  final String clientName;
  final String designerName;
  final String startDate;
  final String endDate;
  final double budget;
  final String status; // PLANNING, ONGOING, COMPLETED, CANCELLED
  final double progress;

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
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
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
    };
  }
}
