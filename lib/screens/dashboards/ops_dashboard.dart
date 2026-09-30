import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/map_painter.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Fleet-ops workspace — rebuilt as a map-dominant command center (Samsara
/// Fleet Overview pattern): the live map IS the dashboard, a KPI strip runs
/// across the top, exceptions stream down the right rail, and utilization /
/// idle leaderboards anchor the bottom. Filters and status colors match the
/// map pins so the whole screen reads as one tactical picture.
class OpsDashboard extends StatefulWidget {
  const OpsDashboard({super.key});

  @override
  State<OpsDashboard> createState() => _OpsDashboardState();
}

class _OpsDashboardState extends State<OpsDashboard> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final mq = MediaQuery.sizeOf(context);
    final wide = mq.width >= 1080;
    // Map-dominant: hero takes as much vertical room as it can get.
    final mapHeight = (mq.height * (wide ? 0.52 : 0.42)).clamp(260.0, 560.0);

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Fleet command',
          subtitle:
              '${state.vehicles.length} assets · ${state.onRouteCount} moving · ${state.idleCount} idle · ${state.inShopCount} in shop',
          actions: [
            Row(
              children: [
                const LiveDot(size: 6),
                const SizedBox(width: K.xs),
                Text(
                  'LIVE · ${state.fleetSpeedHistory.isEmpty ? '—' : '${state.fleetSpeedHistory.last.round()} km/h avg'}',
                  style: TextStyle(
                    fontSize: K.micro,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: context.pal.good,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const RoleSwitchChip(),
          ],
        ),

        // KPI strip with sparklines.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: _kpiStrip(context, state),
        ),
        const SizedBox(height: K.md),

        // Map hero + exception drawer.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: SizedBox(
                        height: mapHeight,
                        child: _mapHero(context, state),
                      ),
                    ),
                    const SizedBox(width: K.md),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: mapHeight,
                        child: _exceptionFeed(context, state),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    SizedBox(height: mapHeight, child: _mapHero(context, state)),
                    const SizedBox(height: K.md),
                    _exceptionFeed(context, state),
                  ],
                ),
        ),
        const SizedBox(height: K.md),

        // Utilization + idle leaderboard row.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _utilizationPanel(context, state)),
                    const SizedBox(width: K.md),
                    Expanded(child: _idlePanel(context, state)),
                    const SizedBox(width: K.md),
                    Expanded(child: _healthPanel(context, state)),
                  ],
                )
              : Column(
                  children: [
                    _utilizationPanel(context, state),
                    const SizedBox(height: K.md),
                    _idlePanel(context, state),
                    const SizedBox(height: K.md),
                    _healthPanel(context, state),
                  ],
                ),
        ),
      ],
    );
  }

  // ── KPI strip with sparklines ────────────────────────────────────────────

  Widget _kpiStrip(BuildContext context, AppState state) {
    final p = context.pal;
    final util = state.fleetUtilization * 100;
    final idlePct = state.idleCount == 0
        ? 4.0
        : (state.vehicles.fold<double>(0, (s, v) => s + v.idleMinutesToday) /
                (state.onRouteCount + state.idleCount + 1) /
                12)
            .clamp(1.0, 40.0);

    return Row(
      children: [
        Expanded(
          child: _kpi(context, 'Utilization', '${util.round()}', '%',
              util >= 70 ? p.good : p.urgent, Icons.speed_rounded,
              spark: [for (final v in state.onRouteHistory) v / state.vehicles.length]),
        ),
        const SizedBox(width: K.xs + 1),
        Expanded(
          child: _kpi(context, 'On route', '${state.onRouteCount}', '',
              p.primary, Icons.route_rounded,
              spark: state.onRouteHistory),
        ),
        const SizedBox(width: K.xs + 1),
        Expanded(
          child: _kpi(context, 'Idle', idlePct.toStringAsFixed(0), '%',
              idlePct < 5 ? p.good : p.urgent, Icons.local_parking_rounded),
        ),
        const SizedBox(width: K.xs + 1),
        Expanded(
          child: _kpi(context, 'Exceptions', '${state.activeAlertCount}', '',
              state.activeAlertCount > 4 ? p.critical : p.satisfactory, Icons.bolt_rounded),
        ),
        const SizedBox(width: K.xs + 1),
        Expanded(
          child: _kpi(context, 'Avg fuel', '${state.avgFuelLevel.round()}', '%',
              state.avgFuelLevel < 40 ? p.urgent : p.good, Icons.local_gas_station_rounded),
        ),
      ],
    );
  }

  Widget _kpi(BuildContext context, String label, String value, String unit, Color color,
      IconData icon, {List<double>? spark}) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.all(K.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: K.xs),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: K.xxs + 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: K.headline,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: color,
                  fontFamily: 'Inter',
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: K.xxs + 1),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w600,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (spark != null && spark.length > 2)
                SizedBox(
                  width: 46,
                  height: 22,
                  child: Sparkline(values: spark, color: color, height: 22),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Map hero ──────────────────────────────────────────────────────────────

  Widget _mapHero(BuildContext context, AppState state) {
    return KCard(
      padding: const EdgeInsets.all(K.xs + 1),
      child: Column(
        children: [
          Expanded(
            child: FleetMap(
              vehicles: state.vehicles,
              geofences: state.geofences,
              stations: state.stations,
              routes: state.trips,
              selectedVehicleId: _selected,
              onVehicleTap: (id) => setState(() => _selected = id),
              showRoutes: true,
              showGeofences: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(K.xs + 1),
            child: const MapLegend(),
          ),
        ],
      ),
    );
  }

  // ── Exception feed (right drawer) ────────────────────────────────────────

  Widget _exceptionFeed(BuildContext context, AppState state) {
    final p = context.pal;
    final active = state.alerts
        .where((a) => a.status == AlertStatus.active)
        .take(9)
        .toList();

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Exception feed',
            eyebrow: 'Live telematics events',
            live: true,
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs),
              decoration: BoxDecoration(
                color: active.isEmpty ? p.goodSoft : p.criticalSoft,
                borderRadius: BorderRadius.circular(K.rSm),
              ),
              child: Text(
                '${active.length}',
                style: TextStyle(
                  fontSize: K.label,
                  fontWeight: FontWeight.w800,
                  color: active.isEmpty ? p.good : p.critical,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          Expanded(
            child: active.isEmpty
                ? const EmptyState(
                    icon: Icons.verified_rounded,
                    title: 'Fleet is quiet',
                    subtitle: 'No active exceptions.',
                  )
                : ListView.builder(
                    itemCount: active.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (_, i) => _exceptionRow(context, state, active[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _exceptionRow(BuildContext context, AppState state, FleetAlert a) {
    final p = context.pal;
    final color = switch (a.severity) {
      AlertSeverity.critical => p.critical,
      AlertSeverity.urgent => p.urgent,
      AlertSeverity.warning => p.accent,
      AlertSeverity.info => p.info,
    };
    final v = state.vehicleById(a.vehicleId);

    return InkWell(
      onTap: () => setState(() => _selected = a.vehicleId),
      borderRadius: BorderRadius.circular(K.rSm),
      child: Container(
        margin: const EdgeInsets.only(bottom: K.xs + 1),
        padding: const EdgeInsets.all(K.sm + 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(K.rSm),
          border: Border(left: BorderSide(color: color, width: 3)),
          color: p.surfaceAlt,
        ),
        child: Row(
          children: [
            Icon(
              switch (a.type) {
                AlertType.sos => Icons.sos_rounded,
                AlertType.fuelLeak => Icons.water_drop_rounded,
                AlertType.tirePressure => Icons.tire_repair_rounded,
                AlertType.collision => Icons.car_crash_rounded,
                AlertType.eldViolation => Icons.schedule_rounded,
                AlertType.tempExcursion => Icons.thermostat_rounded,
                AlertType.geofenceExit => Icons.fence_rounded,
                AlertType.idling => Icons.local_parking_rounded,
                _ => Icons.bolt_rounded,
              },
              size: 14,
              color: color,
            ),
            const SizedBox(width: K.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
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
                    '${v?.plate ?? 'Fleet'} · ${timeAgo(a.timestamp)}',
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
      ),
    );
  }

  // ── Utilization ranking (right-sizing candidates) ────────────────────────

  Widget _utilizationPanel(BuildContext context, AppState state) {
    final p = context.pal;
    // Rank by on-route = high use, idle/offline = under-used.
    final ranked = [...state.vehicles]..sort((a, b) {
        int score(Vehicle v) => switch (v.status) {
              VehicleStatus.onRoute => 2,
              VehicleStatus.idle => 1,
              VehicleStatus.maintenance => 0,
              VehicleStatus.offline => -1,
            };
        return score(b).compareTo(score(a));
      });
    final underused = ranked.reversed.take(5).toList();

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Utilization watch',
            eyebrow: 'Right-sizing candidates · target 70–80%',
          ),
          for (final v in underused)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor(context, v.status)),
                  ),
                  const SizedBox(width: K.sm),
                  Expanded(
                    child: Text(
                      '${v.plate} · ${v.model}',
                      style: TextStyle(
                        fontSize: K.body,
                        color: p.textSecondary,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    v.status == VehicleStatus.onRoute
                        ? 'EARNING'
                        : v.status == VehicleStatus.idle
                            ? 'IDLE'
                            : v.status == VehicleStatus.maintenance
                                ? 'SHOP'
                                : 'OFFLINE',
                    style: TextStyle(
                      fontSize: K.micro,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: statusColor(context, v.status),
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

  // ── Idle leaderboard ─────────────────────────────────────────────────────

  Widget _idlePanel(BuildContext context, AppState state) {
    final p = context.pal;
    final idlers = [...state.vehicles]
      ..sort((a, b) => b.idleMinutesToday.compareTo(a.idleMinutesToday));
    final top = idlers.take(5).where((v) => v.idleMinutesToday > 0).toList();

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Idle leaderboard',
            eyebrow: 'Today · ~0.8 L diesel per idle hour',
          ),
          if (top.isEmpty)
            const EmptyState(icon: Icons.eco_rounded, title: 'No significant idling today')
          else
            for (final v in top)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
                child: Row(
                  children: [
                    SizedBox(
                      width: 62,
                      child: Text(
                        v.plate,
                        style: TextStyle(
                          fontSize: K.body,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Expanded(
                      child: KProgress(
                        value: (v.idleMinutesToday / 60).clamp(0.0, 1.0),
                        color: v.idleMinutesToday > 45 ? p.critical : p.urgent,
                        height: 4,
                      ),
                    ),
                    const SizedBox(width: K.sm),
                    SizedBox(
                      width: 64,
                      child: Text(
                        '${v.idleMinutesToday.round()} min',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: K.label,
                          fontWeight: FontWeight.w700,
                          color: v.idleMinutesToday > 45 ? p.critical : p.textSecondary,
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

  // ── Asset health bridge to the shop ──────────────────────────────────────

  Widget _healthPanel(BuildContext context, AppState state) {
    final p = context.pal;
    final withDtc = state.vehicles.where((v) => v.hasActiveDtc).toList();

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Asset health',
            eyebrow: 'Open fault codes · shop escalation',
            action: Text(
              '${state.predictedMaintenanceCount} PM due',
              style: TextStyle(
                fontSize: K.caption,
                fontWeight: FontWeight.w800,
                color: p.urgent,
                fontFamily: 'Inter',
              ),
            ),
          ),
          if (withDtc.isEmpty)
            const EmptyState(icon: Icons.verified_rounded, title: 'No active fault codes')
          else
            for (final v in withDtc.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
                child: Row(
                  children: [
                    Icon(Icons.memory_rounded, size: 12, color: p.urgent),
                    const SizedBox(width: K.sm),
                    Expanded(
                      child: Text(
                        '${v.plate} · ${v.dtcCodes.where((c) => c.active).firstOrNull?.code ?? 'DTC'}',
                        style: TextStyle(
                          fontSize: K.body,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Text(
                      v.dtcCodes.where((c) => c.active).firstOrNull?.description ?? '',
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
