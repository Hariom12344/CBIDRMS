class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final bool passwordSet;
  final int? companyId;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.passwordSet,
    this.companyId,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'PROJECT_MANAGER',
      isActive: json['isActive'] ?? true,
      passwordSet: json['passwordSet'] ?? false,
      companyId: json['companyId'] != null
          ? (json['companyId'] is int ? json['companyId'] : int.tryParse(json['companyId'].toString()))
          : null,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
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
      'passwordSet': passwordSet,
      'companyId': companyId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
    bool? passwordSet,
    int? companyId,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      passwordSet: passwordSet ?? this.passwordSet,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get roleDisplayName {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'COMPANY_ADMIN':
        return 'Company Admin';
      case 'PROJECT_MANAGER':
        return 'Project Manager';
      case 'SITE_SUPERVISOR':
        return 'Site Supervisor';
      case 'DESIGNER':
        return 'Designer';
      case 'ACCOUNTANT':
        return 'Accountant';
      default:
        return role;
    }
  }
}
