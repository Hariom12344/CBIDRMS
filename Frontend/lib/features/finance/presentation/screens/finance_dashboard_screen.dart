import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/finance_model.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final List<InvoiceModel> _invoices = [
    InvoiceModel(id: 'INV-2026-01', clientName: 'Robert Vance', amount: 45000, dueDate: '2026-03-01', status: 'PAID'),
    InvoiceModel(id: 'INV-2026-02', clientName: 'Apex Innovations', amount: 25000, dueDate: '2026-03-15', status: 'PENDING'),
    InvoiceModel(id: 'INV-2026-03', clientName: 'Elena Rostova', amount: 75000, dueDate: '2026-02-10', status: 'OVERDUE'),
  ];

  @override
  Widget build(BuildContext context) {
    final paidTotal = _invoices.where((i) => i.status == 'PAID').fold(0.0, (s, i) => s + i.amount);
    final pendingTotal = _invoices.where((i) => i.status == 'PENDING').fold(0.0, (s, i) => s + i.amount);
    final overdueTotal = _invoices.where((i) => i.status == 'OVERDUE').fold(0.0, (s, i) => s + i.amount);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Finance & Invoices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/finance'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildCard('Received Payments', '\$${paidTotal.toStringAsFixed(0)}', Icons.arrow_downward_rounded, AppColors.success),
                _buildCard('Pending Invoices', '\$${pendingTotal.toStringAsFixed(0)}', Icons.hourglass_empty_rounded, AppColors.warning),
                _buildCard('Overdue Payments', '\$${overdueTotal.toStringAsFixed(0)}', Icons.warning_amber_rounded, AppColors.error),
              ],
            ),
            const SizedBox(height: 28),

            const Text('INVOICES & TRANSACTIONS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),

            Card(
              color: AppColors.surface,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _invoices.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceLight, height: 1),
                itemBuilder: (context, index) {
                  final inv = _invoices[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.receipt_outlined, color: AppColors.primary),
                    title: Text('${inv.id} - ${inv.clientName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Due: ${inv.dueDate}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${inv.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        StatusBadge(status: inv.status),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
