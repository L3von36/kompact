import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Maintenance workspace (guide p. 11 — predictive maintenance; p. 23 —
/// corrective vs preventive). The shop board: AI-predicted work orders,
/// the vehicle health triage list and active diagnostic trouble codes.
class MaintenanceDashboard extends StatelessWidget {
  const MaintenanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final open = state.openMaintenance;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Shop overview',
          subtitle:
              '${open.length} open work orders · ${state.inShopCount} vehicles in shop · ${state.predictedMaintenanceCount} AI predictions pending',
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
                    Expanded(flex: 3, child: _leftColumn(context, state, open)),
                    const SizedBox(width: K.md),
                    Expanded(flex: 2, child: _rightColumn(context, state)),
                  ],
                )
              : Column(
                  children: [
                    _leftColumn(context, state, open),
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
    final open = state.openMaintenance;
    final downtime = open.fold<double>(0, (s, m) => s + m.downtimeHours);
    return GridView.count(
      crossAxisCount: wide ? 5 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: K.xs,
      crossAxisSpacing: K.xs,
      childAspectRatio: wide ? 1.85 : 1.65,
      children: [
        KpiTile(
          label: 'Open work orders',
          value: '${open.length}',
          icon: Icons.build_circle_outlined,
        ),
        KpiTile(
          label: 'In shop now',
          value: '${state.inShopCount}',
          icon: Icons.garage_rounded,
          accent: p.urgent,
        ),
        KpiTile(
          label: 'AI predictions',
          value: '${state.predictedMaintenanceCount}',
          icon: Icons.psychology_alt_rounded,
          accent: p.primary,
        ),
        KpiTile(
          label: 'Downtime planned',
          value: downtime.toStringAsFixed(0),
          unit: 'h',
          icon: Icons.timer_off_outlined,
        ),
        KpiTile(
          label: 'Open cost est.',
          value: usd(state.openMaintenanceCost),
          icon: Icons.payments_outlined,
          accent: p.accent,
        ),
      ],
    );
  }

  Widget _leftColumn(BuildContext context, AppState state, List<MaintenanceItem> open) {
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Work order pipeline',
            eyebrow: 'Predicted → scheduled → in progress',
            live: true,
          ),
          if (open.isEmpty)
            const EmptyState(
              icon: Icons.verified_rounded,
              title: 'Queue is clear',
              subtitle: 'No open work orders — the fleet is healthy.',
            )
          else
            for (final m in open.take(10)) _workOrderRow(context, state, m),
        ],
      ),
    );
  }

  Widget _workOrderRow(BuildContext context, AppState state, MaintenanceItem m) {
    final p = context.pal;
    final v = state.vehicleById(m.vehicleId);

    (Color, Color, String, IconData) statusVisual() => switch (m.status) {
          MaintenanceStatus.predicted => (p.primary, p.primarySoft, 'PREDICTED', Icons.psychology_alt_rounded),
          MaintenanceStatus.scheduled => (p.satisfactory, p.satisfactorySoft, 'SCHEDULED', Icons.event_available_rounded),
          MaintenanceStatus.inProgress => (p.urgent, p.urgentSoft, 'IN SHOP', Icons.construction_rounded),
          MaintenanceStatus.completed => (p.good, p.goodSoft, 'DONE', Icons.check_circle_rounded),
        };
    final (color, soft, label, icon) = statusVisual();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
      child: Row(
        children: [
          // Status icon block.
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(K.rSm)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: K.sm),
          // Vehicle + job.
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      v?.plate ?? '—',
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: K.sm),
                    StatusChip(label: label, color: color, soft: soft, dot: false),
                    const Spacer(),
                    Text(
                      m.kind == MaintenanceKind.preventive ? 'Preventive' : 'Corrective',
                      style: TextStyle(
                        fontSize: K.caption,
                        fontWeight: FontWeight.w600,
                        color: m.kind == MaintenanceKind.preventive ? p.good : p.accent,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '${m.title} · ${m.part}',
                  style: TextStyle(
                    fontSize: K.caption,
                    color: p.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: K.sm),
          // Due + confidence + cost.
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'due in ${m.dueInKm} km',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w700,
                    color: m.dueInKm < 800 ? p.critical : p.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  '${m.confidencePct}% conf · ${usd(m.costEstUsd)}',
                  style: TextStyle(
                    fontSize: K.caption,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: K.sm),
          // Action.
          SizedBox(
            width: 74,
            height: 24,
            child: switch (m.status) {
              MaintenanceStatus.predicted => FilledButton(
                  onPressed: () => state.scheduleMaintenance(m.id),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontSize: K.caption, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                  ),
                  child: const Text('SCHEDULE'),
                ),
              MaintenanceStatus.scheduled => FilledButton(
                  onPressed: () => state.startMaintenance(m.id),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontSize: K.caption, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                  ),
                  child: const Text('START'),
                ),
              MaintenanceStatus.inProgress => FilledButton(
                  onPressed: () => state.completeMaintenance(m.id),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: p.good,
                    textStyle: const TextStyle(fontSize: K.caption, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                  ),
                  child: const Text('CLOSE'),
                ),
              MaintenanceStatus.completed => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }

  Widget _rightColumn(BuildContext context, AppState state) {
    final p = context.pal;
    final worst = state.healthRanking.take(6).toList();
    final open = state.openMaintenance;
    final preventive = open.where((m) => m.kind == MaintenanceKind.preventive).length;
    final corrective = open.length - preventive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle health triage.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Health triage', eyebrow: 'Worst vehicles first'),
              for (final v in worst)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${v.type.short} · ${kmFmt(v.odometerKm)}',
                              style: TextStyle(
                                fontSize: K.caption,
                                color: p.textTertiary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 2),
                            KProgress(
                              value: 1 - v.condition.rank / 3,
                              color: conditionColor(context, v.condition),
                              height: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: K.sm),
                      StatusChip.condition(context, v.condition),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Predictive mix.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            children: [
              const SectionHeader(title: 'Work mix', eyebrow: 'Preventive vs corrective'),
              Row(
                children: [
                  Donut(
                    size: 88,
                    slices: [
                      (preventive.toDouble(), p.good),
                      (corrective.toDouble(), p.accent),
                    ],
                    centerTop: '${open.length}',
                    centerBottom: 'OPEN',
                  ),
                  const SizedBox(width: K.md),
                  Expanded(
                    child: Column(
                      children: [
                        LabelBar(
                          label: 'Preventive',
                          value: open.isEmpty ? 0 : preventive / open.length,
                          valueText: '$preventive',
                          color: p.good,
                        ),
                        LabelBar(
                          label: 'Corrective',
                          value: open.isEmpty ? 0 : corrective / open.length,
                          valueText: '$corrective',
                          color: p.accent,
                        ),
                        const SizedBox(height: K.xs),
                        Text(
                          'Preventive work avoids the downtime and brand damage of roadside failures.',
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
              ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Active DTC codes.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Active fault codes',
                eyebrow: 'OBD-II diagnostics',
                live: true,
                action: Text(
                  '${state.vehicles.where((v) => v.hasActiveDtc).length} vehicles',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w700,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              ..._dtcRows(context, state),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _dtcRows(BuildContext context, AppState state) {
    final p = context.pal;
    final rows = <Widget>[];
    for (final v in state.vehicles) {
      for (final dtc in v.dtcCodes.where((c) => c.active)) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: K.xs + 1, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.criticalSoft,
                    borderRadius: BorderRadius.circular(K.rSm),
                  ),
                  child: Text(
                    dtc.code,
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w800,
                      color: p.critical,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: K.sm),
                Text(
                  v.plate,
                  style: TextStyle(
                    fontSize: K.label,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: K.sm),
                Expanded(
                  child: Text(
                    dtc.description,
                    style: TextStyle(
                      fontSize: K.caption,
                      color: p.textSecondary,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    if (rows.isEmpty) {
      rows.add(const EmptyState(icon: Icons.verified_outlined, title: 'No active fault codes'));
    }
    return rows;
  }
}
