import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Maintenance workspace — rebuilt as a shop-floor control room (Fleetio
/// pattern): a dense work-order queue you can run the shop from, a PM-due
/// list with interval progress, DTC fault codes that convert to work orders
/// in one tap, and labor tracking. Maximum density — the queue IS the tool.
class MaintenanceDashboard extends StatelessWidget {
  const MaintenanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 1080;
    final open = state.openMaintenance;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Shop control',
          subtitle:
              '${open.length} open work orders · ${state.inShopCount} vehicles in shop · ${state.vehicles.where((v) => v.hasActiveDtc).length} assets with active DTCs',
          actions: [
            _newWoButton(context, state),
            const RoleSwitchChip(),
          ],
        ),

        // Pipeline summary chips: the shop funnel at a glance.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: _pipeline(context, state),
        ),
        const SizedBox(height: K.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _woQueue(context, state, open)),
                    const SizedBox(width: K.md),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _dtcFeed(context, state),
                          const SizedBox(height: K.md),
                          _pmDue(context, state),
                          const SizedBox(height: K.md),
                          _partsPanel(context),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _woQueue(context, state, open),
                    const SizedBox(height: K.md),
                    _dtcFeed(context, state),
                    const SizedBox(height: K.md),
                    _pmDue(context, state),
                    const SizedBox(height: K.md),
                    _partsPanel(context),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _newWoButton(BuildContext context, AppState state) {
    final p = context.pal;
    return InkWell(
      onTap: () {
        // Create a blank inspection WO on the first vehicle with a DTC,
        // or a general service order — instant queue feedback.
        final withDtc = state.vehicles.where((v) => v.hasActiveDtc).firstOrNull;
        if (withDtc != null) {
          final code = withDtc.dtcCodes.where((c) => c.active).first;
          state.createWorkOrderFromDtc(withDtc.id, code);
          _toast(context, 'Work order created from ${code.code} on ${withDtc.plate}');
        } else {
          _toast(context, 'No open fault codes — nothing to convert right now.');
        }
      },
      borderRadius: BorderRadius.circular(K.rSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 2),
        decoration: BoxDecoration(
          color: p.urgent,
          borderRadius: BorderRadius.circular(K.rSm),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, size: 13, color: Colors.white),
            const SizedBox(width: K.xs + 1),
            Text(
              'NEW WORK ORDER',
              style: TextStyle(
                fontSize: K.micro,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3), content: Text(message)),
    );
  }

  // ── Pipeline funnel ──────────────────────────────────────────────────────

  Widget _pipeline(BuildContext context, AppState state) {
    final p = context.pal;
    final stages = <(MaintenanceStatus, String, Color)>[
      (MaintenanceStatus.predicted, 'Predicted', p.info),
      (MaintenanceStatus.scheduled, 'Scheduled', p.primary),
      (MaintenanceStatus.inProgress, 'In progress', p.urgent),
      (MaintenanceStatus.completed, 'Completed', p.good),
    ];
    return Row(
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          if (i > 0) ...[
            const Icon(Icons.chevron_right_rounded, size: 13, color: null),
            const SizedBox(width: K.xxs),
          ],
          Expanded(
            child: _pipelineChip(
              context,
              stages[i].$2.toUpperCase(),
              '${state.maintenance.where((m) => m.status == stages[i].$1).length}',
              stages[i].$3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _pipelineChip(BuildContext context, String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: K.md, vertical: K.sm + 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(K.rSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: K.title,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: K.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: K.micro,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: color,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Work-order queue (the hero table) ────────────────────────────────────

  Widget _woQueue(BuildContext context, AppState state, List<MaintenanceItem> open) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Work order queue',
            eyebrow: 'Live shop floor · priority triage',
            live: true,
            action: Text(
              'ROs > \$${MaintenanceItem.approvalThresholdUsd.round()} need finance approval',
              style: TextStyle(
                fontSize: K.caption,
                color: p.textTertiary,
                fontFamily: 'Inter',
              ),
            ),
          ),

          // Table header.
          _tableHead(context),
          if (open.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: K.xxl),
              child: EmptyState(
                icon: Icons.verified_rounded,
                title: 'Queue is clear',
                subtitle: 'No open work orders — the fleet is healthy.',
              ),
            )
          else
            for (final m in open.take(10)) _woRow(context, state, m),
        ],
      ),
    );
  }

  Widget _tableHead(BuildContext context) {
    final p = context.pal;
    final style = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: p.textTertiary,
      fontFamily: 'Inter',
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(K.rSm),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40, child: Text('PRI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'))),
          SizedBox(width: 62, child: Text('VEHICLE', style: style)),
          Expanded(flex: 4, child: Text('JOB', style: style)),
          SizedBox(width: 78, child: Text('TECH', style: style)),
          SizedBox(width: 56, child: Text('LABOR', style: style)),
          SizedBox(width: 64, child: Text('COST', style: style)),
          SizedBox(width: 90, child: Text('STATUS', style: style)),
          SizedBox(width: 70, child: Text('ACTION', style: style)),
        ],
      ),
    );
  }

  Widget _woRow(BuildContext context, AppState state, MaintenanceItem m) {
    final p = context.pal;
    final v = state.vehicleById(m.vehicleId);
    final priColor = switch (m.priority) {
      MaintenancePriority.emergency => p.critical,
      MaintenancePriority.nonScheduled => p.urgent,
      MaintenancePriority.scheduled => p.primary,
    };
    final statusColor = switch (m.status) {
      MaintenanceStatus.predicted => p.info,
      MaintenanceStatus.scheduled => p.primary,
      MaintenanceStatus.inProgress => p.urgent,
      MaintenanceStatus.completed => p.good,
    };
    final laborText = m.status == MaintenanceStatus.inProgress
        ? '${m.laborHoursActual.toStringAsFixed(1)}/${m.laborHoursEst.toStringAsFixed(0)}h'
        : '${m.laborHoursEst.toStringAsFixed(0)}h';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs + 2),
      margin: const EdgeInsets.only(bottom: K.xxs + 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(K.rSm),
        border: Border.all(color: p.border),
        color: m.priority == MaintenancePriority.emergency ? p.criticalSoft.withValues(alpha: 0.4) : null,
      ),
      child: Row(
        children: [
          // Priority tag.
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: K.xs + 1, vertical: 1),
              decoration: BoxDecoration(
                color: priColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(K.rSm),
                border: Border.all(color: priColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                m.priority.short,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: K.micro,
                  fontWeight: FontWeight.w800,
                  color: priColor,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          const SizedBox(width: K.xs + 1),
          SizedBox(
            width: 62,
            child: Text(
              v?.plate ?? '—',
              style: TextStyle(
                fontSize: K.label,
                fontWeight: FontWeight.w700,
                color: p.text,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              m.title,
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
            width: 78,
            child: Text(
              m.tech ?? 'unassigned',
              style: TextStyle(
                fontSize: K.label,
                color: m.tech == null ? p.textTertiary : p.textSecondary,
                fontStyle: m.tech == null ? FontStyle.italic : FontStyle.normal,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              laborText,
              style: TextStyle(
                fontSize: K.label,
                color: m.status == MaintenanceStatus.inProgress &&
                        m.laborHoursActual > m.laborHoursEst
                    ? p.critical
                    : p.textSecondary,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              usd(m.costEstUsd),
              style: TextStyle(
                fontSize: K.label,
                fontWeight: FontWeight.w700,
                color: m.needsApproval ? p.accent : p.text,
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                ),
                const SizedBox(width: K.xs + 1),
                Expanded(
                  child: Text(
                    switch (m.status) {
                      MaintenanceStatus.predicted => 'Predicted',
                      MaintenanceStatus.scheduled => 'Scheduled',
                      MaintenanceStatus.inProgress => 'In shop',
                      MaintenanceStatus.completed => 'Done',
                    },
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: _rowAction(context, state, m),
          ),
        ],
      ),
    );
  }

  /// Next-best action per WO state: schedule → assign tech → start → close.
  Widget _rowAction(BuildContext context, AppState state, MaintenanceItem m) {
    final p = context.pal;
    late final String label;
    late final VoidCallback onTap;
    late final Color color;

    switch (m.status) {
      case MaintenanceStatus.predicted:
        label = 'SCHEDULE';
        onTap = () => state.scheduleMaintenance(m.id);
        color = p.info;
      case MaintenanceStatus.scheduled:
        if (m.needsApproval) {
          label = 'APPROVE';
          onTap = () => state.approveMaintenance(m.id);
          color = p.accent;
        } else if (m.tech == null) {
          label = 'ASSIGN';
          onTap = () => state.assignTech(m.id, 'Luis Park');
          color = p.primary;
        } else {
          label = 'START';
          onTap = () => state.startMaintenance(m.id);
          color = p.urgent;
        }
      case MaintenanceStatus.inProgress:
        label = 'CLOSE';
        onTap = () => state.completeMaintenance(m.id);
        color = p.good;
      case MaintenanceStatus.completed:
        label = 'DONE';
        onTap = () {};
        color = p.good;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(K.rSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs + 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(K.rSm),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: K.micro,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  // ── DTC feed with one-tap WO conversion ──────────────────────────────────

  Widget _dtcFeed(BuildContext context, AppState state) {
    final p = context.pal;
    final items = <(Vehicle, DtcCode)>[
      for (final v in state.vehicles)
        for (final c in v.dtcCodes.where((c) => c.active)) (v, c),
    ];

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Fault codes',
            eyebrow: 'DTC → work order in one tap',
            action: Text(
              '${items.length} ACTIVE',
              style: TextStyle(
                fontSize: K.caption,
                fontWeight: FontWeight.w800,
                color: items.isEmpty ? p.good : p.urgent,
                fontFamily: 'Inter',
              ),
            ),
          ),
          if (items.isEmpty)
            const EmptyState(icon: Icons.memory_rounded, title: 'No active fault codes')
          else
            for (final (v, c) in items.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: K.xs + 1),
                child: InkWell(
                  onTap: () {
                    state.createWorkOrderFromDtc(v.id, c);
                    _toast(context, '${c.code} converted to a work order for ${v.plate}');
                  },
                  borderRadius: BorderRadius.circular(K.rSm),
                  child: Container(
                    padding: const EdgeInsets.all(K.sm + 1),
                    decoration: BoxDecoration(
                      color: p.urgentSoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(K.rSm),
                      border: Border.all(color: p.urgent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          c.code,
                          style: TextStyle(
                            fontSize: K.label,
                            fontWeight: FontWeight.w800,
                            color: p.urgent,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: K.sm),
                        Expanded(
                          child: Text(
                            c.description,
                            style: TextStyle(
                              fontSize: K.caption,
                              color: p.textSecondary,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: K.xs),
                        Text(
                          v.plate,
                          style: TextStyle(
                            fontSize: K.caption,
                            fontWeight: FontWeight.w700,
                            color: p.textTertiary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: K.sm),
                        Icon(Icons.add_circle_outline_rounded, size: 13, color: p.urgent),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ── PM due list with interval progress ───────────────────────────────────

  Widget _pmDue(BuildContext context, AppState state) {
    final p = context.pal;
    final pm = state.maintenance
        .where((m) => m.kind == MaintenanceKind.preventive && m.status != MaintenanceStatus.completed)
        .toList()
      ..sort((a, b) => a.dueInKm.compareTo(b.dueInKm));

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'PM due',
            eyebrow: 'By odometer · confidence-weighted',
            action: Text(
              '${state.predictedMaintenanceCount} DUE',
              style: TextStyle(
                fontSize: K.caption,
                fontWeight: FontWeight.w800,
                color: p.urgent,
                fontFamily: 'Inter',
              ),
            ),
          ),
          for (final m in pm.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 58,
                        child: Text(
                          state.vehicleById(m.vehicleId)?.plate ?? '—',
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
                          m.part,
                          style: TextStyle(
                            fontSize: K.label,
                            color: p.textSecondary,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${m.dueInKm} km',
                        style: TextStyle(
                          fontSize: K.caption,
                          fontWeight: FontWeight.w800,
                          color: m.dueInKm < 300 ? p.critical : m.dueInKm < 1000 ? p.urgent : p.textTertiary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: K.xxs + 1),
                  Row(
                    children: [
                      Expanded(
                        child: KProgress(
                          value: (1 - (m.dueInKm / 3500)).clamp(0.0, 1.0),
                          color: m.dueInKm < 300 ? p.critical : m.dueInKm < 1000 ? p.urgent : p.primary,
                          height: 3,
                        ),
                      ),
                      const SizedBox(width: K.sm),
                      Text(
                        '${m.confidencePct}% conf.',
                        style: TextStyle(
                          fontSize: K.caption,
                          color: p.textTertiary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Parts inventory alerts ───────────────────────────────────────────────

  Widget _partsPanel(BuildContext context) {
    final p = context.pal;
    const parts = <(String, int, int)>[
      ('Drive tires 11R22.5', 2, 6),
      ('Air disc pads', 4, 8),
      ('Fuel line seal kit', 1, 4),
      ('AGM batteries', 3, 6),
      ('Eaton clutch kit', 0, 2),
    ];

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Parts stock', eyebrow: 'Auto-deducts on WO close'),
          for (final (name, onHand, min) in parts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
              child: Row(
                children: [
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
                    width: 52,
                    child: KProgress(
                      value: (onHand / min).clamp(0.0, 1.0),
                      color: onHand == 0 ? p.critical : onHand * 2 <= min ? p.urgent : p.good,
                      height: 3,
                    ),
                  ),
                  const SizedBox(width: K.sm),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$onHand',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w800,
                        color: onHand == 0 ? p.critical : onHand * 2 <= min ? p.urgent : p.text,
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
}
