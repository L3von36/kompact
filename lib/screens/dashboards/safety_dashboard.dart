import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/fleet_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../ui/charts.dart';
import '../../ui/role_picker.dart';
import '../../ui/widgets.dart';

/// Safety & Compliance workspace (guide p. 5 — driver safety; p. 6 —
/// regulatory compliance with real-time violation notifications; p. 12 —
/// fleet safety). Behavior analytics, HOS compliance and fines exposure.
class SafetyDashboard extends StatelessWidget {
  const SafetyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final leaderboard = state.driverLeaderboard;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        PageHeader(
          title: 'Safety & compliance',
          subtitle:
              'Fleet safety ${state.avgSafetyScore.toStringAsFixed(0)}/100 · ${state.hosRiskCount} drivers near HOS limits · ${state.eldErrorCount} ELD errors',
          actions: [const RoleSwitchChip()],
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
                    Expanded(flex: 3, child: _leftColumn(context, state, leaderboard)),
                    const SizedBox(width: K.md),
                    Expanded(flex: 2, child: _rightColumn(context, state)),
                  ],
                )
              : Column(
                  children: [
                    _leftColumn(context, state, leaderboard),
                    const SizedBox(height: K.md),
                    _rightColumn(context, state),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _kpiGrid(BuildContext context, AppState state, bool wide) {
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
          label: 'Avg safety score',
          value: state.avgSafetyScore.toStringAsFixed(0),
          unit: '/ 100',
          icon: Icons.health_and_safety_outlined,
          accent: state.avgSafetyScore >= 85 ? p.good : p.urgent,
        ),
        KpiTile(
          label: 'Behavior events 30d',
          value: '${state.harshEvents30d}',
          icon: Icons.speed_rounded,
          deltaUpGood: false,
        ),
        KpiTile(
          label: 'HOS at-risk drivers',
          value: '${state.hosRiskCount}',
          unit: '/ ${state.drivers.length}',
          icon: Icons.timelapse_rounded,
          accent: state.hosRiskCount > 0 ? p.critical : p.good,
        ),
        KpiTile(
          label: 'ELD errors',
          value: '${state.eldErrorCount}',
          icon: Icons.sync_problem_rounded,
          accent: state.eldErrorCount > 0 ? p.critical : p.good,
        ),
        KpiTile(
          label: 'Fines exposure',
          value: usd(state.finesExposure),
          icon: Icons.gavel_rounded,
          accent: p.accent,
        ),
      ],
    );
  }

  Widget _leftColumn(BuildContext context, AppState state, List<Driver> leaderboard) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Safety leaderboard.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Driver safety leaderboard',
                eyebrow: 'Telematics-scored · 30-day window',
                action: Text(
                  'top ${leaderboard.first.safetyScore.round()}',
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w800,
                    color: p.good,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              for (final d in leaderboard.take(8)) _leaderRow(context, d),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Violations register.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Violation register',
                eyebrow: 'Regulatory fines · open items',
              ),
              ..._violationRows(context, state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _leaderRow(BuildContext context, Driver d) {
    final p = context.pal;
    final events = d.behavior.harshBraking30d +
        d.behavior.harshAccel30d +
        d.behavior.speeding30d +
        d.behavior.seatbeltViolations30d;
    final good = d.safetyScore >= 90;
    final mid = d.safetyScore >= 78;

    return Padding(
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
                  '$events events · ${d.tripsCompleted} trips',
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
                  d.safetyScore.round().toString(),
                  style: TextStyle(
                    fontSize: K.label,
                    fontWeight: FontWeight.w800,
                    color: good ? p.good : mid ? p.satisfactory : p.critical,
                    fontFamily: 'Inter',
                  ),
                ),
                KProgress(
                  value: d.safetyScore / 100,
                  color: good ? p.good : mid ? p.satisfactory : p.critical,
                  height: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: K.sm),
          if (d.hosRisk)
            StatusChip(label: 'HOS', color: p.critical, soft: p.criticalSoft)
          else if (d.eldStatus == EldStatus.error)
            StatusChip(label: 'ELD', color: p.critical, soft: p.criticalSoft)
          else
            const SizedBox(width: 34),
        ],
      ),
    );
  }

  List<Widget> _violationRows(BuildContext context, AppState state) {
    final p = context.pal;
    final rows = <Widget>[];
    for (final d in state.drivers) {
      for (final v in d.violations) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: K.xs + 1, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.criticalSoft,
                    borderRadius: BorderRadius.circular(K.rSm),
                  ),
                  child: Text(
                    v.code,
                    style: TextStyle(
                      fontSize: K.caption,
                      fontWeight: FontWeight.w800,
                      color: p.critical,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: K.sm),
                SizedBox(
                  width: 92,
                  child: Text(
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
                ),
                Expanded(
                  child: Text(
                    v.title,
                    style: TextStyle(
                      fontSize: K.caption,
                      color: p.textSecondary,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    usd(v.fineUsd),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: K.label,
                      fontWeight: FontWeight.w700,
                      color: p.accent,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    if (rows.isEmpty) {
      rows.add(const EmptyState(icon: Icons.gavel_rounded, title: 'No open violations', subtitle: 'The roster is fully compliant.'));
    }
    return rows;
  }

  Widget _rightColumn(BuildContext context, AppState state) {
    final p = context.pal;
    final fleet = state.drivers;
    int total(int Function(DriverBehavior b) f) => fleet.fold(0, (s, d) => s + f(d.behavior));

    final harshBraking = total((b) => b.harshBraking30d);
    final harshAccel = total((b) => b.harshAccel30d);
    final speeding = total((b) => b.speeding30d);
    final seatbelt = total((b) => b.seatbeltViolations30d);
    final behaviorTotal = harshBraking + harshAccel + speeding + seatbelt;
    final connected = fleet.where((d) => d.eldStatus == EldStatus.connected).length;
    final syncing = fleet.where((d) => d.eldStatus == EldStatus.syncing).length;
    final errored = fleet.where((d) => d.eldStatus == EldStatus.error).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Behavior breakdown.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Behavior breakdown',
                eyebrow: 'Fleet totals · trailing 30 days',
              ),
              DistributionBar(
                segments: [
                  (harshBraking.toDouble(), p.critical, 'Harsh braking'),
                  (harshAccel.toDouble(), p.accent, 'Harsh acceleration'),
                  (speeding.toDouble(), p.urgent, 'Speeding'),
                  (seatbelt.toDouble(), p.primary, 'Seatbelt'),
                ],
                height: 8,
              ),
              const SizedBox(height: K.xs + 1),
              LabelBar(label: 'Harsh braking', value: behaviorTotal == 0 ? 0 : harshBraking / behaviorTotal, valueText: '$harshBraking', color: p.critical),
              LabelBar(label: 'Harsh accel', value: behaviorTotal == 0 ? 0 : harshAccel / behaviorTotal, valueText: '$harshAccel', color: p.accent),
              LabelBar(label: 'Speeding', value: behaviorTotal == 0 ? 0 : speeding / behaviorTotal, valueText: '$speeding', color: p.urgent),
              LabelBar(label: 'Seatbelt', value: behaviorTotal == 0 ? 0 : seatbelt / behaviorTotal, valueText: '$seatbelt', color: p.primary),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // ELD connectivity.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            children: [
              const SectionHeader(title: 'ELD connectivity', eyebrow: 'Electronic logging devices'),
              Row(
                children: [
                  Donut(
                    size: 84,
                    slices: [
                      (connected.toDouble(), p.good),
                      (syncing.toDouble(), p.satisfactory),
                      (errored.toDouble(), p.critical),
                    ],
                    centerTop: '$connected',
                    centerBottom: 'ONLINE',
                  ),
                  const SizedBox(width: K.md),
                  Expanded(
                    child: Column(
                      children: [
                        LabelBar(label: 'Connected', value: fleet.isEmpty ? 0 : connected / fleet.length, valueText: '$connected', color: p.good),
                        LabelBar(label: 'Syncing', value: fleet.isEmpty ? 0 : syncing / fleet.length, valueText: '$syncing', color: p.satisfactory),
                        LabelBar(label: 'Error', value: fleet.isEmpty ? 0 : errored / fleet.length, valueText: '$errored', color: p.critical),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: K.md),

        // Safety alert feed.
        KCard(
          padding: const EdgeInsets.all(K.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Safety feed',
                eyebrow: 'Real-time notifications',
                live: true,
              ),
              ..._safetyFeed(context, state),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _safetyFeed(BuildContext context, AppState state) {
    final p = context.pal;
    const safetyTypes = {
      AlertType.sos,
      AlertType.collision,
      AlertType.harshBraking,
      AlertType.speeding,
      AlertType.eldViolation,
    };
    final feed = state.alerts
        .where((a) => a.status == AlertStatus.active && safetyTypes.contains(a.type))
        .take(5)
        .toList();
    if (feed.isEmpty) {
      return const [
        EmptyState(icon: Icons.health_and_safety_outlined, title: 'No safety events', subtitle: 'No active harsh driving or SOS events.'),
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
                            '${state.driverById(a.driverId)?.name ?? '—'} · ${a.title}',
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
