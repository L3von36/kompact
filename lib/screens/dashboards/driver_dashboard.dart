import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Driver workspace — rebuilt as a true in-cab companion (Motive / Samsara
/// Driver App patterns): a duty-status switcher you can hit with one thumb,
/// HOS clocks as the hero, the current assignment with proof-of-delivery
/// steps, a DVIR checklist, dispatch messages and an eco-coach card.
/// Single column, large touch targets, glanceable in 3–5 seconds.
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
    final unread = state.messages.where((m) => !m.read).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Hi, ${driver.name.split(' ').first}',
          subtitle:
              '${vehicle?.plate ?? 'no vehicle'} · ${driver.license} · ${trip != null ? 'load ${trip.loadId}' : 'no active load'}',
          actions: [
            // Unread dispatch messages pill.
            InkWell(
              onTap: () {}, // messages live a scroll below
              borderRadius: BorderRadius.circular(K.rSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 1),
                decoration: BoxDecoration(
                  color: unread > 0 ? p.primarySoft : p.surfaceAlt,
                  borderRadius: BorderRadius.circular(K.rSm),
                  border: Border.all(color: unread > 0 ? p.primary.withValues(alpha: 0.35) : p.border),
                ),
                child: Row(
                  children: [
                    Icon(unread > 0 ? Icons.mark_email_unread_rounded : Icons.mail_outline_rounded,
                        size: 13, color: unread > 0 ? p.primary : p.textTertiary),
                    const SizedBox(width: K.xs + 1),
                    Text(
                      unread > 0 ? '$unread new' : 'Inbox',
                      style: TextStyle(
                        fontSize: K.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: unread > 0 ? p.primary : p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const RoleSwitchChip(),
          ],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _dutySwitcher(context, state, driver),
              const SizedBox(height: K.md),
              _hosClocks(context, state, driver),
              const SizedBox(height: K.md),
              if (trip != null) ...[
                _currentTrip(context, state, trip, vehicle),
                const SizedBox(height: K.md),
              ],
              _dvir(context, state, vehicle),
              const SizedBox(height: K.md),
              _messages(context, state),
              const SizedBox(height: K.md),
              _ecoAndScores(context, state, driver, vehicle),
            ],
          ),
        ),
      ],
    );
  }

  // ── Duty status: the one-tap hero control ────────────────────────────────

  Widget _dutySwitcher(BuildContext context, AppState state, Driver d) {
    final p = context.pal;
    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Duty status',
            eyebrow: 'ELD clock · changes log automatically',
            live: true,
            action: Text(
              d.eldStatus == EldStatus.error ? 'ELD ERROR' : 'ELD SYNCED',
              style: TextStyle(
                fontSize: K.micro,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: d.eldStatus == EldStatus.error ? p.critical : p.good,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < DutyStatus.values.length; i++) ...[
                if (i > 0) const SizedBox(width: K.xs + 1),
                Expanded(child: _dutyButton(context, state, d, DutyStatus.values[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _dutyButton(BuildContext context, AppState state, Driver d, DutyStatus s) {
    final p = context.pal;
    final active = d.dutyStatus == s;
    final color = switch (s) {
      DutyStatus.offDuty => p.textSecondary,
      DutyStatus.sleeperBerth => p.info,
      DutyStatus.onDuty => p.urgent,
      DutyStatus.driving => p.good,
    };

    // Large touch targets (≥ 48 px) — usable one-handed in the cab.
    return InkWell(
      onTap: () => state.setDutyStatus(d.id, s),
      borderRadius: BorderRadius.circular(K.rMd),
      child: AnimatedContainer(
        duration: K.fast,
        height: 62,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.14) : p.surfaceAlt,
          borderRadius: BorderRadius.circular(K.rMd),
          border: Border.all(color: active ? color : p.border, width: active ? 1.6 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(s.icon, size: 20, color: active ? color : p.textTertiary),
            const SizedBox(height: K.xxs + 1),
            Text(
              s.label,
              style: TextStyle(
                fontSize: K.label,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? color : p.textTertiary,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── HOS clocks: the driver's most-checked numbers ────────────────────────

  Widget _hosClocks(BuildContext context, AppState state, Driver d) {
    final p = context.pal;
    final driveFrac = (d.hosHoursToday / 11).clamp(0.0, 1.0);
    final cycleFrac = (d.hosCycleUsed / d.hosCycleLimit).clamp(0.0, 1.0);
    final resetIn = (10 - (d.hosHoursToday % 10)).clamp(0.0, 10.0);

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Hours of service', eyebrow: 'Your clocks · plan the reset'),
          Row(
            children: [
              Expanded(
                child: Gauge(
                  value: driveFrac,
                  color: driveFrac > 0.86 ? p.critical : p.primary,
                  label: '${d.hosHoursToday.toStringAsFixed(1)}h',
                  sublabel: 'DRIVEN / 11H',
                  size: 118,
                ),
              ),
              Expanded(
                child: Gauge(
                  value: cycleFrac,
                  color: cycleFrac > 0.85 ? p.critical : cycleFrac > 0.7 ? p.urgent : p.good,
                  label: '${d.hosRemaining.toStringAsFixed(1)}h',
                  sublabel: 'CYCLE LEFT / ${d.hosCycleLimit.round()}H',
                  size: 118,
                ),
              ),
              Expanded(
                child: Gauge(
                  value: resetIn / 10,
                  color: p.info,
                  label: '${resetIn.toStringAsFixed(1)}h',
                  sublabel: 'TO 10H RESET',
                  size: 118,
                ),
              ),
            ],
          ),
          if (d.hosRisk) ...[
            const SizedBox(height: K.xs),
            Container(
              padding: const EdgeInsets.all(K.sm + 2),
              decoration: BoxDecoration(
                color: p.criticalSoft,
                borderRadius: BorderRadius.circular(K.rSm),
                border: Border.all(color: p.critical.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: p.critical),
                  const SizedBox(width: K.sm),
                  Expanded(
                    child: Text(
                      'Cycle nearly exhausted — plan your 34-hour reset before accepting the next load.',
                      style: TextStyle(
                        fontSize: K.label,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: p.critical,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Current assignment with POD steps ────────────────────────────────────

  Widget _currentTrip(BuildContext context, AppState state, Trip t, Vehicle? v) {
    final p = context.pal;
    final atRisk = t.status == TripStatus.atRisk;

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Current assignment',
            eyebrow: '${t.loadId} · ${t.customer}',
            live: true,
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs),
              decoration: BoxDecoration(
                color: atRisk ? p.criticalSoft : p.goodSoft,
                borderRadius: BorderRadius.circular(K.rSm),
              ),
              child: Text(
                atRisk ? 'AT RISK +${t.delayMinutes}m' : 'ON TRACK',
                style: TextStyle(
                  fontSize: K.micro,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: atRisk ? p.critical : p.good,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          Text(
            '${t.origin}  →  ${t.destination}',
            style: TextStyle(
              fontSize: K.title + 2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: p.text,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: K.sm + 1),
          KProgress(
            value: t.progressPct / 100,
            color: atRisk ? p.critical : p.good,
            height: 6,
          ),
          const SizedBox(height: K.xs + 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${t.progressPct.round()}% · ${t.distanceKm.round()} km',
                style: TextStyle(fontSize: K.caption, color: p.textTertiary, fontFamily: 'Inter'),
              ),
              Text(
                'ETA ${t.etaMinutes} min',
                style: TextStyle(
                  fontSize: K.caption,
                  fontWeight: FontWeight.w800,
                  color: atRisk ? p.critical : p.text,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: K.md),

          // Proof-of-delivery sequence — the driver's remaining stops.
          _podStep(context, 'Arrive · ${t.destination}', t.progressPct >= 0.9,
              Icons.location_on_rounded),
          _podStep(context, 'Unload & scan cargo', false, Icons.qr_code_scanner_rounded),
          _podStep(
              context, 'Capture POD signature', false, Icons.draw_rounded),
          _podStep(context, 'Close load ${t.loadId}', false, Icons.task_alt_rounded),
          const SizedBox(height: K.xs + 1),
          FactGrid(
            facts: {
              'Cargo': t.cargo,
              'Weight': '${t.weightT.toStringAsFixed(1)} t',
              if (t.reeferSetpointC != null) 'Setpoint': '${t.reeferSetpointC!.toStringAsFixed(0)} C',
              'Truck': v?.plate ?? '—',
            },
          ),
        ],
      ),
    );
  }

  Widget _podStep(BuildContext context, String label, bool done, IconData icon) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? p.good : p.surfaceAlt,
              border: Border.all(color: done ? p.good : p.borderStrong),
            ),
            child: Icon(done ? Icons.check_rounded : icon, size: 12, color: done ? Colors.white : p.textTertiary),
          ),
          const SizedBox(width: K.sm + 1),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: K.body,
                fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                color: done ? p.text : p.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DVIR pre-trip inspection ─────────────────────────────────────────────

  Widget _dvir(BuildContext context, AppState state, Vehicle? v) {
    final p = context.pal;
    final checks = v == null
        ? <(String, bool)>[]
        : <(String, bool)>[
            ('Tire pressure & tread', v.sensors.tirePressurePsi >= 85),
            ('Battery & electrics', v.sensors.batteryVoltage >= 12.4),
            ('Dash camera feed', v.sensors.cameraFeedOk),
            ('Cargo seal (RFID)', v.sensors.rfidLoadSealed),
            ('No active fault codes', !v.hasActiveDtc),
            ('Fuel & fluids', v.fuelLevelPct >= 15),
          ];
    final failed = checks.where((c) => !c.$2).length;

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Pre-trip inspection',
            eyebrow: 'DVIR · AR-guided checklist',
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs),
              decoration: BoxDecoration(
                color: failed == 0 ? p.goodSoft : p.criticalSoft,
                borderRadius: BorderRadius.circular(K.rSm),
              ),
              child: Text(
                failed == 0 ? 'READY' : '$failed DEFECT${failed > 1 ? 'S' : ''}',
                style: TextStyle(
                  fontSize: K.micro,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: failed == 0 ? p.good : p.critical,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          if (v == null)
            const EmptyState(icon: Icons.checklist_rounded, title: 'Awaiting vehicle assignment')
          else
            ...checks.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
                  child: Row(
                    children: [
                      Icon(
                        c.$2 ? Icons.check_circle_rounded : Icons.error_rounded,
                        size: 15,
                        color: c.$2 ? p.good : p.critical,
                      ),
                      const SizedBox(width: K.sm),
                      Expanded(
                        child: Text(
                          c.$1,
                          style: TextStyle(
                            fontSize: K.body,
                            color: p.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Text(
                        c.$2 ? 'PASS' : 'CHECK',
                        style: TextStyle(
                          fontSize: K.micro,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: c.$2 ? p.good : p.critical,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ── Dispatch messages ─────────────────────────────────────────────────────

  Widget _messages(BuildContext context, AppState state) {
    final p = context.pal;
    final msgs = state.messages.take(4).toList();
    final unread = state.messages.where((m) => !m.read).length;

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Messages',
            eyebrow: 'From dispatch & safety',
            action: unread > 0
                ? InkWell(
                    onTap: state.markAllMessagesRead,
                    borderRadius: BorderRadius.circular(K.rSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs),
                      decoration: BoxDecoration(
                        color: p.primarySoft,
                        borderRadius: BorderRadius.circular(K.rSm),
                      ),
                      child: Text(
                        'MARK ALL READ',
                        style: TextStyle(
                          fontSize: K.micro,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: p.primary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          for (final m in msgs)
            InkWell(
              onTap: () => state.markMessageRead(m.id),
              borderRadius: BorderRadius.circular(K.rSm),
              child: Container(
                margin: const EdgeInsets.only(bottom: K.xs + 1),
                padding: const EdgeInsets.all(K.sm + 2),
                decoration: BoxDecoration(
                  color: m.read ? Colors.transparent : p.primarySoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(K.rSm),
                  border: Border.all(
                    color: m.urgent && !m.read ? p.primary.withValues(alpha: 0.35) : p.border,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      m.urgent ? Icons.priority_high_rounded : Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: m.urgent ? p.primary : p.textTertiary,
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
                                  m.from,
                                  style: TextStyle(
                                    fontSize: K.label,
                                    fontWeight: FontWeight.w800,
                                    color: p.text,
                                    fontFamily: 'Inter',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                timeAgo(m.time),
                                style: TextStyle(
                                  fontSize: K.caption,
                                  color: p.textTertiary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: K.xxs + 1),
                          Text(
                            m.text,
                            style: TextStyle(
                              fontSize: K.label,
                              height: 1.4,
                              color: p.textSecondary,
                              fontFamily: 'Inter',
                            ),
                            maxLines: m.read ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Eco coach + personal scores ──────────────────────────────────────────

  Widget _ecoAndScores(BuildContext context, AppState state, Driver d, Vehicle? v) {
    final p = context.pal;
    final idleMin = v?.idleMinutesToday ?? 0;

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'My performance',
            eyebrow: 'DRIVE score · streaks & kudos',
            action: Row(
              children: [
                Icon(Icons.local_fire_department_rounded, size: 13, color: p.accent),
                const SizedBox(width: K.xxs),
                Text(
                  '${d.kudosCount30d} kudos',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w800,
                    color: p.accent,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _scoreRing(context, 'Safety', d.safetyScore,
                  d.safetyScore >= 90 ? p.good : d.safetyScore >= 75 ? p.satisfactory : p.urgent),
              const SizedBox(width: K.md),
              _scoreRing(context, 'Eco', d.ecoScore,
                  d.ecoScore >= 90 ? p.good : d.ecoScore >= 75 ? p.satisfactory : p.urgent),
              const SizedBox(width: K.md),
              _scoreRing(context, 'On-time', d.onTimeRate * 100, p.primary),
            ],
          ),
          const SizedBox(height: K.sm + 1),
          if (idleMin > 20)
            _coachTip(context, 'You idled ${idleMin.round()} min today — shut down during waits to save fuel.')
          else if (d.behavior.harshBraking30d > 8)
            _coachTip(context,
                'Harsh braking is your top fuel-waster (${d.behavior.harshBraking30d} events / 30 d). Brake earlier, save fuel.')
          else
            _coachTip(context, 'Smooth week — your eco score is trending up. Keep cruise near 80 km/h.'),
        ],
      ),
    );
  }

  Widget _scoreRing(BuildContext context, String label, double value, Color color) {
    final p = context.pal;
    return Expanded(
      child: Column(
        children: [
          Gauge(
            value: (value / 100).clamp(0.0, 1.0),
            color: color,
            label: value.round().toString(),
            size: 74,
          ),
          const SizedBox(height: K.xxs + 1),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: K.micro,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: p.textTertiary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _coachTip(BuildContext context, String text) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(K.sm + 2),
      decoration: BoxDecoration(
        color: p.satisfactorySoft,
        borderRadius: BorderRadius.circular(K.rSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, size: 13, color: p.satisfactory),
          const SizedBox(width: K.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: K.label,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
