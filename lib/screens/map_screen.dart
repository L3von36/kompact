import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/map_painter.dart';
import '../ui/widgets.dart';
import 'vehicle_detail_screen.dart';

/// Routing & tracking console (guide p. 10): live map, geofence spatial ops,
/// real-time ETAs and at-risk dispatch supervision.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selected;
  bool _showRoutes = true;
  bool _showZones = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 980;
    final activeTrips = state.trips.where((t) => t.status != TripStatus.delivered).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Live tracking',
          subtitle:
              '${state.onRouteCount} vehicles moving · ${activeTrips.where((t) => t.status == TripStatus.atRisk).length} at-risk routes · ${state.geofences.length} zones',
          actions: [
            _toggle(
              context,
              label: 'Routes',
              value: _showRoutes,
              onChanged: (v) => setState(() => _showRoutes = v),
            ),
            const SizedBox(width: K.xs),
            _toggle(
              context,
              label: 'Zones',
              value: _showZones,
              onChanged: (v) => setState(() => _showZones = v),
            ),
          ],
        ),
        Expanded(
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _mapArea(context, state, tall: true),
                    ),
                    const SizedBox(width: K.md),
                    Expanded(
                      flex: 2,
                      child: _sidePanel(context, state, activeTrips),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 330,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: K.lg),
                          child: _mapArea(context, state, tall: false),
                        ),
                      ),
                      const SizedBox(height: K.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: K.lg),
                        child: _sidePanel(context, state, activeTrips),
                      ),
                      const SizedBox(height: K.xxl),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _toggle(BuildContext context, {required String label, required bool value, required ValueChanged<bool> onChanged}) {
    final p = context.pal;
    return Material(
      color: value ? p.primary : p.surfaceAlt,
      borderRadius: BorderRadius.circular(K.rSm),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(K.rSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(value ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 12, color: value ? p.primaryFg : p.textTertiary),
              const SizedBox(width: K.xxs + 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: K.label,
                  fontWeight: FontWeight.w600,
                  color: value ? p.primaryFg : p.textTertiary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapArea(BuildContext context, AppState state, {required bool tall}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: K.lg),
      child: KCard(
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
                showRoutes: _showRoutes,
                showGeofences: _showZones,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(K.xs + 1),
              child: const MapLegend(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidePanel(BuildContext context, AppState state, List<Trip> activeTrips) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected vehicle card.
        if (state.vehicleById(_selected) != null) ...[
          _selectedCard(context, state, state.vehicleById(_selected)!),
          const SizedBox(height: K.md),
        ],

        // Geofence panel (guide p. 25: spatial operations).
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Geofence zones', eyebrow: 'Spatial operations'),
              for (final g in state.geofences)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
                  child: Row(
                    children: [
                      Icon(
                        g.kind == 'depot'
                            ? Icons.warehouse_rounded
                            : g.kind == 'port'
                                ? Icons.anchor_rounded
                                : g.kind == 'warehouse'
                                    ? Icons.inventory_2_rounded
                                    : Icons.flag_rounded,
                        size: 13,
                        color: p.primary,
                      ),
                      const SizedBox(width: K.sm),
                      Expanded(
                        child: Text(
                          g.name,
                          style: TextStyle(
                            fontSize: K.label,
                            fontWeight: FontWeight.w600,
                            color: p.text,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Text(
                        '${g.entriesToday} in / ${g.exitsToday} out',
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
        const SizedBox(height: K.md),

        // ETA supervision.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'ETA supervision',
                eyebrow: 'At-risk first',
                live: true,
              ),
              ...[...activeTrips]
                  .sort2((a, b) => (b.delayMinutes - b.etaMinutes).compareTo(a.delayMinutes - a.etaMinutes))
                  .take(8)
                  .map((t) => _etaRow(context, state, t)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _selectedCard(BuildContext context, AppState state, Vehicle v) {
    final p = context.pal;
    final trip = state.tripById(v.activeTripId);
    final driver = state.driverById(v.driverId);
    return KCard(
      padding: const EdgeInsets.all(K.md),
      borderColor: conditionColor(context, v.condition),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                v.plate,
                style: TextStyle(
                  fontSize: K.subtitle,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: K.xs),
              StatusChip.condition(context, v.condition),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => VehicleDetailScreen(vehicleId: v.id)),
                ),
                child: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: K.xs),
          MetricRow(label: 'Status', value: v.status.label),
          MetricRow(label: 'Speed', value: '${v.speedKmh.round()} km/h'),
          MetricRow(label: 'Fuel', value: '${v.fuelLevelPct.round()}%'),
          if (driver != null) MetricRow(label: 'Driver', value: driver.name),
          if (trip != null) ...[
            MetricRow(label: 'Dispatch', value: '${trip.origin} → ${trip.destination}'),
            MetricRow(
              label: 'ETA',
              value: '${trip.etaMinutes} min${trip.delayMinutes > 0 ? ' (+${trip.delayMinutes} late)' : ''}',
              valueColor: trip.status == TripStatus.atRisk ? p.critical : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _etaRow(BuildContext context, AppState state, Trip t) {
    final p = context.pal;
    final v = state.vehicleById(t.vehicleId);
    final risky = t.status == TripStatus.atRisk;
    return InkWell(
      onTap: () => setState(() => _selected = t.vehicleId),
      borderRadius: BorderRadius.circular(K.rSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: risky ? p.critical : p.primary,
              ),
            ),
            const SizedBox(width: K.sm),
            SizedBox(
              width: 70,
              child: Text(
                v?.plate ?? '—',
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
                '${t.origin} → ${t.destination}',
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
              risky ? 'ETA ${t.etaMinutes}m +${t.delayMinutes}' : 'ETA ${t.etaMinutes}m',
              style: TextStyle(
                fontSize: K.label,
                fontWeight: FontWeight.w700,
                color: risky ? p.critical : p.text,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _SortLet<T> on List<T> {
  List<T> sort2(int Function(T a, T b) compare) {
    final copy = [...this];
    copy.sort(compare);
    return copy;
  }
}