import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../domain/models/customer_model.dart';
import '../providers/customer_provider.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  final CustomerModel? customerToEdit;

  const AddCustomerScreen({super.key, this.customerToEdit});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool get isEditing => widget.customerToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customerToEdit?.name ?? '');
    _emailController = TextEditingController(text: widget.customerToEdit?.email ?? '');
    _phoneController = TextEditingController(text: widget.customerToEdit?.phone ?? '');
    _addressController = TextEditingController(text: widget.customerToEdit?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    final notifier = ref.read(customerNotifierProvider.notifier);
    bool success;

    if (isEditing) {
      success = await notifier.updateCustomer(
        context,
        widget.customerToEdit!.id,
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
    } else {
      success = await notifier.addCustomer(
        context,
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
    }

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Edit Customer Profile' : 'Add Customer',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                        label: 'Customer Name',
                        hintText: 'John Doe',
                        prefixIcon: Icons.person_outline,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter customer name';
                          if (v.trim().length < 2) return 'Name must be at least 2 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hintText: 'john@example.com',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter email address';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: '555-0192',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter phone number';
                          if (v.trim().length < 5) return 'Phone number must be at least 5 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Billing / Project Address',
                        hintText: '123 Main St, City, State',
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter address';
                          if (v.trim().length < 5) return 'Address must be at least 5 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: isEditing ? 'Update Customer Profile' : 'Save Customer Profile',
                        isLoading: customerState.isLoading,
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
