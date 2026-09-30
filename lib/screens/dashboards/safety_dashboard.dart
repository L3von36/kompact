import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Safety & compliance workspace — rebuilt as a triage-first Safety Inbox
/// (Samsara pattern): a prioritized event queue with AI context labels and
/// coach / dismiss / recognize actions, a Coaching Priority list, compliance
/// tiles (HOS, ELD, fines) and the ABC'S harsh-event trend. The inbox IS the
/// workflow — everything else supports triage decisions.
class SafetyDashboard extends StatelessWidget {
  const SafetyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final pending = state.pendingSafetyEvents;
    final wide = MediaQuery.sizeOf(context).width >= 1080;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Safety inbox',
          subtitle:
              '${pending.length} events awaiting review · ${state.coachingPriority.take(3).map((d) => d.name.split(' ').last).join(', ')} need coaching',
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 1),
              decoration: BoxDecoration(
                color: pending.isEmpty ? p.goodSoft : p.criticalSoft,
                borderRadius: BorderRadius.circular(K.rSm),
              ),
              child: Row(
                children: [
                  Icon(pending.isEmpty ? Icons.verified_rounded : Icons.flag_rounded,
                      size: 12, color: pending.isEmpty ? p.good : p.critical),
                  const SizedBox(width: K.xs + 1),
                  Text(
                    pending.isEmpty ? 'ALL CLEAR' : 'TRIAGE ${pending.length}',
                    style: TextStyle(
                      fontSize: K.micro,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: pending.isEmpty ? p.good : p.critical,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const RoleSwitchChip(),
          ],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Triage inbox dominates (email-client pattern).
                    Expanded(flex: 8, child: _inbox(context, state, pending)),
                    const SizedBox(width: K.md),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _complianceTiles(context, state),
                          const SizedBox(height: K.md),
                          _coachingPriority(context, state),
                          const SizedBox(height: K.md),
                          _eventTrend(context, state),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _inbox(context, state, pending),
                    const SizedBox(height: K.md),
                    _complianceTiles(context, state),
                    const SizedBox(height: K.md),
                    _coachingPriority(context, state),
                    const SizedBox(height: K.md),
                    _eventTrend(context, state),
                  ],
                ),
        ),
      ],
    );
  }

  // ── The inbox: prioritized event queue ───────────────────────────────────

  Widget _inbox(BuildContext context, AppState state, List<SafetyEvent> pending) {
    final p = context.pal;

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Event triage queue',
            eyebrow: 'Crashes first · AI-ranked severity',
            live: true,
            action: Text(
              'WORST FIRST',
              style: TextStyle(
                fontSize: K.micro,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: p.textTertiary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: K.xxl),
              child: EmptyState(
                icon: Icons.verified_user_rounded,
                title: 'Inbox zero',
                subtitle: 'Every detected event has been triaged. Nice work.',
              ),
            )
          else
            for (final e in pending) _eventRow(context, state, e),
        ],
      ),
    );
  }

  Widget _eventRow(BuildContext context, AppState state, SafetyEvent e) {
    final p = context.pal;
    final driver = state.driverById(e.driverId);
    final vehicle = state.vehicleById(e.vehicleId);
    final color = switch (e.severity) {
      3 => p.critical,
      2 => p.urgent,
      _ => p.accent,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: K.xs + 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(K.rMd),
        border: Border.all(color: p.border),
        color: e.severity == 3 ? p.criticalSoft.withValues(alpha: 0.35) : p.surface,
      ),
      child: Column(
        children: [
          // Event header line: type, driver, time, clip.
          Container(
            padding: const EdgeInsets.fromLTRB(K.sm + 2, K.xs + 1, K.sm + 2, 0),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(e.type.icon, size: 14, color: color),
                ),
                const SizedBox(width: K.sm),
                Expanded(
                  child: Text(
                    e.type.label,
                    style: TextStyle(
                      fontSize: K.subtitle,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                if (e.hasClip) ...[
                  Icon(Icons.videocam_rounded, size: 12, color: p.textTertiary),
                  const SizedBox(width: K.xxs),
                  Text(
                    'CLIP',
                    style: TextStyle(
                      fontSize: K.micro,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: K.sm),
                ],
                Text(
                  timeAgo(e.timestamp),
                  style: TextStyle(
                    fontSize: K.caption,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          // AI context + driver.
          Padding(
            padding: const EdgeInsets.fromLTRB(K.sm + 2, K.xs, K.sm + 2, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DriverAvatar(name: driver?.name ?? '?', hue: driver?.hue ?? 0, size: 20),
                const SizedBox(width: K.sm),
                Expanded(
                  child: Text(
                    e.aiContext,
                    style: TextStyle(
                      fontSize: K.label,
                      height: 1.4,
                      color: p.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Meta chips: driver, truck, location, confidence.
          Padding(
            padding: const EdgeInsets.fromLTRB(K.sm + 2, K.xs + 1, K.sm + 2, 0),
            child: Wrap(
              spacing: K.xs + 1,
              runSpacing: K.xxs + 1,
              children: [
                _metaChip(context, driver?.name ?? '—', Icons.person_outline_rounded),
                _metaChip(context, vehicle?.plate ?? '—', Icons.local_shipping_outlined),
                _metaChip(context, e.location, Icons.place_outlined),
                _metaChip(context, '${e.confidencePct}% confident', Icons.psychology_rounded,
                    color: e.confidencePct >= 85 ? p.good : p.textTertiary),
              ],
            ),
          ),
          // Triage actions.
          Padding(
            padding: const EdgeInsets.all(K.sm + 2),
            child: Row(
              children: [
                Expanded(
                  child: _triageButton(
                    context,
                    'COACH DRIVER',
                    Icons.school_rounded,
                    p.primary,
                    () => state.coachSafetyEvent(e.id),
                  ),
                ),
                const SizedBox(width: K.xs + 1),
                Expanded(
                  child: _triageButton(
                    context,
                    'DISMISS',
                    Icons.block_rounded,
                    p.textSecondary,
                    () => state.dismissSafetyEvent(e.id),
                  ),
                ),
                const SizedBox(width: K.xs + 1),
                Expanded(
                  child: _triageButton(
                    context,
                    'RECOGNIZE',
                    Icons.favorite_rounded,
                    p.good,
                    () => state.recognizeSafetyEvent(e.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(BuildContext context, String label, IconData icon, {Color? color}) {
    final p = context.pal;
    final c = color ?? p.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: K.xs + 2, vertical: 1),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(K.rSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: c),
          const SizedBox(width: K.xxs + 1),
          Text(
            label,
            style: TextStyle(
              fontSize: K.caption,
              fontWeight: FontWeight.w600,
              color: c,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _triageButton(
      BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(K.rSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: K.xs + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(K.rSm),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: K.xs + 1),
            Text(
              label,
              style: TextStyle(
                fontSize: K.micro,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: color,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Compliance tiles ─────────────────────────────────────────────────────

  Widget _complianceTiles(BuildContext context, AppState state) {
    final p = context.pal;
    final hosViolations = state.hosRiskCount;
    final eldErrors = state.eldErrorCount;
    final fines = state.finesExposure;

    final tiles = <(String, String, Color, IconData)>[
      ('HOS at risk', '$hosViolations', hosViolations == 0 ? p.good : p.critical, Icons.schedule_rounded),
      ('ELD errors', '$eldErrors', eldErrors == 0 ? p.good : p.urgent, Icons.error_outline_rounded),
      ('Fines exposure', usd(fines), fines > 2000 ? p.critical : p.satisfactory, Icons.gavel_rounded),
      ('Fleet safety', state.avgSafetyScore.toStringAsFixed(0), state.avgSafetyScore >= 85 ? p.good : p.urgent, Icons.shield_rounded),
    ];

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Compliance center', eyebrow: 'DOT audit readiness'),
          Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: K.xs + 1),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: K.sm + 2, horizontal: K.xs + 1),
                    decoration: BoxDecoration(
                      color: tiles[i].$3.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(K.rSm),
                      border: Border.all(color: tiles[i].$3.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Icon(tiles[i].$4, size: 13, color: tiles[i].$3),
                        const SizedBox(height: K.xxs + 1),
                        Text(
                          tiles[i].$2,
                          style: TextStyle(
                            fontSize: K.subtitle,
                            fontWeight: FontWeight.w800,
                            color: tiles[i].$3,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                        ),
                        Text(
                          tiles[i].$1.toUpperCase(),
                          style: TextStyle(
                            fontSize: K.micro,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: p.textTertiary,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Coaching Priority (Samsara pattern) ─────────────────────────────────

  Widget _coachingPriority(BuildContext context, AppState state) {
    final p = context.pal;
    final priority = state.coachingPriority.take(5).toList();

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Coaching priority',
            eyebrow: 'Where to focus this week',
            action: Icon(Icons.school_rounded, size: 14, color: p.primary),
          ),
          for (var i = 0; i < priority.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w800,
                        color: i < 2 ? p.critical : p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: K.xs + 1),
                  DriverAvatar(name: priority[i].name, hue: priority[i].hue, size: 22),
                  const SizedBox(width: K.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priority[i].name,
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
                          '${priority[i].coachingCount30d} sessions / 30 d · ${priority[i].behavior.behaviorTotal} harsh events',
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: K.xs + 2, vertical: 1),
                    decoration: BoxDecoration(
                      color: priority[i].safetyScore < 80
                          ? p.criticalSoft
                          : priority[i].safetyScore < 90
                              ? p.urgentSoft
                              : p.goodSoft,
                      borderRadius: BorderRadius.circular(K.rSm),
                    ),
                    child: Text(
                      priority[i].safetyScore.round().toString(),
                      style: TextStyle(
                        fontSize: K.label,
                        fontWeight: FontWeight.w800,
                        color: priority[i].safetyScore < 80
                            ? p.critical
                            : priority[i].safetyScore < 90
                                ? p.urgent
                                : p.good,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: K.xs),
                  InkWell(
                    onTap: () {
                      state.sendKudos(priority[i].id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          content: Text('Kudos sent to ${priority[i].name}'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(K.rSm),
                    child: Icon(Icons.favorite_border_rounded, size: 14, color: p.good),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── ABC'S event trend + leaderboard ──────────────────────────────────────

  Widget _eventTrend(BuildContext context, AppState state) {
    final p = context.pal;
    final drivers = state.driverLeaderboard;
    final worst = drivers.last;
    final best = drivers.first;
    final totalEvents = state.harshEvents30d;

    // ABC'S: acceleration, braking, cornering (proxy), speeding.
    final braking = state.drivers.fold<int>(0, (s, d) => s + d.behavior.harshBraking30d);
    final accel = state.drivers.fold<int>(0, (s, d) => s + d.behavior.harshAccel30d);
    final speeding = state.drivers.fold<int>(0, (s, d) => s + d.behavior.speeding30d);
    final seatbelt = state.drivers.fold<int>(0, (s, d) => s + d.behavior.seatbeltViolations30d);
    final maxV = [braking, accel, speeding, seatbelt].reduce((a, b) => a > b ? a : b);

    return KCard(
      padding: const EdgeInsets.all(K.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Harsh events · 30 days',
            eyebrow: 'ABC\'S breakdown · $totalEvents total',
          ),
          LabelBar(
              label: 'Braking', value: braking / maxV, valueText: '$braking', color: p.critical),
          const SizedBox(height: K.xs + 1),
          LabelBar(
              label: 'Speeding', value: speeding / maxV, valueText: '$speeding', color: p.urgent),
          const SizedBox(height: K.xs + 1),
          LabelBar(
              label: 'Acceleration', value: accel / maxV, valueText: '$accel', color: p.accent),
          const SizedBox(height: K.xs + 1),
          LabelBar(
              label: 'Seatbelt', value: seatbelt / maxV, valueText: '$seatbelt', color: p.satisfactory),
          const SizedBox(height: K.md),

          // League extremes with network-benchmark framing.
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(K.sm + 2),
                  decoration: BoxDecoration(
                    color: p.goodSoft,
                    borderRadius: BorderRadius.circular(K.rSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOP PERFORMER',
                        style: TextStyle(
                          fontSize: K.micro,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: p.good,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: K.xxs + 1),
                      Text(
                        '${best.name} · ${best.safetyScore.round()}',
                        style: TextStyle(
                          fontSize: K.label,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: K.xs + 1),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(K.sm + 2),
                  decoration: BoxDecoration(
                    color: p.criticalSoft,
                    borderRadius: BorderRadius.circular(K.rSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEEDS COACHING',
                        style: TextStyle(
                          fontSize: K.micro,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: p.critical,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: K.xxs + 1),
                      Text(
                        '${worst.name} · ${worst.safetyScore.round()}',
                        style: TextStyle(
                          fontSize: K.label,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
