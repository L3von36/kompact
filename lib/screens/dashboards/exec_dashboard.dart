import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Executive workspace — rebuilt as a benchmark scorecard (Samsara Fleet
/// Benchmarks pattern): big-number tiles each carrying a delta and a
/// three-band peer benchmark (you vs segment average vs top decile), trend
/// charts, a division comparison table and strategic initiative trackers.
/// Read-mostly — every tile drills through into the owning role dashboard.
class ExecDashboard extends StatelessWidget {
  const ExecDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 1080;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Executive scorecard',
          subtitle:
              'Fleet of ${state.vehicles.length} assets · ${state.drivers.length} drivers · benchmarked against regional LTL segment',
          actions: [
            _periodChip(context),
            const RoleSwitchChip(),
          ],
        ),

        // Hero: benchmark KPI tiles.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: _scorecard(context, state),
        ),
        const SizedBox(height: K.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _trendPanel(context, state),
                          const SizedBox(height: K.md),
                          _divisionTable(context, state),
                        ],
                      ),
                    ),
                    const SizedBox(width: K.md),
                    Expanded(
                      child: Column(
                        children: [
                          _initiatives(context, state),
                          const SizedBox(height: K.md),
                          _attentionList(context, state),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _trendPanel(context, state),
                    const SizedBox(height: K.md),
                    _divisionTable(context, state),
                    const SizedBox(height: K.md),
                    _initiatives(context, state),
                    const SizedBox(height: K.md),
                    _attentionList(context, state),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _periodChip(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 2),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(K.rSm),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 11, color: p.textTertiary),
          const SizedBox(width: K.xs + 1),
          Text(
            'QTD',
            style: TextStyle(
              fontSize: K.micro,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: p.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          Icon(Icons.expand_more_rounded, size: 12, color: p.textTertiary),
        ],
      ),
    );
  }

  // ── Benchmark scorecard (the hero) ───────────────────────────────────────

  Widget _scorecard(BuildContext context, AppState state) {
    final util = state.fleetUtilization * 100;
    final onTime = state.avgOnTimeRate * 100;
    final safety = state.avgSafetyScore;
    final cpk = state.costPerKm;
    final incidentsPerMm = 3.2; // per million miles, trailing 12 mo
    final evShare = state.vehicles.where((v) => v.type == VehicleType.van).length /
        state.vehicles.length *
        100;
    final co2 = state.co2Kg30d / 1000;
    final live = (util, onTime, safety, cpk, incidentsPerMm, evShare, co2);

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 760 ? 4 : 2;
        final rows = (_tiles.length / cols).ceil();
        return Column(
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) const SizedBox(height: K.xs + 1),
              Row(
                children: [
                  for (var i = 0; i < cols; i++) ...[
                    if (i > 0) const SizedBox(width: K.xs + 1),
                    Expanded(
                      child: r * cols + i < _tiles.length
                          ? _tile(context, state, r * cols + i, live)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  /// Tile catalog: (title, value, unit, delta, upGood, you, segment, top10, drill role)
  static const _tiles = <(String, String, String, String, bool, double, double, double, FleetRole)>[
    ('Utilization', '', '%', '+3.4%', true, 74, 68, 81, FleetRole.ops),
    ('On-time delivery', '', '%', '+1.2%', true, 93, 91, 97, FleetRole.dispatcher),
    ('Cost per km', '', 'USD', '-1.8%', true, 1.62, 1.71, 1.49, FleetRole.finance),
    ('Safety score', '', '/100', '+2.1', true, 87, 84, 92, FleetRole.safety),
    ('Incidents / M mi', '', '', '-0.4', true, 3.2, 3.6, 2.4, FleetRole.safety),
    ('Fuel spend 30 d', '', '', '-2.6%', true, 61, 64, 55, FleetRole.finance),
    ('EV share', '', '%', '+1.5', true, 14, 12, 22, FleetRole.executive),
    ('CO2e 30 d', '', 't', '-4.0%', true, 18.4, 21, 15, FleetRole.ops),
  ];

  Widget _tile(BuildContext context, AppState state, int index,
      (double, double, double, double, double, double, double) live) {
    final p = context.pal;
    final t = _tiles[index];
    final value = switch (index) {
      0 => live.$1.toStringAsFixed(0),
      1 => live.$2.toStringAsFixed(0),
      2 => live.$4.toStringAsFixed(2),
      3 => live.$3.toStringAsFixed(0),
      4 => live.$5.toStringAsFixed(1),
      5 => usd(state.fuelCost30d),
      6 => live.$6.toStringAsFixed(0),
      7 => live.$7.toStringAsFixed(1),
      _ => '—',
    };

    // Scale for the benchmark band: max of the three values.
    final scale = [t.$6, t.$7, t.$8].reduce((a, b) => a > b ? a : b) * 1.15;

    return InkWell(
      onTap: () {
        // Drill through into the owning role workspace.
        state.setRole(t.$9);
      },
      borderRadius: BorderRadius.circular(K.rMd),
      child: KCard(
        padding: const EdgeInsets.all(K.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.$1.toUpperCase(),
                    style: TextStyle(
                      fontSize: K.micro,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.north_east_rounded, size: 10, color: p.textTertiary),
              ],
            ),
            const SizedBox(height: K.xxs + 1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: K.display,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: p.text,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (t.$3.isNotEmpty) ...[
                  const SizedBox(width: K.xxs + 1),
                  Text(
                    t.$3,
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w600,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
                const Spacer(),
                _deltaChip(context, t.$4, t.$5),
              ],
            ),
            const SizedBox(height: K.sm),

            // Three-band benchmark: you vs segment vs top decile.
            _benchmarkBar(context, t.$6 / scale, t.$7 / scale, t.$8 / scale),
            const SizedBox(height: K.xxs + 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _benchLabel(context, 'SEGMENT', p.textTertiary),
                _benchLabel(context, 'TOP 10%', p.good),
                _benchLabel(context, 'YOU', p.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _deltaChip(BuildContext context, String delta, bool upGood) {
    final p = context.pal;
    final up = delta.startsWith('+');
    final good = up == upGood;
    final color = good ? p.good : p.critical;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 12, color: color),
        Text(
          delta.replaceFirst(RegExp(r'^[+-]'), ''),
          style: TextStyle(
            fontSize: K.caption,
            fontWeight: FontWeight.w800,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _benchmarkBar(BuildContext context, double you, double segment, double top10) {
    final p = context.pal;
    return SizedBox(
      height: 8,
      child: Stack(
        children: [
          // Track.
          Container(
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Segment average band.
          FractionallySizedBox(
            widthFactor: segment.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: p.textTertiary.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Top decile marker.
          Align(
            alignment: Alignment(-1 + 2 * top10.clamp(0.0, 1.0), 0),
            child: Container(width: 2, color: p.good),
          ),
          // You.
          FractionallySizedBox(
            widthFactor: you.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benchLabel(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: K.xxs),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  // ── Trend panel (12-month) ───────────────────────────────────────────────

  Widget _trendPanel(BuildContext context, AppState state) {
    final p = context.pal;
    // Deterministic 12-month series seeded from fleet state.
    final base = state.costPerKm;
    final costTrend = <double>[
      for (var i = 0; i < 12; i++) base * (1.12 - i * 0.011 + (i % 3) * 0.006),
    ];
    final utilTrend = <double>[
      for (var i = 0; i < 12; i++) state.fleetUtilization * 100 * (0.86 + i * 0.012),
    ];

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Twelve-month trends', eyebrow: 'Cost per km vs utilization'),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COST PER KM · USD',
                      style: TextStyle(
                        fontSize: K.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: p.accent,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: K.xs),
                    SizedBox(
                      height: 84,
                      child: Sparkline(values: costTrend, color: p.accent, height: 84),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: K.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UTILIZATION · %',
                      style: TextStyle(
                        fontSize: K.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: p.good,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: K.xs),
                    SizedBox(
                      height: 84,
                      child: Sparkline(values: utilTrend, color: p.good, height: 84),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: K.xs + 1),
          Text(
            'Both lines moving the right way — cost down 11% while utilization climbed 14 points.',
            style: TextStyle(
              fontSize: K.caption,
              height: 1.4,
              color: p.textTertiary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ── Division comparison table ────────────────────────────────────────────

  Widget _divisionTable(BuildContext context, AppState state) {
    final p = context.pal;

    // Group by vehicle class → mini divisions with RAG status.
    final classes = VehicleType.values.map((ty) {
      final list = state.vehicles.where((v) => v.type == ty).toList();
      final onRoute = list.where((v) => v.status == VehicleStatus.onRoute).length;
      final util = list.isEmpty ? 0.0 : onRoute / list.length * 100;
      final eco = list.isEmpty ? 0.0 : list.map((v) => v.ecoScore).reduce((a, b) => a + b) / list.length;
      final dtc = list.where((v) => v.hasActiveDtc).length;
      return (ty, list.length, util, eco, dtc);
    }).where((d) => d.$2 > 0).toList();

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Division comparison', eyebrow: 'By asset class · PM compliance'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(K.rSm),
            ),
            child: Row(
              children: [
                const Expanded(child: Text('DIVISION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'))),
                const SizedBox(width: 44, child: Text('ASSETS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'))),
                const SizedBox(width: 52, child: Text('UTIL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'))),
                const SizedBox(width: 48, child: Text('ECO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'))),
                SizedBox(
                  width: 76,
                  child: Text(
                    'STATUS',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'),
                  ),
                ),
              ],
            ),
          ),
          for (final d in classes)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs + 2),
              margin: const EdgeInsets.only(bottom: K.xxs + 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(K.rSm),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d.$1.name[0].toUpperCase() + d.$1.name.substring(1),
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('${d.$2}', style: TextStyle(fontSize: K.label, color: p.textSecondary, fontFamily: 'Inter')),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${d.$3.round()}%',
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w700,
                        color: d.$3 >= 70 ? p.good : p.urgent,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      d.$4.toStringAsFixed(0),
                      style: TextStyle(fontSize: K.label, color: p.textSecondary, fontFamily: 'Inter'),
                    ),
                  ),
                  SizedBox(
                    width: 76,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: K.xs + 2, vertical: 1),
                        decoration: BoxDecoration(
                          color: d.$5 > 1
                              ? p.criticalSoft
                              : d.$5 == 1
                                  ? p.urgentSoft
                                  : p.goodSoft,
                          borderRadius: BorderRadius.circular(K.rSm),
                        ),
                        child: Text(
                          d.$5 > 1 ? 'ACTION' : d.$5 == 1 ? 'WATCH' : 'GOOD',
                          style: TextStyle(
                            fontSize: K.micro,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: d.$5 > 1
                                ? p.critical
                                : d.$5 == 1
                                    ? p.urgent
                                    : p.good,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Strategic initiatives ────────────────────────────────────────────────

  Widget _initiatives(BuildContext context, AppState state) {
    final p = context.pal;
    final co2Saved = state.co2Kg30d / 1000 * 0.18;
    final items = <(String, String, double, Color, IconData)>[
      ('Safety program ROI',
          'Crash costs avoided this year: \$310k vs \$48k program spend.',
          0.86, p.critical, Icons.health_and_safety_rounded),
      ('Green fleet initiative',
          'CO2e down 18% YoY — idle reduction and eco-coaching paying off (${co2Saved.toStringAsFixed(1)} t this month).',
          0.64, p.good, Icons.eco_rounded),
      ('Driver retention',
          'Turnover at 11% vs 30% industry average — recognition program credited.',
          0.78, p.satisfactory, Icons.groups_rounded),
      ('Electrification pilot',
          '2 of 3 vans ready for EV replacement; charging depots scoped.',
          0.42, p.info, Icons.electric_car_rounded),
    ];

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Strategic initiatives', eyebrow: 'Board-level progress'),
          for (final (title, note, progress, color, icon) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: K.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 13, color: color),
                      const SizedBox(width: K.sm),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: K.body,
                            fontWeight: FontWeight.w800,
                            color: p.text,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: K.label,
                          fontWeight: FontWeight.w800,
                          color: color,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: K.xxs + 1),
                  KProgress(value: progress, color: color, height: 4),
                  const SizedBox(height: K.xxs + 1),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: K.caption,
                      height: 1.4,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Attention list (one-liners with owners) ──────────────────────────────

  Widget _attentionList(BuildContext context, AppState state) {
    final p = context.pal;
    final items = <(String, String, FleetRole)>[
      ('${state.vehicles.where((v) => v.condition == VehicleCondition.critical).length} assets in critical condition — replacement case needed', 'Maintenance', FleetRole.maintenance),
      ('HOS cycles at risk for ${state.hosRiskCount} drivers this week', 'Safety', FleetRole.safety),
      ('Fuel spend variance +4.2% vs budget', 'Finance', FleetRole.finance),
      ('${state.unassignedLoads.length} loads unassigned on the board', 'Dispatch', FleetRole.dispatcher),
    ];

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Needs attention', eyebrow: 'One line · one owner'),
          for (final (line, owner, role) in items)
            InkWell(
              onTap: () => state.setRole(role),
              borderRadius: BorderRadius.circular(K.rSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: roleColor(context, role)),
                    ),
                    const SizedBox(width: K.sm),
                    Expanded(
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: K.label,
                          height: 1.35,
                          color: p.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: K.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: K.xs + 2, vertical: 1),
                      decoration: BoxDecoration(
                        color: roleColor(context, role).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(K.rSm),
                      ),
                      child: Text(
                        owner.toUpperCase(),
                        style: TextStyle(
                          fontSize: K.micro,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: roleColor(context, role),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
