import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/fleet_state.dart';
import 'core/models.dart';
import 'core/theme.dart';
import 'screens/alerts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/fleet_screen.dart';
import 'screens/fuel_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/login_screen.dart';
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

    if (!state.loaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: Scaffold(
          backgroundColor: KPallette.light.bg,
          body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return MaterialApp(
      title: 'Kompact — Fleet Management',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(state.settings.accentIndex, state.settings.densityIndex == 0),
      darkTheme: AppTheme.dark(state.settings.accentIndex, state.settings.densityIndex == 0),
      home: state.signedIn ? const HomeShell() : const LoginScreen(),
    );
  }
}

/// Adaptive navigation shell with lazy, state-preserving pages.
///
/// The destination set is role-filtered: each persona sees the modules
/// that matter for their job, with the dashboard always first. Switching
/// roles rebuilds the page set and lands back on the role's dashboard.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  FleetRole? _lastRole;

  // ── Module registry ─────────────────────────────────────────────────────

  static const _dashboard = AdaptiveDestination(
    id: 'dashboard',
    label: 'Dashboard',
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
    section: 'Operations',
  );
  static const _tracking = AdaptiveDestination(
    id: 'tracking',
    label: 'Live Tracking',
    icon: Icons.map_outlined,
    selectedIcon: Icons.map_rounded,
    section: 'Operations',
  );
  static const _alerts = AdaptiveDestination(
    id: 'alerts',
    label: 'Alerts',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
    badgeKey: 'alerts',
    section: 'Operations',
  );
  static const _myRoute = AdaptiveDestination(
    id: 'tracking',
    label: 'My Route',
    icon: Icons.navigation_outlined,
    selectedIcon: Icons.navigation_rounded,
    section: 'Operations',
  );
  static const _myAlerts = AdaptiveDestination(
    id: 'alerts',
    label: 'My Alerts',
    icon: Icons.notifications_active_outlined,
    selectedIcon: Icons.notifications_active_rounded,
    badgeKey: 'alerts',
    section: 'Operations',
  );
  static const _fleet = AdaptiveDestination(
    id: 'fleet',
    label: 'Vehicles',
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping_rounded,
    section: 'Fleet & People',
  );
  static const _drivers = AdaptiveDestination(
    id: 'drivers',
    label: 'Drivers',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge_rounded,
    section: 'Fleet & People',
  );
  static const _maintenance = AdaptiveDestination(
    id: 'maintenance',
    label: 'Maintenance',
    icon: Icons.build_circle_outlined,
    selectedIcon: Icons.build_circle_rounded,
    badgeKey: 'maintenance',
    section: 'Fleet & People',
  );
  static const _fuel = AdaptiveDestination(
    id: 'fuel',
    label: 'Fuel',
    icon: Icons.local_gas_station_outlined,
    selectedIcon: Icons.local_gas_station_rounded,
    section: 'Business',
  );
  static const _insights = AdaptiveDestination(
    id: 'insights',
    label: 'Insights',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
    section: 'Business',
  );
  static const _settings = AdaptiveDestination(
    id: 'settings',
    label: 'Settings',
    icon: Icons.tune,
    section: 'System',
  );

  /// Role-filtered module sets. Sections stay contiguous so the rail can
  /// group them under micro headers.
  static List<AdaptiveDestination> _destinationsFor(FleetRole role) => switch (role) {
        FleetRole.ops => const [
            _dashboard, _tracking, _alerts,
            _fleet, _drivers, _maintenance,
            _fuel, _insights,
            _settings,
          ],
        FleetRole.dispatcher => const [
            _dashboard, _tracking, _alerts,
            _fleet, _drivers, _maintenance,
            _settings,
          ],
        FleetRole.driver => const [
            _dashboard, _myRoute, _myAlerts,
            _settings,
          ],
        FleetRole.maintenance => const [
            _dashboard, _alerts,
            _maintenance, _fleet,
            _insights,
            _settings,
          ],
        FleetRole.safety => const [
            _dashboard, _alerts,
            _drivers,
            _insights,
            _settings,
          ],
        FleetRole.finance => const [
            _dashboard,
            _fuel, _insights,
            _fleet,
            _settings,
          ],
        FleetRole.executive => const [
            _dashboard,
            _insights,
            _fleet, _drivers,
            _settings,
          ],
      };

  static Widget _screenFor(String id) => switch (id) {
        'dashboard' => const DashboardScreen(),
        'fleet' => const FleetScreen(),
        'tracking' => const MapScreen(),
        'drivers' => const DriversScreen(),
        'alerts' => const AlertsScreen(),
        'maintenance' => const MaintenanceScreen(),
        'fuel' => const FuelScreen(),
        'insights' => const InsightsScreen(),
        'settings' => const SettingsScreen(),
        _ => const SizedBox.shrink(),
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Role switches always land on that role's dashboard.
    if (_lastRole != state.role) {
      _lastRole = state.role;
      _index = 0;
    }
    final destinations = _destinationsFor(state.role);
    final index = _index < destinations.length ? _index : 0;

    return AdaptiveScaffold(
      currentIndex: index,
      onTap: (i) => setState(() => _index = i),
      destinations: destinations,
      roleContext: RoleContext(
        role: state.role,
        userName: state.role == FleetRole.driver ? state.demoDriver.name : state.role.demoUser,
        movingVehicles: state.onRouteCount,
        fleetSpeedKmh: state.fleetSpeedHistory.isEmpty ? null : state.fleetSpeedHistory.last,
      ),
      onRoleChange: (_) {}, // role changes flow through AppState; shell reacts above
      badgeCounts: {
        'alerts': state.activeAlertCount,
        'maintenance': state.predictedMaintenanceCount,
      },
      body: IndexedStack(
        index: index,
        children: [for (final d in destinations) _screenFor(d.id)],
      ),
    );
  }
}
