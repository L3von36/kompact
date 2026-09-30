import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';
import 'ui/adaptive_scaffold.dart';

/// Root widget: wires state → theme → adaptive shell.
class KompactApp extends StatelessWidget {
  const KompactApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final themeMode = switch (state.settings.themeModeIndex) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      title: 'Kompact',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(state.settings.accentIndex, state.settings.density),
      darkTheme: AppTheme.dark(state.settings.accentIndex, state.settings.density),
      home: const HomeShell(),
    );
  }
}

/// Adaptive navigation shell with lazy, state-preserving pages.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    AdaptiveDestination(
      label: 'Home',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
    ),
    AdaptiveDestination(
      label: 'Tasks',
      icon: Icons.checklist,
      selectedIcon: Icons.checklist_rounded,
    ),
    AdaptiveDestination(
      label: 'Notes',
      icon: Icons.sticky_note_2_outlined,
      selectedIcon: Icons.sticky_note_2,
    ),
    AdaptiveDestination(
      label: 'Insights',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
    ),
    AdaptiveDestination(
      label: 'Settings',
      icon: Icons.tune,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.loaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    // IndexedStack keeps scroll positions and form state per tab.
    return AdaptiveScaffold(
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
      destinations: _destinations,
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          TasksScreen(),
          NotesScreen(),
          InsightsScreen(),
          SettingsScreen(),
        ],
      ),
    );
  }
}
