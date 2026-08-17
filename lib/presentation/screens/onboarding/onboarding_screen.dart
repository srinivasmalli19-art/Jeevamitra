import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/common/jm_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  List<_OnboardPage> _pages(AppLocalizations loc) => [
        _OnboardPage(
          icon: Icons.agriculture_rounded,
          title: loc.onboardTitle1,
          body: loc.onboardBody1,
          color: AppColors.primary,
        ),
        _OnboardPage(
          icon: Icons.search_rounded,
          title: loc.onboardTitle2,
          body: loc.onboardBody2,
          color: AppColors.secondary,
        ),
        _OnboardPage(
          icon: Icons.local_hospital_rounded,
          title: loc.onboardTitle3,
          body: loc.onboardBody3,
          color: AppColors.info,
        ),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final pages = _pages(loc);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => pages[i],
              ),
            ),
            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i ? AppColors.primary : AppColors.outline,
                          borderRadius: AppSpacing.chipRadius,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_page < pages.length - 1)
                    Row(
                      children: [
                        Expanded(
                          child: JmButton(
                            label: loc.skipBtn,
                            onPressed: () => context.go(RouteConstants.chooseProfile),
                            variant: JmButtonVariant.ghost,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: JmButton(
                            label: '${loc.nextBtn} →',
                            onPressed: () => _controller.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    JmButton(
                      label: loc.getStartedBtn,
                      onPressed: () => context.go(RouteConstants.phoneLogin),
                      leadingIcon: Icons.arrow_forward_rounded,
                    ),
                  const SizedBox(height: AppSpacing.base),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: color),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.base),
          Text(body, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
