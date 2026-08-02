import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../domain/models/boq_model.dart';

class CreateBoqScreen extends StatefulWidget {
  const CreateBoqScreen({super.key});

  @override
  State<CreateBoqScreen> createState() => _CreateBoqScreenState();
}

class _CreateBoqScreenState extends State<CreateBoqScreen> {
  final _projectController = TextEditingController();
  final List<BoqItemModel> _items = [];

  final _itemController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _projectController.dispose();
    _itemController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _itemController.text.trim();
    final qty = int.tryParse(_qtyController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (name.isNotEmpty && price > 0) {
      setState(() {
        _items.add(BoqItemModel(itemName: name, quantity: qty, unitPrice: price));
        _itemController.clear();
        _qtyController.clear();
        _priceController.clear();
      });
    }
  }

  double get _totalSum => _items.fold(0.0, (s, i) => s + i.totalAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create New BOQ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CustomTextField(
                  controller: _projectController,
                  label: 'Select / Enter Project Name',
                  hintText: 'e.g. Villa Royale Renovation',
                  prefixIcon: Icons.folder_outlined,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Item Input Form
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
                      label: 'Item Name / Description',
                      hintText: 'e.g. Hardwood Flooring',
                      prefixIcon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _qtyController,
                            label: 'Quantity',
                            hintText: '10',
                            prefixIcon: Icons.numbers,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _priceController,
                            label: 'Unit Price (\$) ',
                            hintText: '50.00',
                            prefixIcon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
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
                    ..._items.map(
                      (item) => ListTile(
                        title: Text(item.itemName, style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}'),
                        trailing: Text('\$${item.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Divider(color: AppColors.surfaceLight),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Calculated BOQ:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('\$${_totalSum.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Save BOQ Document',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('BOQ saved successfully!'), backgroundColor: AppColors.success),
                  );
                  context.pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
