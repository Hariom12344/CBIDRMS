import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../permissions/app_permissions.dart';

class AppDrawerSidebar extends ConsumerWidget {
  final String currentRoute;

  const AppDrawerSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Logo Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                border: const Border(bottom: BorderSide(color: AppColors.surfaceLight)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.architecture_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IDPMS SaaS',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Role: ${user?.role ?? "Admin"}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Menu List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  _buildNavItem(context, Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
                  _buildNavItem(context, Icons.filter_alt_outlined, 'Lead Pipeline', '/leads'),
                  _buildNavItem(context, Icons.folder_outlined, 'Projects', '/projects'),
                  _buildNavItem(context, Icons.draw_outlined, 'Design Drawings', '/design'),
                  _buildNavItem(context, Icons.receipt_long_outlined, 'BOQ Management', '/boq'),
                  _buildNavItem(context, Icons.request_quote_outlined, 'Quotations', '/quotations'),
                  _buildNavItem(context, Icons.shopping_bag_outlined, 'Purchase Orders', '/purchase_orders'),
                  _buildNavItem(context, Icons.camera_alt_outlined, 'Site Updates', '/site'),
                  _buildNavItem(context, Icons.people_alt_outlined, 'Customers', '/customers'),
                  if (AppPermissions.canAccessUserManagement(user?.role))
                    _buildNavItem(context, Icons.manage_accounts_outlined, 'Team / Users', '/users'),
                  _buildNavItem(context, Icons.storefront_outlined, 'Vendors', '/vendors'),
                  _buildNavItem(context, Icons.account_balance_wallet_outlined, 'Finance', '/finance'),
                  _buildNavItem(context, Icons.file_present_outlined, 'Documents', '/documents'),
                  _buildNavItem(context, Icons.bar_chart_outlined, 'Reports', '/reports'),
                  _buildNavItem(context, Icons.show_chart_rounded, 'Analytics', '/analytics'),
                ],
              ),
            ),

            // User Profile Footer
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'User',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              user?.email ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.key_outlined, color: AppColors.primary, size: 14),
                            label: const Text(
                              'Password',
                              softWrap: false,
                              style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              context.push('/change-password');
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 14),
                            label: const Text(
                              'Logout',
                              softWrap: false,
                              style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              await ref.read(authNotifierProvider.notifier).logout(context);
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route) {
    final isSelected = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textMuted,
          size: 18,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) {
            context.go(route);
          }
        },
      ),
    );
  }
}
