import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/common/jm_button.dart';
import '../../widgets/common/jm_text_field.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocAsync = ref.read(currentUserDocProvider);
    final role = userDocAsync.valueOrNull?.role ?? 'farmer';

    final saved = await ref.read(authNotifierProvider.notifier).createUserDoc(
      uid: user.uid,
      phone: user.phoneNumber ?? '',
      role: role,
      name: _nameCtrl.text.trim(),
      village: _villageCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
    );
    if (!context.mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveProfileFailedMsg),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (role == 'farmer') {
      context.go(RouteConstants.farmerDashboard);
    } else {
      context.go(RouteConstants.shepherdDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
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
                Text(
                  loc.completeProfile,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  loc.completeProfileSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                JmTextField(
                  label: loc.yourName,
                  hint: loc.yourNameHint,
                  controller: _nameCtrl,
                  validator: (v) => Validators.name(v, loc),
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(height: AppSpacing.base),
                JmTextField(
                  label: loc.yourVillage,
                  hint: loc.yourVillageHint,
                  controller: _villageCtrl,
                  validator: (v) => Validators.village(v, loc),
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                const SizedBox(height: AppSpacing.base),
                JmTextField(
                  label: loc.yourDistrict,
                  hint: loc.yourDistrict,
                  controller: _districtCtrl,
                  validator: (v) => Validators.district(v, loc),
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.map_outlined),
                ),
                const SizedBox(height: AppSpacing.xxl),
                JmButton(
                  label: loc.saveContinueBtn,
                  onPressed: isLoading ? null : _save,
                  isLoading: isLoading,
                  leadingIcon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
