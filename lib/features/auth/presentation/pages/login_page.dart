import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

/// Login page for phone number authentication
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement phone authentication logic
      // await ref.read(authProvider.notifier).verifyPhoneNumber(
      //   _phoneController.text,
      // );

      // Navigate to verification page
      // context.push('/verify-phone', extra: _phoneController.text);

      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // App Logo or Icon
                Icon(
                  Icons.chat_bubble,
                  size: 80,
                  color: AppColors.primary,
                ),

                const SizedBox(height: 24),

                // Welcome Text
                Text(
                  'Welcome to Chatz',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter your phone number to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Phone Number Field
                PhoneTextField(
                  controller: _phoneController,
                  validator: Validators.validatePhoneNumber,
                  onSubmitted: (_) => _handleLogin(),
                ),

                const SizedBox(height: 24),

                // Login Button
                CustomButton(
                  text: 'Send Verification Code',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // Terms and Privacy
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Alternative Login Methods
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign In Button
                CustomButton(
                  text: 'Continue with Google',
                  onPressed: () {
                    // TODO: Implement Google Sign In
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google Sign In coming soon!'),
                      ),
                    );
                  },
                  isOutlined: true,
                  leading: const Icon(Icons.g_mobiledata, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
