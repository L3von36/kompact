import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';
import 'vehicle_detail_screen.dart';

/// Driver profile: performance report, 30-day behavior, HOS/ELD ledger,
/// violations with fines (guide p. 10, p. 16).
class DriverDetailScreen extends StatelessWidget {
  final String driverId;

  const DriverDetailScreen({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    final d = state.driverById(driverId);
    if (d == null) {
      return const Scaffold(body: EmptyState(icon: Icons.error_outline, title: 'Driver not found'));
    }
    final vehicle = state.vehicleById(d.vehicleId);
    final trip = state.tripForVehicle(d.vehicleId);
    final wide = MediaQuery.sizeOf(context).width >= 950;
    final fines = d.violations.fold<double>(0, (s, v) => s + v.fineUsd);

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
            DriverAvatar(name: d.name, hue: d.hue, size: 26),
            const SizedBox(width: K.sm),
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
            const SizedBox(width: K.sm),
            StatusChip.plain(context, d.license, p.primary),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(K.lg),
        children: [
          // Score strip.
          Row(
            children: [
              Expanded(
                child: KpiTile(
                  label: 'Safety score',
                  value: d.safetyScore.toStringAsFixed(0),
                  unit: '/ 100',
                  icon: Icons.health_and_safety_outlined,
                ),
              ),
              const SizedBox(width: K.xs),
              Expanded(
                child: KpiTile(
                  label: 'Eco score',
                  value: d.ecoScore.toStringAsFixed(0),
                  unit: '/ 100',
                  icon: Icons.eco_outlined,
                  accent: p.satisfactory,
                ),
              ),
              const SizedBox(width: K.xs),
              Expanded(
                child: KpiTile(
                  label: 'On-time rate',
                  value: (d.onTimeRate * 100).toStringAsFixed(0),
                  unit: '%',
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: K.xs),
              Expanded(
                child: KpiTile(
                  label: 'Open fines',
                  value: usd(fines),
                  icon: Icons.gavel_rounded,
                  accent: d.violations.isEmpty ? p.good : p.critical,
                ),
              ),
            ],
          ),
          const SizedBox(height: K.md),

          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _behaviorCard(context, d)),
                const SizedBox(width: K.md),
                Expanded(child: _hosCard(context, d, vehicle, trip)),
              ],
            )
          else ...[
            _behaviorCard(context, d),
            const SizedBox(height: K.md),
            _hosCard(context, d, vehicle, trip),
          ],
          const SizedBox(height: K.md),
          _violationsCard(context, state, d),
        ],
      ),
    );
  }

  Widget _behaviorCard(BuildContext context, Driver d) {
    final p = context.pal;
    final b = d.behavior;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Driving behavior', eyebrow: 'Last 30 days · telematics'),
          MetricRow(
            label: 'Harsh braking',
            value: '${b.harshBraking30d} events',
            valueColor: b.harshBraking30d > 6 ? p.critical : null,
          ),
          MetricRow(
            label: 'Harsh acceleration',
            value: '${b.harshAccel30d} events',
            valueColor: b.harshAccel30d > 6 ? p.critical : null,
          ),
          MetricRow(
            label: 'Speeding',
            value: '${b.speeding30d} events',
            valueColor: b.speeding30d > 6 ? p.critical : null,
          ),
          MetricRow(
            label: 'Seatbelt violations',
            value: '${b.seatbeltViolations30d}',
            valueColor: b.seatbeltViolations30d > 2 ? p.critical : null,
          ),
          const Divider(),
          const SizedBox(height: K.xs),
          const SectionHeader(title: 'Performance report', eyebrow: 'Auto-generated'),
          MetricRow(label: 'Trips completed', value: '${d.tripsCompleted}'),
          MetricRow(label: 'Experience', value: '${d.yearsExperience} years'),
          MetricRow(label: 'License', value: d.license),
          MetricRow(label: 'Phone', value: d.phone),
        ],
      ),
    );
  }

  Widget _hosCard(BuildContext context, Driver d, Vehicle? vehicle, Trip? trip) {
    final p = context.pal;
    final cyclePct = d.hosCycleUsed / d.hosCycleLimit;
    final todayPct = d.hosHoursToday / 11;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Hours of service',
            eyebrow: 'ELD · 70h / 8-day cycle',
            action: d.eldStatus == EldStatus.error
                ? StatusChip.severity(context, AlertSeverity.urgent)
                : StatusChip.plain(context, d.eldStatus.name.toUpperCase(), p.good),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cycle used ${d.hosCycleUsed.toStringAsFixed(1)}h of ${d.hosCycleLimit.toStringAsFixed(0)}h',
                      style: TextStyle(fontSize: K.label, color: p.textSecondary, fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: K.xs),
                    KProgress(
                      value: cyclePct,
                      color: cyclePct > 0.85 ? p.critical : cyclePct > 0.7 ? p.urgent : p.good,
                    ),
                    const SizedBox(height: K.xxs),
                    Text(
                      '${d.hosRemaining.toStringAsFixed(1)}h remaining',
                      style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: K.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today ${d.hosHoursToday.toStringAsFixed(1)}h of 11h drive limit',
                      style: TextStyle(fontSize: K.label, color: p.textSecondary, fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: K.xs),
                    KProgress(
                      value: todayPct,
                      color: todayPct > 0.85 ? p.critical : todayPct > 0.7 ? p.urgent : p.good,
                    ),
                    const SizedBox(height: K.xxs),
                    Text(
                      '${d.hosTodayRemaining.toStringAsFixed(1)}h left today',
                      style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: K.xs),
          const SectionHeader(title: 'Current assignment', eyebrow: 'Driver-vehicle pairing'),
          if (vehicle == null)
            const EmptyState(icon: Icons.garage_rounded, title: 'Unassigned', subtitle: 'Resting between dispatches.')
          else ...[
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => VehicleDetailScreen(vehicleId: vehicle.id)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_rounded, size: 15, color: p.primary),
                  const SizedBox(width: K.sm),
                  Expanded(
                    child: Text(
                      '${vehicle.plate} · ${vehicle.model}',
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w600,
                        color: p.text,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 15, color: p.textTertiary),
                ],
              ),
            ),
            if (trip != null) ...[
              const SizedBox(height: K.xs),
              MetricRow(label: 'Dispatch', value: '${trip.origin} → ${trip.destination}'),
              MetricRow(label: 'Cargo', value: '${trip.cargo} · ${trip.weightT.toStringAsFixed(1)} t'),
              MetricRow(label: 'ETA', value: '${trip.etaMinutes} min'),
            ],
          ],
        ],
      ),
    );
  }

  Widget _violationsCard(BuildContext context, AppState state, Driver d) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Violations & fines',
            eyebrow: 'Regulatory compliance',
            action: d.violations.isEmpty
                ? StatusChip.plain(context, 'CLEAN RECORD', p.good)
                : StatusChip.plain(context, '${d.violations.length} OPEN', p.critical),
          ),
          if (d.violations.isEmpty)
            const EmptyState(icon: Icons.verified_outlined, title: 'No violations on record')
          else
            for (final v in d.violations)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: K.xs),
                child: Row(
                  children: [
                    StatusChip.plain(context, v.code, p.critical),
                    const SizedBox(width: K.sm),
                    Expanded(
                      child: Text(
                        v.title,
                        style: TextStyle(fontSize: K.label, color: p.textSecondary, fontFamily: 'Inter'),
                      ),
                    ),
                    Text(
                      '${v.date.month}/${v.date.year}',
                      style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
                    ),
                    const SizedBox(width: K.sm),
                    Text(
                      usd(v.fineUsd),
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w800,
                        color: p.critical,
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
}
