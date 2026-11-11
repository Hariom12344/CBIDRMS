import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/purchase_order_provider.dart';

class PurchaseOrderListScreen extends ConsumerStatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  ConsumerState<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends ConsumerState<PurchaseOrderListScreen> {
  final List<String> _statusFilters = ['All', 'Draft', 'Approved', 'Ordered', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseOrderNotifierProvider.notifier).fetchPurchaseOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrderNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Purchase Orders (PO)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              ref.read(purchaseOrderNotifierProvider.notifier).fetchPurchaseOrders();
            },
          ),
        ],
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/purchase_orders'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create PO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          context.push('/purchase_orders/create');
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(purchaseOrderNotifierProvider.notifier).fetchPurchaseOrders();
        },
        child: Column(
          children: [
            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: _statusFilters.map((filter) {
                  final isSelected = state.selectedStatusFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(filter),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        ref.read(purchaseOrderNotifierProvider.notifier).setFilter(filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Content List
            Expanded(
              child: state.isLoading && state.purchaseOrders.isEmpty
                  ? const LoadingWidget()
                  : state.errorMessage != null && state.purchaseOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(state.errorMessage!, style: const TextStyle(color: AppColors.error)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(purchaseOrderNotifierProvider.notifier).fetchPurchaseOrders();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : state.purchaseOrders.isEmpty
                          ? const Center(
                              child: Text('No purchase orders found', style: TextStyle(color: AppColors.textSecondary)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.purchaseOrders.length,
                              itemBuilder: (context, index) {
                                final po = state.purchaseOrders[index];
                                return Card(
                                  color: AppColors.surface,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                                    ),
                                    title: Text(
                                      '${po.id} • ${po.vendorName}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('Project: ${po.projectName} • Date: ${po.date}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        const SizedBox(height: 6),
                                        Text('PO Total: ₹${po.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ],
                                    ),
                                    trailing: StatusBadge(status: po.status),
                                    onTap: () {
                                      context.push('/purchase_orders/details', extra: po);
                                    },
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
}
