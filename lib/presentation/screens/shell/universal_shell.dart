import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/common/emergency_fab.dart';

/// The single bottom-navigation shell every authenticated, fully-onboarded
/// user lands in — Home / Lands / Bookings / Vets / Profile, identical for
/// every profile (Livestock Owner, Fodder Land Provider, Both). Replaces
/// the former FarmerShell/ShepherdShell pair, which exposed two different
/// tab sets depending on role. Each tab's *content* still varies by role
/// this sprint (existing dashboards/lists reused as-is, not redesigned) —
/// only the shell itself (which tabs exist, and that every profile gets
/// all of them) changes here.
class UniversalShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const UniversalShell({super.key, required this.navigationShell});

  List<_TabItem> _tabs(AppLocalizations loc) => [
        _TabItem(icon: Icons.home_rounded, label: loc.homeTab),
        _TabItem(icon: Icons.landscape_rounded, label: loc.landsLabel),
        _TabItem(icon: Icons.calendar_month_rounded, label: loc.bookings),
        _TabItem(icon: Icons.medical_services_rounded, label: loc.vets),
        _TabItem(icon: Icons.person_rounded, label: loc.profile),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: const EmergencyFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        // Green-active / muted-inactive states come from the app-wide
        // navigationBarTheme (Sprint 1); only the bar's own cream surface
        // is set explicitly here, same as the legacy shells did.
        backgroundColor: AppColors.surfaceCream,
        destinations: _tabs(AppLocalizations.of(context))
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}
