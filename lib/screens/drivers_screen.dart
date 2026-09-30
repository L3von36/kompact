import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';
import 'driver_detail_screen.dart';

/// Driver management (guide p. 10): profiles, safety/eco scores, HOS-ELD
/// compliance, violations. Dense leaderboard-style layout.
class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  int _sort = 0; // 0 safety, 1 eco, 2 hos risk

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final drivers = [...state.drivers];
    switch (_sort) {
      case 1:
        drivers.sort((a, b) => b.ecoScore.compareTo(a.ecoScore));
      case 2:
        drivers.sort((a, b) => b.hosCycleUsed.compareTo(a.hosCycleUsed));
      default:
        drivers.sort((a, b) => b.safetyScore.compareTo(a.safetyScore));
    }

    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      children: [
        PageHeader(
          title: 'Drivers',
          subtitle:
              'avg safety ${state.avgSafetyScore.toStringAsFixed(0)} · avg eco ${state.avgEcoScore.toStringAsFixed(0)} · on-time ${(state.avgOnTimeRate * 100).toStringAsFixed(0)}%',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.sm),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilterRow<int>(
              selected: _sort,
              onChanged: (v) => setState(() => _sort = v),
              options: const [
                (0, 'Sort: Safety'),
                (1, 'Sort: Eco'),
                (2, 'Sort: HOS load'),
              ],
            ),
          ),
        ),
        Expanded(
          child: wide
              ? GridView.builder(
                  padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.xxl),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 560,
                    mainAxisSpacing: K.xs,
                    crossAxisSpacing: K.xs,
                    childAspectRatio: 2.35,
                  ),
                  itemCount: drivers.length,
                  itemBuilder: (_, i) => _DriverCard(driver: drivers[i]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.xxl),
                  itemCount: drivers.length,
                  itemBuilder: (_, i) => _DriverCard(driver: drivers[i]),
                ),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  final Driver driver;

  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    final d = driver;
    final vehicle = state.vehicleById(d.vehicleId);
    final hosPct = d.hosCycleUsed / d.hosCycleLimit;

    return KCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => DriverDetailScreen(driverId: d.id)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: K.md, vertical: K.sm + 1),
      child: Column(
        children: [
          Row(
            children: [
              DriverAvatar(name: d.name, hue: d.hue, size: 30),
              const SizedBox(width: K.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: TextStyle(
                        fontSize: K.subtitle,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${d.license} · ${d.yearsExperience} yrs · ${d.tripsCompleted} trips',
                      style: TextStyle(
                        fontSize: K.caption,
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
                  Row(
                    children: [
                      Icon(
                        d.eldStatus == EldStatus.connected
                            ? Icons.link_rounded
                            : d.eldStatus == EldStatus.syncing
                                ? Icons.sync_rounded
                                : Icons.link_off_rounded,
                        size: 12,
                        color: d.eldStatus == EldStatus.error ? p.critical : p.good,
                      ),
                      const SizedBox(width: K.xxs + 1),
                      Text(
                        'ELD',
                        style: TextStyle(
                          fontSize: K.caption,
                          fontWeight: FontWeight.w700,
                          color: d.eldStatus == EldStatus.error ? p.critical : p.textTertiary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  if (d.violations.isNotEmpty)
                    Text(
                      '${d.violations.length} violation${d.violations.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: K.caption,
                        fontWeight: FontWeight.w600,
                        color: p.critical,
                        fontFamily: 'Inter',
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: K.xs + 1),
          Row(
            children: [
              // Safety score.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SAFETY',
                          style: TextStyle(
                            fontSize: K.micro,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: p.textTertiary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          d.safetyScore.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: K.caption,
                            fontWeight: FontWeight.w800,
                            color: _scoreColor(context, d.safetyScore),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    KProgress(
                      value: d.safetyScore / 100,
                      color: _scoreColor(context, d.safetyScore),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: K.md),
              // Eco score.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ECO',
                          style: TextStyle(
                            fontSize: K.micro,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: p.textTertiary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          d.ecoScore.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: K.caption,
                            fontWeight: FontWeight.w800,
                            color: _scoreColor(context, d.ecoScore),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    KProgress(value: d.ecoScore / 100, color: _scoreColor(context, d.ecoScore)),
                  ],
                ),
              ),
              const SizedBox(width: K.md),
              // HOS cycle.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HOS ${d.hosCycleUsed.toStringAsFixed(0)}/${d.hosCycleLimit.toStringAsFixed(0)}h',
                          style: TextStyle(
                            fontSize: K.micro,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: hosPct > 0.85 ? p.critical : p.textTertiary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          d.hosRisk ? 'RISK' : 'OK',
                          style: TextStyle(
                            fontSize: K.caption,
                            fontWeight: FontWeight.w800,
                            color: d.hosRisk ? p.critical : p.good,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    KProgress(value: hosPct, color: hosPct > 0.85 ? p.critical : hosPct > 0.7 ? p.urgent : p.good),
                  ],
                ),
              ),
            ],
          ),
          if (vehicle != null) ...[
            const SizedBox(height: K.xs + 1),
            Row(
              children: [
                Icon(Icons.local_shipping_rounded, size: 11, color: p.textTertiary),
                const SizedBox(width: K.xxs + 1),
                Text(
                  '${vehicle.plate} · ${vehicle.type.label}',
                  style: TextStyle(
                    fontSize: K.caption,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                Text(
                  'today ${d.hosHoursToday.toStringAsFixed(1)}h driven',
                  style: TextStyle(
                    fontSize: K.caption,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _scoreColor(BuildContext c, double v) =>
      v >= 90 ? c.pal.good : v >= 78 ? c.pal.satisfactory : v >= 65 ? c.pal.urgent : c.pal.critical;
}
