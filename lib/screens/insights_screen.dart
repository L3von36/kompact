import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/charts.dart';
import '../ui/widgets.dart';

/// Business intelligence (guide p. 26–27): utilization heatmap, cost analytics,
/// safety leaderboard, green-initiative tracking and emerging-tech impact.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 980;
    final costPerDay = state.fuelCostPerDay(14);

    // Emerging tech impact (guide ch. 03: productivity with custom software).
    final downtimeAvoided = state.maintenance
        .where((m) => m.status == MaintenanceStatus.completed)
        .fold<double>(0, (s, m) => s + m.downtimeHours);
    final predictedOpen = state.maintenance.where((m) => m.status == MaintenanceStatus.predicted).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Insights & analytics',
          subtitle: 'Fleet business intelligence · predictive analysis',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Impact KPI row.
              Row(
                children: [
                  Expanded(
                    child: KpiTile(
                      label: 'Fleet utilization',
                      value: (state.fleetUtilization * 100).toStringAsFixed(0),
                      unit: '%',
                      icon: Icons.speed_rounded,
                    ),
                  ),
                  const SizedBox(width: K.xs),
                  Expanded(
                    child: KpiTile(
                      label: 'On-time delivery',
                      value: (state.avgOnTimeRate * 100).toStringAsFixed(0),
                      unit: '%',
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  const SizedBox(width: K.xs),
                  Expanded(
                    child: KpiTile(
                      label: 'Downtime avoided',
                      value: downtimeAvoided.toStringAsFixed(0),
                      unit: 'h',
                      icon: Icons.build_circle_outlined,
                      accent: p.satisfactory,
                    ),
                  ),
                  const SizedBox(width: K.xs),
                  Expanded(
                    child: KpiTile(
                      label: 'AI predictions open',
                      value: '$predictedOpen',
                      icon: Icons.auto_awesome,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: K.md),

              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _heatCard(context, state)),
                    const SizedBox(width: K.md),
                    Expanded(child: _rightColumn(context, state, costPerDay)),
                  ],
                )
              else ...[
                _heatCard(context, state),
                const SizedBox(height: K.md),
                _rightColumn(context, state, costPerDay),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _heatCard(BuildContext context, AppState state) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Dispatch utilization',
            eyebrow: 'Hour × day · last week pattern',
          ),
          Heatmap(data: state.utilizationHeat),
          const SizedBox(height: K.sm),
          Row(
            children: [
              Text(
                'low',
                style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
              ),
              const SizedBox(width: K.xs),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i <= 4; i++)
                      Expanded(
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.only(right: 1),
                          decoration: BoxDecoration(
                            color: Color.lerp(p.surfaceSunken, p.primary, i / 4),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: K.xs),
              Text(
                'high',
                style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: K.xs),
          SectionHeader(
            title: 'Safety leaderboard',
            eyebrow: 'Driver performance reports',
          ),
          for (var i = 0; i < state.driverLeaderboard.length && i < 6; i++)
            LabelBar(
              label: state.driverLeaderboard[i].name,
              value: state.driverLeaderboard[i].safetyScore / 100,
              valueText: state.driverLeaderboard[i].safetyScore.toStringAsFixed(0),
              color: state.driverLeaderboard[i].safetyScore >= 90
                  ? p.good
                  : state.driverLeaderboard[i].safetyScore >= 78
                      ? p.satisfactory
                      : p.urgent,
            ),
        ],
      ),
    );
  }

  Widget _rightColumn(BuildContext context, AppState state, List<double> costPerDay) {
    final p = context.pal;
    return Column(
      children: [
        // Cost analytics.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Cost structure — 14 days',
                eyebrow: 'Fuel + maintenance exposure',
              ),
              MiniBars(values: costPerDay, height: 64, highlightIndex: costPerDay.length - 1),
              const SizedBox(height: K.sm),
              MetricRow(label: 'Fuel spend (30d)', value: usd(state.fuelCost30d)),
              MetricRow(label: 'Maintenance exposure', value: usd(state.openMaintenanceCost), valueColor: p.accent),
              MetricRow(
                label: 'Cost per km (est.)',
                value:
                    '\$${(state.kmDrivenToday > 0 ? state.litersConsumedToday * 1.58 / state.kmDrivenToday : 0.42).toStringAsFixed(2)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Green initiatives (guide p. 9).
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Green initiatives',
                eyebrow: 'Carbon footprint · eco program',
              ),
              Row(
                children: [
                  Expanded(
                    child: Gauge(
                      value: state.avgEcoScore / 100,
                      color: p.satisfactory,
                      label: state.avgEcoScore.toStringAsFixed(0),
                      sublabel: 'ECO AVG',
                      size: 72,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        MetricRow(label: 'CO2 today', value: '${state.co2KgToday.round()} kg'),
                        MetricRow(label: 'CO2 30 days', value: '${state.co2Kg30d.round()} kg'),
                        MetricRow(label: 'Idle waste today', value: usd(state.idleCostToday), valueColor: p.accent),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: K.sm),
              Text(
                'Telematics-guided eco-driving and idle reduction keep the fleet on its quarterly emission-reduction track. Predictive maintenance further cuts waste from catastrophic failures and emergency tows.',
                style: TextStyle(
                  fontSize: K.body,
                  height: 1.45,
                  color: p.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Emerging tech impact.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Emerging tech impact',
                eyebrow: 'IoT · AI · spatial ops',
              ),
              _techRow(
                context,
                icon: Icons.sensors_rounded,
                title: 'IoT telematics',
                detail: '${state.vehicles.where((v) => v.status != VehicleStatus.offline).length}/${state.vehicles.length} units streaming live sensor data',
              ),
              _techRow(
                context,
                icon: Icons.auto_awesome,
                title: 'AI predictive maintenance',
                detail: '${state.maintenance.where((m) => m.kind == MaintenanceKind.preventive && m.status != MaintenanceStatus.completed).length} open AI-flagged services',
              ),
              _techRow(
                context,
                icon: Icons.my_location_rounded,
                title: 'Geofencing & spatial ops',
                detail: '${state.geofences.length} zones monitored · closest-point refuel planning active',
              ),
              _techRow(
                context,
                icon: Icons.dashboard_customize_rounded,
                title: 'Remote dashboards',
                detail: 'Real-time KPIs refreshed every 2 seconds across devices',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _techRow(BuildContext context, {required IconData icon, required String title, required String detail}) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.xs),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: p.primarySoft,
              borderRadius: BorderRadius.circular(K.rSm),
            ),
            child: Icon(icon, size: 13, color: p.primary),
          ),
          const SizedBox(width: K.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: K.label,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: K.caption,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
