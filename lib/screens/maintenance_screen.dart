import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';

/// Predictive maintenance console (guide p. 11 + p. 23): AI-flagged service
/// windows, scheduled work, shop floor status and completed history.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  MaintenanceStatus _filter = MaintenanceStatus.predicted;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final items = state.maintenance.where((m) => m.status == _filter).toList()
      ..sort((a, b) => a.dueInKm.compareTo(b.dueInKm));
    final wide = MediaQuery.sizeOf(context).width >= 950;

    final predictedCount = state.maintenance.where((m) => m.status == MaintenanceStatus.predicted).length;
    final scheduledCount = state.maintenance.where((m) => m.status == MaintenanceStatus.scheduled).length;
    final inProgressCount = state.maintenance.where((m) => m.status == MaintenanceStatus.inProgress).length;
    final doneCount = state.maintenance.where((m) => m.status == MaintenanceStatus.completed).length;

    return Column(
      children: [
        PageHeader(
          title: 'Maintenance',
          subtitle:
              '$predictedCount predicted · $scheduledCount scheduled · $inProgressCount in shop · ${usd(state.openMaintenanceCost)} exposure',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.sm),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilterRow<MaintenanceStatus>(
              selected: _filter,
              onChanged: (v) => setState(() => _filter = v),
              options: [
                (MaintenanceStatus.predicted, 'Predicted ($predictedCount)'),
                (MaintenanceStatus.scheduled, 'Scheduled ($scheduledCount)'),
                (MaintenanceStatus.inProgress, 'In shop ($inProgressCount)'),
                (MaintenanceStatus.completed, 'Done ($doneCount)'),
              ],
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: Icons.build_circle_outlined,
                  title: 'Nothing here',
                  subtitle: 'No ${_filter.name} maintenance items right now.',
                )
              : wide
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.xxl),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 620,
                        mainAxisSpacing: K.xs,
                        crossAxisSpacing: K.xs,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _MaintenanceCard(item: items[i]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(K.lg, 0, K.lg, K.xxl),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _MaintenanceCard(item: items[i]),
                    ),
        ),
      ],
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final MaintenanceItem item;

  const _MaintenanceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    final m = item;
    final vehicle = state.vehicleById(m.vehicleId);
    final isPredicted = m.status == MaintenanceStatus.predicted;
    final isDone = m.status == MaintenanceStatus.completed;

    return KCard(
      padding: const EdgeInsets.symmetric(horizontal: K.md, vertical: K.sm + 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip.plain(
                context,
                m.kind == MaintenanceKind.preventive ? 'PREVENTIVE' : 'CORRECTIVE',
                m.kind == MaintenanceKind.preventive ? p.satisfactory : p.critical,
              ),
              const SizedBox(width: K.xs),
              Expanded(
                child: Text(
                  m.title,
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
              StatusChip.plain(
                context,
                m.status.name.toUpperCase(),
                switch (m.status) {
                  MaintenanceStatus.predicted => p.primary,
                  MaintenanceStatus.scheduled => p.satisfactory,
                  MaintenanceStatus.inProgress => p.accent,
                  MaintenanceStatus.completed => p.good,
                },
              ),
            ],
          ),
          const SizedBox(height: K.xs + 1),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle?.plate ?? '—'} · ${m.part}',
                      style: TextStyle(
                        fontSize: K.label,
                        color: p.textSecondary,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: K.xxs),
                    Text(
                      isDone
                          ? 'completed · ${usd(m.costEstUsd)} · ${m.downtimeHours.toStringAsFixed(0)}h downtime'
                          : m.dueInKm > 0
                              ? 'due in ${kmFmt(m.dueInKm.toDouble())} · est. ${usd(m.costEstUsd)} · ${m.downtimeHours.toStringAsFixed(0)}h down'
                              : 'due now · est. ${usd(m.costEstUsd)} · ${m.downtimeHours.toStringAsFixed(0)}h down',
                      style: TextStyle(
                        fontSize: K.caption,
                        color: p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              if (isPredicted) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${m.confidencePct}%',
                      style: TextStyle(
                        fontSize: K.subtitle,
                        fontWeight: FontWeight.w800,
                        color: p.primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      'AI confidence',
                      style: TextStyle(
                        fontSize: K.caption,
                        color: p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: K.md),
                OutlinedButton(
                  onPressed: () => state.scheduleMaintenance(m.id),
                  child: const Text('Schedule'),
                ),
              ] else if (m.status == MaintenanceStatus.scheduled) ...[
                FilledButton.icon(
                  onPressed: () => state.startMaintenance(m.id),
                  icon: const Icon(Icons.build_rounded, size: 13),
                  label: const Text('Start'),
                ),
              ] else if (m.status == MaintenanceStatus.inProgress) ...[
                FilledButton.icon(
                  onPressed: () => state.completeMaintenance(m.id),
                  icon: const Icon(Icons.check_rounded, size: 13),
                  label: const Text('Complete'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
