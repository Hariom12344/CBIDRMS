import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/report_model.dart';
import '../providers/report_provider.dart';
import '../widgets/generate_report_dialog.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).fetchReportHistory();
    });
  }

  bool _isReportPermitted(String reportType, String role) {
    final normRole = role.toUpperCase();
    switch (reportType) {
      case 'PROJECT':
        return ['SUPER_ADMIN', 'COMPANY_ADMIN', 'ADMIN', 'PROJECT_MANAGER', 'SITE_SUPERVISOR'].contains(normRole);
      case 'EXPENSE':
        return ['SUPER_ADMIN', 'COMPANY_ADMIN', 'ADMIN', 'PROJECT_MANAGER', 'ACCOUNTANT'].contains(normRole);
      case 'PURCHASE':
        return ['SUPER_ADMIN', 'COMPANY_ADMIN', 'ADMIN', 'PROJECT_MANAGER'].contains(normRole);
      case 'REVENUE':
        return ['SUPER_ADMIN', 'COMPANY_ADMIN', 'ADMIN', 'PROJECT_MANAGER', 'ACCOUNTANT'].contains(normRole);
      case 'VENDOR':
        return ['SUPER_ADMIN', 'COMPANY_ADMIN', 'ADMIN', 'PROJECT_MANAGER'].contains(normRole);
      case 'TEAM':
        return ['SUPER_ADMIN', 'COMPANY_ADMIN', 'ADMIN', 'PROJECT_MANAGER', 'SITE_SUPERVISOR'].contains(normRole);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider).user;
    final userRole = currentUser?.role ?? 'COMPANY_ADMIN';

    final reportState = ref.watch(reportProvider);
    final reportNotifier = ref.read(reportProvider.notifier);

    final allReportsList = [
      {'type': 'PROJECT', 'title': 'Project Report', 'subtitle': 'Overall timelines & milestones', 'icon': Icons.insert_chart_outlined},
      {'type': 'EXPENSE', 'title': 'Expense Report', 'subtitle': 'Site costs & material expenses', 'icon': Icons.account_balance_outlined},
      {'type': 'PURCHASE', 'title': 'Purchase Report', 'subtitle': 'Vendor PO summary', 'icon': Icons.shopping_bag_outlined},
      {'type': 'REVENUE', 'title': 'Revenue Report', 'subtitle': 'Client billing & cashflow', 'icon': Icons.monetization_on_outlined},
      {'type': 'VENDOR', 'title': 'Vendor Report', 'subtitle': 'Supplier reliability & costs', 'icon': Icons.storefront_outlined},
      {'type': 'TEAM', 'title': 'Team Report', 'subtitle': 'Designer & Supervisor activity', 'icon': Icons.groups_outlined},
    ];

    final allowedReports = allReportsList.where((r) => _isReportPermitted(r['type'] as String, userRole)).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Reports & Analytics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => reportNotifier.fetchReportHistory(),
          ),
        ],
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/reports'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'EXECUTIVE BUSINESS REPORTS',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Role: ${userRole.replaceAll('_', ' ')}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (allowedReports.isEmpty) ...[
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('No Reports Assigned', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 6),
                        Text('Your user role does not have permission to view executive reports.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.0,
                children: allowedReports.map((r) {
                  return _buildReportCard(
                    context,
                    r['type'] as String,
                    r['icon'] as IconData,
                    r['title'] as String,
                    r['subtitle'] as String,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),

            // Report History Section
            const Text(
              'RECENTLY GENERATED REPORTS',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),

            if (reportState.isLoadingHistory)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary)))
            else if (reportState.history.isEmpty)
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No reports generated yet. Tap any report card above to generate a PDF document.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reportState.history.length,
                itemBuilder: (context, index) {
                  final item = reportState.history[index];
                  return _buildHistoryItem(context, item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String type, IconData icon, String title, String subtitle) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => GenerateReportDialog(
              reportType: type,
              reportTitle: title,
              icon: icon,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, ReportModel item) {
    final typeColor = item.type == 'REVENUE'
        ? AppColors.success
        : (item.type == 'EXPENSE' ? AppColors.error : AppColors.primary);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.description_outlined, color: typeColor, size: 20),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                item.id,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
              child: Text(item.type, style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Date Range: ${item.fromDate} to ${item.toDate} • Generated: ${item.createdAt.split('T')[0]}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        trailing: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 14),
          label: const Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          onPressed: () async {
            String fileUrlStr = item.fileUrl;
            if (!fileUrlStr.startsWith('http')) {
              final base = ApiConstants.baseUrl.replaceAll('/api', '');
              fileUrlStr = '$base$fileUrlStr';
            }
            final uri = Uri.parse(fileUrlStr);
            try {
              final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (!launched) {
                await launchUrl(uri);
              }
            } catch (e) {
              debugPrint('Could not launch report: $e');
            }
          },
        ),
      ),
    );
  }
}
