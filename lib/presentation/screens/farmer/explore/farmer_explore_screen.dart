import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../widgets/common/responsive_center.dart';
import '../../../widgets/explore/category_card.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/explore_header.dart';
import '../../../widgets/explore/search_card.dart';
import '../../shared/alerts/alert_dashboard.dart';

class FarmerExploreScreen extends ConsumerStatefulWidget {
  const FarmerExploreScreen({super.key});

  @override
  ConsumerState<FarmerExploreScreen> createState() =>
      _FarmerExploreScreenState();
}

class _FarmerExploreScreenState extends ConsumerState<FarmerExploreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // Fixed-height (non-collapsing) hero, unlike the Dashboard's SliverAppBar
  // — deliberate: Advisory nests its own category TabBarView inside this
  // tab, and combining that with an outer collapsing NestedScrollView risks
  // a genuine scroll-coordination conflict between the two independent
  // scrollables. A fixed header keeps the same visual language (gradient,
  // motif, overlay, typography) without that risk.
  static const _headerHeight = 150.0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, __) => _tabs.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => context.push(RouteConstants.reportAlert),
                icon: const Icon(Icons.add_alert_rounded),
                label: Text(loc.reportBtn),
                heroTag: 'report_alert_fab',
              )
            : const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          SizedBox(
            height: _headerHeight,
            width: double.infinity,
            child: ExploreHeader(
              title: loc.explore,
              subtitle: loc.exploreSubtitle,
              icon: Icons.coronavirus_rounded,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  tooltip: loc.searchEverythingTooltip,
                  onPressed: () => context.push(RouteConstants.unifiedSearch),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.primaryDark,
            child: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: const Icon(Icons.coronavirus_rounded), text: loc.diseaseAlertsTabLabel),
                Tab(icon: const Icon(Icons.tips_and_updates_rounded), text: loc.advisoryTabLabel),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                AlertDashboard(),
                _AdvisoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Advisory tab ─────────────────────────────────────────────────────────────

/// Localized display label for a tip's category. The underlying
/// [_Tip.category] string stays English — it's also the lookup key into
/// [_AdvisoryTabState._categoryIcons]/`_categoryColors` and the value
/// `_categories` filters on — only the text shown to the user changes.
String _categoryLabel(String category, AppLocalizations loc) => switch (category) {
      'Health' => loc.categoryHealth,
      'Nutrition' => loc.categoryNutrition,
      'Fodder' => loc.categoryFodder,
      'Grazing' => loc.categoryGrazing,
      'Finance' => loc.categoryFinance,
      'Weather' => loc.categoryWeather,
      _ => category,
    };

class _AdvisoryTab extends StatefulWidget {
  const _AdvisoryTab();

  @override
  State<_AdvisoryTab> createState() => _AdvisoryTabState();
}

class _AdvisoryTabState extends State<_AdvisoryTab>
    with SingleTickerProviderStateMixin {
  static const _tips = [
    _Tip(
      icon: Icons.vaccines_rounded,
      title: 'Seasonal Vaccination',
      body:
          'Vaccinate sheep for PPR (Peste des Petits Ruminants) before the monsoon and FMD vaccination every 6 months. Contact your local AH department for free camps.',
      color: AppColors.success,
      category: 'Health',
    ),
    _Tip(
      icon: Icons.water_drop_rounded,
      title: 'Water Quality in Summer',
      body:
          'Ensure animals drink 3–5 liters of clean water per day in summer. Stagnant water causes diarrhea and foot-rot. Clean troughs daily.',
      color: AppColors.info,
      category: 'Nutrition',
    ),
    _Tip(
      icon: Icons.grass_rounded,
      title: 'Fodder Storage',
      body:
          'Dry fodder in shade for 2 days before stacking to prevent mold. Keep stacks off the ground with wooden pallets. Properly stored fodder lasts 6–8 months.',
      color: AppColors.primary,
      category: 'Fodder',
    ),
    _Tip(
      icon: Icons.monitor_weight_rounded,
      title: 'Optimal Stocking Density',
      body:
          'Overgrazing reduces fodder quality. Rule of thumb: 1 sheep per 0.25 acres of good pasture. Rotate between plots every 3–4 weeks.',
      color: AppColors.secondary,
      category: 'Grazing',
    ),
    _Tip(
      icon: Icons.pest_control_rounded,
      title: 'Tick & Parasite Control',
      body:
          'Dip or spray cattle-grade acaricide every 21 days during monsoon. Internal deworming every 3 months — consult your vet for dosage by weight.',
      color: AppColors.warning,
      category: 'Health',
    ),
    _Tip(
      icon: Icons.currency_rupee_rounded,
      title: 'Govt Subsidy Schemes',
      body:
          'AP farmers can claim subsidies under NABARD schemes for sheep rearing. Apply at nearest Animal Husbandry office. Bring Aadhaar, land records, and bank passbook.',
      color: AppColors.primary,
      category: 'Finance',
    ),
    _Tip(
      icon: Icons.thermostat_rounded,
      title: 'Heat Stress in Summer',
      body:
          'Avoid grazing between 11 AM – 4 PM in peak summer. Ensure shade for animals. Heat stress reduces weight gain by 15–20%. Early morning grazing is most productive.',
      color: AppColors.error,
      category: 'Weather',
    ),
  ];
  late final List<String> _categories =
      _tips.map((t) => t.category).toSet().toList();
  late final TabController _categoryTabs =
      TabController(length: _categories.length + 1, vsync: this);

  @override
  void initState() {
    super.initState();
    _categoryTabs.addListener(() {
      if (!_categoryTabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _categoryTabs.dispose();
    super.dispose();
  }

  static const _categoryIcons = {
    'Health': Icons.medical_services_rounded,
    'Nutrition': Icons.water_drop_rounded,
    'Fodder': Icons.grass_rounded,
    'Grazing': Icons.landscape_rounded,
    'Finance': Icons.currency_rupee_rounded,
    'Weather': Icons.thermostat_rounded,
  };

  static const _categoryColors = {
    'Health': AppColors.success,
    'Nutrition': AppColors.info,
    'Fodder': AppColors.primary,
    'Grazing': AppColors.secondary,
    'Finance': AppColors.primary,
    'Weather': AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ResponsiveCenter(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchCard(hint: loc.searchAdvisoryHint),
            const SizedBox(height: AppSpacing.base),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return CategoryCard(
                      icon: Icons.apps_rounded,
                      label: loc.allCategoryLabel,
                      color: AppColors.primary,
                      selected: _categoryTabs.index == 0,
                      onTap: () => setState(() => _categoryTabs.animateTo(0)),
                    );
                  }
                  final category = _categories[i - 1];
                  return CategoryCard(
                    icon: _categoryIcons[category] ?? Icons.tips_and_updates_rounded,
                    label: _categoryLabel(category, loc),
                    color: _categoryColors[category] ?? AppColors.primary,
                    selected: _categoryTabs.index == i,
                    onTap: () => setState(() => _categoryTabs.animateTo(i)),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Expanded(
              child: TabBarView(
                controller: _categoryTabs,
                children: [
                  _TipList(tips: _tips, loc: loc),
                  ..._categories.map((c) =>
                      _TipList(tips: _tips.where((t) => t.category == c).toList(), loc: loc)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipList extends StatelessWidget {
  final List<_Tip> tips;
  final AppLocalizations loc;
  const _TipList({required this.tips, required this.loc});

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return EmptyStateCard(
        icon: Icons.tips_and_updates_outlined,
        title: loc.noTipsYetTitle,
        subtitle: loc.noTipsYetMsg,
      );
    }
    return ListView.separated(
      itemCount: tips.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _TipCard(tip: tips[i], loc: loc),
    );
  }
}

class _TipCard extends StatelessWidget {
  final _Tip tip;
  final AppLocalizations loc;
  const _TipCard({required this.tip, required this.loc});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadius,
        side: BorderSide(color: tip.color.withAlpha(60)),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tip.color.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tip.icon, color: tip.color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip.title,
                          style: Theme.of(context).textTheme.titleSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 1),
                        decoration: BoxDecoration(
                          color: tip.color.withAlpha(26),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          _categoryLabel(tip.category, loc),
                          style: TextStyle(
                              fontSize: 10,
                              color: tip.color,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(tip.body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _Tip {
  final IconData icon;
  final String title, body, category;
  final Color color;
  const _Tip({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.category,
  });
}
