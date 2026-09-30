import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import 'dashboards/dispatcher_dashboard.dart';
import 'dashboards/driver_dashboard.dart';
import 'dashboards/exec_dashboard.dart';
import 'dashboards/finance_dashboard.dart';
import 'dashboards/maintenance_dashboard.dart';
import 'dashboards/ops_dashboard.dart';
import 'dashboards/safety_dashboard.dart';

/// Role-aware dashboard router: renders the workspace matching the active
/// operator persona. Every role views the same live telematics pipeline,
/// framed for the decisions that role actually makes.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return switch (state.role) {
      FleetRole.ops => const OpsDashboard(),
      FleetRole.dispatcher => const DispatcherDashboard(),
      FleetRole.driver => const DriverDashboard(),
      FleetRole.maintenance => const MaintenanceDashboard(),
      FleetRole.safety => const SafetyDashboard(),
      FleetRole.finance => const FinanceDashboard(),
      FleetRole.executive => const ExecDashboard(),
    };
  }
}
