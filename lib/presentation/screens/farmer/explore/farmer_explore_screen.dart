import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/disease_alert_model.dart';
import '../../../providers/alerts/disease_alert_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../widgets/common/jm_empty_state.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/common/responsive_center.dart';
import '../../../widgets/common/standard_app_bar.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = ref.read(locationProvider);
      if (!loc.hasValue || loc.valueOrNull == null) {
        ref.read(locationProvider.notifier).fetch();
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Explore',
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.coronavirus_rounded), text: 'Disease Alerts'),
            Tab(icon: Icon(Icons.tips_and_updates_rounded), text: 'Advisory'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, __) => _tabs.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => context.push(RouteConstants.reportAlert),
                icon: const Icon(Icons.add_alert_rounded),
                label: const Text('Report'),
                heroTag: 'report_alert_fab',
              )
            : const SizedBox.shrink(),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _DiseaseAlertsTab(),
          _AdvisoryTab(),
        ],
      ),
    );
  }
}

// ─── Disease Alerts tab ───────────────────────────────────────────────────────

class _DiseaseAlertsTab extends ConsumerWidget {
  const _DiseaseAlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locAsync = ref.watch(locationProvider);

    if (locAsync.isLoading) {
      return const Center(child: JmLoading());
    }
    if (locAsync.hasError || locAsync.valueOrNull == null) {
      return _LocationPrompt(
        onEnable: () => ref.read(locationProvider.notifier).fetch(),
      );
    }

    final loc = locAsync.value!;
    final alertsAsync = ref.watch(nearbyAlertsProvider((
      lat: loc.lat,
      lng: loc.lng,
      radiusKm: 150,
    )));

    return alertsAsync.when(
      loading: () => const JmShimmerList(count: 3, cardHeight: 120),
      error: (e, _) => JmErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(nearbyAlertsProvider),
      ),
      data: (alerts) {
        if (alerts.isEmpty) {
          return const JmEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'No Active Alerts',
            subtitle: 'No disease alerts reported in your area. Stay vigilant!',
          );
        }
        return ResponsiveCenter(
          child: ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => _AlertCard(alert: alerts[i]),
          ),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final DiseaseAlertModel alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final (bg, border, textColor) = _severityColors(alert.severity);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: border, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: _SeverityIcon(severity: alert.severity),
          title: Text(
            alert.title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: textColor),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${alert.disease} · ${alert.affectedSpecies}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: textColor.withAlpha(180)),
              ),
              Text(
                '${alert.district}, ${alert.state} · ${_age(alert.issuedAt)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: textColor.withAlpha(140)),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
          children: [
            const Divider(),
            Text(alert.description,
                style: Theme.of(context).textTheme.bodyMedium),
            if (alert.prevention != null) ...[
              const SizedBox(height: AppSpacing.md),
              _InfoBlock(
                icon: Icons.shield_rounded,
                label: 'Prevention',
                text: alert.prevention!,
                color: AppColors.success,
              ),
            ],
            if (alert.treatment != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _InfoBlock(
                icon: Icons.healing_rounded,
                label: 'Treatment',
                text: alert.treatment!,
                color: AppColors.info,
              ),
            ],
            if (alert.vetContactPhone != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('tel:${alert.vetContactPhone}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.phone_rounded, size: 16),
                label: Text('Call Vet: ${alert.vetContactPhone}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Source: ${alert.sourceAuthority}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textDisabled),
            ),
          ],
        ),
      ),
    );
  }

  (Color bg, Color border, Color text) _severityColors(String severity) {
    return switch (severity) {
      'critical' => (
          AppColors.errorContainer,
          AppColors.error,
          AppColors.error,
        ),
      'high' => (
          AppColors.warningContainer,
          AppColors.warning,
          AppColors.warning,
        ),
      'medium' => (
          AppColors.infoContainer,
          AppColors.info,
          AppColors.info,
        ),
      _ => (
          AppColors.surfaceVariant,
          AppColors.outline,
          AppColors.textSecondary,
        ),
    };
  }

  String _age(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}

class _SeverityIcon extends StatelessWidget {
  final String severity;
  const _SeverityIcon({required this.severity});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (severity) {
      'critical' => (Icons.dangerous_rounded, AppColors.error),
      'high' => (Icons.warning_rounded, AppColors.warning),
      'medium' => (Icons.info_rounded, AppColors.info),
      _ => (Icons.info_outline_rounded, AppColors.textSecondary),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String label, text;
  final Color color;
  const _InfoBlock(
      {required this.icon,
      required this.label,
      required this.text,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 2),
                Text(text, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPrompt extends StatelessWidget {
  final VoidCallback onEnable;
  const _LocationPrompt({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded,
                size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.base),
            Text('Location Required',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enable location to see disease alerts near your farm.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onEnable,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Enable Location'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Advisory tab ─────────────────────────────────────────────────────────────

class _AdvisoryTab extends StatelessWidget {
  const _AdvisoryTab();

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

  @override
  Widget build(BuildContext context) {
    final categories = _tips.map((t) => t.category).toSet().toList();

    return DefaultTabController(
      length: categories.length + 1,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                const Tab(text: 'All'),
                ...categories.map((c) => Tab(text: c)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TipList(tips: _tips),
                ...categories.map((c) => _TipList(
                    tips: _tips.where((t) => t.category == c).toList())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipList extends StatelessWidget {
  final List<_Tip> tips;
  const _TipList({required this.tips});

  @override
  Widget build(BuildContext context) {
    return ResponsiveCenter(
      child: ListView.separated(
        padding: AppSpacing.screenPadding,
        itemCount: tips.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => _TipCard(tip: tips[i]),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final _Tip tip;
  const _TipCard({required this.tip});

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
                          tip.category,
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
