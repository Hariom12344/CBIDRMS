import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../domain/models/boq_model.dart';
import '../providers/boq_provider.dart';

class CreateBoqScreen extends ConsumerStatefulWidget {
  final BoqModel? initialBoq;
  const CreateBoqScreen({super.key, this.initialBoq});

  @override
  ConsumerState<CreateBoqScreen> createState() => _CreateBoqScreenState();
}

class _CreateBoqScreenState extends ConsumerState<CreateBoqScreen> {
  String? _selectedProjectId;
  final List<BoqItemModel> _items = [];

  final _itemController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedUnit = 'nos';

  final List<String> _unitOptions = ['nos', 'sqft', 'pcs', 'kg', 'ltr', 'rft', 'set', 'ls'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
    });

    if (widget.initialBoq != null) {
      _selectedProjectId = widget.initialBoq!.projectId;
      _items.addAll(widget.initialBoq!.items);
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _itemController.text.trim();
    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid unit price > 0'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _items.add(BoqItemModel(
        itemName: name,
        unit: _selectedUnit,
        quantity: qty,
        unitPrice: price,
      ));
      _itemController.clear();
      _qtyController.clear();
      _priceController.clear();
      _selectedUnit = 'nos';
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _totalSum => _items.fold(0.0, (s, i) => s + i.totalAmount);

  Future<void> _saveBoq() async {
    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project for this BOQ'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item before saving'), backgroundColor: AppColors.error),
      );
      return;
    }

    final notifier = ref.read(boqNotifierProvider.notifier);

    if (widget.initialBoq != null) {
      final res = await notifier.updateBoq(id: widget.initialBoq!.id, items: _items);
      if (mounted) {
        if (res != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('BOQ updated successfully!'), backgroundColor: AppColors.success),
          );
          context.pop();
        } else {
          final err = ref.read(boqNotifierProvider).errorMessage ?? 'Failed to update BOQ';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
          );
        }
      }
    } else {
      final res = await notifier.createBoq(projectId: _selectedProjectId!, items: _items);
      if (mounted) {
        if (res != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('BOQ created successfully!'), backgroundColor: AppColors.success),
          );
          context.pop();
        } else {
          final err = ref.read(boqNotifierProvider).errorMessage ?? 'Failed to create BOQ';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectNotifierProvider);
    final projects = projectState.projects;
    final boqState = ref.watch(boqNotifierProvider);
    final isEditing = widget.initialBoq != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(isEditing ? 'Edit BOQ Document' : 'Create New BOQ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Project Selector Card
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TARGET PROJECT *', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProjectId,
                      dropdownColor: AppColors.surfaceLight,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.folder_outlined, color: AppColors.primary),
                        hintText: 'Select Associated Project',
                      ),
                      items: projects.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: isEditing
                          ? null
                          : (val) {
                              setState(() {
                                _selectedProjectId = val;
                              });
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Item Input Form Card
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Add Line Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _itemController,
                      label: 'Item Name / Description *',
                      hintText: 'e.g. Italian Marble Flooring',
                      prefixIcon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 500;
                        final qtyField = CustomTextField(
                          controller: _qtyController,
                          label: 'Qty *',
                          hintText: '10',
                          prefixIcon: Icons.numbers,
                          keyboardType: TextInputType.number,
                        );

                        final unitDropdown = DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          dropdownColor: AppColors.surfaceLight,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                          ),
                          items: _unitOptions.map((u) {
                            return DropdownMenuItem<String>(
                              value: u,
                              child: Text(u.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedUnit = val;
                              });
                            }
                          },
                        );

                        final priceField = CustomTextField(
                          controller: _priceController,
                          label: 'Rate (₹) *',
                          hintText: '50.00',
                          prefixIcon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                        );

                        if (isMobile) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: qtyField),
                                  const SizedBox(width: 10),
                                  Expanded(child: unitDropdown),
                                ],
                              ),
                              const SizedBox(height: 12),
                              priceField,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(flex: 2, child: qtyField),
                            const SizedBox(width: 10),
                            Expanded(flex: 2, child: unitDropdown),
                            const SizedBox(width: 10),
                            Expanded(flex: 3, child: priceField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      label: const Text('Add Item to List', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      onPressed: _addItem,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Added Items Summary
            if (_items.isNotEmpty) ...[
              Card(
                color: AppColors.surface,
                child: Column(
                  children: [
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return ListTile(
                        title: Text(item.itemName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text('${item.quantity} ${item.unit.toUpperCase()} x ₹${item.unitPrice.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${item.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                              onPressed: () => _removeItem(idx),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: AppColors.surfaceLight),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Calculated BOQ Cost:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('₹${_totalSum.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: isEditing ? 'Update BOQ Document' : 'Save BOQ Document',
                isLoading: boqState.isLoading,
                onPressed: _saveBoq,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
