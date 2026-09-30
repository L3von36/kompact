import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/fleet_state.dart';
import 'core/theme.dart';
import 'screens/alerts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/fleet_screen.dart';
import 'screens/fuel_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'ui/adaptive_scaffold.dart';


/// Root widget: wires state → theme → adaptive shell.
class KompactApp extends StatelessWidget {
  const KompactApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final themeMode = switch (state.settings.themeModeIndex) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      title: 'Kompact — Fleet Management',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(state.settings.accentIndex, state.settings.densityIndex == 0),
      darkTheme: AppTheme.dark(state.settings.accentIndex, state.settings.densityIndex == 0),
      home: const HomeShell(),
    );
  }
}

/// Adaptive navigation shell with lazy, state-preserving pages.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    AdaptiveDestination(
      label: 'Dashboard',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
    ),
    AdaptiveDestination(
      label: 'Fleet',
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping_rounded,
    ),
    AdaptiveDestination(
      label: 'Tracking',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
    ),
    AdaptiveDestination(
      label: 'Drivers',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge_rounded,
    ),
    AdaptiveDestination(
      label: 'Alerts',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      badgeKey: 'alerts',
    ),
    AdaptiveDestination(
      label: 'Maintenance',
      icon: Icons.build_circle_outlined,
      selectedIcon: Icons.build_circle_rounded,
    ),
    AdaptiveDestination(
      label: 'Fuel',
      icon: Icons.local_gas_station_outlined,
      selectedIcon: Icons.local_gas_station_rounded,
    ),
    AdaptiveDestination(
      label: 'Insights',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    AdaptiveDestination(
      label: 'Settings',
      icon: Icons.tune,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.loaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    // IndexedStack keeps scroll positions and live state per tab.
    return AdaptiveScaffold(
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
      destinations: _destinations,
      badgeCount: state.activeAlertCount,
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          FleetScreen(),
          MapScreen(),
          DriversScreen(),
          AlertsScreen(),
          MaintenanceScreen(),
          FuelScreen(),
          InsightsScreen(),
          SettingsScreen(),
        ],
      ),
    );
  }
}
