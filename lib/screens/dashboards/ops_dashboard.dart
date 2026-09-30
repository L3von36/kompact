import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/map_painter.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Fleet Manager workspace (guide p. 26–27): live KPIs, condition mix,
/// real-time alert feed, active trips with ETAs and the live fleet map.
class OpsDashboard extends StatelessWidget {
  const OpsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 1000;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Operations overview',
          subtitle:
              '${state.vehicles.length} vehicles · ${state.drivers.length} drivers · ${state.trips.where((t) => t.status != TripStatus.delivered).length} active dispatches',
          actions: [
            Row(
              children: [
                const LiveDot(size: 6),
                const SizedBox(width: K.xs),
                Text(
                  'LIVE TELEMETRICS',
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

        // KPI strip.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: _kpiGrid(context, state, wide),
        ),
        const SizedBox(height: K.md),

        // Main split: map+trips | condition+alerts.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _leftColumn(context, state)),
              const SizedBox(width: K.md),
              Expanded(flex: 2, child: _rightColumn(context, state)),
            ],
          ) : Column(
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
    final items = <Widget>[
      KpiTile(
        label: 'On route',
        value: '${state.onRouteCount}',
        unit: '/ ${state.vehicles.length}',
        icon: Icons.route_rounded,
        trailing: Sparkline(
          values: state.onRouteHistory.isEmpty ? [0, 0] : state.onRouteHistory,
          height: 16,
          color: context.pal.good,
        ),
      ),
      KpiTile(
        label: 'Active alerts',
        value: '${state.activeAlertCount}',
        icon: Icons.notifications_active_outlined,
        accent: state.criticalAlertCount > 0 ? context.pal.critical : context.pal.accent,
        delta: state.criticalAlertCount > 0 ? '+${state.criticalAlertCount} crit' : null,
        deltaUpGood: false,
      ),
      KpiTile(
        label: 'Avg safety score',
        value: state.avgSafetyScore.toStringAsFixed(0),
        unit: '/ 100',
        icon: Icons.health_and_safety_outlined,
      ),
      KpiTile(
        label: 'Fuel consumed today',
        value: state.litersConsumedToday.toStringAsFixed(0),
        unit: 'L',
        icon: Icons.local_gas_station_outlined,
      ),
      KpiTile(
        label: 'CO2 today',
        value: state.co2KgToday.toStringAsFixed(0),
        unit: 'kg',
        icon: Icons.eco_outlined,
        accent: context.pal.satisfactory,
      ),
      KpiTile(
        label: 'Utilization',
        value: (state.fleetUtilization * 100).toStringAsFixed(0),
        unit: '%',
        icon: Icons.speed_rounded,
      ),
    ];

    return GridView.count(
      crossAxisCount: wide ? 6 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: K.xs,
      crossAxisSpacing: K.xs,
      childAspectRatio: wide ? 1.55 : 1.65,
      children: items,
    );
  }

  Widget _leftColumn(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live map.
        KCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(K.md, K.sm + 2, K.md, K.sm),
                child: SectionHeader(
                  title: 'Live fleet map',
                  eyebrow: 'Routing & tracking',
                  live: true,
                  action: Text(
                    '${state.onRouteCount} moving',
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w700,
                      color: context.pal.good,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 250,
                child: FleetMap(
                  vehicles: state.vehicles,
                  geofences: state.geofences,
                  stations: state.stations,
                  routes: state.trips,
                  selectedVehicleId: null,
                  onVehicleTap: (_) {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(K.md, K.xs, K.md, K.sm + 2),
                child: const MapLegend(),
              ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Active trips with ETAs (guide p. 6: predict ETAs accurately).
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Active dispatches',
                eyebrow: 'ETA monitoring',
                live: true,
                action: Text(
                  'on-time ${(state.avgOnTimeRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w700,
                    color: context.pal.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              ..._tripRows(context, state),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _tripRows(BuildContext context, AppState state) {
    final active = state.trips.where((t) => t.status != TripStatus.delivered).toList()
      ..sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
    if (active.isEmpty) {
      return [
        const EmptyState(icon: Icons.route_outlined, title: 'No active dispatches', subtitle: 'Vehicles are resting at their zones.'),
      ];
    }
    final p = context.pal;
    return [
      for (final t in active)
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(K.rSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
            child: Row(
              children: [
                SizedBox(
                  width: 74,
                  child: Text(
                    state.vehicleById(t.vehicleId)?.plate ?? '—',
                    style: TextStyle(
                      fontSize: K.label,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.origin} → ${t.destination}',
                        style: TextStyle(
                          fontSize: K.label,
                          fontWeight: FontWeight.w500,
                          color: p.textSecondary,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      KProgress(
                        value: t.progressPct / 100,
                        color: t.status == TripStatus.atRisk ? p.critical : p.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: K.sm),
                SizedBox(
                  width: 78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ETA ${t.etaMinutes}m',
                        style: TextStyle(
                          fontSize: K.label,
                          fontWeight: FontWeight.w700,
                          color: t.status == TripStatus.atRisk ? p.critical : p.text,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (t.delayMinutes > 0)
                        Text(
                          '+${t.delayMinutes}m delay',
                          style: TextStyle(
                            fontSize: K.caption,
                            fontWeight: FontWeight.w600,
                            color: p.critical,
                            fontFamily: 'Inter',
                          ),
                        )
                      else
                        Text(
                          '${(t.progressPct).round()}% done',
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
          ),
        ),
    ];
  }

  Widget _rightColumn(BuildContext context, AppState state) {
    final cc = state.conditionCounts;
    final p = context.pal;
    final total = state.vehicles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fleet condition (guide p. 26: Good/Satisfactory/Urgent/Critical).
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            children: [
              const SectionHeader(title: 'Fleet condition', eyebrow: 'Remote diagnostics'),
              Row(
                children: [
                  Donut(
                    size: 96,
                    slices: [
                      (cc[VehicleCondition.good]!.toDouble(), p.good),
                      (cc[VehicleCondition.satisfactory]!.toDouble(), p.satisfactory),
                      (cc[VehicleCondition.urgent]!.toDouble(), p.urgent),
                      (cc[VehicleCondition.critical]!.toDouble(), p.critical),
                    ],
                    centerTop: '$total',
                    centerBottom: 'VEHICLES',
                  ),
                  const SizedBox(width: K.md),
                  Expanded(
                    child: Column(
                      children: [
                        for (final c in VehicleCondition.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(color: conditionColor(context, c), borderRadius: BorderRadius.circular(2)),
                                ),
                                const SizedBox(width: K.xs),
                                Expanded(
                                  child: Text(
                                    c.label,
                                    style: TextStyle(
                                      fontSize: K.label,
                                      color: p.textSecondary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                Text(
                                  '${cc[c]}',
                                  style: TextStyle(
                                    fontSize: K.label,
                                    fontWeight: FontWeight.w700,
                                    color: p.text,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
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

        // Live alert feed.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Live alerts',
                eyebrow: 'Real-time notifications',
                live: true,
              ),
              ..._alertFeed(context, state),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Fleet speed sparkline.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Fleet average speed',
                eyebrow: 'Telematics stream',
                live: true,
                action: Text(
                  state.fleetSpeedHistory.isEmpty
                      ? '—'
                      : '${state.fleetSpeedHistory.last.toStringAsFixed(0)} km/h',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Sparkline(
                values: state.fleetSpeedHistory.isEmpty
                    ? List.filled(30, 60.0)
                    : state.fleetSpeedHistory,
                height: 42,
              ),
              const SizedBox(height: K.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'idle waste today',
                    style: TextStyle(
                      fontSize: K.caption,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    usd(state.idleCostToday),
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w700,
                      color: p.accent,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _alertFeed(BuildContext context, AppState state) {
    final feed = state.alerts.where((a) => a.status == AlertStatus.active).take(5).toList();
    if (feed.isEmpty) {
      return [
        const EmptyState(icon: Icons.check_circle_outline, title: 'All clear', subtitle: 'No active alerts right now.'),
      ];
    }
    final p = context.pal;
    return [
      for (final a in feed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: K.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: severityColor(context, a.severity),
                ),
              ),
              const SizedBox(width: K.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.title,
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
                        Text(
                          timeAgo(a.timestamp),
                          style: TextStyle(
                            fontSize: K.caption,
                            color: p.textTertiary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      a.message,
                      style: TextStyle(
                        fontSize: K.caption,
                        color: p.textSecondary,
                        height: 1.3,
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
        ),
    ];
  }
}
