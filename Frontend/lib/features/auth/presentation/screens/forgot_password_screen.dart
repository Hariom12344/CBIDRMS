import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final success = await ref.read(authNotifierProvider.notifier).forgotPassword(
            context,
            _emailController.text.trim(),
          );
      if (success && mounted) {
        context.push('/reset-password');
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
                              const Text('Forgot Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Enter your registered email address to receive password reset token.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 28),

                          CustomTextField(
                            controller: _emailController,
                            label: 'Registered Email',
                            hintText: 'user@example.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter your email' : null,
                          ),
                          const SizedBox(height: 28),

                          CustomButton(
                            text: 'Send Reset Link',
                            isLoading: authState.isLoading,
                            onPressed: _handleSubmit,
                          ),
                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () => context.push('/reset-password'),
                            child: const Text('Already have a reset token? Enter here', style: TextStyle(color: AppColors.primary, fontSize: 13)),
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
