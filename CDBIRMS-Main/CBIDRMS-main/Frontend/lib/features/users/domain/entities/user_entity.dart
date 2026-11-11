class UserEntity {
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

  const UserEntity({
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
