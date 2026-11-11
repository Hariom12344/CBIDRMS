import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../providers/lead_provider.dart';

class CreateLeadScreen extends ConsumerStatefulWidget {
  const CreateLeadScreen({super.key});

  @override
  ConsumerState<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends ConsumerState<CreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _propertyController = TextEditingController();
  final _budgetController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _propertyController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      
      final budgetText = _budgetController.text.trim();
      final budget = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;
      final messenger = ScaffoldMessenger.of(context);
      final nav = GoRouter.of(context);

      final newLead = await ref.read(leadsNotifierProvider.notifier).createLead(
        clientName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        propertyType: _propertyController.text.trim(),
        estimatedBudget: budget,
      );

      if (newLead != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Lead ${newLead.id} created successfully!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        nav.pop();
      } else {
        final err = ref.read(leadsNotifierProvider).errorMessage ?? 'Failed to create lead';
        messenger.showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leadsState = ref.watch(leadsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create New Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        label: 'Client Name',
                        hintText: 'Alexander Hayes',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hintText: 'alex@example.com',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: '+1 555-0321',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _propertyController,
                        label: 'Property Type / Requirements',
                        hintText: '3BHK Flat, Office Space, Villa',
                        prefixIcon: Icons.home_work_outlined,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _budgetController,
                        label: 'Estimated Budget (₹)',
                        hintText: '75000',
                        prefixIcon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Save Lead to Pipeline',
                        isLoading: leadsState.isMutating,
                        onPressed: leadsState.isMutating ? null : _handleSave,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
