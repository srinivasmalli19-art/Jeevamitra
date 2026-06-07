import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
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

    await ref.read(authNotifierProvider.notifier).createUserDoc(
      uid: user.uid,
      phone: user.phoneNumber ?? '',
      role: role,
      name: _nameCtrl.text.trim(),
      village: _villageCtrl.text.trim(),
    );
    if (!context.mounted) return;

    if (role == 'farmer') {
      context.go(RouteConstants.farmerDashboard);
    } else {
      context.go(RouteConstants.shepherdDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final userDoc = ref.watch(currentUserDocProvider).valueOrNull;
    final isFarmer = userDoc?.isFarmer ?? true;

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
                  isFarmer ? 'రైతు ప్రొఫైల్' : 'కాపరి ప్రొఫైల్',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Complete your profile to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                JmTextField(
                  label: 'Your Name',
                  hint: 'Enter your full name',
                  controller: _nameCtrl,
                  validator: Validators.name,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(height: AppSpacing.base),
                JmTextField(
                  label: 'Village / Town',
                  hint: 'Your village or town name',
                  controller: _villageCtrl,
                  validator: Validators.village,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                const SizedBox(height: AppSpacing.base),
                JmTextField(
                  label: 'District',
                  hint: 'Your district',
                  controller: _districtCtrl,
                  validator: (v) => Validators.required(v, 'District'),
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.map_outlined),
                ),
                const SizedBox(height: AppSpacing.xxl),
                JmButton(
                  label: 'Save & Continue',
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
