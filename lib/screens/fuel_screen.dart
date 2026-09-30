import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/charts.dart';
import '../ui/widgets.dart';

/// Fuel management (guide p. 11): consumption trend, spend control, idle
/// waste, eco-driving leaderboard and per-vehicle efficiency ranking.
class FuelScreen extends StatelessWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 980;
    final costPerDay = state.fuelCostPerDay(30);
    final avgDaily = costPerDay.fold<double>(0, (s, e) => s + e) / 30;

    // Per-vehicle consumption last 30 days.
    final byVehicle = <String, double>{};
    for (final e in state.fuelEvents) {
      if (e.date.isAfter(DateTime.now().subtract(const Duration(days: 30)))) {
        byVehicle[e.vehicleId] = (byVehicle[e.vehicleId] ?? 0) + e.liters;
      }
    }
    final ranked = byVehicle.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Eco leaderboard.
    final ecoRanked = [...state.drivers]..sort((a, b) => b.ecoScore.compareTo(a.ecoScore));

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Fuel management',
          subtitle:
              '${state.liters30d.round()} L / 30d · ${usd(state.fuelCost30d)} spend · avg ${usd(avgDaily)}/day',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _trendCard(context, state, costPerDay)),
                    const SizedBox(width: K.md),
                    Expanded(flex: 2, child: _statsColumn(context, state, ranked, ecoRanked)),
                  ],
                )
              : Column(
                  children: [
                    _trendCard(context, state, costPerDay),
                    const SizedBox(height: K.md),
                    _statsColumn(context, state, ranked, ecoRanked),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _trendCard(BuildContext context, AppState state, List<double> costPerDay) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Fuel spend — last 30 days',
            eyebrow: 'Daily cost trend',
            action: Text(
              usd(costPerDay.last),
              style: TextStyle(
                fontSize: K.body,
                fontWeight: FontWeight.w800,
                color: p.text,
                fontFamily: 'Inter',
              ),
            ),
          ),
          MiniBars(
            values: costPerDay,
            height: 92,
            highlightIndex: costPerDay.length - 1,
            color: p.primary,
            highlightColor: p.accent,
          ),
          const SizedBox(height: K.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30 days ago',
                style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
              ),
              Text(
                'today',
                style: TextStyle(fontSize: K.caption, fontWeight: FontWeight.w700, color: p.accent, fontFamily: 'Inter'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: K.xs),
          SectionHeader(
            title: 'Consumption today',
            eyebrow: 'Live telematics',
            live: true,
          ),
          Row(
            children: [
              Expanded(
                child: KpiTile(
                  label: 'Liters burned',
                  value: state.litersConsumedToday.toStringAsFixed(0),
                  unit: 'L',
                  icon: Icons.local_gas_station_outlined,
                ),
              ),
              const SizedBox(width: K.xs),
              Expanded(
                child: KpiTile(
                  label: 'Distance today',
                  value: state.kmDrivenToday.toStringAsFixed(0),
                  unit: 'km',
                  icon: Icons.route_rounded,
                ),
              ),
              const SizedBox(width: K.xs),
              Expanded(
                child: KpiTile(
                  label: 'Fleet avg tank',
                  value: state.avgFuelLevel.toStringAsFixed(0),
                  unit: '%',
                  icon: Icons.speed_rounded,
                  accent: state.avgFuelLevel < 40 ? p.critical : p.good,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsColumn(BuildContext context, AppState state, List<MapEntry<String, double>> ranked,
      List<Driver> ecoRanked) {
    final p = context.pal;
    return Column(
      children: [
        // Per-vehicle consumption.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Consumption by vehicle',
                eyebrow: 'Last 30 days · top 8',
              ),
              for (var i = 0; i < ranked.length && i < 8; i++)
                LabelBar(
                  label: state.vehicleById(ranked[i].key)?.plate ?? '—',
                  value: ranked[i].value / (ranked.first.value),
                  valueText: '${ranked[i].value.round()} L',
                  color: i == 0 ? p.accent : p.primary,
                ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Eco-driving leaderboard (guide p. 5: optimize fuel expenditure).
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Eco-driving leaderboard',
                eyebrow: 'Behavior-based fuel savings',
              ),
              for (var i = 0; i < ecoRanked.length && i < 6; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: K.label,
                            fontWeight: FontWeight.w800,
                            color: i < 3 ? p.primary : p.textTertiary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      DriverAvatar(name: ecoRanked[i].name, hue: ecoRanked[i].hue, size: 20),
                      const SizedBox(width: K.sm),
                      Expanded(
                        child: Text(
                          ecoRanked[i].name,
                          style: TextStyle(
                            fontSize: K.label,
                            fontWeight: FontWeight.w600,
                            color: p.text,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Expanded(
                        child: KProgress(
                          value: ecoRanked[i].ecoScore / 100,
                          color: ecoRanked[i].ecoScore >= 90 ? p.good : p.satisfactory,
                        ),
                      ),
                      const SizedBox(width: K.sm),
                      SizedBox(
                        width: 56,
                        child: Text(
                          ecoRanked[i].ecoScore.toStringAsFixed(0),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: K.label,
                            fontWeight: FontWeight.w800,
                            color: p.text,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              const SizedBox(height: K.xs),
              SectionHeader(title: 'Waste watch', eyebrow: 'Idle reduction program'),
              MetricRow(
                label: 'Idle cost today',
                value: usd(state.idleCostToday),
                valueColor: p.accent,
              ),
              MetricRow(
                label: 'CO2 30 days',
                value: '${state.co2Kg30d.round()} kg',
                valueColor: p.satisfactory,
              ),
              MetricRow(
                label: 'Avg efficiency',
                value:
                    '${(state.vehicles.isEmpty ? 0 : state.vehicles.map((v) => v.efficiencyKmpl).reduce((a, b) => a + b) / state.vehicles.length).toStringAsFixed(1)} km/L',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
