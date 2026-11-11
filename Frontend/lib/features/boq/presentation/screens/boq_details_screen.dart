import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/boq_model.dart';

class BoqDetailsScreen extends StatelessWidget {
  final BoqModel? boq;

  const BoqDetailsScreen({super.key, this.boq});

  @override
  Widget build(BuildContext context) {
    final b = boq ??
        BoqModel(
          id: 'BOQ-901',
          projectName: 'Villa Royale Interior Renovation',
          createdAt: '2026-02-01',
          items: [
            BoqItemModel(itemName: 'Italian Marble Flooring', quantity: 450, unitPrice: 85),
            BoqItemModel(itemName: 'Custom Oak Cabinetry', quantity: 1, unitPrice: 24000),
            BoqItemModel(itemName: 'LED Recessed Lighting Sets', quantity: 30, unitPrice: 120),
          ],
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('${b.id} Details', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Project: ${b.projectName}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Created: ${b.createdAt}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('BOQ LINE ITEMS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            Card(
              color: AppColors.surface,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: b.items.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceLight, height: 1),
                itemBuilder: (context, i) {
                  final item = b.items[i];
                  return ListTile(
                    title: Text(item.itemName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.quantity} units x \$${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: Text('\$${item.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: AppColors.primary.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.primary.withOpacity(0.4))),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total BOQ Estimate:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('\$${b.totalCost.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
