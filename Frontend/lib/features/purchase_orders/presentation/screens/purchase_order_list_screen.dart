import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/purchase_order_model.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  final List<PurchaseOrderModel> _orders = [
    PurchaseOrderModel(id: 'PO-401', vendorName: 'Luxe Marble & Granite Co.', projectName: 'Villa Royale', totalAmount: 38250, status: 'Approved', date: '2026-02-20'),
    PurchaseOrderModel(id: 'PO-402', vendorName: 'TimberCraft Woodworks', projectName: 'Penthouse Suite', totalAmount: 24000, status: 'Delivered', date: '2026-03-05'),
    PurchaseOrderModel(id: 'PO-403', vendorName: 'Lumina Smart Lighting', projectName: 'TechHub Office', totalAmount: 9600, status: 'Ordered', date: '2026-03-11'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Purchase Orders (PO)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/purchase_orders'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
        label: const Text('Create PO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Purchase Order dialog opened'), backgroundColor: AppColors.primary),
          );
        },
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final po = _orders[index];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.success),
              ),
              title: Text('${po.id} - ${po.vendorName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Project: ${po.projectName} • Date: ${po.date}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('PO Total: \$${po.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              trailing: StatusBadge(status: po.status),
            ),
          );
        },
      ),
    );
  }
}
