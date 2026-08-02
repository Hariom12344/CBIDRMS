import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Reports & Analytics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/reports'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EXECUTIVE BUSINESS REPORTS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.0,
              children: [
                _buildReportCard(context, Icons.insert_chart_outlined, 'Project Report', 'Overall timelines & milestones'),
                _buildReportCard(context, Icons.account_balance_outlined, 'Expense Report', 'Site costs & material expenses'),
                _buildReportCard(context, Icons.shopping_bag_outlined, 'Purchase Report', 'Vendor PO summary'),
                _buildReportCard(context, Icons.monetization_on_outlined, 'Revenue Report', 'Client billing & cashflow'),
                _buildReportCard(context, Icons.storefront_outlined, 'Vendor Report', 'Supplier reliability & costs'),
                _buildReportCard(context, Icons.groups_outlined, 'Team Report', 'Designer & Supervisor activity'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      color: AppColors.surface,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generating $title PDF...'), backgroundColor: AppColors.success),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle),
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
              const Icon(Icons.download_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
