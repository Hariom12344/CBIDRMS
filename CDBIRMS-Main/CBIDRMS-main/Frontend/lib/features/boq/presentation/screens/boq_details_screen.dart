import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/boq_model.dart';
import 'create_boq_screen.dart';

class BoqDetailsScreen extends StatelessWidget {
  final BoqModel? boq;

  const BoqDetailsScreen({super.key, this.boq});

  @override
  Widget build(BuildContext context) {
    if (boq == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('BOQ Details', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('No BOQ document selected', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final b = boq!;
    final formattedDate = b.createdAt.length >= 10 ? b.createdAt.substring(0, 10) : b.createdAt;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('BOQ Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit BOQ',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateBoqScreen(initialBoq: b)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            b.projectName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${b.items.length} Items',
                            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Created: $formattedDate', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('BOQ LINE ITEMS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: b.items.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceLight, height: 1),
                itemBuilder: (context, i) {
                  final item = b.items[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(item.itemName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.quantity} ${item.unit.toUpperCase()} x ₹${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: Text('₹${item.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4))),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total BOQ Estimate:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('₹${b.totalCost.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 20)),
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
