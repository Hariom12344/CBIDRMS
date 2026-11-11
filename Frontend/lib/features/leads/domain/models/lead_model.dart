class LeadModel {
  final String id;
  final String clientName;
  final String phone;
  final String email;
  final String status; // New, Contacted, Meeting Scheduled, Proposal Sent, Won, Lost
  final String propertyType;
  final double estimatedBudget;
  final String assignedTo;

  LeadModel({
    required this.id,
    required this.clientName,
    required this.phone,
    required this.email,
    required this.status,
    required this.propertyType,
    required this.estimatedBudget,
    required this.assignedTo,
  });

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
    };
  }
}
