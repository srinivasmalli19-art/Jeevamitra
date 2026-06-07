import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../widgets/common/emergency_fab.dart';

class ShepherdShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShepherdShell({super.key, required this.navigationShell});

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home', route: RouteConstants.shepherdDashboard),
    _TabItem(icon: Icons.travel_explore_rounded, label: 'Discover', route: RouteConstants.shepherdDiscover),
    _TabItem(icon: Icons.calendar_month_rounded, label: 'Bookings', route: RouteConstants.shepherdBookings),
    _TabItem(icon: Icons.medical_services_rounded, label: 'Vets', route: RouteConstants.shepherdVets),
    _TabItem(icon: Icons.person_rounded, label: 'Profile', route: RouteConstants.shepherdProfile),
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
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String route;
  const _TabItem({required this.icon, required this.label, required this.route});
}
