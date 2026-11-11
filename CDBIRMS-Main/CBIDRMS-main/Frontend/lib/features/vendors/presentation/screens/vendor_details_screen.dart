import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/permissions/app_permissions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/vendor_model.dart';
import '../providers/vendor_provider.dart';

class VendorDetailsScreen extends ConsumerStatefulWidget {
  final VendorModel? vendor;

  const VendorDetailsScreen({super.key, this.vendor});

  @override
  ConsumerState<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends ConsumerState<VendorDetailsScreen> {
  late VendorModel _currentVendor;
  List<dynamic> _purchaseOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.vendor != null) {
      _currentVendor = widget.vendor!;
      _loadFullDetails();
    } else {
      _errorMessage = 'No vendor record provided.';
    }
  }

  Future<void> _loadFullDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final details = await ref.read(vendorNotifierProvider.notifier).fetchVendorDetails(_currentVendor.id);

    if (mounted) {
      if (details != null && details['vendor'] != null) {
        setState(() {
          final v = details['vendor'];
          if (v is VendorModel) {
            _currentVendor = v;
          } else if (v is Map<String, dynamic>) {
            _currentVendor = VendorModel.fromJson(v);
          }
          _purchaseOrders = details['purchaseOrders'] as List? ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onEditTap() async {
    final updated = await context.push<VendorModel>('/vendors/edit', extra: _currentVendor);
    if (updated != null && mounted) {
      setState(() {
        _currentVendor = updated;
      });
      _loadFullDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final canManage = AppPermissions.canManageVendors(user?.role);

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Vendor Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(_currentVendor.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
              tooltip: 'Edit Vendor',
              onPressed: _onEditTap,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFullDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor Info Header Card
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.storefront_outlined, color: AppColors.secondary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentVendor.companyName,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vendor ID: ${_currentVendor.id}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.surfaceLight),
                      const SizedBox(height: 16),
                      _buildRow(Icons.person_outline, 'Contact Person', _currentVendor.contactPerson),
                      const SizedBox(height: 12),
                      _buildRow(Icons.email_outlined, 'Email', _currentVendor.email),
                      const SizedBox(height: 12),
                      _buildRow(Icons.phone_outlined, 'Phone', _currentVendor.phone),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Materials & Supplies Section
              const Text(
                'MATERIALS & SUPPLIES',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              if (_currentVendor.materialsSupplied.isEmpty)
                const Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No material catalog specified yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                )
              else
                ..._currentVendor.materialsSupplied.map(
                  (m) => Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                      title: Text(m, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Order History Section (PRD §7.7 View Vendor History)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ORDER HISTORY (PURCHASE ORDERS)',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_purchaseOrders.isEmpty)
                Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'No purchase orders placed with this vendor yet.',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Purchase order history will populate here once orders (FC-009) are linked.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _purchaseOrders.length,
                  itemBuilder: (context, index) {
                    final po = _purchaseOrders[index];
                    return Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(po['poNumber'] ?? 'PO #${po['id']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('Status: ${po['status'] ?? 'Draft'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
