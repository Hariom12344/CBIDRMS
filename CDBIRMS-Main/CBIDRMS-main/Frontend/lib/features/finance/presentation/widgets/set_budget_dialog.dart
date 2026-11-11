import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/finance_provider.dart';

class SetBudgetDialog extends ConsumerStatefulWidget {
  final String projectId;
  final double? currentBudget;
  const SetBudgetDialog({super.key, required this.projectId, this.currentBudget});

  @override
  ConsumerState<SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends ConsumerState<SetBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.currentBudget != null) {
      _budgetController.text = widget.currentBudget!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Set Budget - ${widget.projectId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
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

                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Total Project Budget (₹) *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g. 500000',
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Budget is required';
                    final num = double.tryParse(v.trim());
                    if (num == null || num < 0) return 'Budget cannot be negative';
                    return null;
                  },
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
                    final budget = double.parse(_budgetController.text.trim());
                    final success = await ref.read(financeNotifierProvider.notifier).setProjectBudget(
                          projectId: widget.projectId,
                          budget: budget,
                        );

                    setState(() => _isSubmitting = false);

                    if (success) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Project budget set successfully'), backgroundColor: AppColors.success),
                      );
                    } else {
                      final err = ref.read(financeNotifierProvider).errorMessage ?? 'Failed to set budget';
                      setState(() => _errorMessage = err);
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
