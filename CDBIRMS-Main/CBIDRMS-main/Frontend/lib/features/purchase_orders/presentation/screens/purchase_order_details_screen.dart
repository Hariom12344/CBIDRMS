import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/purchase_order_model.dart';
import '../providers/purchase_order_provider.dart';

class PurchaseOrderDetailsScreen extends ConsumerStatefulWidget {
  final PurchaseOrderModel? initialPo;
  final String? poId;

  const PurchaseOrderDetailsScreen({super.key, this.initialPo, this.poId});

  @override
  ConsumerState<PurchaseOrderDetailsScreen> createState() => _PurchaseOrderDetailsScreenState();
}

class _PurchaseOrderDetailsScreenState extends ConsumerState<PurchaseOrderDetailsScreen> {
  PurchaseOrderModel? _po;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _po = widget.initialPo;
    _loadPoDetails();
  }

  Future<void> _loadPoDetails() async {
    final targetId = _po?.id ?? widget.poId;
    if (targetId == null || targetId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final updated = await ref.read(purchaseOrderNotifierProvider.notifier).getPurchaseOrderById(targetId);
      if (mounted) {
        setState(() {
          _po = updated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String nextStatus) async {
    if (_po == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Status Change', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to change status from "${_po!.status}" to "$nextStatus"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref.read(purchaseOrderNotifierProvider.notifier).updatePurchaseOrderStatus(
      id: _po!.id,
      status: nextStatus,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase Order status updated to $nextStatus'), backgroundColor: AppColors.success),
        );
        _loadPoDetails();
      } else {
        final err = ref.read(purchaseOrderNotifierProvider).errorMessage ?? 'Failed to update status';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final role = user?.role ?? 'COMPANY_ADMIN';
    final isAdmin = ['SUPER_ADMIN', 'COMPANY_ADMIN', 'ADMIN'].contains(role);
    final isPM = role == 'PROJECT_MANAGER';
    final isSupervisor = role == 'SITE_SUPERVISOR';

    if (_isLoading && _po == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('PO Details')),
        body: const LoadingWidget(),
      );
    }

    if (_po == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('PO Details')),
        body: Center(
          child: Text(_errorMessage ?? 'Purchase Order not found', style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final po = _po!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('${po.id} Details', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadPoDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Header Card
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(po.id, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        StatusBadge(status: po.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Vendor: ${po.vendorName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Project: ${po.projectName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Order Date: ${po.date}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '₹${po.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Actions Toolbar
            const Text('PO Actions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Approve Action (Admin tier only)
                if (po.status == 'Draft' && isAdmin)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text('Approve PO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => _updateStatus('Approved'),
                  ),

                // Mark Ordered Action (Admin or PM)
                if (po.status == 'Approved' && (isAdmin || isPM))
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.local_shipping_outlined, color: Colors.white),
                    label: const Text('Mark as Ordered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => _updateStatus('Ordered'),
                  ),

                // Mark Delivered Action (Admin, PM, or Site Supervisor)
                if (po.status == 'Ordered' && (isAdmin || isPM || isSupervisor))
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.inventory_2_outlined, color: Colors.white),
                    label: const Text('Mark as Delivered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => _updateStatus('Delivered'),
                  ),

                // Cancel Action
                if ((po.status == 'Draft' && (isAdmin || isPM)) || (po.status == 'Approved' && isAdmin))
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel PO', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _updateStatus('Cancelled'),
                  ),
              ],
            ),

            const SizedBox(height: 32),
            const Text('Line Items', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Items Table / Cards
            if (po.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No line items recorded', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              Card(
                color: AppColors.surface,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: po.items.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white24, height: 1),
                  itemBuilder: (context, index) {
                    final item = po.items[index];
                    return ListTile(
                      title: Text(item.itemName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('Qty: ${item.quantity} ${item.unit} @ ₹${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      trailing: Text('₹${item.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
