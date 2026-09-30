import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/adaptive_scaffold.dart';
import '../ui/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return PagePadding(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: PageHeader(
              title: 'Settings',
              subtitle: 'Appearance, density and data',
            ),
          ),
          // ---- Appearance ----
          const SliverToBoxAdapter(child: SectionHeader('Appearance')),
          SliverToBoxAdapter(
            child: AppCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'Theme',
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Auto')),
                        ButtonSegment(value: 1, label: Text('Light')),
                        ButtonSegment(value: 2, label: Text('Dark')),
                      ],
                      selected: {state.settings.themeModeIndex},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => state.setThemeMode(s.first),
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  Divider(color: scheme.outline, height: 1),
                  _SettingsRow(
                    icon: Icons.palette_outlined,
                    label: 'Accent',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < K.accents.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                                left: i == 0 ? 0 : 6),
                            child: _AccentDot(
                              color: K.accents[i].$2,
                              name: K.accents[i].$1,
                              selected: state.settings.accentIndex == i,
                              onTap: () => state.setAccent(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.m)),
          // ---- Layout ----
          const SliverToBoxAdapter(child: SectionHeader('Layout')),
          SliverToBoxAdapter(
            child: AppCard(
              child: _SettingsRow(
                icon: Icons.compress,
                label: 'Density',
                sublabel: 'Compact packs more on screen · Comfortable adds air',
                child: SegmentedButton<DensityMode>(
                  segments: const [
                    ButtonSegment(value: DensityMode.compact, label: Text('Compact')),
                    ButtonSegment(
                        value: DensityMode.comfortable, label: Text('Comfortable')),
                  ],
                  selected: {state.settings.density},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => state.setDensity(s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.m)),
          // ---- Data ----
          const SliverToBoxAdapter(child: SectionHeader('Data')),
          SliverToBoxAdapter(
            child: AppCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.file_download_outlined,
                    label: 'Export',
                    sublabel: 'Copy all tasks, notes and settings as JSON',
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: state.exportJson()));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              width: 320,
                              content: Text('Copied JSON export to clipboard'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 15),
                      label: const Text('Copy'),
                    ),
                  ),
                  Divider(color: scheme.outline, height: 1),
                  _SettingsRow(
                    icon: Icons.science_outlined,
                    label: 'Demo data',
                    sublabel: 'Restore the sample tasks and notes',
                    child: OutlinedButton(
                      onPressed: () => state.loadDemoData(),
                      child: const Text('Load'),
                    ),
                  ),
                  Divider(color: scheme.outline, height: 1),
                  _SettingsRow(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Clear everything',
                    sublabel: 'Remove all tasks and notes from this device',
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmClear(context, state),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: K.danger,
                        side: BorderSide(
                            color: K.danger.withValues(alpha: 0.4)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 15),
                      label: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.m)),
          // ---- About ----
          const SliverToBoxAdapter(child: SectionHeader('About')),
          SliverToBoxAdapter(
            child: AppCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: K.xs),
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.info_outline,
                      label: 'Kompact',
                      sublabel: 'v1.0.0 · Built with Flutter · Compact by design',
                      child: const SizedBox(
                        width: 110,
                        child: Text('',
                            style: TextStyle(fontSize: 1)),
                      ),
                    ),
                    Divider(color: scheme.outline, height: 1),
                    _SettingsRow(
                      icon: Icons.grid_view_outlined,
                      label: 'Design system',
                      sublabel: '4px grid · Inter · hairline surfaces',
                      child: const SizedBox(width: 110),
                    ),
                    Divider(color: scheme.outline, height: 1),
                    _SettingsRow(
                      icon: Icons.devices_outlined,
                      label: 'Targets',
                      sublabel:
                          'Android · iOS · Web · Windows · macOS · Linux',
                      child: const SizedBox(width: 110),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.l)),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, AppState state) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This removes every task and note stored on this device. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: K.danger,
            ),
            onPressed: () {
              state.clearAll();
              Navigator.of(context).pop();
            },
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.child,
  });

  final IconData icon;
  final String label;
  final String? sublabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: K.m, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.1)),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(sublabel!,
                      style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8))),
                ],
              ],
            ),
          ),
          const SizedBox(width: K.m),
          child,
        ],
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}
