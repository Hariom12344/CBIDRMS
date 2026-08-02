import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final success = await ref.read(authNotifierProvider.notifier).resetPassword(
            context,
            _tokenController.text.trim(),
            _newPasswordController.text,
          );
      if (success && mounted) {
        context.go('/login');
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
                constraints: const BoxConstraints(maxWidth: 440),
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
                              const Text('Reset Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          CustomTextField(
                            controller: _tokenController,
                            label: 'Reset Token',
                            hintText: 'Paste token here',
                            prefixIcon: Icons.key_rounded,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter reset token' : null,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _newPasswordController,
                            label: 'New Password',
                            hintText: 'At least 6 characters',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                          ),
                          const SizedBox(height: 28),

                          CustomButton(
                            text: 'Update Password',
                            isLoading: authState.isLoading,
                            onPressed: _handleReset,
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
