import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Dispatcher workspace: the load board, driver availability and one-tap
/// dispatch actions (guide p. 6 — predict ETAs accurately; p. 10 — driver
/// management). Everything on this screen answers "who takes which load
/// next, and will it arrive on time".
class DispatcherDashboard extends StatelessWidget {
  const DispatcherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final active = state.trips.where((t) => t.status != TripStatus.delivered).toList()
      ..sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Dispatch board',
          subtitle:
              '${active.length} loads in motion · ${state.dispatchableVehicles.length} vehicles ready · ${state.availableDrivers.length} drivers available',
          actions: [
            Row(
              children: [
                const LiveDot(size: 6),
                const SizedBox(width: K.xs),
                Text(
                  'LIVE',
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
                    Expanded(flex: 3, child: _leftColumn(context, state, active)),
                    const SizedBox(width: K.md),
                    Expanded(flex: 2, child: _rightColumn(context, state)),
                  ],
                )
              : Column(
                  children: [
                    _leftColumn(context, state, active),
                    const SizedBox(height: K.md),
                    _rightColumn(context, state),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _kpiGrid(BuildContext context, AppState state, bool wide) {
    return GridView.count(
      crossAxisCount: wide ? 5 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: K.xs,
      crossAxisSpacing: K.xs,
      childAspectRatio: wide ? 1.85 : 1.65,
      children: [
        KpiTile(
          label: 'Loads in motion',
          value: '${state.trips.where((t) => t.status != TripStatus.delivered).length}',
          icon: Icons.route_rounded,
        ),
        KpiTile(
          label: 'At-risk loads',
          value: '${state.atRiskTrips.length}',
          icon: Icons.warning_amber_rounded,
          accent: state.atRiskTrips.isEmpty ? context.pal.good : context.pal.critical,
        ),
        KpiTile(
          label: 'Vehicles ready',
          value: '${state.dispatchableVehicles.length}',
          unit: '/ ${state.vehicles.length}',
          icon: Icons.local_shipping_outlined,
        ),
        KpiTile(
          label: 'Drivers available',
          value: '${state.availableDrivers.length}',
          unit: '/ ${state.drivers.length}',
          icon: Icons.badge_outlined,
        ),
        KpiTile(
          label: 'On-time rate',
          value: (state.avgOnTimeRate * 100).toStringAsFixed(0),
          unit: '%',
          icon: Icons.schedule_rounded,
          accent: context.pal.good,
        ),
      ],
    );
  }

  Widget _leftColumn(BuildContext context, AppState state, List<Trip> active) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Load board.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Load board',
                eyebrow: 'Active dispatches · ETA monitoring',
                live: true,
                action: Text(
                  'next ETA ${active.isEmpty ? '—' : '${active.first.etaMinutes}m'}',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w700,
                    color: context.pal.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              ..._loadRows(context, state, active),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Ready fleet.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Ready to dispatch',
                eyebrow: 'Idle vehicles · closest-point refuel planning',
              ),
              ..._readyRows(context, state),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _loadRows(BuildContext context, AppState state, List<Trip> active) {
    if (active.isEmpty) {
      return const [
        EmptyState(icon: Icons.route_outlined, title: 'No active loads', subtitle: 'Every dispatch has been delivered.'),
      ];
    }
    final p = context.pal;
    return [
      for (final t in active)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
          child: Row(
            children: [
              // Vehicle + driver stack.
              SizedBox(
                width: 108,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.vehicleById(t.vehicleId)?.plate ?? '—',
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      state.driverById(t.driverId)?.name ?? 'Unassigned',
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
                width: 86,
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
                    if (t.status == TripStatus.atRisk)
                      Text(
                        '+${t.delayMinutes}m delay',
                        style: TextStyle(
                          fontSize: K.caption,
                          fontWeight: FontWeight.w700,
                          color: p.critical,
                          fontFamily: 'Inter',
                        ),
                      )
                    else
                      Text(
                        t.cargo,
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
    ];
  }

  List<Widget> _readyRows(BuildContext context, AppState state) {
    final p = context.pal;
    final ready = state.dispatchableVehicles.take(6).toList();
    if (ready.isEmpty) {
      return const [
        EmptyState(icon: Icons.local_shipping_outlined, title: 'Fleet fully committed', subtitle: 'No idle vehicles right now.'),
      ];
    }
    return [
      for (final v in ready)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
          child: Row(
            children: [
              SizedBox(
                width: 108,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.plate,
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      '${v.type.short} · ${state.driverById(v.driverId)?.name ?? 'No driver'}',
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_gas_station_rounded, size: 11, color: v.fuelLevelPct < 20 ? p.critical : p.textTertiary),
                        const SizedBox(width: K.xxs + 1),
                        Text(
                          '${v.fuelLevelPct.round()}% fuel',
                          style: TextStyle(
                            fontSize: K.caption,
                            fontWeight: v.fuelLevelPct < 20 ? FontWeight.w700 : FontWeight.w500,
                            color: v.fuelLevelPct < 20 ? p.critical : p.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: K.sm + 2),
                        Icon(Icons.place_outlined, size: 11, color: p.textTertiary),
                        const SizedBox(width: K.xxs + 1),
                        Expanded(
                          child: Text(
                            v.geofenceId.isEmpty ? 'in transit zone' : v.geofenceId.replaceAll('gf-', '').replaceAll('-', ' '),
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
                    const SizedBox(height: K.xxs + 1),
                    KProgress(value: v.fuelLevelPct / 100, color: v.fuelLevelPct < 20 ? p.critical : p.good, height: 2),
                  ],
                ),
              ),
              const SizedBox(width: K.sm),
              SizedBox(
                width: 74,
                height: 24,
                child: FilledButton(
                  onPressed: () => state.dispatchVehicle(v.id),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontSize: K.caption, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                  ),
                  child: const Text('DISPATCH'),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _rightColumn(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Driver availability with HOS.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Driver availability',
                eyebrow: 'HOS remaining · ELD status',
              ),
              ..._driverRows(context, state),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Route exceptions.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Route exceptions',
                eyebrow: 'Geofence + delay events',
                live: true,
              ),
              ..._exceptionFeed(context, state),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _driverRows(BuildContext context, AppState state) {
    final p = context.pal;
    final available = state.availableDrivers.take(6).toList();
    if (available.isEmpty) {
      return const [
        EmptyState(icon: Icons.badge_outlined, title: 'No drivers available', subtitle: 'All drivers are on loads or resting.'),
      ];
    }
    return [
      for (final d in available)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
          child: Row(
            children: [
              DriverAvatar(name: d.name, hue: d.hue, size: 24),
              const SizedBox(width: K.sm),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${d.license} · safety ${d.safetyScore.round()}',
                      style: TextStyle(
                        fontSize: K.caption,
                        color: p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${d.hosRemaining.toStringAsFixed(1)}h cycle left',
                      style: TextStyle(
                        fontSize: K.caption,
                        fontWeight: FontWeight.w700,
                        color: d.hosRemaining < 10 ? p.urgent : p.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    KProgress(
                      value: d.hosRemaining / d.hosCycleLimit,
                      color: d.hosRemaining < 10 ? p.urgent : p.good,
                      height: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: K.sm),
              StatusChip(
                label: d.eldStatus.name,
                color: d.eldStatus == EldStatus.error ? p.critical : p.good,
                soft: d.eldStatus == EldStatus.error ? p.criticalSoft : p.goodSoft,
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _exceptionFeed(BuildContext context, AppState state) {
    final p = context.pal;
    final feed = state.alerts
        .where((a) =>
            a.status == AlertStatus.active &&
            (a.type == AlertType.geofenceExit || a.type == AlertType.harshBraking || a.type == AlertType.speeding))
        .take(5)
        .toList();
    if (feed.isEmpty) {
      return const [
        EmptyState(icon: Icons.check_circle_outline, title: 'No exceptions', subtitle: 'Route adherence is nominal.'),
      ];
    }
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
                decoration: BoxDecoration(shape: BoxShape.circle, color: severityColor(context, a.severity)),
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
