import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resetPassword(
        context: context,
        token: _tokenController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      if (success && mounted) {
        context.go('/login');
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
                constraints: const BoxConstraints(maxWidth: 440),
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
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                                    onPressed: () => context.pop(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reset Password',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Enter your reset token and your new password.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Reset Token Input
                              CustomTextField(
                                controller: _tokenController,
                                label: 'Reset Token',
                                hintText: 'Paste token here',
                                prefixIcon: Icons.key_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter the reset token';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // New Password Input
                              CustomTextField(
                                controller: _newPasswordController,
                                label: 'New Password',
                                hintText: 'At least 6 characters',
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                                obscureText: _obscureNewPassword,
                                onToggleVisibility: () {
                                  setState(() => _obscureNewPassword = !_obscureNewPassword);
                                },
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Confirm Password Input
                              CustomTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm New Password',
                                hintText: 'Re-enter your new password',
                                prefixIcon: Icons.lock_reset_rounded,
                                isPassword: true,
                                obscureText: _obscureConfirmPassword,
                                onToggleVisibility: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                                validator: (value) {
                                  if (value != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),

                              CustomButton(
                                text: 'Update Password',
                                isLoading: auth.isLoading,
                                onPressed: _handleResetPassword,
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
