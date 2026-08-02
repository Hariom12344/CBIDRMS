import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';

class CreateLeadScreen extends StatefulWidget {
  const CreateLeadScreen({super.key});

  @override
  State<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends State<CreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _propertyController = TextEditingController();
  final _budgetController = TextEditingController();
  String _status = 'New';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _propertyController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead created successfully!'), backgroundColor: AppColors.success),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        label: 'Estimated Budget (\$)',
                        hintText: '75000',
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      const Text('Lead Status', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _status,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_outlined, color: AppColors.textMuted)),
                        items: const [
                          DropdownMenuItem(value: 'New', child: Text('New')),
                          DropdownMenuItem(value: 'Contacted', child: Text('Contacted')),
                          DropdownMenuItem(value: 'Meeting Scheduled', child: Text('Meeting Scheduled')),
                          DropdownMenuItem(value: 'Proposal Sent', child: Text('Proposal Sent')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Save Lead to Pipeline',
                        onPressed: _handleSave,
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
