import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/user_provider.dart';

class UserDetailsScreen extends ConsumerWidget {
  final UserEntity? user;

  const UserDetailsScreen({super.key, this.user});

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
      default:
        return AppColors.textMuted;
    }
  }

  void _showStatusDialog(BuildContext context, WidgetRef ref, UserEntity targetUser) {
    final willDeactivate = targetUser.isActive;
    final actionText = willDeactivate ? 'Deactivate' : 'Reactivate';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            '$actionText User Account?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            willDeactivate
                ? 'Deactivate ${targetUser.fullName}? They will no longer be able to log in.'
                : 'Reactivate ${targetUser.fullName}? They will regain access to IDPMS SaaS.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: willDeactivate ? AppColors.error : AppColors.success,
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final result = await ref
                    .read(userNotifierProvider.notifier)
                    .toggleUserStatus(targetUser.id, !targetUser.isActive);

                if (context.mounted) {
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Account successfully ${!targetUser.isActive ? "reactivated" : "deactivated"}'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['error']?.toString() ?? 'Status update failed'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(
                actionText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, UserEntity targetUser) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Delete ${targetUser.fullName}?', style: const TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to permanently delete this user account? This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final result = await ref
                    .read(userNotifierProvider.notifier)
                    .deleteUser(targetUser.id);

                if (context.mounted) {
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User account permanently deleted'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['error']?.toString() ?? 'Delete failed'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userNotifierProvider);
    final currentUser = ref.watch(authNotifierProvider).user;

    final targetUser = userState.selectedUser ?? user;

    if (targetUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('User Details')),
        body: const Center(
          child: Text('No user selected', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final isSelf = currentUser?.id == targetUser.id;
    final isUpdating = userState.updatingUserId == targetUser.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('User Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // User Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _getRoleColor(targetUser.role).withValues(alpha: 0.2),
                    child: Text(
                      targetUser.fullName.isNotEmpty ? targetUser.fullName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: _getRoleColor(targetUser.role),
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    targetUser.fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    targetUser.email,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRoleColor(targetUser.role).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getRoleColor(targetUser.role).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          targetUser.roleDisplayName,
                          style: TextStyle(
                            color: _getRoleColor(targetUser.role),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: targetUser.isActive
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          targetUser.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: targetUser.isActive ? AppColors.success : AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account Information', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(color: AppColors.surfaceLight, height: 24),
                  _buildDetailRow('User ID', '#${targetUser.id}'),
                  _buildDetailRow('Phone Number', targetUser.phone.isNotEmpty ? targetUser.phone : 'Not specified'),
                  _buildDetailRow(
                    'Password Setup',
                    targetUser.passwordSet ? 'Completed' : 'Pending Set-Password Link',
                    textColor: targetUser.passwordSet ? AppColors.success : Colors.amber,
                  ),
                  if (targetUser.createdAt != null)
                    _buildDetailRow('Created Date', targetUser.createdAt!.split('T')[0]),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                    label: const Text(
                      'Edit',
                      softWrap: false,
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      context.push(
                        '/users/edit',
                        extra: targetUser,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(0, 48),
                      backgroundColor: targetUser.isActive ? AppColors.error : AppColors.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: isUpdating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(
                            targetUser.isActive ? Icons.person_off_rounded : Icons.person_add_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      targetUser.isActive ? 'Deactivate' : 'Reactivate',
                      softWrap: false,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: (isSelf || isUpdating)
                        ? null
                        : () => _showStatusDialog(context, ref, targetUser),
                  ),
                ),
              ],
            ),

            if (!isSelf) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    minimumSize: const Size(0, 48),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                  label: const Text(
                    'Delete Worker Account',
                    softWrap: false,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: isUpdating ? null : () => _showDeleteDialog(context, ref, targetUser),
                ),
              ),
            ],

            if (isSelf) ...[
              const SizedBox(height: 12),
              const Text(
                'You cannot deactivate or delete your own logged-in account.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
