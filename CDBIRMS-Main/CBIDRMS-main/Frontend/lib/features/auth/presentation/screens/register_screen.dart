import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'CLIENT';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final success = await ref.read(authNotifierProvider.notifier).register(
            context: context,
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: _phoneController.text.trim(),
            role: _selectedRole,
          );
      if (success && mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                                onPressed: () => context.pop(),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Register Account',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          CustomTextField(
                            controller: _fullNameController,
                            label: 'Full Name',
                            hintText: 'Jane Smith',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hintText: 'jane@example.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter email' : null,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hintText: '+1 234 567 8900',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          const Text('Account Role', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedRole,
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted, size: 20),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Admin')),
                              DropdownMenuItem(value: 'COMPANY_ADMIN', child: Text('Company Admin')),
                              DropdownMenuItem(value: 'ADMIN', child: Text('System Admin')),
                              DropdownMenuItem(value: 'PROJECT_MANAGER', child: Text('Project Manager')),
                              DropdownMenuItem(value: 'SITE_SUPERVISOR', child: Text('Site Supervisor')),
                              DropdownMenuItem(value: 'DESIGNER', child: Text('Interior Designer')),
                              DropdownMenuItem(value: 'ACCOUNTANT', child: Text('Accountant')),
                              DropdownMenuItem(value: 'VENDOR', child: Text('Vendor')),
                              DropdownMenuItem(value: 'CLIENT', child: Text('Client')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedRole = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: 'At least 6 characters',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                          ),
                          const SizedBox(height: 28),

                          CustomButton(
                            text: 'Create Account',
                            isLoading: authState.isLoading,
                            onPressed: _handleRegister,
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already registered? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
