import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final role = user?.role ?? 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '$role Dashboard',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${user?.fullName ?? "User"} 👋',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Role: $role • IDPMS SaaS Workspace Active',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.architecture, color: Colors.white38, size: 54),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Role Based Content
            if (role == 'ADMIN') ...[
              _buildAdminDashboard(context),
            ] else if (role == 'DESIGNER') ...[
              _buildDesignerDashboard(context),
            ] else if (role == 'CLIENT') ...[
              _buildClientDashboard(context),
            ] else ...[
              _buildVendorDashboard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ENTERPRISE METRICS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard('Total Projects', '24 Active', Icons.folder_special_outlined, AppColors.primary),
            _buildStatCard('Total Clients', '18 Verified', Icons.people_outline, AppColors.secondary),
            _buildStatCard('Total Vendors', '12 Partners', Icons.storefront_outlined, AppColors.success),
            _buildStatCard('Pending Payments', '\$45,200', Icons.account_balance_wallet_outlined, AppColors.warning),
          ],
        ),
        const SizedBox(height: 28),
        const Text('RECENT PROJECTS STATUS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildRecentProjectTile(context, 'Penthouse Luxury Interior', 'Luxury Modern Villa', 'ONGOING', 0.75),
        _buildRecentProjectTile(context, 'Downtown Commercial Office', 'Tech Workspace Design', 'PLANNING', 0.25),
        _buildRecentProjectTile(context, 'Skyline Residence 4B', 'Minimalist Apartment', 'COMPLETED', 1.0),
      ],
    );
  }

  Widget _buildDesignerDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DESIGNER WORKSPACE', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard('Assigned Projects', '5 Projects', Icons.architecture, AppColors.primary),
            _buildStatCard('Upcoming Tasks', '14 Pending', Icons.task_alt, AppColors.warning),
            _buildStatCard('Client Requests', '3 New', Icons.chat_bubble_outline, AppColors.secondary),
          ],
        ),
      ],
    );
  }

  Widget _buildClientDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MY PROJECTS OVERVIEW', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildRecentProjectTile(context, 'My Luxury Penthouse Design', 'Assigned: Designer Sarah', 'ONGOING', 0.65),
      ],
    );
  }

  Widget _buildVendorDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VENDOR ORDERS & SUPPLIES', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard('Assigned Work', '8 Orders', Icons.inventory_2_outlined, AppColors.primary),
            _buildStatCard('Material Requests', '12 Items', Icons.local_shipping_outlined, AppColors.success),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accentColor) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Icon(icon, color: accentColor, size: 22),
              ],
            ),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProjectTile(BuildContext context, String title, String subtitle, String status, double progress) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.home_work_outlined, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress, backgroundColor: AppColors.surfaceLight, color: AppColors.primary, minHeight: 6),
          ],
        ),
        trailing: StatusBadge(status: status),
        onTap: () => context.go('/projects'),
      ),
    );
  }
}
