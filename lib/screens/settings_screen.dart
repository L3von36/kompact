import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fleet_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';

/// Settings: appearance, telemetry simulation controls, demo data reset.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.pal;
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final s = state.settings;

    return ListView(
      padding: const EdgeInsets.only(bottom: K.xxl),
      children: [
        const PageHeader(title: 'Settings', subtitle: 'Workspace, telemetry and display'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Workspace (role).
              KCard(
                padding: const EdgeInsets.all(K.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Workspace',
                      eyebrow: 'Role-based dashboards',
                      action: Text(
                        state.role.demoUser,
                        style: TextStyle(
                          fontSize: K.caption,
                          fontWeight: FontWeight.w700,
                          color: roleColor(context, state.role),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: K.xs,
                      runSpacing: K.xs,
                      children: [
                        for (final r in FleetRole.values)
                          _roleChip(context, state, r),
                      ],
                    ),
                    const SizedBox(height: K.xs + 1),
                    Text(
                      state.role.mandate,
                      style: TextStyle(
                        fontSize: K.caption,
                        height: 1.35,
                        color: p.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: K.md),

              // Appearance.
              KCard(
                padding: const EdgeInsets.all(K.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Appearance', eyebrow: 'Kompact design system'),
                    _optionRow(
                      context,
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme',
                      child: Segmented<int>(
                        selected: s.themeModeIndex,
                        onChanged: (v) => state.updateSettings(
                          AppSettings(
                            themeModeIndex: v,
                            accentIndex: s.accentIndex,
                            densityIndex: s.densityIndex,
                            roleIndex: s.roleIndex,
                            useMetric: s.useMetric,
                            alertsEnabled: s.alertsEnabled,
                            simRunning: s.simRunning,
                            simSpeed: s.simSpeed,
                          ),
                        ),
                        options: const [(0, 'System'), (1, 'Light'), (2, 'Dark')],
                      ),
                    ),
                    _optionRow(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Accent',
                      child: Segmented<int>(
                        selected: s.accentIndex,
                        onChanged: (v) => state.updateSettings(
                          AppSettings(
                            themeModeIndex: s.themeModeIndex,
                            accentIndex: v,
                            densityIndex: s.densityIndex,
                            roleIndex: s.roleIndex,
                            useMetric: s.useMetric,
                            alertsEnabled: s.alertsEnabled,
                            simRunning: s.simRunning,
                            simSpeed: s.simSpeed,
                          ),
                        ),
                        options: const [(0, 'Blue'), (1, 'Indigo'), (2, 'Teal')],
                      ),
                    ),
                    _optionRow(
                      context,
                      icon: Icons.density_medium_rounded,
                      title: 'Density',
                      child: Segmented<int>(
                        selected: s.densityIndex,
                        onChanged: (v) => state.updateSettings(
                          AppSettings(
                            themeModeIndex: s.themeModeIndex,
                            accentIndex: s.accentIndex,
                            densityIndex: v,
                            useMetric: s.useMetric,
                            alertsEnabled: s.alertsEnabled,
                            simRunning: s.simRunning,
                            simSpeed: s.simSpeed,
                          ),
                        ),
                        options: const [(0, 'Compact'), (1, 'Comfortable')],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: K.md),

              // Telemetry simulation.
              KCard(
                padding: const EdgeInsets.all(K.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Telematics engine', eyebrow: 'Live data simulation'),
                    _optionRow(
                      context,
                      icon: Icons.play_circle_outline_rounded,
                      title: 'Stream',
                      subtitle: 'Moves vehicles, burns fuel, raises alerts',
                      child: Switch(
                        value: s.simRunning,
                        onChanged: (v) => state.setSimRunning(v),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    _optionRow(
                      context,
                      icon: Icons.speed_rounded,
                      title: 'Stream speed',
                      subtitle: '${s.simSpeed.toStringAsFixed(1)}× realtime',
                      child: Segmented<double>(
                        selected: s.simSpeed,
                        onChanged: (v) => state.setSimSpeed(v),
                        options: const [(0.5, '0.5×'), (1.0, '1×'), (2.0, '2×'), (4.0, '4×')],
                      ),
                    ),
                    _optionRow(
                      context,
                      icon: Icons.notifications_active_outlined,
                      title: 'Live alerts',
                      subtitle: 'Generate telematics events while streaming',
                      child: Switch(
                        value: s.alertsEnabled,
                        onChanged: (v) => state.updateSettings(
                          AppSettings(
                            themeModeIndex: s.themeModeIndex,
                            accentIndex: s.accentIndex,
                            densityIndex: s.densityIndex,
                            roleIndex: s.roleIndex,
                            useMetric: s.useMetric,
                            alertsEnabled: v,
                            simRunning: s.simRunning,
                            simSpeed: s.simSpeed,
                          ),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: K.md),

              // Demo data.
              KCard(
                padding: const EdgeInsets.all(K.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Demo fleet', eyebrow: 'Data management'),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reset vehicles, drivers, trips, alerts, maintenance and fuel history back to the seeded scenario from the fleet management guide.',
                            style: TextStyle(
                              fontSize: K.body,
                              height: 1.4,
                              color: p.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(width: K.md),
                        OutlinedButton.icon(
                          onPressed: () => _confirmReset(context, state),
                          icon: Icon(Icons.restart_alt_rounded, size: 14, color: p.critical),
                          label: Text(
                            'Reset demo data',
                            style: TextStyle(color: p.critical, fontFamily: 'Inter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: K.md),

              // About.
              KCard(
                padding: const EdgeInsets.all(K.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'About', eyebrow: 'Kompact FMS'),
                    const MetricRow(label: 'Version', value: '2.1.0'),
                    const MetricRow(label: 'Design system', value: 'Kompact · compact design'),
                    const MetricRow(label: 'Workspaces', value: 'Ops · Dispatch · Driver · Shop · Safety · Finance · Exec'),
                    const MetricRow(label: 'Platforms', value: 'Android · iOS · Web · Windows · macOS · Linux'),
                    const MetricRow(label: 'Data', value: 'Local demo telemetry (no network)'),
                    const SizedBox(height: K.sm),
                    Text(
                      'Kompact is a compact-design fleet management system: driver management, routing and tracking, fuel management, predictive maintenance and fleet safety & compliance — in the densest usable layout, with a dedicated dashboard for every role in the operation.',
                      style: TextStyle(
                        fontSize: K.body,
                        height: 1.45,
                        color: p.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roleChip(BuildContext context, AppState state, FleetRole r) {
    final p = context.pal;
    final selected = r == state.role;
    final color = roleColor(context, r);
    return Material(
      color: selected ? color : p.surfaceAlt,
      borderRadius: BorderRadius.circular(K.rSm),
      child: InkWell(
        onTap: () => state.setRole(r),
        borderRadius: BorderRadius.circular(K.rSm),
        hoverColor: p.surfaceSunken,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: K.sm + 2, vertical: K.xs + 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(r.icon, size: 12, color: selected ? Colors.white : p.textSecondary),
              const SizedBox(width: K.xs + 1),
              Text(
                r.shortLabel,
                style: TextStyle(
                  fontSize: K.label,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : p.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.xs + 1),
      child: Row(
        children: [
          Icon(icon, size: 15, color: p.textTertiary),
          const SizedBox(width: K.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: K.body,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: K.caption,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, AppState state) {
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'All vehicles, drivers, trips, alerts and history return to the seeded scenario. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(d);
              await state.resetDemoData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo fleet reset to seeded scenario')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

/// Tiny segmented control for compact option rows.
class Segmented<T> extends StatelessWidget {
  final T selected;
  final ValueChanged<T> onChanged;
  final List<(T, String)> options;

  const Segmented({super.key, required this.selected, required this.onChanged, required this.options});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(K.rSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            Material(
              color: options[i].$1 == selected ? p.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(K.rSm),
              child: InkWell(
                onTap: () => onChanged(options[i].$1),
                borderRadius: BorderRadius.circular(K.rSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs + 1),
                  child: Text(
                    options[i].$2,
                    style: TextStyle(
                      fontSize: K.label,
                      fontWeight: FontWeight.w700,
                      color: options[i].$1 == selected ? p.primaryFg : p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
