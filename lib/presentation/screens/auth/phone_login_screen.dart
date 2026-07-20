import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/otp_flow_logger.dart';
import '../../../core/utils/validators.dart';
import '../../../generated/l10n/app_localizations.dart';
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

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = '+91${_phoneCtrl.text.trim()}';
    otpFlowLog('Phone number entered on login screen — phone=$phone');
    final error = await ref.read(authNotifierProvider.notifier).sendOtp(phone);
    if (!context.mounted) return;
    if (error != null) {
      otpFlowLog(
        'Login screen navigation decision — error present, '
        'staying on login screen: $error',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }
    otpFlowLog(
      'Login screen navigation decision — no error, navigating to OTP screen',
    );
    context.push(RouteConstants.otpVerification, extra: {'phone': phone});
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final loc = AppLocalizations.of(context);

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
                Text(loc.mobileNumber, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  loc.mobileNumberSubtitle,
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
                        label: loc.mobileNumber,
                        hint: loc.mobileNumberHint,
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => Validators.phone(v, loc),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                JmButton(
                  label: loc.sendOtp,
                  onPressed: isLoading ? null : _sendOtp,
                  isLoading: isLoading,
                  leadingIcon: Icons.send_rounded,
                ),
                const SizedBox(height: AppSpacing.base),
                Center(
                  child: Text(
                    loc.termsAgreement,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
