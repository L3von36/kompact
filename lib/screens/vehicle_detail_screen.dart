import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/charts.dart';
import '../ui/widgets.dart';

/// Vehicle detail: live telemetry gauges, IoT sensor panel (guide p. 12/p. 22),
/// DTC diagnostics, predictive maintenance, trip context, refuel planning.
class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    final v = state.vehicleById(vehicleId);
    if (v == null) {
      return const Scaffold(body: EmptyState(icon: Icons.error_outline, title: 'Vehicle not found'));
    }
    final driver = state.driverById(v.driverId);
    final trip = state.tripById(v.activeTripId);
    final openMaintenance = state.maintenance
        .where((m) => m.vehicleId == v.id && m.status != MaintenanceStatus.completed)
        .toList();
    final history = state.maintenance
        .where((m) => m.vehicleId == v.id && m.status == MaintenanceStatus.completed)
        .toList();
    final fuelEvents = state.fuelEvents.where((e) => e.vehicleId == v.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final wide = MediaQuery.sizeOf(context).width >= 950;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Text(
              v.plate,
              style: TextStyle(
                fontSize: K.headline,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: p.text,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: K.sm),
            StatusChip.condition(context, v.condition),
            const SizedBox(width: K.xs),
            StatusChip.plain(context, v.type.short, p.textSecondary),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Plan refuel (closest station)',
            icon: Icon(Icons.local_gas_station_outlined, size: 17, color: p.accent),
            onPressed: () => _refuel(context, state, v),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(K.lg),
        children: [
          // Identity strip.
          KCard(
            padding: const EdgeInsets.all(K.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${v.model} · ${v.year}',
                        style: TextStyle(
                          fontSize: K.subtitle,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: K.xxs),
                      Text(
                        'ODO ${kmFmt(v.odometerKm)} · home zone ${state.geofences.where((g) => g.id == v.geofenceId).firstOrNull?.name ?? '—'}',
                        style: TextStyle(
                          fontSize: K.label,
                          color: p.textTertiary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip.status(context, v.status),
                    const SizedBox(height: K.xxs + 1),
                    if (driver != null)
                      Row(
                        children: [
                          DriverAvatar(name: driver.name, hue: driver.hue, size: 18),
                          const SizedBox(width: K.xs),
                          Text(
                            driver.name,
                            style: TextStyle(
                              fontSize: K.label,
                              fontWeight: FontWeight.w600,
                              color: p.text,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: K.md),

          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _telemetry(context, state, v, trip)),
                const SizedBox(width: K.md),
                Expanded(flex: 2, child: _sensorsPanel(context, state, v)),
              ],
            )
          else ...[
            _telemetry(context, state, v, trip),
            const SizedBox(height: K.md),
            _sensorsPanel(context, state, v),
          ],
          const SizedBox(height: K.md),

          // Diagnostics + predictive maintenance.
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _diagnostics(context, v)),
                const SizedBox(width: K.md),
                Expanded(child: _maintenancePanel(context, state, v, openMaintenance, history)),
              ],
            )
          else ...[
            _diagnostics(context, v),
            const SizedBox(height: K.md),
            _maintenancePanel(context, state, v, openMaintenance, history),
          ],
          const SizedBox(height: K.md),

          // Fuel history.
          KCard(
            padding: const EdgeInsets.all(K.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Fuel events',
                  eyebrow: 'Fuel management',
                  action: Text(
                    '${v.efficiencyKmpl.toStringAsFixed(1)} km/L avg',
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w700,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                if (fuelEvents.isEmpty)
                  const EmptyState(icon: Icons.local_gas_station_outlined, title: 'No fuel events')
                else
                  for (final e in fuelEvents.take(5))
                    MetricRow(
                      label: '${e.date.month}/${e.date.day} · ${e.station}',
                      value: '${e.liters.toStringAsFixed(0)} L · ${usd(e.totalCost)}',
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _telemetry(BuildContext context, AppState state, Vehicle v, Trip? trip) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Live telemetry',
            eyebrow: 'Telematics · updates every 2s',
            live: v.status == VehicleStatus.onRoute,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Gauge(
                value: v.speedKmh / 100,
                color: p.primary,
                label: '${v.speedKmh.round()}',
                sublabel: 'KM/H',
              ),
              Gauge(
                value: v.fuelLevelPct / 100,
                color: v.fuelLevelPct < 25 ? p.critical : p.good,
                label: '${v.fuelLevelPct.round()}',
                sublabel: '% FUEL',
              ),
              Gauge(
                value: v.engineTempC / 120,
                color: v.engineTempC > 95 ? p.critical : p.urgent,
                label: '${v.engineTempC.round()}',
                sublabel: '°C ENGINE',
              ),
            ],
          ),
          const SizedBox(height: K.sm),
          const Divider(),
          const SizedBox(height: K.xs),
          MetricRow(label: 'Tank capacity', value: '${v.tankCapacityL.round()} L'),
          MetricRow(label: 'Efficiency', value: '${v.efficiencyKmpl.toStringAsFixed(1)} km/L'),
          MetricRow(label: 'Eco score', value: '${v.ecoScore.toStringAsFixed(0)} / 100'),
          MetricRow(label: 'CO2 intensity', value: '${v.co2KgPer100Km.toStringAsFixed(0)} kg/100km'),
          MetricRow(label: 'Idle today', value: '${v.idleMinutesToday} min'),
          MetricRow(label: 'Harsh events today', value: '${v.harshEventsToday}'),
          if (trip != null) ...[
            const Divider(),
            const SizedBox(height: K.xs),
            SectionHeader(title: 'Current dispatch', eyebrow: '${trip.origin} → ${trip.destination}'),
            MetricRow(label: 'Cargo', value: '${trip.cargo} · ${trip.weightT.toStringAsFixed(1)} t'),
            MetricRow(label: 'Progress', value: '${trip.progressPct.round()}%'),
            KProgress(
              value: trip.progressPct / 100,
              color: trip.status == TripStatus.atRisk ? p.critical : p.primary,
            ),
            const SizedBox(height: K.xs + 2),
            MetricRow(
              label: 'ETA',
              value: '${trip.etaMinutes} min${trip.delayMinutes > 0 ? ' (+${trip.delayMinutes} late)' : ''}',
              valueColor: trip.status == TripStatus.atRisk ? p.critical : null,
            ),
            if (trip.reeferSetpointC != null)
              MetricRow(
                label: 'Reefer setpoint',
                value: '${trip.reeferSetpointC!.toStringAsFixed(0)} °C',
              ),
          ],
        ],
      ),
    );
  }

  Widget _sensorsPanel(BuildContext context, AppState state, Vehicle v) {
    final p = context.pal;
    final s = v.sensors;
    final station = state.closestFuelStation(v);
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'IoT sensors', eyebrow: 'Connected vehicle devices'),
          _sensorTile(
            context,
            icon: Icons.device_thermostat_rounded,
            label: 'Cargo temperature',
            value: '${s.cargoTempC.toStringAsFixed(1)} °C',
            ok: v.type != VehicleType.reefer ? true : s.cargoTempC < -15,
          ),
          _sensorTile(
            context,
            icon: Icons.water_drop_rounded,
            label: 'Humidity',
            value: '${s.humidityPct.round()} %',
            ok: true,
          ),
          _sensorTile(
            context,
            icon: Icons.tire_repair_rounded,
            label: 'Tire pressure (TPMS)',
            value: '${s.tirePressurePsi.round()} psi',
            ok: s.tirePressurePsi >= 85,
          ),
          _sensorTile(
            context,
            icon: Icons.battery_charging_full_rounded,
            label: 'Battery bank',
            value: '${s.batteryVoltage.toStringAsFixed(1)} V',
            ok: s.batteryVoltage >= 12.2,
          ),
          _sensorTile(
            context,
            icon: Icons.videocam_rounded,
            label: 'Dash camera feed',
            value: s.cameraFeedOk ? 'Streaming' : 'Offline',
            ok: s.cameraFeedOk,
          ),
          _sensorTile(
            context,
            icon: Icons.qr_code_rounded,
            label: 'RFID load seal',
            value: s.rfidLoadSealed ? 'Sealed' : 'Broken',
            ok: s.rfidLoadSealed,
          ),
          const Divider(),
          const SizedBox(height: K.xs),
          SectionHeader(title: 'Refuel planning', eyebrow: 'Closest-point spatial op'),
          MetricRow(label: 'Nearest station', value: station?.name ?? '—'),
          if (station != null)
            MetricRow(
              label: 'Distance (est.)',
              value: '${((station.center - v.pos).distance * 320).round()} km',
            ),
          const SizedBox(height: K.xs),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _refuel(context, state, v),
              icon: Icon(Icons.local_gas_station_rounded, size: 14, color: p.accent),
              label: Text(
                'Refuel at ${station?.name ?? 'station'}',
                style: TextStyle(color: p.accent, fontFamily: 'Inter'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorTile(BuildContext context, {required IconData icon, required String label, required String value, required bool ok}) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
      child: Row(
        children: [
          Icon(icon, size: 14, color: ok ? p.textTertiary : p.critical),
          const SizedBox(width: K.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: K.label, color: p.textSecondary, fontFamily: 'Inter'),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: K.label,
              fontWeight: FontWeight.w700,
              color: ok ? p.text : p.critical,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: K.xs),
          Icon(ok ? Icons.check_circle : Icons.warning, size: 13, color: ok ? p.good : p.critical),
        ],
      ),
    );
  }

  Widget _diagnostics(BuildContext context, Vehicle v) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'On-board diagnostics',
            eyebrow: 'DTC codes · ELD',
            action: v.hasActiveDtc
                ? StatusChip.severity(context, AlertSeverity.urgent)
                : StatusChip.plain(context, 'NO ACTIVE DTC', p.good),
          ),
          if (v.dtcCodes.isEmpty)
            const EmptyState(icon: Icons.verified_outlined, title: 'No diagnostic codes stored')
          else
            for (final d in v.dtcCodes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: K.xs),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: K.xs + 2, vertical: 2),
                      decoration: BoxDecoration(
                        color: d.active ? p.criticalSoft : p.surfaceAlt,
                        borderRadius: BorderRadius.circular(K.rSm),
                      ),
                      child: Text(
                        d.code,
                        style: TextStyle(
                          fontSize: K.caption,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                          color: d.active ? p.critical : p.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: K.sm),
                    Expanded(
                      child: Text(
                        d.description,
                        style: TextStyle(fontSize: K.label, color: p.textSecondary, fontFamily: 'Inter'),
                      ),
                    ),
                    StatusChip.plain(
                      context,
                      d.active ? 'ACTIVE' : 'CLEARED',
                      d.active ? p.critical : p.textTertiary,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _maintenancePanel(
    BuildContext context,
    AppState state,
    Vehicle v,
    List<MaintenanceItem> open,
    List<MaintenanceItem> history,
  ) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Predictive maintenance',
            eyebrow: 'AI-scheduled service',
          ),
          if (open.isEmpty && history.isEmpty)
            const EmptyState(icon: Icons.build_circle_outlined, title: 'No service records')
          else ...[
            for (final m in open)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: K.xs),
                child: Row(
                  children: [
                    StatusChip.plain(
                      context,
                      m.status.name.toUpperCase(),
                      m.status == MaintenanceStatus.inProgress ? p.accent : p.primary,
                    ),
                    const SizedBox(width: K.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            style: TextStyle(
                              fontSize: K.label,
                              fontWeight: FontWeight.w600,
                              color: p.text,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            m.dueInKm > 0 ? 'due in ${kmFmt(m.dueInKm.toDouble())}' : (m.dueDate != null ? 'scheduled' : 'asap'),
                            style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${m.confidencePct}%',
                          style: TextStyle(
                            fontSize: K.label,
                            fontWeight: FontWeight.w800,
                            color: p.primary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          'AI conf.',
                          style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (history.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: K.xs),
              for (final m in history)
                MetricRow(label: m.title, value: 'done · ${usd(m.costEstUsd)}'),
            ],
          ],
        ],
      ),
    );
  }

  void _refuel(BuildContext context, AppState state, Vehicle v) {
    final station = state.closestFuelStation(v);
    final liters = v.tankCapacityL * (1 - v.fuelLevelPct / 100);
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Plan refuel stop'),
        content: Text(
          'Refuel ${v.plate} at ${station?.name ?? 'Fleet Fuel Stop'} — add ${liters.toStringAsFixed(0)} L '
          '(est. ${usd(liters * 1.58)}). Fuel card pre-authorized.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              state.refuelVehicle(v.id);
              Navigator.pop(d);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${v.plate} refueled at ${station?.name ?? 'Fleet Fuel Stop'}')),
              );
            },
            child: const Text('Confirm refuel'),
          ),
        ],
      ),
    );
  }
}
