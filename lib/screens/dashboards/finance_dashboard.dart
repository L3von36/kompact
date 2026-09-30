import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Finance & Admin workspace (guide p. 5 — optimize fuel expenditure;
/// p. 9 — speed up admin tasks; p. 18 — IFTA reporting). Fuel spend trends,
/// cost per kilometer, maintenance exposure and quarterly tax estimates.
class FinanceDashboard extends StatelessWidget {
  const FinanceDashboard({super.key});

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
          title: 'Cost center',
          subtitle:
              '${usd(state.fuelCost30d)} fuel last 30 d · ${state.costPerKm.toStringAsFixed(2)} \$/km blended · ${usd(state.openMaintenanceCost)} maintenance exposure',
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
          label: 'Fuel spend 30d',
          value: usd(state.fuelCost30d),
          icon: Icons.local_gas_station_outlined,
        ),
        KpiTile(
          label: 'Fuel volume 30d',
          value: state.liters30d.round().toString(),
          unit: 'L',
          icon: Icons.propane_tank_rounded,
        ),
        KpiTile(
          label: 'Cost per km',
          value: state.costPerKm.toStringAsFixed(2),
          unit: '\$/km',
          icon: Icons.calculate_rounded,
          accent: p.accent,
        ),
        KpiTile(
          label: 'Maintenance exposure',
          value: usd(state.openMaintenanceCost),
          icon: Icons.build_circle_outlined,
          accent: p.urgent,
        ),
        KpiTile(
          label: 'Idle waste today',
          value: usd(state.idleCostToday),
          icon: Icons.timer_off_outlined,
          deltaUpGood: false,
        ),
        KpiTile(
          label: 'Fines exposure',
          value: usd(state.finesExposure),
          icon: Icons.gavel_rounded,
          accent: p.critical,
        ),
      ],
    );
  }

  Widget _leftColumn(BuildContext context, AppState state) {
    final p = context.pal;
    final fuel30 = state.fuelCostPerDay(30);
    final fuelTotal = fuel30.fold<double>(0, (s, v) => s + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fuel spend trend.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Fuel spend — last 30 days',
                eyebrow: 'Fuel-card + telematics reconciliation',
                action: Text(
                  usd(fuelTotal),
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              MiniBars(
                values: fuel30,
                height: 64,
                highlightIndex: fuel30.length - 1,
                highlightColor: p.accent,
              ),
              const SizedBox(height: K.xs + 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '30-day average',
                    style: TextStyle(
                      fontSize: K.caption,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    '${usd(fuelTotal / 30)}/day',
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w700,
                      color: p.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Cost structure.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Cost structure', eyebrow: 'Where the money goes'),
              DistributionBar(
                segments: [
                  (state.fuelCost30d, p.primary, 'Fuel'),
                  (state.openMaintenanceCost, p.urgent, 'Maintenance'),
                  (state.idleCostToday * 30, p.satisfactory, 'Idle waste'),
                  (state.finesExposure, p.critical, 'Fines'),
                ],
                height: 10,
              ),
              const SizedBox(height: K.sm),
              _costRow(context, 'Fuel — 30 days', usd(state.fuelCost30d), p.primary),
              _costRow(context, 'Maintenance — open orders', usd(state.openMaintenanceCost), p.urgent),
              _costRow(context, 'Idle waste — projected monthly', usd(state.idleCostToday * 30), p.satisfactory),
              _costRow(context, 'Traffic fines — open', usd(state.finesExposure), p.critical),
              const Divider(height: K.md, color: Colors.transparent),
              _costRow(context, 'Total exposure', usd(state.fuelCost30d + state.openMaintenanceCost + state.idleCostToday * 30 + state.finesExposure), p.text, bold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _costRow(BuildContext context, String label, String value, Color color, {bool bold = false}) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: K.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: K.label,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: p.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: K.label,
              fontWeight: FontWeight.w800,
              color: p.text,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightColumn(BuildContext context, AppState state) {
    final p = context.pal;

    // Efficiency by vehicle type.
    final types = VehicleType.values;
    final effByType = <VehicleType, double>{};
    for (final t in types) {
      final group = state.vehicles.where((v) => v.type == t).toList();
      effByType[t] = group.isEmpty
          ? 0
          : group.fold<double>(0, (s, v) => s + v.efficiencyKmpl) / group.length;
    }
    final bestEff = effByType.values.fold<double>(0, (a, b) => a > b ? a : b);

    // IFTA quarterly estimate: ~$0.28/L blended fuel-tax rate.
    final iftaEst = state.liters30d * 0.28 * 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Maintenance spend trend.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Maintenance spend — 30 days',
                eyebrow: 'Completed work orders',
              ),
              MiniBars(
                values: state.maintenanceCostPerDay(30),
                height: 56,
                highlightIndex: -1,
                color: p.urgent,
              ),
              const SizedBox(height: K.xs),
              Text(
                'Preventive scheduling keeps unplanned repair spend flat — the corrective spike risk drops with every predicted fix.',
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
        const SizedBox(height: K.md),

        // IFTA card.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'IFTA fuel tax estimate',
                eyebrow: 'Quarterly filing · auto-generated',
                action: Text(
                  'Q estimate',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w700,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    usd(iftaEst),
                    style: TextStyle(
                      fontSize: K.display,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: p.text,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: K.sm),
                  Expanded(
                    child: Text(
                      'based on ${state.liters30d.round()} L / 30 d × \$0.28 blended rate',
                      style: TextStyle(
                        fontSize: K.caption,
                        color: p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: K.xs),
              Text(
                'Jurisdiction splits computed from GPS trip lines. Export-ready for filing.',
                style: TextStyle(
                  fontSize: K.caption,
                  height: 1.3,
                  color: p.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Efficiency by type.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Efficiency by class', eyebrow: 'Average km/L per vehicle type'),
              for (final t in types)
                if (effByType[t]! > 0)
                  LabelBar(
                    label: t.label,
                    value: effByType[t]! / bestEff,
                    valueText: effByType[t]!.toStringAsFixed(1),
                    color: p.primary,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
