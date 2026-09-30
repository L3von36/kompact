import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Driver workspace: "my vehicle, my trip, my hours" (guide p. 6 — ELDs keep
/// drivers from being over-strained; p. 12 — SOS + cargo safety sensors).
/// The cockpit frames the exact telematics a driver needs during a shift:
/// live trip progress, HOS clocks, vehicle vitals and a DVIR checklist.
class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final driver = state.demoDriver;
    final vehicle = state.demoDriverVehicle;
    final trip = state.demoDriverTrip;
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Driver cockpit',
          subtitle:
              '${driver.name} · ${driver.license} · ${vehicle?.plate ?? 'no vehicle assigned'}',
          actions: [
            Row(
              children: [
                const LiveDot(size: 6),
                const SizedBox(width: K.xs),
                Text(
                  'ELD ${driver.eldStatus.name.toUpperCase()}',
                  style: TextStyle(
                    fontSize: K.micro,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: driver.eldStatus == EldStatus.error ? p.critical : p.good,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const RoleSwitchChip(),
          ],
        ),

        // Identity strip.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: _identityCard(context, state, driver, vehicle),
        ),
        const SizedBox(height: K.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: _kpiGrid(context, state, driver, trip, wide),
        ),
        const SizedBox(height: K.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _leftColumn(context, state, driver, vehicle, trip)),
                    const SizedBox(width: K.md),
                    Expanded(flex: 2, child: _rightColumn(context, state, driver, vehicle)),
                  ],
                )
              : Column(
                  children: [
                    _leftColumn(context, state, driver, vehicle, trip),
                    const SizedBox(height: K.md),
                    _rightColumn(context, state, driver, vehicle),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _identityCard(BuildContext context, AppState state, Driver d, Vehicle? v) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Row(
        children: [
          DriverAvatar(name: d.name, hue: d.hue, size: 42),
          const SizedBox(width: K.lg),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  style: TextStyle(
                    fontSize: K.headline,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${d.license} · ${d.yearsExperience} yrs experience · ${d.tripsCompleted} completed trips',
                  style: TextStyle(
                    fontSize: K.label,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _scoreStat(context, 'Safety', d.safetyScore, d.safetyScore >= 90 ? p.good : d.safetyScore >= 75 ? p.satisfactory : p.urgent),
                _scoreStat(context, 'Eco', d.ecoScore, d.ecoScore >= 90 ? p.good : d.ecoScore >= 75 ? p.satisfactory : p.urgent),
                _scoreStat(context, 'On-time', d.onTimeRate * 100, p.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreStat(BuildContext context, String label, double value, Color color) {
    final p = context.pal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.round().toString(),
          style: TextStyle(
            fontSize: K.title,
            fontWeight: FontWeight.w800,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: K.micro,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: p.textTertiary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _kpiGrid(BuildContext context, AppState state, Driver d, Trip? trip, bool wide) {
    final p = context.pal;
    return GridView.count(
      crossAxisCount: wide ? 5 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: K.xs,
      crossAxisSpacing: K.xs,
      childAspectRatio: wide ? 1.85 : 1.65,
      children: [
        KpiTile(
          label: 'Trip progress',
          value: trip == null ? '—' : '${trip.progressPct.round()}',
          unit: '%',
          icon: Icons.route_rounded,
        ),
        KpiTile(
          label: 'ETA to delivery',
          value: trip == null ? '—' : '${trip.etaMinutes}',
          unit: 'min',
          icon: Icons.schedule_rounded,
          accent: trip != null && trip.status == TripStatus.atRisk ? p.critical : p.primary,
        ),
        KpiTile(
          label: 'Driving today',
          value: d.hosHoursToday.toStringAsFixed(1),
          unit: '/ 11 h',
          icon: Icons.timelapse_rounded,
          accent: d.hosHoursToday > 9.5 ? p.critical : p.primary,
        ),
        KpiTile(
          label: 'Cycle remaining',
          value: d.hosRemaining.toStringAsFixed(1),
          unit: 'h',
          icon: Icons.battery_charging_full_rounded,
          accent: d.hosRemaining < 10 ? p.urgent : p.good,
        ),
        KpiTile(
          label: 'Harsh events today',
          value: '${state.vehicles.where((v) => v.driverId == d.id).fold<int>(0, (s, v) => s + v.harshEventsToday)}',
          icon: Icons.speed_rounded,
          accent: p.urgent,
        ),
      ],
    );
  }

  Widget _leftColumn(BuildContext context, AppState state, Driver d, Vehicle? v, Trip? trip) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current trip.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Current trip',
                eyebrow: 'Load assignment · live ETA',
                live: trip != null,
                action: trip == null
                    ? null
                    : Text(
                        trip.status == TripStatus.atRisk ? 'AT RISK' : 'ON TRACK',
                        style: TextStyle(
                          fontSize: K.micro,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: trip.status == TripStatus.atRisk ? p.critical : p.good,
                          fontFamily: 'Inter',
                        ),
                      ),
              ),
              if (trip == null)
                const EmptyState(
                  icon: Icons.night_shelter_rounded,
                  title: 'No active assignment',
                  subtitle: 'Your next dispatch will appear here.',
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${trip.origin}  →  ${trip.destination}',
                        style: TextStyle(
                          fontSize: K.subtitle,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${trip.etaMinutes} min',
                      style: TextStyle(
                        fontSize: K.subtitle,
                        fontWeight: FontWeight.w800,
                        color: trip.status == TripStatus.atRisk ? p.critical : p.primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: K.xs + 1),
                KProgress(
                  value: trip.progressPct / 100,
                  color: trip.status == TripStatus.atRisk ? p.critical : p.primary,
                  height: 4,
                ),
                const SizedBox(height: K.xs + 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${trip.progressPct.round()}% · ${trip.distanceKm.round()} km total',
                      style: TextStyle(
                        fontSize: K.caption,
                        color: p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (trip.delayMinutes > 0)
                      Text(
                        '+${trip.delayMinutes} min delay',
                        style: TextStyle(
                          fontSize: K.caption,
                          fontWeight: FontWeight.w700,
                          color: p.critical,
                          fontFamily: 'Inter',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: K.sm),
                FactGrid(
                  facts: {
                    'Cargo': trip.cargo,
                    'Weight': '${trip.weightT.toStringAsFixed(1)} t',
                    if (trip.reeferSetpointC != null) 'Setpoint': '${trip.reeferSetpointC!.toStringAsFixed(0)} C',
                    'Vehicle': v?.plate ?? '—',
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Vehicle vitals.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Vehicle vitals',
                eyebrow: 'On-board diagnostics',
                live: v?.status == VehicleStatus.onRoute,
              ),
              if (v == null)
                const EmptyState(icon: Icons.local_shipping_outlined, title: 'No vehicle assigned')
              else ...[
                MetricRow(
                  label: 'Fuel level',
                  value: '${v.fuelLevelPct.round()}%',
                  trailing: KProgress(value: v.fuelLevelPct / 100, color: v.fuelLevelPct < 20 ? p.critical : p.good),
                ),
                MetricRow(
                  label: 'Engine temp',
                  value: '${v.engineTempC.toStringAsFixed(0)} C',
                  valueColor: v.engineTempC > 98 ? p.critical : null,
                ),
                MetricRow(
                  label: 'Tire pressure',
                  value: '${v.sensors.tirePressurePsi.round()} psi',
                  valueColor: v.sensors.tirePressurePsi < 85 ? p.urgent : null,
                ),
                MetricRow(
                  label: 'Cargo temp',
                  value: '${v.sensors.cargoTempC.toStringAsFixed(1)} C',
                ),
                MetricRow(
                  label: 'Battery',
                  value: '${v.sensors.batteryVoltage.toStringAsFixed(1)} V',
                  valueColor: v.sensors.batteryVoltage < 12.4 ? p.urgent : null,
                ),
                MetricRow(
                  label: 'Odometer',
                  value: kmFmt(v.odometerKm),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _rightColumn(BuildContext context, AppState state, Driver d, Vehicle? v) {
    final p = context.pal;
    final hosTodayFrac = (d.hosHoursToday / 11).clamp(0.0, 1.0);
    final hosCycleFrac = (d.hosCycleUsed / d.hosCycleLimit).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HOS clocks.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            children: [
              const SectionHeader(title: 'Hours of service', eyebrow: 'ELD clock · plan your reset'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Gauge(
                    value: hosTodayFrac,
                    color: hosTodayFrac > 0.86 ? p.critical : p.primary,
                    label: '${d.hosHoursToday.toStringAsFixed(1)}h',
                    sublabel: 'DRIVEN TODAY / 11H',
                    size: 92,
                  ),
                  Gauge(
                    value: hosCycleFrac,
                    color: hosCycleFrac > 0.85 ? p.critical : hosCycleFrac > 0.7 ? p.urgent : p.good,
                    label: '${d.hosRemaining.toStringAsFixed(1)}h',
                    sublabel: 'CYCLE LEFT / 70H',
                    size: 92,
                  ),
                ],
              ),
              if (d.hosRisk) ...[
                const SizedBox(height: K.xs),
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 12, color: p.critical),
                    const SizedBox(width: K.xs),
                    Expanded(
                      child: Text(
                        'Cycle nearly exhausted — plan a reset before your next dispatch.',
                        style: TextStyle(
                          fontSize: K.caption,
                          fontWeight: FontWeight.w600,
                          color: p.critical,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // DVIR pre-trip checklist.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Pre-trip inspection', eyebrow: 'DVIR · AR-guided checklist'),
              ..._dvirRows(context, v),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Eco coaching.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Eco coaching',
                eyebrow: 'Fuel-efficient driving',
                action: Text(
                  'eco ${d.ecoScore.round()}/100',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w800,
                    color: d.ecoScore >= 90 ? p.good : p.satisfactory,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              ..._ecoTips(context, d, v),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _dvirRows(BuildContext context, Vehicle? v) {
    final p = context.pal;
    if (v == null) {
      return const [
        EmptyState(icon: Icons.checklist_rounded, title: 'Awaiting vehicle assignment'),
      ];
    }
    final checks = <(String, bool)>[
      ('Tire pressure & tread', v.sensors.tirePressurePsi >= 85),
      ('Battery & electrics', v.sensors.batteryVoltage >= 12.4),
      ('Dash camera feed', v.sensors.cameraFeedOk),
      ('Cargo seal (RFID)', v.sensors.rfidLoadSealed),
      ('No active fault codes', !v.hasActiveDtc),
      ('Fuel & fluids', v.fuelLevelPct >= 15),
    ];
    return [
      for (final (label, pass) in checks)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
          child: Row(
            children: [
              Icon(
                pass ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 13,
                color: pass ? p.good : p.critical,
              ),
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
                pass ? 'PASS' : 'CHECK',
                style: TextStyle(
                  fontSize: K.micro,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: pass ? p.good : p.critical,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _ecoTips(BuildContext context, Driver d, Vehicle? v) {
    final p = context.pal;
    final tips = <String>[
      if (v != null && v.idleMinutesToday > 20)
        'Idling ${v.idleMinutesToday} min today — shut down during waits to save fuel.',
      if (d.behavior.harshBraking30d > 8)
        'Harsh braking is your top fuel-waster (${d.behavior.harshBraking30d} events / 30 d). Brake earlier, save ${((d.behavior.harshBraking30d) * 0.4).toStringAsFixed(0)} L.',
      if (d.behavior.speeding30d > 5)
        'Cruise control above 85 km/h costs ~${(d.behavior.speeding30d * 0.3).toStringAsFixed(1)} L per trip. Hold 80.',
      'Smooth acceleration keeps your eco score above ${d.ecoScore.round()} — worth ~\$0.06/km in fuel.',
    ];
    return [
      for (final t in tips)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 12, color: p.satisfactory),
              const SizedBox(width: K.sm),
              Expanded(
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: K.caption,
                    height: 1.35,
                    color: p.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}
