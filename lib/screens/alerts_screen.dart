import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';
import 'driver_detail_screen.dart';
import 'vehicle_detail_screen.dart';

/// Real-time alert center (guide p. 12): severity feed, acknowledge / resolve
/// workflow and SOS roadside-assistance dispatch (guide p. 17).
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertSeverity? _severity;
  bool _showResolved = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final alerts = state.alerts.where((a) {
      if (!_showResolved && a.status == AlertStatus.resolved) return false;
      if (_severity != null && a.severity != _severity) return false;
      return true;
    }).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Alert center',
          subtitle:
              '${state.activeAlertCount} active · ${state.criticalAlertCount} critical · ${state.urgentAlertCount} urgent',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.sm),
          child: Row(
            children: [
              Expanded(
                child: FilterRow<AlertSeverity?>(
                  selected: _severity,
                  onChanged: (v) => setState(() => _severity = v),
                  options: const [
                    (null, 'All'),
                    (AlertSeverity.critical, 'Critical'),
                    (AlertSeverity.urgent, 'Urgent'),
                    (AlertSeverity.warning, 'Warning'),
                    (AlertSeverity.info, 'Info'),
                  ],
                ),
              ),
              const SizedBox(width: K.sm),
              _resolvedToggle(context),
            ],
          ),
        ),
        Expanded(
          child: alerts.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: 'No alerts',
                  subtitle: 'Nothing matching this filter.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.xxl),
                  itemCount: alerts.length,
                  itemBuilder: (_, i) => _AlertTile(alert: alerts[i]),
                ),
        ),
      ],
    );
  }

  Widget _resolvedToggle(BuildContext context) {
    final p = context.pal;
    return Material(
      color: _showResolved ? p.primary : p.surfaceAlt,
      borderRadius: BorderRadius.circular(K.rSm),
      child: InkWell(
        onTap: () => setState(() => _showResolved = !_showResolved),
        borderRadius: BorderRadius.circular(K.rSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showResolved ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                size: 12,
                color: _showResolved ? p.primaryFg : p.textTertiary,
              ),
              const SizedBox(width: K.xxs + 1),
              Text(
                'Resolved',
                style: TextStyle(
                  fontSize: K.label,
                  fontWeight: FontWeight.w600,
                  color: _showResolved ? p.primaryFg : p.textTertiary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final FleetAlert alert;

  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    final a = alert;
    final sev = severityColor(context, a.severity);
    final vehicle = state.vehicleById(a.vehicleId);
    final driver = state.driverById(a.driverId);
    final isSos = a.type == AlertType.sos && a.status == AlertStatus.active;
    final resolved = a.status == AlertStatus.resolved;
    final acked = a.status == AlertStatus.acknowledged;

    return KCard(
      margin: const EdgeInsets.only(bottom: K.xs),
      padding: const EdgeInsets.all(K.md),
      borderColor: a.status == AlertStatus.active ? sev.withValues(alpha: 0.45) : null,
      child: Opacity(
        opacity: resolved ? 0.62 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header.
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: K.sm),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: sev),
                ),
                Expanded(
                  child: Text(
                    a.title,
                    style: TextStyle(
                      fontSize: K.subtitle,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                StatusChip.severity(context, a.severity),
                const SizedBox(width: K.xs),
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
            const SizedBox(height: K.xs + 1),

            // Message.
            Text(
              a.message,
              style: TextStyle(
                fontSize: K.body,
                height: 1.4,
                color: p.textSecondary,
                fontFamily: 'Inter',
              ),
            ),

            // Facts (guide p. 26 alert card: date, driver, truck, condition).
            if (a.facts.isNotEmpty) ...[
              const SizedBox(height: K.sm),
              FactGrid(facts: a.facts),
            ],

            const SizedBox(height: K.sm),
            // Footer: context links + actions.
            Row(
              children: [
                if (vehicle != null)
                  _contextLink(
                    context,
                    icon: Icons.local_shipping_rounded,
                    label: vehicle.plate,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => VehicleDetailScreen(vehicleId: vehicle.id)),
                    ),
                  ),
                if (driver != null) ...[
                  const SizedBox(width: K.md),
                  _contextLink(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: driver.name,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => DriverDetailScreen(driverId: driver.id)),
                    ),
                  ),
                ],
                const Spacer(),
                if (a.status == AlertStatus.active) ...[
                  if (isSos) ...[
                    FilledButton.icon(
                      onPressed: () => state.dispatchRoadside(a.id),
                      style: FilledButton.styleFrom(
                        backgroundColor: p.critical,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.emergency_share, size: 13),
                      label: const Text('Dispatch roadside'),
                    ),
                    const SizedBox(width: K.xs),
                  ],
                  TextButton(
                    onPressed: () => state.acknowledgeAlert(a.id),
                    child: const Text('Acknowledge'),
                  ),
                  TextButton(
                    onPressed: () => state.resolveAlert(a.id),
                    child: const Text('Resolve'),
                  ),
                ] else
                  StatusChip.plain(
                    context,
                    acked ? 'ACKNOWLEDGED' : 'RESOLVED',
                    acked ? p.satisfactory : p.good,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _contextLink(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(K.rSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: K.xxs + 1, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: p.primary),
            const SizedBox(width: K.xxs + 1),
            Text(
              label,
              style: TextStyle(
                fontSize: K.label,
                fontWeight: FontWeight.w700,
                color: p.primary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
