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
import '../../../generated/l10n/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/onboarding/profile_type_provider.dart';
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
        SnackBar(content: Text(AppLocalizations.of(context).invalidOtpMsg), backgroundColor: AppColors.error),
      );
      return;
    }
    // If the user already chose a profile pre-auth (the new Welcome ->
    // Choose Profile -> Phone Login flow), create their doc immediately —
    // there's no need to ask again on a dedicated role-select screen.
    // Everything in this block only runs when a pending selection actually
    // exists, so the common/legacy path below (no pending selection) never
    // touches authStateProvider/currentUserDocProvider — preserving the
    // exact prior behavior for that case. Reads authStateProvider (rather
    // than FirebaseAuth.instance directly) so this stays testable through
    // Riverpod overrides like the rest of the app's auth-aware logic.
    final pendingType = ref.read(pendingProfileTypeProvider);
    if (pendingType != null) {
      final user = ref.read(authStateProvider).valueOrNull;
      final existingDoc = ref.read(currentUserDocProvider).valueOrNull;
      // existingDoc != null means this phone number already has a complete
      // account (e.g. re-onboarding after logging out) — don't overwrite it.
      if (user != null && existingDoc == null) {
        final created = await ref.read(authNotifierProvider.notifier).createUserDoc(
              uid: user.uid,
              phone: user.phoneNumber ?? '',
              role: pendingType.backendRole,
              name: '',
              profileType: pendingType.storageValue,
            );
        ref.read(pendingProfileTypeProvider.notifier).state = null;
        if (!context.mounted) return;
        if (created) {
          context.go(RouteConstants.profileSetup);
          return;
        }
      } else {
        ref.read(pendingProfileTypeProvider.notifier).state = null;
      }
    }
    // Router redirect will handle navigation based on user doc state
    context.go(RouteConstants.roleSelect);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final canResend = _seconds == 0;
    final loc = AppLocalizations.of(context);

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
                Text(loc.enterOtp, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  loc.otpSentTo(widget.phone),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxl),
                JmTextField(
                  label: loc.enterOtp,
                  hint: loc.otpHint,
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: AppConstants.otpLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => Validators.otp(v, loc),
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    Text(
                      canResend ? loc.otpNotReceivedMsg : loc.resendIn(_seconds),
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
                        child: Text(loc.resendOtp),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                JmButton(
                  label: loc.verifyOtp,
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
