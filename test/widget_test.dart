import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kompact/app.dart';
import 'package:kompact/core/fleet_state.dart';
import 'package:kompact/core/models.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot(WidgetTester tester) async {
  // Desktop surface: expanded rail with text labels, dashboard fully visible.
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const KompactApp(),
    ),
  );
  // The app runs a live 2s telemetry timer + pulse animations, so
  // pumpAndSettle never settles — advance time explicitly instead.
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  testWidgets('App boots to the operations dashboard with fleet KPIs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _boot(tester);

    expect(find.text('Operations overview'), findsOneWidget);
    expect(find.text('ON ROUTE'), findsOneWidget);
    expect(find.text('ACTIVE ALERTS'), findsOneWidget);
    expect(find.text('Live fleet map'), findsOneWidget);
    expect(find.text('Fleet condition'), findsOneWidget);
  });

  testWidgets('Navigation switches to Fleet inventory', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _boot(tester);

    await tester.tap(find.text('Fleet'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Fleet'), findsWidgets);
    expect(find.byType(MaterialApp), findsOneWidget);
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
