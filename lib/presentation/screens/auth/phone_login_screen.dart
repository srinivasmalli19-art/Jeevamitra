import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/common/jm_button.dart';
import '../../widgets/common/jm_text_field.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _devLogin(String role) async {
    await ref.read(authNotifierProvider.notifier).devSignIn(role: role);
    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dev login failed: ${authState.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = '+91${_phoneCtrl.text.trim()}';
    final error = await ref.read(authNotifierProvider.notifier).sendOtp(phone);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }
    context.push(RouteConstants.otpVerification, extra: {'phone': phone});
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('మీ మొబైల్ నంబర్', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter your mobile number to receive OTP',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: AppSpacing.inputHeight,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline),
                        borderRadius: AppSpacing.inputRadius,
                        color: AppColors.surfaceVariant,
                      ),
                      child: const Center(
                        child: Text('+91', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: JmTextField(
                        label: 'Mobile Number',
                        hint: '9876543210',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: Validators.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                JmButton(
                  label: 'Send OTP',
                  onPressed: isLoading ? null : _sendOtp,
                  isLoading: isLoading,
                  leadingIcon: Icons.send_rounded,
                ),
                const SizedBox(height: AppSpacing.base),
                Center(
                  child: Text(
                    'By continuing, you agree to our Terms & Privacy Policy',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),

                // ── Debug-only bypass (invisible in release builds) ──────────
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        'DEBUG ONLY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : () => _devLogin('farmer'),
                          icon: const Icon(Icons.agriculture_rounded, size: 18),
                          label: const Text('As Farmer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade800,
                            side: BorderSide(color: Colors.orange.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : () => _devLogin('shepherd'),
                          icon: const Icon(Icons.pets_rounded, size: 18),
                          label: const Text('As Shepherd'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade800,
                            side: BorderSide(color: Colors.orange.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
