import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/fleet_state.dart';
import 'core/models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Workspace deep link: `?role=driver` (also `dispatcher`, `maintenance`,
  // `safety`, `finance`, `executive`, `ops`) opens straight into that role's
  // dashboard — handy for bookmarks, demos and screenshots.
  final roleParam = Uri.base.queryParameters['role'];
  if (roleParam != null) {
    for (final r in FleetRole.values) {
      if (r.name == roleParam) {
        AppState.startupRoleOverride = r;
        break;
      }
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const KompactApp(),
    ),
  );
}
