import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/common/jm_button.dart';
import '../../widgets/common/jm_text_field.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpVerificationScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  int _seconds = AppConstants.otpTimeoutSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = AppConstants.otpTimeoutSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authNotifierProvider.notifier).verifyOtp(_otpCtrl.text.trim());
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: AppColors.error),
      );
      return;
    }
    // Router redirect will handle navigation based on user doc state
    context.go(RouteConstants.roleSelect);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final canResend = _seconds == 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text('OTP నమోదు చేయండి', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter the 6-digit OTP sent to ${widget.phone}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxl),
                JmTextField(
                  label: 'OTP',
                  hint: '• • • • • •',
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: AppConstants.otpLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.otp,
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    Text(
                      canResend ? 'Didn\'t receive OTP?' : 'Resend OTP in ${_seconds}s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (canResend) ...[
                      const SizedBox(width: AppSpacing.xs),
                      TextButton(
                        onPressed: () async {
                          _startTimer();
                          final error = await ref
                              .read(authNotifierProvider.notifier)
                              .sendOtp(widget.phone);
                          if (!context.mounted) return;
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: AppColors.error),
                            );
                          }
                        },
                        child: const Text('Resend'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                JmButton(
                  label: 'Verify OTP',
                  onPressed: isLoading ? null : _verify,
                  isLoading: isLoading,
                  leadingIcon: Icons.verified_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
