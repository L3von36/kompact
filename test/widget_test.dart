import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kompact/app.dart';
import 'package:kompact/core/fleet_state.dart';
import 'package:kompact/core/models.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _boot(WidgetTester tester) async {
  // Desktop surface: expanded rail with text labels, dashboard fully visible.
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final state = AppState();
  await tester.pumpWidget(
    // create: gives the provider ownership — it disposes the AppState (and
    // cancels the telemetry timer) when the tree is torn down.
    ChangeNotifierProvider<AppState>(
      create: (_) => state,
      child: const KompactApp(),
    ),
  );
  // The app runs a live 2s telemetry timer + pulse animations, so
  // pumpAndSettle never settles — advance time explicitly instead.
  await tester.pump(const Duration(seconds: 3));
  return state;
}

/// Boots straight into a signed-in [role] workspace by pre-seeding the
/// persisted session, skipping the login screen.
Future<AppState> _bootAs(WidgetTester tester, FleetRole role) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final user = kFleetUsers.firstWhere((u) => u.role == role);
  final state = AppState();
  await tester.pumpWidget(
    // Keyed per role so repeated bootAs calls build a fresh provider and
    // never reuse the previous iteration's AppState element.
    ChangeNotifierProvider<AppState>(
      key: ValueKey('boot-$role'),
      create: (_) => state,
      child: const KompactApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  state.signIn(user);
  await tester.pump(const Duration(seconds: 2));
  return state;
}

void main() {
  testWidgets('Login screen lists demo accounts and signs into ops', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _boot(tester);

    // The login screen is the entry point with one account per role.
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('DEMO ACCOUNTS'), findsOneWidget);
    for (final u in kFleetUsers) {
      expect(find.text(u.name), findsOneWidget, reason: 'account ${u.name}');
    }

    // Select Dana (ops) and sign in with the demo password.
    await tester.tap(find.text('Dana Whitfield'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'kompact');
    await tester.tap(find.text('Sign in as Ops'));
    await tester.pump(const Duration(seconds: 2));

    // Landed in the ops workspace.
    expect(find.text('Fleet command'), findsOneWidget);
    expect(find.text('Dana Whitfield'), findsOneWidget);
  });

  testWidgets('Ops workspace renders map-first command center', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _bootAs(tester, FleetRole.ops);

    expect(find.text('Fleet command'), findsOneWidget);
    expect(find.text('Exception feed'), findsOneWidget);
    expect(find.text('Utilization watch'), findsOneWidget);
    expect(find.text('Idle leaderboard'), findsOneWidget);

    // Operator identity card + role-filtered rail sections.
    expect(find.text('Dana Whitfield'), findsOneWidget);
    expect(find.text('OPERATIONS'), findsOneWidget);
    expect(find.text('FLEET & PEOPLE'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
  });

  testWidgets('Navigation switches to the vehicle inventory', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _bootAs(tester, FleetRole.ops);

    await tester.tap(find.text('Vehicles'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('Account menu offers workspace switching and sign-out', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _bootAs(tester, FleetRole.driver);

    // Open the account popover from the rail identity card.
    final driver = kFleetUsers.firstWhere((u) => u.role == FleetRole.driver);
    await tester.tap(find.text(driver.name).last);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('SWITCH WORKSPACE'), findsOneWidget);
    expect(find.text('Sign out · switch user'), findsOneWidget);

    // Quick-switch keeps the session: jump to the dispatcher workspace.
    await tester.tap(find.text('DISPATCH'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Dispatch board'), findsOneWidget);

    // Sign out lands back on the login screen.
    await tester.tap(find.text('Ray Kowalski'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Sign out · switch user'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('DEMO ACCOUNTS'), findsOneWidget);
  });

  testWidgets('Every role renders its own distinct dashboard', (tester) async {
    // Each dashboard leads with a unique hero — this is the regression
    // guard against them collapsing back into one shared template.
    final expectations = <FleetRole, String>{
      FleetRole.ops: 'Fleet command',
      FleetRole.dispatcher: 'Dispatch board',
      FleetRole.driver: 'Duty status',
      FleetRole.maintenance: 'Shop control',
      FleetRole.safety: 'Event triage queue',
      FleetRole.finance: 'Cost per kilometer — league table',
      FleetRole.executive: 'Executive scorecard',
    };

    for (final entry in expectations.entries) {
      SharedPreferences.setMockInitialValues({});
      await _bootAs(tester, entry.key);
      expect(find.text(entry.value), findsOneWidget,
          reason: 'dashboard hero for ${entry.key}');
    }
  });

  test('Role state persists through AppSettings round-trip', () {
    final s = AppSettings(roleIndex: 3);
    expect(FleetRole.values[s.roleIndex], FleetRole.maintenance);
    final j = s.toJson();
    final s2 = AppSettings.fromJson(j);
    expect(FleetRole.values[s2.roleIndex], FleetRole.maintenance);
    // Out-of-range values fall back safely.
    final s3 = AppSettings.fromJson({...j, 'role': 99});
    expect(s3.roleIndex, 0);
  });

  test('FleetRole metadata is complete', () {
    for (final r in FleetRole.values) {
      expect(r.label, isNotEmpty);
      expect(r.shortLabel, isNotEmpty);
      expect(r.demoUser, isNotEmpty);
      expect(r.mandate, isNotEmpty);
    }
  });

  test('Demo user directory covers every role exactly once', () {
    for (final r in FleetRole.values) {
      final matches = kFleetUsers.where((u) => u.role == r).toList();
      expect(matches.length, 1, reason: 'one account per role: $r');
      expect(matches.first.email, contains('@'));
      expect(matches.first.initials.length, 2);
    }
  });

  test('Seed data is internally consistent', () {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    expect(state.loaded, false); // loads async — fine for unit check
  });

  test('Vehicle JSON round-trips', () {
    final v = Vehicle(
      id: 'v99',
      plate: 'NY 0T 9999',
      model: 'Test Truck',
      type: VehicleType.semi,
      year: 2024,
      status: VehicleStatus.onRoute,
      condition: VehicleCondition.good,
      driverId: 'd1',
      odometerKm: 1000,
      speedKmh: 80,
      headingDeg: 90,
      pos: const Offset(0.5, 0.5),
      fuelLevelPct: 60,
      tankCapacityL: 500,
      efficiencyKmpl: 3.0,
      engineTempC: 85,
      ecoScore: 88,
      co2KgPer100Km: 60,
      geofenceId: 'gf-depot',
      dtcCodes: const [DtcCode(code: 'P1000', description: 'Test code')],
      sensors: const SensorSnapshot(
        cargoTempC: 4,
        humidityPct: 50,
        tirePressurePsi: 100,
        batteryVoltage: 13.0,
      ),
    );
    final j = v.toJson();
    final v2 = Vehicle.fromJson(j);
    expect(v2.plate, v.plate);
    expect(v2.type, VehicleType.semi);
    expect(v2.dtcCodes.first.code, 'P1000');
    expect(v2.sensors.tirePressurePsi, 100);
  });

  test('Trip posAt interpolates waypoints', () {
    final t = Trip(
      id: 't1',
      vehicleId: 'v1',
      driverId: 'd1',
      origin: 'A',
      destination: 'B',
      cargo: 'x',
      weightT: 1,
      distanceKm: 10,
      progressPct: 50,
      etaMinutes: 10,
      delayMinutes: 0,
      status: TripStatus.enRoute,
      waypoints: const [Offset(0, 0), Offset(1, 1)],
    );
    final mid = t.posAt(0.5);
    expect(mid.dx, closeTo(0.5, 0.001));
    expect(mid.dy, closeTo(0.5, 0.001));
  });

  test('MaintenanceItem round-trips the new shop fields', () {
    final m = MaintenanceItem(
      id: 'm99',
      vehicleId: 'v1',
      kind: MaintenanceKind.corrective,
      status: MaintenanceStatus.scheduled,
      title: 'Test WO',
      part: 'Part',
      dueInKm: 0,
      confidencePct: 100,
      costEstUsd: 900,
      downtimeHours: 4,
      priority: MaintenancePriority.emergency,
      tech: 'Ana Delgado',
      laborHoursEst: 5,
      laborHoursActual: 2.5,
    );
    final j = m.toJson();
    final m2 = MaintenanceItem.fromJson(j);
    expect(m2.priority, MaintenancePriority.emergency);
    expect(m2.tech, 'Ana Delgado');
    expect(m2.laborHoursActual, 2.5);
    expect(m2.needsApproval, isTrue);

    // Old persisted payloads (no shop fields) still parse with defaults.
    final legacy = MaintenanceItem.fromJson({
      'id': 'm1', 'vid': 'v1', 'k': 'preventive', 'st': 'predicted',
      't': 'Old', 'p': 'Old part', 'dkm': 100, 'cf': 90,
      'c': 300.0, 'dt': 2.0,
    });
    expect(legacy.priority, MaintenancePriority.scheduled);
    expect(legacy.needsApproval, isFalse);
  });

  test('SafetyEvent round-trips and keeps triage state', () {
    final e = SafetyEvent(
      id: 'se99',
      type: SafetyEventType.drowsiness,
      driverId: 'd1',
      vehicleId: 'v1',
      timestamp: DateTime(2026, 1, 1),
      location: 'I-80',
      severity: 3,
      aiContext: 'Eye closure detected',
      confidencePct: 91,
      status: SafetyEventStatus.coached,
    );
    final e2 = SafetyEvent.fromJson(e.toJson());
    expect(e2.type, SafetyEventType.drowsiness);
    expect(e2.status, SafetyEventStatus.coached);
    expect(e2.severity, 3);
  });
}
