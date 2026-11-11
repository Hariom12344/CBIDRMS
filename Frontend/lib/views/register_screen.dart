import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'CLIENT';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        context: context,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (success && mounted) {
        if (authProvider.isAuthenticated) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return Form(
                      key: _formKey,
                      child: Card(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: AppColors.surfaceLight.withOpacity(0.4)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Bar
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                                    onPressed: () => context.pop(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Create Account',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 48),
                                child: Text(
                                  'Register to access IDPMS modules',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Full Name
                              CustomTextField(
                                controller: _fullNameController,
                                label: 'Full Name',
                                hintText: 'John Doe',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Email Address
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                hintText: 'john@example.com',
                                prefixIcon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Account Role Dropdown
                              const Text(
                                'Account Role',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedRole,
                                dropdownColor: AppColors.surface,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted, size: 20),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'CLIENT', child: Text('Client')),
                                  DropdownMenuItem(value: 'ADMIN', child: Text('Administrator')),
                                  DropdownMenuItem(value: 'PROJECT_MANAGER', child: Text('Project Manager')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedRole = val;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 18),

                              // Password
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hintText: 'At least 6 characters',
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                                obscureText: _obscurePassword,
                                onToggleVisibility: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Confirm Password
                              CustomTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                hintText: 'Re-enter your password',
                                prefixIcon: Icons.lock_reset_rounded,
                                isPassword: true,
                                obscureText: _obscureConfirmPassword,
                                onToggleVisibility: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),

                              // Submit Button
                              CustomButton(
                                text: 'Complete Registration',
                                isLoading: auth.isLoading,
                                onPressed: _handleRegister,
                              ),
                              const SizedBox(height: 24),

                              // Already Have Account
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account? ',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
