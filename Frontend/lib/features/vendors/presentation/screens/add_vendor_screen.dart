import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';

class AddVendorScreen extends StatefulWidget {
  const AddVendorScreen({super.key});

  @override
  State<AddVendorScreen> createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends State<AddVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _materialsController = TextEditingController();

  @override
  void dispose() {
    _companyController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _materialsController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor registered successfully!'), backgroundColor: AppColors.success),
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
        title: const Text('Add Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        controller: _companyController,
                        label: 'Company Name',
                        hintText: 'Luxe Marble & Granite Co.',
                        prefixIcon: Icons.storefront_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter company name' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _contactController,
                        label: 'Contact Person',
                        hintText: 'David Miller',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hintText: 'david@luxemarble.com',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: '+1 555-0711',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _materialsController,
                        label: 'Materials Supplied (Comma separated)',
                        hintText: 'Italian Marble, Quartz, Granite',
                        prefixIcon: Icons.inventory_2_outlined,
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Register Vendor Supplier',
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
