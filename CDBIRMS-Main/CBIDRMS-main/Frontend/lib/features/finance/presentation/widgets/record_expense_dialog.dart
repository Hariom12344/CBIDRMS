import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../providers/finance_provider.dart';

class RecordExpenseDialog extends ConsumerStatefulWidget {
  final String? preselectedProjectId;
  const RecordExpenseDialog({super.key, this.preselectedProjectId});

  @override
  ConsumerState<RecordExpenseDialog> createState() => _RecordExpenseDialogState();
}

class _RecordExpenseDialogState extends ConsumerState<RecordExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedProjectId = 'PRJ-101';
  String _selectedCategory = 'MATERIAL';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final projects = ref.read(projectNotifierProvider).projects;
    _selectedProjectId = widget.preselectedProjectId ?? (projects.isNotEmpty ? projects.first.id : 'PRJ-101');
    _dateController.text = DateTime.now().toIso8601String().split('T')[0];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectNotifierProvider).projects;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text('Record Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ],

                // Project Selector
                const Text('PROJECT *', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProjectId,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: projects.isEmpty
                      ? [DropdownMenuItem(value: _selectedProjectId, child: Text(_selectedProjectId))]
                      : projects.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.id} - ${p.name}'))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProjectId = val);
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                const Text('EXPENSE CATEGORY *', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: ['MATERIAL', 'LABOR', 'VENDOR_PAYMENT', 'OTHER']
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.replaceAll('_', ' ')),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),

                // Expense Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Expense Amount (₹) *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g. 15000',
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount is required';
                    final num = double.tryParse(v.trim());
                    if (num == null || num <= 0) return 'Amount must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Expense Date
                TextFormField(
                  controller: _dateController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Date (YYYY-MM-DD) *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateController.text = picked.toIso8601String().split('T')[0];
                          });
                        }
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Date is required' : null,
                ),
                const SizedBox(height: 16),

                // Note / Description
                TextFormField(
                  controller: _noteController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Note / Description (Optional)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g. Purchase of 20 bags cement',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isSubmitting = true;
                      _errorMessage = null;
                    });

                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final amount = double.parse(_amountController.text.trim());
                    final success = await ref.read(financeNotifierProvider.notifier).recordExpense(
                          projectId: _selectedProjectId,
                          category: _selectedCategory,
                          amount: amount,
                          date: _dateController.text.trim(),
                          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
                        );

                    setState(() => _isSubmitting = false);

                    if (success) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Expense recorded successfully'), backgroundColor: AppColors.success),
                      );
                    } else {
                      final err = ref.read(financeNotifierProvider).errorMessage ?? 'Failed to record expense';
                      setState(() => _errorMessage = err);
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Record Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
