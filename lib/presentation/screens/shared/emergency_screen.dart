import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/location_provider.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: AppColors.emergency,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // SOS banner
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.emergency, Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Column(
              children: [
                const Icon(Icons.emergency_rounded,
                    size: 48, color: Colors.white),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Animal Emergency?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Call the helpline immediately or locate the nearest vet.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.base),
                FilledButton.icon(
                  onPressed: () => _call('1962'),
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('Call Helpline: 1962'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.emergency,
                    minimumSize:
                        const Size(double.infinity, AppSpacing.buttonHeight),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Government Helplines',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _ContactTile(
            icon: Icons.support_agent_rounded,
            title: 'Animal Husbandry Helpline',
            subtitle: 'Livestock emergency — free call 24×7',
            number: '1962',
            color: AppColors.emergency,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactTile(
            icon: Icons.local_police_rounded,
            title: 'National Emergency',
            subtitle: 'Police, fire, ambulance',
            number: '112',
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactTile(
            icon: Icons.health_and_safety_rounded,
            title: 'AP Animal Husbandry Dept',
            subtitle: 'Andhra Pradesh state helpline',
            number: '18004251525',
            color: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Quick Actions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: Icons.medical_services_rounded,
            title: 'Find Nearest Vet',
            subtitle: 'Locate verified vets near you',
            color: AppColors.primary,
            onTap: () {
              context.pop();
              context.go(RouteConstants.shepherdVets);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.my_location_rounded,
            title: 'Share My Location',
            subtitle: 'Copy current GPS coordinates',
            color: AppColors.secondary,
            onTap: () async {
              final loc = ref.read(locationProvider);
              if (loc.valueOrNull == null) {
                await ref.read(locationProvider.notifier).fetch();
              }
              final l = ref.read(locationProvider).valueOrNull;
              if (l != null && context.mounted) {
                await _shareLocation(context, l.lat, l.lng);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Fetching location, please wait...')),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Common Livestock Emergencies',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ..._symptoms.map((s) => _SymptomCard(symptom: s)),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _shareLocation(
      BuildContext context, double lat, double lng) async {
    final text = 'My location: $lat, $lng\nhttps://maps.google.com/?q=$lat,$lng';
    final uri = Uri.parse(
        'sms:?body=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coordinates: $lat, $lng')),
      );
    }
  }

  static const _symptoms = [
    _Symptom(
      title: 'Bloat / Distended Abdomen',
      action: 'Walk the animal slowly. Do not feed water. Call vet immediately.',
      urgency: 'high',
    ),
    _Symptom(
      title: 'Limping / Foot-rot',
      action: 'Clean the hoof, apply zinc sulfate solution. Vet within 24h.',
      urgency: 'medium',
    ),
    _Symptom(
      title: 'Bloody Diarrhea',
      action: 'Isolate animal. Provide electrolytes. Emergency vet needed.',
      urgency: 'high',
    ),
    _Symptom(
      title: 'Difficulty Breathing',
      action: 'Move to shade. Check for nasal discharge. Vet immediately.',
      urgency: 'critical',
    ),
    _Symptom(
      title: 'Sudden Collapse / Seizures',
      action:
          'Call 1962 immediately. Keep animal calm, prevent self-injury.',
      urgency: 'critical',
    ),
    _Symptom(
      title: 'Not Eating for 24+ Hours',
      action: 'Check temperature. If fever > 104°F, call vet within 4h.',
      urgency: 'medium',
    ),
  ];
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, number;
  final Color color;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.number,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: AppSpacing.cardRadius,
      child: InkWell(
        borderRadius: AppSpacing.cardRadius,
        onTap: () async {
          final uri = Uri.parse('tel:$number');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: color.withAlpha(40), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      number,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
              ),
              Icon(Icons.call_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(15),
      borderRadius: AppSpacing.cardRadius,
      child: InkWell(
        borderRadius: AppSpacing.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: color.withAlpha(35), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymptomCard extends StatelessWidget {
  final _Symptom symptom;
  const _SymptomCard({required this.symptom});

  @override
  Widget build(BuildContext context) {
    final color = switch (symptom.urgency) {
      'critical' => AppColors.error,
      'high' => AppColors.warning,
      _ => AppColors.info,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(symptom.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(symptom.action,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Symptom {
  final String title, action, urgency;
  const _Symptom(
      {required this.title, required this.action, required this.urgency});
}
