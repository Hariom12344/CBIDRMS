class CustomerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final List<String> projectHistory;
  final double totalSpent;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.projectHistory,
    required this.totalSpent,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      projectHistory: List<String>.from(json['projectHistory'] ?? []),
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'projectHistory': projectHistory,
      'totalSpent': totalSpent,
    };
  }
}
