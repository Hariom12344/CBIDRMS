class UserModel {
  final dynamic id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'CLIENT',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
