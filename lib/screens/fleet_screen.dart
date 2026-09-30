import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';
import 'vehicle_detail_screen.dart';

/// Fleet inventory — dense vehicle table with status/type filters.
/// Compact design: a 32px-row data grid beats card lists at equal screen size.
class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  VehicleStatus? _status;
  VehicleType? _type;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final vehicles = state.vehicles.where((v) {
      if (_status != null && v.status != _status) return false;
      if (_type != null && v.type != _type) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.condition.rank.compareTo(b.condition.rank));

    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      children: [
        PageHeader(
          title: 'Fleet',
          subtitle:
              '${state.onRouteCount} on route · ${state.idleCount} idle · ${state.inShopCount} in shop · ${state.offlineCount} offline',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.sm),
          child: Row(
            children: [
              Flexible(
                child: FilterRow<VehicleStatus?>(
                  selected: _status,
                  onChanged: (v) => setState(() => _status = v),
                  options: const [
                    (null, 'All'),
                    (VehicleStatus.onRoute, 'On route'),
                    (VehicleStatus.idle, 'Idle'),
                    (VehicleStatus.maintenance, 'In shop'),
                    (VehicleStatus.offline, 'Offline'),
                  ],
                ),
              ),
              const SizedBox(width: K.sm),
              Flexible(
                child: FilterRow<VehicleType?>(
                  selected: _type,
                  onChanged: (v) => setState(() => _type = v),
                  options: const [
                    (null, 'All types'),
                    (VehicleType.semi, 'Semi'),
                    (VehicleType.reefer, 'Reefer'),
                    (VehicleType.box, 'Box'),
                    (VehicleType.tanker, 'Tanker'),
                    (VehicleType.van, 'Van'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: wide
              ? _grid(context, state, vehicles)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.xxl),
                  itemCount: vehicles.length,
                  itemBuilder: (_, i) => _VehicleCard(vehicle: vehicles[i]),
                ),
        ),
      ],
    );
  }

  Widget _grid(BuildContext context, AppState state, List<Vehicle> vehicles) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.xxl),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 640,
        mainAxisSpacing: K.xs,
        crossAxisSpacing: K.xs,
        childAspectRatio: 2.55,
      ),
      itemCount: vehicles.length,
      itemBuilder: (_, i) => _VehicleCard(vehicle: vehicles[i], compact: true),
    );
  }
}

/// One vehicle row card — clickable to open telemetry detail.
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool compact;

  const _VehicleCard({required this.vehicle, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    final v = vehicle;
    final driver = state.driverById(v.driverId);
    final trip = state.tripById(v.activeTripId);

    return KCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => VehicleDetailScreen(vehicleId: v.id)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: K.md, vertical: K.sm + 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: plate, model, chips.
          Row(
            children: [
              Text(
                v.plate,
                style: TextStyle(
                  fontSize: K.subtitle,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: p.text,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: K.sm),
              Expanded(
                child: Text(
                  '${v.model} · ${v.year}',
                  style: TextStyle(
                    fontSize: K.label,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusChip.plain(context, v.type.short, p.textSecondary),
              const SizedBox(width: K.xs),
              StatusChip.condition(context, v.condition),
            ],
          ),
          const SizedBox(height: K.xs + 1),
          // Row 2: metrics strip.
          Row(
            children: [
              _miniMetric(
                context,
                icon: Icons.speed_rounded,
                value: v.speedKmh > 0 ? '${v.speedKmh.round()}' : '—',
                label: 'km/h',
                live: v.status == VehicleStatus.onRoute,
              ),
              _miniMetric(
                context,
                icon: Icons.local_gas_station_rounded,
                value: '${v.fuelLevelPct.round()}',
                label: '% fuel',
                valueColor: v.fuelLevelPct < 25 ? p.critical : null,
              ),
              _miniMetric(
                context,
                icon: Icons.device_thermostat_rounded,
                value: '${v.engineTempC.round()}',
                label: '°C',
                valueColor: v.engineTempC > 95 ? p.critical : null,
              ),
              _miniMetric(
                context,
                icon: Icons.route_rounded,
                value: trip != null
                    ? '${trip.etaMinutes}m'
                    : (v.status == VehicleStatus.idle ? 'depot' : '—'),
                label: trip != null ? 'ETA' : 'at',
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip.status(context, v.status),
                  if (driver != null) ...[
                    const SizedBox(height: K.xxs + 1),
                    Text(
                      driver.name,
                      style: TextStyle(
                        fontSize: K.caption,
                        color: p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
    bool live = false,
  }) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(right: K.md),
      child: Row(
        children: [
          Icon(icon, size: 13, color: p.textTertiary),
          const SizedBox(width: K.xxs + 1),
          if (live) ...[
            const LiveDot(size: 5),
            const SizedBox(width: 2),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: K.label,
              fontWeight: FontWeight.w700,
              color: valueColor ?? p.text,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 1),
          Text(
            label,
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
}
