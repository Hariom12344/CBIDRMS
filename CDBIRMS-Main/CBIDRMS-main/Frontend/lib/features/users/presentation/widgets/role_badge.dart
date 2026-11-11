import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final String roleDisplayName;

  const RoleBadge({
    super.key,
    required this.role,
    required this.roleDisplayName,
  });

  Color _getRoleColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return Colors.purpleAccent;
      case 'COMPANY_ADMIN':
        return AppColors.primary;
      case 'PROJECT_MANAGER':
        return Colors.blueAccent;
      case 'SITE_SUPERVISOR':
        return Colors.orangeAccent;
      case 'DESIGNER':
        return Colors.tealAccent;
      case 'ACCOUNTANT':
        return Colors.greenAccent;
      case 'VENDOR':
        return Colors.amberAccent;
      case 'CLIENT':
        return Colors.cyanAccent;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        roleDisplayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
