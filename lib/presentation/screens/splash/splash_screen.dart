import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth/auth_provider.dart';
import '../../../core/router/firebase_initialized_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final firebaseReady = ref.read(firebaseInitializedProvider);
    if (!firebaseReady) {
      // Firebase not configured — show setup instructions
      return; // splash stays; in real app show setup screen
    }

    final userDoc = ref.read(currentUserDocProvider);
    userDoc.when(
      data: (doc) {
        if (doc == null) {
          context.go(RouteConstants.languageSelect);
        } else if (!doc.isProfileComplete) {
          context.go(RouteConstants.profileSetup);
        } else if (doc.isFarmer) {
          context.go(RouteConstants.farmerDashboard);
        } else {
          context.go(RouteConstants.shepherdDashboard);
        }
      },
      loading: () => context.go(RouteConstants.languageSelect),
      error: (_, __) => context.go(RouteConstants.languageSelect),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grass_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'జీవమిత్ర • जीवमित्र',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 80),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
