import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).fetchDashboardData();
    });
  }

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return dateStr;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'PROJECT_CREATED':
        return Icons.folder_special_outlined;
      case 'LEAD_WON':
        return Icons.star_rounded;
      case 'QUOTATION_CREATED':
        return Icons.receipt_long_outlined;
      case 'USER_REGISTERED':
        return Icons.person_add_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final user = authState.user;
    final role = user?.role ?? 'COMPANY_ADMIN';
    final summary = dashboardState.summary;

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
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              ref.read(dashboardNotifierProvider.notifier).fetchDashboardData();
            },
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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardNotifierProvider.notifier).fetchDashboardData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      color: AppColors.primary.withValues(alpha: 0.3),
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

              // Role-based Stat Cards Grid
              const Text('KEY PERFORMANCE METRICS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),

              if (dashboardState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: LoadingWidget(message: 'Calculating live organization metrics...'),
                )
              else
                _buildRoleStatGrid(context, role, summary),

              const SizedBox(height: 28),

              // Recent Activities Section
              const Text('RECENT ACTIVITIES FEED', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),

              Card(
                color: AppColors.surface,
                child: dashboardState.activities.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No recent activity recorded yet.', style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dashboardState.activities.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceLight, height: 1),
                        itemBuilder: (context, index) {
                          final item = dashboardState.activities[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_getActivityIcon(item.type), color: AppColors.primary, size: 20),
                            ),
                            title: Text(
                              item.message,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              'By ${item.actorName}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            trailing: Text(
                              _formatTimeAgo(item.createdAt),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleStatGrid(BuildContext context, String role, Map<String, dynamic> summary) {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 900 ? 4 : (width > 600 ? 2 : 1);

    List<Widget> cards = [];

    if (role == 'SUPER_ADMIN' || role == 'COMPANY_ADMIN' || role == 'ADMIN') {
      final totalPrj = summary['totalProjects']?.toString() ?? '0';
      final activePrj = summary['activeProjects']?.toString() ?? '0';
      final clients = summary['totalClients']?.toString() ?? '0';
      final vendors = summary['totalVendors']?.toString() ?? '0';
      final rev = summary['revenue'] is num ? (summary['revenue'] as num).toDouble() : 0.0;
      final pending = summary['pendingPayments'] is num ? (summary['pendingPayments'] as num).toDouble() : 0.0;

      cards = [
        _buildStatCard('Total Projects', '$totalPrj Projects', Icons.folder_special_outlined, AppColors.primary, () => context.push('/projects')),
        _buildStatCard('Active Projects', '$activePrj Active', Icons.architecture, AppColors.secondary, () => context.push('/projects')),
        _buildStatCard('Total Clients', '$clients Registered', Icons.people_outline, AppColors.success, () => context.push('/customers')),
        _buildStatCard('Total Vendors', '$vendors Partners', Icons.storefront_outlined, AppColors.primary, () => context.push('/vendors')),
        _buildStatCard('Revenue (Paid)', '₹${rev.toStringAsFixed(0)}', Icons.currency_rupee_rounded, AppColors.success, () => context.push('/finance')),
        _buildStatCard('Pending Payments', '₹${pending.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined, AppColors.warning, () => context.push('/finance')),
      ];
    } else if (role == 'PROJECT_MANAGER') {
      final assigned = summary['assignedProjects']?.toString() ?? '0';
      final tasks = summary['upcomingTasks']?.toString() ?? '0';
      final approvals = summary['pendingApprovals']?.toString() ?? '0';

      cards = [
        _buildStatCard('Assigned Projects', '$assigned Projects', Icons.folder_special_outlined, AppColors.primary, () => context.push('/projects')),
        _buildStatCard('Upcoming Tasks', '$tasks Stages', Icons.task_alt_rounded, AppColors.warning, () => context.push('/projects')),
        _buildStatCard('Pending Approvals', '$approvals Requests', Icons.rule_rounded, AppColors.secondary, () => context.push('/projects')),
      ];
    } else if (role == 'SITE_SUPERVISOR') {
      final assigned = summary['assignedProjects']?.toString() ?? '0';
      final updates = summary['todaysSiteUpdates']?.toString() ?? '0';

      cards = [
        _buildStatCard('Assigned Sites', '$assigned Sites', Icons.location_on_outlined, AppColors.primary, () => context.push('/site')),
        _buildStatCard("Today's Site Updates", '$updates In-Progress', Icons.checklist_rounded, AppColors.success, () => context.push('/site')),
        _buildStatCard('Material Requests', '0 Requests', Icons.inventory_2_outlined, AppColors.warning, () => context.push('/purchase_orders')),
      ];
    } else if (role == 'DESIGNER') {
      final assigned = summary['assignedProjects']?.toString() ?? '0';
      final reviews = summary['pendingDesignReviews']?.toString() ?? '0';

      cards = [
        _buildStatCard('My Design Projects', '$assigned Projects', Icons.architecture, AppColors.primary, () => context.push('/design')),
        _buildStatCard('Pending Reviews', '$reviews Designs', Icons.rate_review_outlined, AppColors.secondary, () => context.push('/design')),
      ];
    } else {
      // ACCOUNTANT
      final pending = summary['pendingPayments'] is num ? (summary['pendingPayments'] as num).toDouble() : 0.0;
      final totalRev = summary['totalRevenue'] is num ? (summary['totalRevenue'] as num).toDouble() : 0.0;

      cards = [
        _buildStatCard('Total Revenue', '₹${totalRev.toStringAsFixed(0)}', Icons.currency_rupee_rounded, AppColors.success, () => context.push('/finance')),
        _buildStatCard('Pending Payments', '₹${pending.toStringAsFixed(0)}', Icons.hourglass_empty_rounded, AppColors.warning, () => context.push('/finance')),
        _buildStatCard('Overdue Invoices', '0 Overdue', Icons.error_outline_rounded, AppColors.error, () => context.push('/finance')),
      ];
    }

    final aspectRatio = width > 600 ? 1.8 : 2.4;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio,
      children: cards,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
