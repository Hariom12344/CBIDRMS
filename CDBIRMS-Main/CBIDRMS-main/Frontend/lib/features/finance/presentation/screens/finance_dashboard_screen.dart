import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/generate_invoice_dialog.dart';
import '../widgets/record_expense_dialog.dart';
import '../widgets/record_payment_dialog.dart';

class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends ConsumerState<FinanceDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
      ref.read(financeNotifierProvider.notifier).fetchAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeNotifierProvider);
    final notifier = ref.read(financeNotifierProvider.notifier);
    final projects = ref.watch(projectNotifierProvider).projects;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Finance & Invoices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => notifier.fetchAllData(),
          ),
        ],
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/finance'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Filter & Action Buttons Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: isMobile ? double.infinity : 300,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.folder_special_outlined, color: AppColors.textMuted, size: 18),
                            const SizedBox(width: 8),
                            const Text('Project:', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: state.selectedProjectId,
                                  dropdownColor: AppColors.surface,
                                  isExpanded: true,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All Projects', style: TextStyle(color: AppColors.primary)),
                                    ),
                                    ...projects.map((p) => DropdownMenuItem<String?>(
                                          value: p.id,
                                          child: Text('${p.id} - ${p.name}', overflow: TextOverflow.ellipsis),
                                        )),
                                  ],
                                  onChanged: (val) => notifier.setProjectId(val),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                        label: const Text('Generate Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          showDialog(context: context, builder: (context) => const GenerateInvoiceDialog());
                        },
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                        label: const Text('Record Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          showDialog(context: context, builder: (context) => const RecordExpenseDialog());
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Live Stat Cards Row
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: MediaQuery.of(context).size.width > 700 ? 2.4 : 2.8,
              children: [
                _buildStatCard('Received Payments', '₹${state.received.toStringAsFixed(0)}', Icons.arrow_downward_rounded, AppColors.success),
                _buildStatCard('Pending Invoices', '₹${state.pending.toStringAsFixed(0)}', Icons.hourglass_empty_rounded, AppColors.warning),
                _buildStatCard('Overdue Payments', '₹${state.overdue.toStringAsFixed(0)}', Icons.warning_amber_rounded, AppColors.error),
              ],
            ),
            const SizedBox(height: 28),

            // Dual Tab Header (Invoices vs Expenses)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Invoices & Payments'),
                  Tab(text: 'Project Expenses'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            SizedBox(
              height: 500,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Invoices List
                  _buildInvoicesTab(context, state),
                  // Tab 2: Expenses List
                  _buildExpensesTab(context, state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesTab(BuildContext context, FinanceState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state.invoices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No invoices generated yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Tap "Generate Invoice" above to create client billing', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.invoices.length,
      itemBuilder: (context, index) {
        final inv = state.invoices[index];
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 480;

                final infoCol = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(inv.id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        StatusBadge(status: inv.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Client: ${inv.clientName} • Project: ${inv.projectId.isNotEmpty ? inv.projectId : 'N/A'} • Due: ${inv.dueDate}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    if (inv.pendingAmount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pending Balance: ₹${inv.pendingAmount.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                );

                final actionCol = Column(
                  crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    Text('₹${inv.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (inv.status != 'PAID')
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.payment_rounded, size: 14),
                        label: const Text('+ Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          showDialog(context: context, builder: (context) => RecordPaymentDialog(invoice: inv));
                        },
                      ),
                  ],
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: infoCol),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          actionCol,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: infoCol),
                    const SizedBox(width: 16),
                    actionCol,
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab(BuildContext context, FinanceState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state.expenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No expenses recorded yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Tap "Record Expense" above to log project expenditures', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.expenses.length,
      itemBuilder: (context, index) {
        final exp = state.expenses[index];
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.monetization_on_outlined, color: AppColors.secondary),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(exp.category.replaceAll('_', ' '), style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Project: ${exp.projectId}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                '${exp.note ?? 'No note provided'} • Date: ${exp.date}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            trailing: Text(
              '₹${exp.amount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
