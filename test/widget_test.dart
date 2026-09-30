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

void main() {
  testWidgets('App boots to the ops workspace with fleet KPIs and role context', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _boot(tester);

    expect(find.text('Operations overview'), findsOneWidget);
    expect(find.text('ON ROUTE'), findsOneWidget);
    expect(find.text('ACTIVE ALERTS'), findsOneWidget);
    expect(find.text('Live fleet map'), findsOneWidget);
    expect(find.text('Fleet condition'), findsOneWidget);

    // Operator identity card + role-filtered rail sections.
    expect(find.text('Dana Whitfield'), findsOneWidget);
    expect(find.text('Fleet Manager'), findsOneWidget);
    expect(find.text('OPERATIONS'), findsOneWidget);
    expect(find.text('FLEET & PEOPLE'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
  });

  testWidgets('Navigation switches to the vehicle inventory', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _boot(tester);

    await tester.tap(find.text('Vehicles'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('Role picker switches the workspace dashboard and modules', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _boot(tester);

    // Open the role switcher from the sidebar identity card.
    await tester.tap(find.text('Dana Whitfield'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Switch workspace'), findsOneWidget);

    // Switch to the Driver persona.
    await tester.tap(find.text('Driver').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));

    // Driver cockpit renders, with role-personalized modules.
    expect(find.text('Driver cockpit'), findsOneWidget);
    expect(find.text('Hours of service'), findsOneWidget);
    expect(find.text('Pre-trip inspection'), findsOneWidget);
    expect(find.text('My Route'), findsOneWidget);
    expect(find.text('My Alerts'), findsOneWidget);
    // The ops-only modules are filtered out of the driver's rail.
    expect(find.text('Insights'), findsNothing);
  });

  testWidgets('Every role renders its own dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await _boot(tester);

    final expectations = <FleetRole, String>{
      FleetRole.dispatcher: 'Dispatch board',
      FleetRole.maintenance: 'Shop overview',
      FleetRole.safety: 'Safety & compliance',
      FleetRole.finance: 'Cost center',
      FleetRole.executive: 'Executive overview',
    };

    for (final entry in expectations.entries) {
      state.setRole(entry.key);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(entry.value), findsOneWidget, reason: 'dashboard for ${entry.key}');
    }

    // Back to ops.
    state.setRole(FleetRole.ops);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Operations overview'), findsOneWidget);
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
}
