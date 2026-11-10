import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/adaptive/adaptive_spec.dart';
import '../l10n/app_localizations.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = context.adaptive;

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.today),
        label: l10n.tabToday,
      ),
      NavigationDestination(
        icon: const Icon(Icons.kitchen),
        label: l10n.tabPantry,
      ),
      NavigationDestination(
        icon: const Icon(Icons.calendar_month),
        label: l10n.tabCalendar,
      ),
      NavigationDestination(
        icon: const Icon(Icons.history),
        label: l10n.tabHistory,
      ),
      if (adaptive.showStatistics)
        NavigationDestination(
          icon: const Icon(Icons.insights_outlined),
          selectedIcon: const Icon(Icons.insights),
          label: l10n.tabStatistics,
        ),
    ];

    final currentIndex = navigationShell.currentIndex.clamp(
      0,
      destinations.length - 1,
    );

    if (!adaptive.showStatistics &&
        navigationShell.currentIndex >= destinations.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigationShell.goBranch(0);
      });
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: destinations,
        ),
      ),
    );
  }
}
