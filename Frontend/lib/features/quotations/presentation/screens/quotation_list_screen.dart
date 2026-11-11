import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/quotation_model.dart';

class QuotationListScreen extends StatefulWidget {
  const QuotationListScreen({super.key});

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  final List<QuotationModel> _quotes = [
    QuotationModel(id: 'QT-601', clientName: 'Robert Vance', projectName: 'Villa Royale Interior', totalAmount: 125000, date: '2026-01-10', status: 'Converted to Project'),
    QuotationModel(id: 'QT-602', clientName: 'Apex Innovations', projectName: 'TechHub Office Fitout', totalAmount: 85000, date: '2026-02-15', status: 'Approved'),
    QuotationModel(id: 'QT-603', clientName: 'Samantha Reed', projectName: 'Penthouse Renovation', totalAmount: 150000, date: '2026-03-01', status: 'Sent'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Quotations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/quotations'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.request_quote_outlined, color: Colors.white),
        label: const Text('Create Quotation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Quotation form opened'), backgroundColor: AppColors.primary),
          );
        },
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _quotes.length,
        itemBuilder: (context, index) {
          final q = _quotes[index];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.info.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.request_quote_outlined, color: AppColors.info),
              ),
              title: Text('${q.id} - ${q.clientName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Project: ${q.projectName} • Date: ${q.date}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('Quotation Amount: \$${q.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              trailing: StatusBadge(status: q.status),
            ),
          );
        },
      ),
    );
  }
}
