import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Dispatcher workspace — rebuilt as a true dispatch board (Samsara Dispatch
/// pattern): kanban columns over the load lifecycle, drivers ranked by HOS
/// remaining for assignment matching, an ETA exception feed and a live map
/// inset. Dense, board-first, built for rapid assign/reassign decisions.
class DispatcherDashboard extends StatelessWidget {
  const DispatcherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 1080;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Dispatch board',
          subtitle:
              '${state.unassignedLoads.length} unassigned · ${state.enRouteTrips.length} en route · ${state.availableDrivers.length} drivers available',
          actions: [
            Row(
              children: [
                const LiveDot(size: 6),
                const SizedBox(width: K.xs),
                Text(
                  'AUTO-REFRESH',
                  style: TextStyle(
                    fontSize: K.micro,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: p.good,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const RoleSwitchChip(),
          ],
        ),

        // Slim strip of board KPIs — not the hero, just the pulse.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: _kpiStrip(context, state),
        ),
        const SizedBox(height: K.md),

        // The board: kanban lifecycle columns (horizontally scrollable).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: _kanban(context, state),
        ),
        const SizedBox(height: K.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _driverPanel(context, state)),
                    const SizedBox(width: K.md),
                    Expanded(flex: 4, child: _exceptionsPanel(context, state)),
                  ],
                )
              : Column(
                  children: [
                    _driverPanel(context, state),
                    const SizedBox(height: K.md),
                    _exceptionsPanel(context, state),
                  ],
                ),
        ),
      ],
    );
  }

  // ── KPI strip ────────────────────────────────────────────────────────────

  Widget _kpiStrip(BuildContext context, AppState state) {
    final p = context.pal;
    final onTime = state.avgOnTimeRate * 100;
    final tiles = <Widget>[
      _stripTile(context, 'Unassigned', '${state.unassignedLoads.length}',
          Icons.inbox_rounded, state.unassignedLoads.isEmpty ? p.good : p.urgent),
      _stripTile(context, 'En route', '${state.enRouteTrips.length}',
          Icons.route_rounded, p.primary),
      _stripTile(
          context,
          'At-risk ETA',
          '${state.atRiskTrips.length}',
          Icons.schedule_rounded,
          state.atRiskTrips.isEmpty ? p.good : p.critical),
      _stripTile(context, 'Drivers avail.', '${state.availableDrivers.length}',
          Icons.badge_rounded, p.satisfactory),
      _stripTile(context, 'On-time', '${onTime.round()}%', Icons.verified_rounded,
          onTime >= 95 ? p.good : p.urgent),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: K.xs + 1),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  Widget _stripTile(BuildContext context, String label, String value, IconData icon, Color color) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.symmetric(horizontal: K.md, vertical: K.sm + 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: K.sm),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: K.micro,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: p.textTertiary,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: K.subtitle,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ── Kanban lifecycle board ────────────────────────────────────────────────

  Widget _kanban(BuildContext context, AppState state) {
    final unassigned = state.unassignedLoads;
    final assigned = state.assignedNotStarted;
    final enRoute = state.trips
        .where((t) => t.status == TripStatus.enRoute && t.driverId.isNotEmpty)
        .toList();
    final atRisk = state.atRiskTrips;
    final delivered = state.deliveredTrips;

    return KCard(
      padding: const EdgeInsets.all(K.sm + 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kanbanColumn(context, state, 'UNASSIGNED', unassigned, critColor(context), Icons.inbox_rounded),
            _kanbanColumn(context, state, 'ASSIGNED', assigned, context.pal.primary, Icons.checklist_rounded),
            _kanbanColumn(context, state, 'EN ROUTE', enRoute, context.pal.good, Icons.route_rounded),
            _kanbanColumn(context, state, 'AT RISK', atRisk, critColor(context), Icons.warning_amber_rounded),
            _kanbanColumn(context, state, 'DELIVERED', delivered, context.pal.textSecondary, Icons.task_alt_rounded),
          ],
        ),
      ),
    );
  }

  Color critColor(BuildContext context) => context.pal.critical;

  static const _colWidth = 236.0;

  Widget _kanbanColumn(
      BuildContext context, AppState state, String title, List<Trip> loads, Color color, IconData icon) {
    final p = context.pal;
    return Container(
      width: _colWidth,
      margin: const EdgeInsets.only(right: K.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column header with count.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(K.rSm),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: K.xs + 1),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: K.micro,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: color,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: K.xs + 1, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(K.rSm),
                  ),
                  child: Text(
                    '${loads.length}',
                    style: TextStyle(
                      fontSize: K.micro,
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: K.xs + 1),

          if (loads.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: K.lg),
              child: Text(
                'Nothing here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: K.caption,
                  color: p.textTertiary,
                  fontFamily: 'Inter',
                ),
              ),
            )
          else
            for (final t in loads.take(6)) _loadCard(context, state, t, color),
        ],
      ),
    );
  }

  Widget _loadCard(BuildContext context, AppState state, Trip t, Color columnColor) {
    final p = context.pal;
    final driver = state.driverById(t.driverId);
    final vehicle = state.vehicleById(t.vehicleId);
    final isUnassigned = t.driverId.isEmpty;

    return GestureDetector(
      onTap: isUnassigned ? () => _openAssignSheet(context, state, t) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: K.xs + 1),
        padding: const EdgeInsets.all(K.sm + 2),
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(K.rMd),
          border: Border.all(
            color: isUnassigned ? columnColor.withValues(alpha: 0.45) : p.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  t.loadId,
                  style: TextStyle(
                    fontSize: K.label,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                if (isUnassigned)
                  Icon(Icons.add_circle_rounded, size: 14, color: columnColor)
                else if (t.status == TripStatus.atRisk)
                  Icon(Icons.warning_amber_rounded, size: 13, color: p.critical),
              ],
            ),
            const SizedBox(height: K.xxs + 1),
            Text(
              t.customer,
              style: TextStyle(
                fontSize: K.caption,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: K.xs + 1),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 10, color: p.textTertiary),
                const SizedBox(width: K.xxs + 1),
                Expanded(
                  child: Text(
                    '${t.origin} → ${t.destination}',
                    style: TextStyle(
                      fontSize: K.caption,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: K.xs + 1),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 10, color: p.textTertiary),
                const SizedBox(width: K.xxs + 1),
                Expanded(
                  child: Text(
                    vehicle?.plate ?? '—',
                    style: TextStyle(
                      fontSize: K.caption,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                if (t.progressPct > 0) ...[
                  SizedBox(
                    width: 42,
                    child: KProgress(value: t.progressPct / 100, color: p.good, height: 3),
                  ),
                  const SizedBox(width: K.xs),
                  Text(
                    '${t.progressPct.round()}%',
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w700,
                      color: p.good,
                      fontFamily: 'Inter',
                    ),
                  ),
                ] else if (driver != null)
                  Text(
                    driver.name.split(' ').last,
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w700,
                      color: p.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
              ],
            ),
            if (isUnassigned) ...[
              const SizedBox(height: K.xs + 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs + 1),
                decoration: BoxDecoration(
                  color: columnColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(K.rSm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_rounded, size: 11, color: columnColor),
                    const SizedBox(width: K.xs + 1),
                    Text(
                      'TAP TO ASSIGN DRIVER',
                      style: TextStyle(
                        fontSize: K.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: columnColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Assignment matcher: drivers ranked by HOS remaining; one tap assigns.
  void _openAssignSheet(BuildContext context, AppState state, Trip load) {
    final p = context.pal;
    final (_, candidates) = state.assignmentCandidates(load);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(K.rLg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(K.lg, K.md, K.lg, K.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign ${load.loadId}',
                        style: TextStyle(
                          fontSize: K.headline,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: p.text,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: K.xxs + 1),
                      Text(
                        '${load.origin} → ${load.destination} · ${load.customer} · ${load.distanceKm.round()} km',
                        style: TextStyle(
                          fontSize: K.label,
                          color: p.textTertiary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: p.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(K.lg, K.xs, K.lg, K.xs),
                  child: Text(
                    'RANKED BY HOURS REMAINING · ${candidates.length} LEGAL CANDIDATES',
                    style: TextStyle(
                      fontSize: K.micro,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Flexible(
                  child: candidates.isEmpty
                      ? EmptyState(
                          icon: Icons.person_off_rounded,
                          title: 'No drivers available',
                          subtitle: 'Everyone is on a route or out of hours.',
                        )
                      : ListView.builder(
                          itemCount: candidates.length,
                          padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.lg),
                          itemBuilder: (_, i) {
                            final d = candidates[i];
                            final v = state.vehicles
                                .where((x) => x.driverId == d.id)
                                .firstOrNull;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: K.xs + 1),
                              child: InkWell(
                                onTap: () {
                                  state.assignLoad(load.id, d.id);
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                      content: Text(
                                        '${load.loadId} assigned to ${d.name} — sent to driver app.',
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(K.rMd),
                                child: Container(
                                  padding: const EdgeInsets.all(K.sm + 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(K.rMd),
                                    border: Border.all(
                                      color: i == 0 ? p.good.withValues(alpha: 0.5) : p.border,
                                      width: i == 0 ? 1.4 : 1,
                                    ),
                                    color: i == 0 ? p.goodSoft.withValues(alpha: 0.4) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      DriverAvatar(name: d.name, hue: d.hue, size: 30),
                                      const SizedBox(width: K.sm + 2),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    d.name,
                                                    style: TextStyle(
                                                      fontSize: K.subtitle,
                                                      fontWeight: FontWeight.w700,
                                                      color: p.text,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                                if (i == 0)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: K.xs + 1, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: p.goodSoft,
                                                      borderRadius: BorderRadius.circular(K.rSm),
                                                    ),
                                                    child: Text(
                                                      'BEST MATCH',
                                                      style: TextStyle(
                                                        fontSize: K.micro,
                                                        fontWeight: FontWeight.w800,
                                                        letterSpacing: 0.4,
                                                        color: p.good,
                                                        fontFamily: 'Inter',
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              '${v?.plate ?? 'no truck'} · ${d.license} · safety ${d.safetyScore.round()}',
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${d.hosRemaining.toStringAsFixed(1)}h',
                                            style: TextStyle(
                                              fontSize: K.subtitle,
                                              fontWeight: FontWeight.w800,
                                              color: d.hosRemaining > 20 ? p.good : p.urgent,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                          Text(
                                            'HOS LEFT',
                                            style: TextStyle(
                                              fontSize: K.micro,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                              color: p.textTertiary,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Driver availability panel ─────────────────────────────────────────────

  Widget _driverPanel(BuildContext context, AppState state) {
    final p = context.pal;
    final drivers = state.availableDrivers.take(8).toList();

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: 'Driver availability', eyebrow: 'Ranked by HOS remaining', live: true),
          for (final d in drivers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
              child: Row(
                children: [
                  DriverAvatar(name: d.name, hue: d.hue, size: 26),
                  const SizedBox(width: K.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: TextStyle(
                            fontSize: K.body,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          '${state.vehicles.where((v) => v.driverId == d.id).firstOrNull?.plate ?? 'no truck'} · on-time ${(d.onTimeRate * 100).round()}%',
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
                  SizedBox(
                    width: 74,
                    child: KProgress(
                      value: (d.hosRemaining / d.hosCycleLimit).clamp(0.0, 1.0),
                      color: d.hosRemaining > 20 ? p.good : d.hosRemaining > 8 ? p.urgent : p.critical,
                      height: 4,
                    ),
                  ),
                  const SizedBox(width: K.sm),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '${d.hosRemaining.toStringAsFixed(1)}h',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w800,
                        color: d.hosRemaining > 20 ? p.good : p.urgent,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (drivers.isEmpty)
            const EmptyState(icon: Icons.person_off_rounded, title: 'No available drivers'),
        ],
      ),
    );
  }

  // ── ETA exceptions & geofence feed ────────────────────────────────────────

  Widget _exceptionsPanel(BuildContext context, AppState state) {
    final p = context.pal;
    final risky = state.atRiskTrips;
    final geofEvents = state.alerts
        .where((a) => a.type == AlertType.geofenceExit && a.status == AlertStatus.active)
        .take(4)
        .toList();

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Exceptions & arrivals',
            eyebrow: 'ETA slips · geofence events',
            live: true,
            action: Text(
              '${risky.length + geofEvents.length}',
              style: TextStyle(
                fontSize: K.subtitle,
                fontWeight: FontWeight.w800,
                color: risky.isEmpty ? p.good : p.critical,
                fontFamily: 'Inter',
              ),
            ),
          ),
          for (final t in risky)
            _exceptionRow(
              context,
              Icons.schedule_rounded,
              p.critical,
              '${t.loadId} slipping · +${t.delayMinutes} min',
              '${state.driverById(t.driverId)?.name ?? '—'} · ETA ${t.etaMinutes} min · ${t.destination}',
            ),
          for (final a in geofEvents)
            _exceptionRow(
              context,
              Icons.fence_rounded,
              p.info,
              a.title,
              '${state.vehicleById(a.vehicleId)?.plate ?? '—'} · ${timeAgo(a.timestamp)}',
            ),
          if (risky.isEmpty && geofEvents.isEmpty)
            const EmptyState(
              icon: Icons.verified_rounded,
              title: 'All loads on schedule',
              subtitle: 'No ETA slips or geofence events right now.',
            ),
        ],
      ),
    );
  }

  Widget _exceptionRow(BuildContext context, IconData icon, Color color, String title, String sub) {
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.only(bottom: K.xs + 1),
      padding: const EdgeInsets.all(K.sm + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(K.rSm),
        border: Border(left: BorderSide(color: color, width: 3)),
        color: p.surfaceAlt,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: K.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: K.body,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: K.caption,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
