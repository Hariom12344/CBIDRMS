class LeadModel {
  final String id;
  final String clientName;
  final String phone;
  final String email;
  final String status; // New, Contacted, Meeting Scheduled, Proposal Sent, Won, Lost
  final String propertyType;
  final double estimatedBudget;
  final String assignedTo;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? project;

  LeadModel({
    required this.id,
    required this.clientName,
    required this.phone,
    required this.email,
    required this.status,
    required this.propertyType,
    required this.estimatedBudget,
    required this.assignedTo,
    this.createdAt,
    this.updatedAt,
    this.project,
  });

  bool get isConverted => status == 'Won' || project != null;

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id']?.toString() ?? '',
      clientName: json['clientName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'New',
      propertyType: json['propertyType'] ?? 'Residential',
      estimatedBudget: (json['estimatedBudget'] ?? 0.0).toDouble(),
      assignedTo: json['assignedTo'] ?? 'Unassigned',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      project: json['project'] is Map<String, dynamic> ? json['project'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'phone': phone,
      'email': email,
      'status': status,
      'propertyType': propertyType,
      'estimatedBudget': estimatedBudget,
      'assignedTo': assignedTo,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (project != null) 'project': project,
    };
  }
}
