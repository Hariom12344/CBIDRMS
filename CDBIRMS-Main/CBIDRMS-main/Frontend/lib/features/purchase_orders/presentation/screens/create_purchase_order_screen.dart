import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../vendors/presentation/providers/vendor_provider.dart';
import '../../../vendors/domain/models/vendor_model.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../../projects/domain/models/project_model.dart';
import '../../../boq/data/repositories/boq_repository.dart';
import '../../domain/models/purchase_order_model.dart';
import '../providers/purchase_order_provider.dart';

class CreatePurchaseOrderScreen extends ConsumerStatefulWidget {
  const CreatePurchaseOrderScreen({super.key});

  @override
  ConsumerState<CreatePurchaseOrderScreen> createState() => _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState extends ConsumerState<CreatePurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  VendorModel? _selectedVendor;
  ProjectModel? _selectedProject;
  String? _linkedBoqId;
  final DateTime _poDate = DateTime.now();

  final List<Map<String, dynamic>> _itemRows = [];
  bool _isImportingBoq = false;
  bool _isSubmitting = false;

  final List<String> _unitOptions = ['nos', 'sqft', 'pcs', 'kg', 'ltr', 'bags', 'meters'];

  @override
  void initState() {
    super.initState();
    // Add default initial item row
    _addItemRow();
  }

  void _addItemRow({String name = '', String unit = 'nos', double qty = 1.0, double rate = 0.0}) {
    final nameCtrl = TextEditingController(text: name);
    final qtyCtrl = TextEditingController(text: qty > 0 ? qty.toString() : '1');
    final rateCtrl = TextEditingController(text: rate > 0 ? rate.toString() : '0');

    setState(() {
      _itemRows.add({
        'nameCtrl': nameCtrl,
        'unit': unit,
        'qtyCtrl': qtyCtrl,
        'rateCtrl': rateCtrl,
      });
    });
  }

  void _removeItemRow(int index) {
    if (_itemRows.length > 1) {
      setState(() {
        _itemRows.removeAt(index);
      });
    }
  }

  double get _totalAmount {
    double sum = 0.0;
    for (final row in _itemRows) {
      final q = double.tryParse((row['qtyCtrl'] as TextEditingController).text) ?? 0.0;
      final r = double.tryParse((row['rateCtrl'] as TextEditingController).text) ?? 0.0;
      sum += q * r;
    }
    return sum;
  }

  Future<void> _importFromBoq() async {
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project first'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isImportingBoq = true);
    try {
      final boqRepo = BoqRepository();
      final boqs = await boqRepo.getBoqs(projectId: _selectedProject!.id);
      if (boqs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active BOQ found for this project'), backgroundColor: AppColors.warning),
          );
        }
      } else {
        final boq = boqs.first;
        _linkedBoqId = boq.id;

        setState(() {
          _itemRows.clear();
          for (final item in boq.items) {
            _addItemRow(
              name: item.itemName,
              unit: item.unit,
              qty: item.quantity,
              rate: item.unitPrice,
            );
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported ${boq.items.length} items from BOQ for project "${boq.projectName}"'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing BOQ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isImportingBoq = false);
    }
  }

  Future<void> _submitPurchaseOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier vendor'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Build PoItemModel list
    final List<PoItemModel> poItems = [];
    for (final row in _itemRows) {
      final name = (row['nameCtrl'] as TextEditingController).text.trim();
      final unit = row['unit'] as String;
      final qty = double.tryParse((row['qtyCtrl'] as TextEditingController).text) ?? 1.0;
      final rate = double.tryParse((row['rateCtrl'] as TextEditingController).text) ?? 0.0;

      if (name.isNotEmpty && qty > 0) {
        poItems.add(PoItemModel(
          itemName: name,
          unit: unit,
          quantity: qty,
          unitPrice: rate,
        ));
      }
    }

    if (poItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final numericVendorId = int.tryParse(_selectedVendor!.id.replaceAll('VND-', '')) ?? 1;
    final dateStr = _poDate.toIso8601String().split('T')[0];
    final success = await ref.read(purchaseOrderNotifierProvider.notifier).createPurchaseOrder(
      vendorId: numericVendorId,
      projectId: _selectedProject!.id,
      boqId: _linkedBoqId,
      date: dateStr,
      items: poItems,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase Order created as Draft'), backgroundColor: AppColors.success),
        );
        context.pop();
      } else {
        final err = ref.read(purchaseOrderNotifierProvider).errorMessage ?? 'Failed to create PO';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorsState = ref.watch(vendorNotifierProvider);
    final projectsState = ref.watch(projectNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Create Purchase Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor & Project Pickers
              const Text('General Information', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Vendor Dropdown
              DropdownButtonFormField<VendorModel>(
                initialValue: _selectedVendor,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Vendor *',
                  prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.textSecondary),
                ),
                dropdownColor: AppColors.surface,
                items: vendorsState.vendors.map((v) {
                  return DropdownMenuItem<VendorModel>(
                    value: v,
                    child: Text(
                      '${v.companyName} (${v.contactPerson})',
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedVendor = val),
                validator: (val) => val == null ? 'Vendor selection is required' : null,
              ),
              const SizedBox(height: 16),

              // Project Dropdown
              DropdownButtonFormField<ProjectModel>(
                initialValue: _selectedProject,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Project *',
                  prefixIcon: Icon(Icons.assignment_outlined, color: AppColors.textSecondary),
                ),
                dropdownColor: AppColors.surface,
                items: projectsState.projects.map((p) {
                  return DropdownMenuItem<ProjectModel>(
                    value: p,
                    child: Text(
                      '${p.id} - ${p.name}',
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedProject = val),
                validator: (val) => val == null ? 'Project selection is required' : null,
              ),
              const SizedBox(height: 20),

              // BOQ Import Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  minimumSize: const Size(0, 46),
                  alignment: Alignment.center,
                ),
                icon: _isImportingBoq
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.download_outlined),
                label: const Text('Import Line Items from BOQ', softWrap: false, style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _isImportingBoq ? null : _importFromBoq,
              ),

              const SizedBox(height: 32),
              const Divider(color: AppColors.surface),
              const SizedBox(height: 16),

              // Items Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Order Line Items', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
                    onPressed: () => _addItemRow(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Line Items List
              ..._itemRows.asMap().entries.map((entry) {
                final idx = entry.key;
                final row = entry.value;
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: row['nameCtrl'] as TextEditingController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Item Name #${idx + 1}',
                                  isDense: true,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: row['unit'] as String,
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              underline: const SizedBox(),
                              items: _unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => row['unit'] = val);
                                }
                              },
                            ),
                            if (_itemRows.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 22),
                                onPressed: () => _removeItemRow(idx),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: row['qtyCtrl'] as TextEditingController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: row['rateCtrl'] as TextEditingController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(labelText: 'Rate (₹)', isDense: true),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Builder(builder: (context) {
                              final q = double.tryParse((row['qtyCtrl'] as TextEditingController).text) ?? 0.0;
                              final r = double.tryParse((row['rateCtrl'] as TextEditingController).text) ?? 0.0;
                              return Text(
                                '₹${(q * r).toStringAsFixed(2)}',
                                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Running Total Summary Card
              Card(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total PO Amount:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    minimumSize: const Size(0, 48),
                    alignment: Alignment.center,
                  ),
                  icon: _isSubmitting
                      ? const LoadingWidget()
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Creating PO...' : 'Create Purchase Order (Draft)',
                    softWrap: false,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: _isSubmitting ? null : _submitPurchaseOrder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
