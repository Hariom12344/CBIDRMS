class UserModel {
  final dynamic id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CLIENT',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
