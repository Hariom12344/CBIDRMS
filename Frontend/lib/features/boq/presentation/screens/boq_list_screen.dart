import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../domain/models/boq_model.dart';

class BoqListScreen extends StatefulWidget {
  const BoqListScreen({super.key});

  @override
  State<BoqListScreen> createState() => _BoqListScreenState();
}

class _BoqListScreenState extends State<BoqListScreen> {
  final List<BoqModel> _boqs = [
    BoqModel(
      id: 'BOQ-901',
      projectName: 'Villa Royale Interior Renovation',
      createdAt: '2026-02-01',
      items: [
        BoqItemModel(itemName: 'Italian Marble Flooring', quantity: 450, unitPrice: 85),
        BoqItemModel(itemName: 'Custom Oak Cabinetry', quantity: 1, unitPrice: 24000),
        BoqItemModel(itemName: 'LED Recessed Lighting Sets', quantity: 30, unitPrice: 120),
      ],
    ),
    BoqModel(
      id: 'BOQ-902',
      projectName: 'TechHub Open Plan Office',
      createdAt: '2026-03-10',
      items: [
        BoqItemModel(itemName: 'Acoustic Wall Panels', quantity: 80, unitPrice: 150),
        BoqItemModel(itemName: 'Ergonomic Desk Systems', quantity: 25, unitPrice: 650),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Bill of Quantities (BOQ)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/boq'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.note_add_outlined, color: Colors.white),
        label: const Text('Create BOQ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/boq/create'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _boqs.length,
        itemBuilder: (context, index) {
          final boq = _boqs[index];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
              ),
              title: Text(boq.projectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${boq.id} • ${boq.items.length} Line Items • ${boq.createdAt}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('Total BOQ Cost: \$${boq.totalCost.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
              onTap: () => context.push('/boq/details', extra: boq),
            ),
          );
        },
      ),
    );
  }
}
