import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../providers/finance_provider.dart';

class GenerateInvoiceDialog extends ConsumerStatefulWidget {
  final String? preselectedProjectId;
  const GenerateInvoiceDialog({super.key, this.preselectedProjectId});

  @override
  ConsumerState<GenerateInvoiceDialog> createState() => _GenerateInvoiceDialogState();
}

class _GenerateInvoiceDialogState extends ConsumerState<GenerateInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();

  String _selectedProjectId = 'PRJ-101';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final projects = ref.read(projectNotifierProvider).projects;
    _selectedProjectId = widget.preselectedProjectId ?? (projects.isNotEmpty ? projects.first.id : 'PRJ-101');
    final thirtyDaysLater = DateTime.now().add(const Duration(days: 30));
    _dueDateController.text = thirtyDaysLater.toISOStringSplit();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
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
          Icon(Icons.receipt_long_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text('Generate Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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

                // Client Name
                TextFormField(
                  controller: _clientNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Client / Customer Name *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g. Robert Vance',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Client name is required' : null,
                ),
                const SizedBox(height: 16),

                // Invoice Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Invoice Amount (₹) *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g. 50000',
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

                // Due Date
                TextFormField(
                  controller: _dueDateController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Due Date (YYYY-MM-DD) *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _dueDateController.text = picked.toISOStringSplit();
                          });
                        }
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Due date is required' : null,
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
                    final success = await ref.read(financeNotifierProvider.notifier).generateInvoice(
                          projectId: _selectedProjectId,
                          clientName: _clientNameController.text.trim(),
                          amount: amount,
                          dueDate: _dueDateController.text.trim(),
                        );

                    setState(() => _isSubmitting = false);

                    if (success) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Invoice generated successfully'), backgroundColor: AppColors.success),
                      );
                    } else {
                      final err = ref.read(financeNotifierProvider).errorMessage ?? 'Failed to generate invoice';
                      setState(() => _errorMessage = err);
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Generate Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

extension DateFormatter on DateTime {
  String toISOStringSplit() => toIso8601String().split('T')[0];
}
