import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Executive workspace (guide p. 4 — operational efficacy; p. 8 — green
/// initiatives). The one-glance board: utilization, delivery reliability,
/// cost and carbon trends, plus the strategic focus areas the guide
/// highlights for leadership.
class ExecDashboard extends StatelessWidget {
  const ExecDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 1000;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Executive overview',
          subtitle:
              '${state.vehicles.length} vehicles · ${state.drivers.length} drivers · utilization ${(state.fleetUtilization * 100).toStringAsFixed(0)}% · on-time ${(state.avgOnTimeRate * 100).toStringAsFixed(0)}%',
          actions: [const RoleSwitchChip()],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: _kpiGrid(context, state, wide),
        ),
        const SizedBox(height: K.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _leftColumn(context, state)),
                    const SizedBox(width: K.md),
                    Expanded(flex: 2, child: _rightColumn(context, state)),
                  ],
                )
              : Column(
                  children: [
                    _leftColumn(context, state),
                    const SizedBox(height: K.md),
                    _rightColumn(context, state),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _kpiGrid(BuildContext context, AppState state, bool wide) {
    final p = context.pal;
    return GridView.count(
      crossAxisCount: wide ? 6 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: K.xs,
      crossAxisSpacing: K.xs,
      childAspectRatio: wide ? 1.55 : 1.65,
      children: [
        KpiTile(
          label: 'Fleet utilization',
          value: (state.fleetUtilization * 100).toStringAsFixed(0),
          unit: '%',
          icon: Icons.speed_rounded,
          trailing: Sparkline(
            values: state.onRouteHistory.isEmpty ? [0, 0] : state.onRouteHistory,
            height: 16,
            color: p.primary,
          ),
        ),
        KpiTile(
          label: 'On-time delivery',
          value: (state.avgOnTimeRate * 100).toStringAsFixed(0),
          unit: '%',
          icon: Icons.event_available_rounded,
          accent: p.good,
        ),
        KpiTile(
          label: 'Avg safety score',
          value: state.avgSafetyScore.toStringAsFixed(0),
          unit: '/ 100',
          icon: Icons.health_and_safety_outlined,
        ),
        KpiTile(
          label: 'Cost per km',
          value: state.costPerKm.toStringAsFixed(2),
          unit: '\$/km',
          icon: Icons.paid_rounded,
          accent: p.accent,
        ),
        KpiTile(
          label: 'CO2 — 30 days',
          value: (state.co2Kg30d / 1000).toStringAsFixed(1),
          unit: 't',
          icon: Icons.eco_outlined,
          accent: p.satisfactory,
        ),
        KpiTile(
          label: 'At-risk loads',
          value: '${state.atRiskTrips.length}',
          icon: Icons.warning_amber_rounded,
          accent: state.atRiskTrips.isEmpty ? p.good : p.critical,
        ),
      ],
    );
  }

  Widget _leftColumn(BuildContext context, AppState state) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Utilization heatmap.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Utilization by hour of week',
                eyebrow: 'Dispatch planning · 7-day heat',
                action: Text(
                  'peak +${(state.utilizationHeat.expand((d) => d).reduce((a, b) => a > b ? a : b) * 100).round()}%',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w700,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Heatmap(data: state.utilizationHeat),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Strategic focus.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Strategic focus', eyebrow: 'Board-level initiatives'),
              _focusCard(
                context,
                icon: Icons.groups_rounded,
                color: p.primary,
                title: 'Driver retention',
                body:
                    'Industry shortage of 175k drivers by 2026 — retention beats recruiting. Top-quartile coaching lifts safety scores without churn.',
                metric: '${state.drivers.where((d) => d.safetyScore >= 90).length} of ${state.drivers.length} drivers above 90 safety',
              ),
              _focusCard(
                context,
                icon: Icons.eco_rounded,
                color: p.good,
                title: 'Green fleet initiative',
                body:
                    'Idle-reduction and eco-driving directly cut the carbon line. Paperless PODs and digitized logs remove the rest of the footprint.',
                metric: '${(state.co2Kg30d / 1000).toStringAsFixed(1)} t CO2 over 30 days · idle waste ${usd(state.idleCostToday)} today',
              ),
              _focusCard(
                context,
                icon: Icons.trending_down_rounded,
                color: p.accent,
                title: 'Cost control',
                body:
                    'Fuel is the second-largest line item. Predictive maintenance plus route optimization compound into measurable cost-per-km reduction.',
                metric: '${state.costPerKm.toStringAsFixed(2)} \$/km blended · ${usd(state.fuelCost30d)} fuel / 30 d',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _focusCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required String metric,
  }) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: K.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(K.rSm)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: K.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: K.subtitle,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: K.caption,
                    height: 1.35,
                    color: p.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: K.xxs + 1),
                Text(
                  metric,
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w700,
                    color: color,
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

  Widget _rightColumn(BuildContext context, AppState state) {
    final p = context.pal;

    // Fleet mix.
    final mix = <VehicleType, int>{};
    for (final t in VehicleType.values) {
      mix[t] = state.vehicles.where((v) => v.type == t).length;
    }

    // Delivery performance.
    final delivered = state.trips.where((t) => t.status == TripStatus.delivered).length;
    final atRisk = state.atRiskTrips.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delivery performance.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            children: [
              const SectionHeader(title: 'Delivery performance', eyebrow: 'Rolling window'),
              Row(
                children: [
                  Gauge(
                    value: state.avgOnTimeRate,
                    color: p.good,
                    label: '${(state.avgOnTimeRate * 100).round()}%',
                    sublabel: 'ON-TIME',
                    size: 88,
                  ),
                  const SizedBox(width: K.md),
                  Expanded(
                    child: Column(
                      children: [
                        MetricRow(label: 'Delivered today', value: '$delivered'),
                        MetricRow(label: 'At-risk loads', value: '$atRisk', valueColor: atRisk > 0 ? p.critical : p.good),
                        MetricRow(label: 'Active fleet', value: '${state.onRouteCount}/${state.vehicles.length}'),
                        MetricRow(label: 'Avg eco score', value: state.avgEcoScore.toStringAsFixed(0)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Fleet mix.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Fleet mix', eyebrow: 'Asset classes'),
              DistributionBar(
                segments: [
                  for (final t in VehicleType.values)
                    if ((mix[t] ?? 0) > 0) (mix[t]!.toDouble(), _typeColor(context, t), t.label),
                ],
                height: 10,
              ),
              const SizedBox(height: K.xs + 1),
              for (final t in VehicleType.values)
                if ((mix[t] ?? 0) > 0)
                  LabelBar(
                    label: t.label,
                    value: mix[t]! / state.vehicles.length,
                    valueText: '${mix[t]}',
                    color: _typeColor(context, t),
                  ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Green initiatives.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Green initiatives',
                eyebrow: 'Carbon footprint',
                action: Text(
                  '${(state.co2Kg30d / 1000).toStringAsFixed(1)} t / 30 d',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w800,
                    color: p.satisfactory,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              LabelBar(
                label: 'Eco-driving adoption',
                value: state.avgEcoScore / 100,
                valueText: '${state.avgEcoScore.round()}',
                color: p.good,
              ),
              LabelBar(
                label: 'Idle reduction vs baseline',
                value: 0.68,
                valueText: '32%',
                color: p.satisfactory,
              ),
              LabelBar(
                label: 'Paperless POD rate',
                value: 0.94,
                valueText: '94%',
                color: p.primary,
              ),
              const SizedBox(height: K.xs),
              Text(
                'Telematics-guided eco-driving cut idle emissions and fuel burn — the fastest measurable green win for the fleet.',
                style: TextStyle(
                  fontSize: K.caption,
                  height: 1.3,
                  color: p.textTertiary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Color _typeColor(BuildContext c, VehicleType t) => switch (t) {
        VehicleType.semi => c.pal.primary,
        VehicleType.reefer => c.pal.satisfactory,
        VehicleType.box => c.pal.info,
        VehicleType.tanker => c.pal.urgent,
        VehicleType.van => c.pal.accent,
      };
}
