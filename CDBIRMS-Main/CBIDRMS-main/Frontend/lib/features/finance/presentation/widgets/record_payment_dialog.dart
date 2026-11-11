import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/finance_model.dart';
import '../providers/finance_provider.dart';

class RecordPaymentDialog extends ConsumerStatefulWidget {
  final InvoiceModel invoice;
  const RecordPaymentDialog({super.key, required this.invoice});

  @override
  ConsumerState<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedMethod = 'BANK_TRANSFER';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.invoice.pendingAmount.toStringAsFixed(0);
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
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Record Payment - ${widget.invoice.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Client: ${widget.invoice.clientName} • Pending: ₹${widget.invoice.pendingAmount.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
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

                // Payment Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Payment Amount (₹) *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    helperText: 'Must not exceed pending balance of ₹${widget.invoice.pendingAmount.toStringAsFixed(2)}',
                    helperStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Payment amount is required';
                    final num = double.tryParse(v.trim());
                    if (num == null || num <= 0) return 'Amount must be greater than 0';
                    if (num > widget.invoice.pendingAmount) {
                      return 'Amount exceeds pending balance of ₹${widget.invoice.pendingAmount.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payment Method
                const Text('PAYMENT METHOD *', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMethod,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: ['BANK_TRANSFER', 'UPI', 'CASH', 'CHEQUE', 'OTHER']
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.replaceAll('_', ' ')),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMethod = val);
                  },
                ),
                const SizedBox(height: 16),

                // Payment Date
                TextFormField(
                  controller: _dateController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Payment Date (YYYY-MM-DD) *',
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

                // Note / Reference
                TextFormField(
                  controller: _noteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Note / UTR / Reference No.',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g. UTR123456789 or Check #4412',
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
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
                    final success = await ref.read(financeNotifierProvider.notifier).recordPayment(
                          widget.invoice.id,
                          amount: amount,
                          date: _dateController.text.trim(),
                          method: _selectedMethod,
                          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
                        );

                    setState(() => _isSubmitting = false);

                    if (success) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Payment recorded successfully'), backgroundColor: AppColors.success),
                      );
                    } else {
                      final err = ref.read(financeNotifierProvider).errorMessage ?? 'Failed to record payment';
                      setState(() => _errorMessage = err);
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Record Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
