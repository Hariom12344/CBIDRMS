import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusUpper = status.toUpperCase();
    Color bg;
    Color fg;

    switch (statusUpper) {
      case 'ONGOING':
      case 'PAID':
      case 'COMPLETED':
      case 'ACTIVE':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case 'PLANNING':
      case 'PENDING':
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        break;
      case 'CANCELLED':
      case 'OVERDUE':
      case 'INACTIVE':
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
      default:
        bg = AppColors.info.withValues(alpha: 0.15);
        fg = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        statusUpper,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
