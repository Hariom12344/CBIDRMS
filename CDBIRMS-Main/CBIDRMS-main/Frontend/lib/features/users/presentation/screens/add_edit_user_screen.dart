import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/user_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AddEditUserScreen extends ConsumerStatefulWidget {
  final UserEntity? userToEdit;

  const AddEditUserScreen({super.key, this.userToEdit});

  @override
  ConsumerState<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends ConsumerState<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String _selectedRole = 'PROJECT_MANAGER';
  bool _isActive = true;

  String? _emailInlineError;
  String? _generalError;

  bool get isEditMode => widget.userToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userToEdit?.fullName ?? '');
    _emailController = TextEditingController(text: widget.userToEdit?.email ?? '');
    _phoneController = TextEditingController(text: widget.userToEdit?.phone ?? '');
    _isActive = widget.userToEdit?.isActive ?? true;

    if (widget.userToEdit?.role != null && widget.userToEdit!.role != 'SUPER_ADMIN') {
      _selectedRole = widget.userToEdit!.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    setState(() {
      _emailInlineError = null;
      _generalError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    final notifier = ref.read(userNotifierProvider.notifier);

    Map<String, dynamic> result;
    if (isEditMode) {
      result = await notifier.updateUser(
        widget.userToEdit!.id,
        fullName: fullName,
        email: email,
        phone: phone,
        role: _selectedRole,
      );
    } else {
      result = await notifier.createUser(
        fullName: fullName,
        email: email,
        phone: phone,
        role: _selectedRole,
      );
    }

    if (!mounted) return;

    if (result['success'] == true) {
      final msg = isEditMode
          ? 'User updated successfully'
          : (result['message'] ?? 'User created. Login details sent to their email.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
        ),
      );

      context.pop();
    } else {
      final err = result['error']?.toString() ?? 'An error occurred';
      if (err.contains('USER_EMAIL_EXISTS') || err.contains('Email already registered')) {
        setState(() {
          _emailInlineError = 'This email is already in use by another staff account.';
        });
      } else if (err.contains('ROLE_NOT_ASSIGNABLE')) {
        setState(() {
          _generalError = 'You do not have permission to assign this role.';
        });
      } else {
        setState(() {
          _generalError = err;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);
    final isSubmitting = userState.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          isEditMode ? 'Edit Staff User' : 'Add Staff User',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditMode
                    ? 'Update account details and assigned permissions.'
                    : 'Create a new internal staff user account. A temporary password link will be emailed automatically.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 24),

              if (_generalError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _generalError!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),

              // Full Name
              const Text('Full Name *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. Sarah Jenkins'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Full name is required';
                  if (val.trim().length < 2) return 'Full name must be at least 2 characters';
                  if (val.trim().length > 100) return 'Full name cannot exceed 100 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Email Address
              const Text('Email Address *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. sarah@idpms.com', errorText: _emailInlineError),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Email is required';
                  final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegExp.hasMatch(val.trim())) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Number
              const Text('Phone Number *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('10-digit mobile number'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Phone number is required';
                  final digitsOnly = val.replaceAll(RegExp(r'\D'), '');
                  if (digitsOnly.length != 10) return 'Phone number must be exactly 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Role Dropdown
              const Text('Staff Role *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDecoration(''),
                items: [
                  if (ref.watch(authNotifierProvider).user?.role == 'SUPER_ADMIN')
                    const DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Admin')),
                  const DropdownMenuItem(value: 'COMPANY_ADMIN', child: Text('Company Admin')),
                  const DropdownMenuItem(value: 'PROJECT_MANAGER', child: Text('Project Manager')),
                  const DropdownMenuItem(value: 'SITE_SUPERVISOR', child: Text('Site Supervisor')),
                  const DropdownMenuItem(value: 'DESIGNER', child: Text('Designer')),
                  const DropdownMenuItem(value: 'ACCOUNTANT', child: Text('Accountant')),
                  const DropdownMenuItem(value: 'VENDOR', child: Text('Vendor')),
                  const DropdownMenuItem(value: 'CLIENT', child: Text('Client')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),

              // Active Status Toggle (Edit Mode Only)
              if (isEditMode) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Account Active Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            _isActive ? 'User can log in and access system' : 'Account is deactivated',
                            style: TextStyle(
                              color: _isActive ? AppColors.success : AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isActive,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) async {
                          setState(() => _isActive = val);
                          await ref
                              .read(userNotifierProvider.notifier)
                              .toggleUserStatus(widget.userToEdit!.id, val);
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(0, 48),
                    alignment: Alignment.center,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting ? null : _submitForm,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          isEditMode ? 'Save Changes' : 'Create Staff Account',
                          softWrap: false,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? errorText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      errorText: errorText,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.surfaceLight.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.surfaceLight.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}
