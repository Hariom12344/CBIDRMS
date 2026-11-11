import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../domain/models/vendor_model.dart';
import '../providers/vendor_provider.dart';

class AddVendorScreen extends ConsumerStatefulWidget {
  final VendorModel? vendorToEdit;

  const AddVendorScreen({super.key, this.vendorToEdit});

  @override
  ConsumerState<AddVendorScreen> createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends ConsumerState<AddVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _materialsController;
  bool _isSaving = false;

  bool get _isEditing => widget.vendorToEdit != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vendorToEdit;
    _companyController = TextEditingController(text: v?.companyName ?? '');
    _contactController = TextEditingController(text: v?.contactPerson ?? '');
    _emailController = TextEditingController(text: v?.email ?? '');
    _phoneController = TextEditingController(text: v?.phone ?? '');
    _materialsController = TextEditingController(text: v?.materialsSupplied.join(', ') ?? '');
  }

  @override
  void dispose() {
    _companyController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _materialsController.dispose();
    super.dispose();
  }

  List<String> _parseMaterials(String text) {
    if (text.trim().isEmpty) return [];
    final raw = text.split(',');
    final Set<String> seen = {};
    final List<String> result = [];
    for (final item in raw) {
      final trimmed = item.trim();
      final lower = trimmed.toLowerCase();
      if (trimmed.isNotEmpty && !seen.contains(lower)) {
        seen.add(lower);
        result.add(trimmed);
      }
    }
    return result;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final materials = _parseMaterials(_materialsController.text);

    final notifier = ref.read(vendorNotifierProvider.notifier);
    final VendorModel? result;

    if (_isEditing) {
      result = await notifier.updateVendor(
        context,
        widget.vendorToEdit!.id,
        companyName: _companyController.text.trim(),
        contactPerson: _contactController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        materialsSupplied: materials,
      );
    } else {
      result = await notifier.addVendor(
        context,
        companyName: _companyController.text.trim(),
        contactPerson: _contactController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        materialsSupplied: materials,
      );
    }

    setState(() => _isSaving = false);

    if (result != null && mounted) {
      context.pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _isEditing ? 'Edit Vendor' : 'Add Vendor';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(titleText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Company name is required';
                          if (v.trim().length < 2 || v.trim().length > 150) {
                            return 'Company name must be between 2 and 150 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _contactController,
                        label: 'Contact Person',
                        hintText: 'David Miller',
                        prefixIcon: Icons.person_outline,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Contact person is required';
                          if (v.trim().length < 2 || v.trim().length > 100) {
                            return 'Contact person must be between 2 and 100 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hintText: 'david@luxemarble.com',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email address is required';
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: '9876543210',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Phone number is required';
                          final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                          if (digitsOnly.length != 10) {
                            return 'Phone number must be a 10-digit number';
                          }
                          return null;
                        },
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
                        text: _isSaving
                            ? (_isEditing ? 'Updating Vendor...' : 'Registering Vendor...')
                            : (_isEditing ? 'Update Vendor Details' : 'Register Vendor Supplier'),
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _handleSave,
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
