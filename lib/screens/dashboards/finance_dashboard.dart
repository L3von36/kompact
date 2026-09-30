import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Finance workspace — rebuilt as a chart-led cost center (Geotab TCO /
/// Samsara fuel-insight patterns): period-scoped KPI header, spend trend and
/// cost-structure charts, a cost-per-km league table that surfaces
/// replacement candidates, an IFTA tax panel and the repair-order approval
/// queue. Exports and period switches everywhere — finance lives in Excel
/// mode, not ops mode.
class FinanceDashboard extends StatelessWidget {
  const FinanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 1080;
    final approvals =
        state.maintenance.where((m) => m.needsApproval).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Cost center',
          subtitle:
              'MTD fuel ${usd(state.fuelCost30d)} · maintenance exposure ${usd(state.openMaintenanceCost)} · cost per km \$${state.costPerKm.toStringAsFixed(2)}',
          actions: [
            _exportButton(context),
            const RoleSwitchChip(),
          ],
        ),

        // KPI header row (period: last 30 days).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: _kpiRow(context, state),
        ),
        const SizedBox(height: K.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          _spendTrend(context, state),
                          const SizedBox(height: K.md),
                          _cpkLeague(context, state),
                        ],
                      ),
                    ),
                    const SizedBox(width: K.md),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _costStructure(context, state),
                          const SizedBox(height: K.md),
                          _iftaPanel(context, state),
                          const SizedBox(height: K.md),
                          _approvals(context, state, approvals),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _spendTrend(context, state),
                    const SizedBox(height: K.md),
                    _costStructure(context, state),
                    const SizedBox(height: K.md),
                    _cpkLeague(context, state),
                    const SizedBox(height: K.md),
                    _iftaPanel(context, state),
                    const SizedBox(height: K.md),
                    _approvals(context, state, approvals),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _exportButton(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Text('Cost report exported — check your downloads.'),
        ),
      ),
      borderRadius: BorderRadius.circular(K.rSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 2),
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(K.rSm),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Icon(Icons.file_download_outlined, size: 12, color: p.textSecondary),
            const SizedBox(width: K.xs + 1),
            Text(
              'EXPORT CSV',
              style: TextStyle(
                fontSize: K.micro,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: p.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── KPI header ───────────────────────────────────────────────────────────

  Widget _kpiRow(BuildContext context, AppState state) {
    final p = context.pal;
    final fuel = state.fuelCost30d;
    final maint = state.openMaintenanceCost;
    final idle = state.idleCostToday * 30;
    final total = fuel + maint + idle;
    final budget = 148000.0; // quarterly budget reference
    final variance = (total / budget - 1) * 100;

    return Row(
      children: [
        Expanded(
          child: KpiTile(
            label: 'Spend · 30 d',
            value: usd(total),
            icon: Icons.payments_rounded,
            delta: '+4.2%',
            deltaUpGood: false,
          ),
        ),
        const SizedBox(width: K.xs + 1),
        Expanded(
          child: KpiTile(
            label: 'Cost per km',
            value: state.costPerKm.toStringAsFixed(2),
            unit: 'USD',
            icon: Icons.route_rounded,
            delta: '-1.8%',
            deltaUpGood: true,
          ),
        ),
        const SizedBox(width: K.xs + 1),
        Expanded(
          child: KpiTile(
            label: 'Fuel · 30 d',
            value: usd(fuel),
            icon: Icons.local_gas_station_rounded,
            accent: p.accent,
          ),
        ),
        const SizedBox(width: K.xs + 1),
        Expanded(
          child: KpiTile(
            label: 'Maintenance open',
            value: usd(maint),
            icon: Icons.build_rounded,
            accent: p.urgent,
          ),
        ),
        const SizedBox(width: K.xs + 1),
        Expanded(
          child: KpiTile(
            label: 'vs budget',
            value: '${variance > 0 ? '+' : ''}${variance.toStringAsFixed(1)}',
            unit: '%',
            icon: Icons.track_changes_rounded,
            accent: variance > 5 ? p.critical : variance > 0 ? p.urgent : p.good,
          ),
        ),
      ],
    );
  }

  // ── Fuel spend trend ─────────────────────────────────────────────────────

  Widget _spendTrend(BuildContext context, AppState state) {
    final p = context.pal;
    final daily = state.fuelCostPerDay(30);
    final idleCost = state.idleCostToday * 30;

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Fuel spend — last 30 days',
            eyebrow: 'Daily totals · idle cost callout',
            action: Text(
              'IDLE ${usd(idleCost)}',
              style: TextStyle(
                fontSize: K.caption,
                fontWeight: FontWeight.w800,
                color: p.urgent,
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(
            height: 128,
            child: MiniBars(
              values: daily,
              color: p.accent.withValues(alpha: 0.55),
              highlightColor: p.accent,
              highlightIndex: daily.length - 1,
            ),
          ),
          const SizedBox(height: K.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30 d ago',
                style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
              ),
              Text(
                'peak ${usd(daily.reduce((a, b) => a > b ? a : b))}',
                style: TextStyle(
                  fontSize: K.caption,
                  fontWeight: FontWeight.w700,
                  color: p.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'today',
                style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
              ),
            ],
          ),
          const SizedBox(height: K.sm),
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 12, color: p.satisfactory),
              const SizedBox(width: K.sm),
              Expanded(
                child: Text(
                  'A semi burns ~0.8 L of diesel per idle hour. Cutting fleet idle 15 min/day saves about ${usd(state.vehicles.length * 15 * 30 * 0.8 * 1.58 / 60)} per month.',
                  style: TextStyle(
                    fontSize: K.caption,
                    height: 1.4,
                    color: p.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Cost structure donut ────────────────────────────────────────────────

  Widget _costStructure(BuildContext context, AppState state) {
    final p = context.pal;
    final fuel = state.fuelCost30d;
    final maint = state.openMaintenanceCost;
    final idle = state.idleCostToday * 30;
    final fines = state.finesExposure;
    final total = fuel + maint + idle + fines;

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Cost structure', eyebrow: 'Where the money goes · 30 d'),
          Row(
            children: [
              Donut(
                slices: [
                  (fuel, p.accent),
                  (maint, p.urgent),
                  (idle, p.satisfactory),
                  (fines, p.critical),
                ],
                centerTop: usd(total),
                centerBottom: 'TOTAL',
                size: 108,
              ),
              const SizedBox(width: K.md),
              Expanded(
                child: Column(
                  children: [
                    _costRow(context, 'Fuel', usd(fuel), p.accent, fuel / total),
                    _costRow(context, 'Maintenance', usd(maint), p.urgent, maint / total),
                    _costRow(context, 'Idle burn', usd(idle), p.satisfactory, idle / total),
                    _costRow(context, 'Fines', usd(fines), p.critical, fines / total),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: K.xs + 1),
          Text(
            'Fuel is typically ~40% of fleet OPEX — price-shopping and idle control are the fastest levers.',
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

  Widget _costRow(BuildContext context, String label, String value, Color color, double frac) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: K.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: K.label,
                color: p.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Text(
            '${(frac * 100).round()}%',
            style: TextStyle(
              fontSize: K.caption,
              fontWeight: FontWeight.w700,
              color: p.textTertiary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: K.sm),
          SizedBox(
            width: 58,
            child: Text(
              value,
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
    );
  }

  // ── Cost-per-km league table ─────────────────────────────────────────────

  Widget _cpkLeague(BuildContext context, AppState state) {
    final p = context.pal;

    // Per-vehicle cost model: fuel burn by efficiency + maintenance share,
    // producing a comparable $/km league table.
    final rows = state.vehicles.map((v) {
      final fuelPerKm = 1.58 / v.efficiencyKmpl;
      final maintPerKm =
          state.maintenance.where((m) => m.vehicleId == v.id).fold<double>(0, (s, m) => s + m.costEstUsd) /
              (v.odometerKm / 20).clamp(1, double.infinity);
      return (v, fuelPerKm + maintPerKm);
    }).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    final worst = rows.take(3).map((r) => r.$1.id).toSet();

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Cost per kilometer — league table',
            eyebrow: 'Replacement candidates highlighted',
            action: Text(
              '${rows.length} ASSETS',
              style: TextStyle(
                fontSize: K.caption,
                fontWeight: FontWeight.w800,
                color: p.textTertiary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          // Header.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(K.rSm),
            ),
            child: Row(
              children: [
                const SizedBox(width: 64, child: Text('ASSET', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'))),
                const Expanded(child: Text('TYPE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'))),
                const SizedBox(width: 70, child: Text('ODO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'))),
                const SizedBox(width: 60, child: Text('\$/KM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'))),
                SizedBox(
                  width: 86,
                  child: Text(
                    'VERDICT',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'),
                  ),
                ),
              ],
            ),
          ),
          for (final (v, cpk) in rows.take(10))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs + 2),
              margin: const EdgeInsets.only(bottom: K.xxs + 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(K.rSm),
                border: Border.all(color: p.border),
                color: worst.contains(v.id) ? p.criticalSoft.withValues(alpha: 0.35) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      v.plate,
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      v.type.name,
                      style: TextStyle(
                        fontSize: K.label,
                        color: p.textSecondary,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      kmFmt(v.odometerKm),
                      style: TextStyle(
                        fontSize: K.label,
                        color: p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      cpk.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w800,
                        color: worst.contains(v.id) ? p.critical : p.text,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 86,
                    child: Text(
                      worst.contains(v.id) ? 'REPLACE?' : 'KEEP',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: K.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: worst.contains(v.id) ? p.critical : p.good,
                        fontFamily: 'Inter',
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

  // ── IFTA panel ───────────────────────────────────────────────────────────

  Widget _iftaPanel(BuildContext context, AppState state) {
    final p = context.pal;
    // Jurisdiction share of fleet miles (seeded model).
    const jurisdictions = <(String, double, double)>[
      ('New York', 0.42, 0.368),
      ('New Jersey', 0.28, 0.402),
      ('Pennsylvania', 0.19, 0.574),
      ('Connecticut', 0.11, 0.492),
    ];
    final totalMiles = state.trips.fold<double>(0, (s, t) => s + t.distanceKm) * 1.6; // km→mi

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'IFTA · Q4 filing',
            eyebrow: 'Per-jurisdiction position',
            action: Text(
              '28 DAYS LEFT',
              style: TextStyle(
                fontSize: K.caption,
                fontWeight: FontWeight.w800,
                color: p.satisfactory,
                fontFamily: 'Inter',
              ),
            ),
          ),
          for (final (name, share, rate) in jurisdictions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      name.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w800,
                        color: p.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: K.label,
                        color: p.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(
                      '${(totalMiles * share).round()} mi',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: K.label,
                        color: p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: K.sm),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '\$${(totalMiles * share * rate / 100).toStringAsFixed(0)}',
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
          const SizedBox(height: K.xs),
          Text(
            'Automated from GPS miles + fuel-card data — audit-ready.',
            style: TextStyle(
              fontSize: K.caption,
              color: p.textTertiary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ── RO approval queue (ties to the shop) ─────────────────────────────────

  Widget _approvals(BuildContext context, AppState state, List<MaintenanceItem> approvals) {
    final p = context.pal;

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Repair approvals',
            eyebrow: 'Over \$${MaintenanceItem.approvalThresholdUsd.round()} threshold',
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs),
              decoration: BoxDecoration(
                color: approvals.isEmpty ? p.goodSoft : p.accentSoft,
                borderRadius: BorderRadius.circular(K.rSm),
              ),
              child: Text(
                '${approvals.length}',
                style: TextStyle(
                  fontSize: K.label,
                  fontWeight: FontWeight.w800,
                  color: approvals.isEmpty ? p.good : p.accent,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          if (approvals.isEmpty)
            const EmptyState(icon: Icons.verified_rounded, title: 'Nothing awaiting approval')
          else
            for (final m in approvals)
              Padding(
                padding: const EdgeInsets.only(bottom: K.xs + 1),
                child: Container(
                  padding: const EdgeInsets.all(K.sm + 2),
                  decoration: BoxDecoration(
                    color: p.accentSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(K.rSm),
                    border: Border.all(color: p.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.title,
                              style: TextStyle(
                                fontSize: K.body,
                                fontWeight: FontWeight.w700,
                                color: p.text,
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            usd(m.costEstUsd),
                            style: TextStyle(
                              fontSize: K.subtitle,
                              fontWeight: FontWeight.w800,
                              color: p.accent,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: K.xxs + 1),
                      Text(
                        '${state.vehicleById(m.vehicleId)?.plate ?? '—'} · ${m.tech ?? 'unassigned'} · est ${m.laborHoursEst.toStringAsFixed(0)}h labor',
                        style: TextStyle(
                          fontSize: K.caption,
                          color: p.textTertiary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: K.xs + 1),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => state.approveMaintenance(m.id),
                              borderRadius: BorderRadius.circular(K.rSm),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
                                decoration: BoxDecoration(
                                  color: p.good,
                                  borderRadius: BorderRadius.circular(K.rSm),
                                ),
                                child: Text(
                                  'APPROVE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: K.micro,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: K.xs + 1),
                          Expanded(
                            child: InkWell(
                              onTap: () => state.approveMaintenance(m.id, value: false),
                              borderRadius: BorderRadius.circular(K.rSm),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
                                decoration: BoxDecoration(
                                  color: p.surfaceAlt,
                                  borderRadius: BorderRadius.circular(K.rSm),
                                  border: Border.all(color: p.border),
                                ),
                                child: Text(
                                  'QUERY',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: K.micro,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: p.textSecondary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
