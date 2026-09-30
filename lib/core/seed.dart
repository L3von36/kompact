import 'dart:math';
import 'dart:ui';

import 'models.dart';

/// Deterministic fleet seed — mirrors the scenarios described in the
/// "Building Custom Fleet Management Software" guide.
class SeedData {
  final List<Vehicle> vehicles;
  final List<Driver> drivers;
  final List<Trip> trips;
  final List<FleetAlert> alerts;
  final List<MaintenanceItem> maintenance;
  final List<FuelEvent> fuelEvents;
  final List<Geofence> geofences;
  final List<Station> stations;

  const SeedData({
    required this.vehicles,
    required this.drivers,
    required this.trips,
    required this.alerts,
    required this.maintenance,
    required this.fuelEvents,
    required this.geofences,
    required this.stations,
  });
}

// Landmark anchors in normalized map space.
const kDepot = Offset(0.22, 0.62);
const kPort = Offset(0.88, 0.75);
const kNorthWh = Offset(0.33, 0.17);
const kAirport = Offset(0.12, 0.12);
const kEastDc = Offset(0.72, 0.38);
const kFuelStop = Offset(0.48, 0.55);

SeedData buildSeed() {
  final rnd = Random(7);
  final now = DateTime.now();

  // ── Geofences ────────────────────────────────────────────────────────────
  final geofences = [
    Geofence(id: 'gf-depot', name: 'Central Depot', kind: 'depot', center: kDepot, radiusNorm: 0.085, entriesToday: 18, exitsToday: 15),
    Geofence(id: 'gf-port', name: 'Port Terminal', kind: 'port', center: kPort, radiusNorm: 0.065, entriesToday: 6, exitsToday: 4),
    Geofence(id: 'gf-north', name: 'North Warehouse', kind: 'warehouse', center: kNorthWh, radiusNorm: 0.055, entriesToday: 9, exitsToday: 8),
    Geofence(id: 'gf-airport', name: 'Airport Cargo', kind: 'customer', center: kAirport, radiusNorm: 0.05, entriesToday: 3, exitsToday: 2),
    Geofence(id: 'gf-east', name: 'East DC', kind: 'customer', center: kEastDc, radiusNorm: 0.06, entriesToday: 7, exitsToday: 6),
  ];

  final stations = [
    const Station(name: 'Fleet Fuel Stop', brand: 'fuel', center: kFuelStop),
    const Station(name: 'Highway Plaza', brand: 'fuel', center: Offset(0.18, 0.44)),
    const Station(name: 'Port Fuel', brand: 'fuel', center: Offset(0.80, 0.66)),
    const Station(name: 'North Service', brand: 'service', center: Offset(0.40, 0.26)),
  ];

  // ── Drivers ──────────────────────────────────────────────────────────────
  Driver mkDriver(
    int i,
    String name,
    String lic, [
    double saf = 88,
    double eco = 82,
    EldStatus eld = EldStatus.connected,
    double hcu = 44,
    double ht = 3.5,
    List<Violation> vio = const [],
    int tc = 240,
    double otr = 0.94,
    int yx = 8,
  ]) =>
      Driver(
        id: 'd$i',
        name: name,
        license: lic,
        phone: '+1 (212) 555-0${100 + i}',
        hue: (137 * i) % 360,
        safetyScore: saf,
        ecoScore: eco,
        behavior: DriverBehavior(
          harshBraking30d: 2 + i % 5,
          harshAccel30d: 1 + (i * 2) % 6,
          speeding30d: i % 7,
          seatbeltViolations30d: i % 3,
        ),
        eldStatus: eld,
        hosHoursToday: ht,
        hosCycleLimit: 70,
        hosCycleUsed: hcu,
        violations: vio,
        tripsCompleted: tc,
        onTimeRate: otr,
        yearsExperience: yx,
      );

  final drivers = <Driver>[
    mkDriver(0, 'Derrick Reyes', 'CDL-A', 84, 78, EldStatus.connected, 51.5, 6.2, [
      Violation(code: 'HOS-11', title: '11-hour driving limit exceeded', fineUsd: 1250, date: now.subtract(const Duration(days: 46))),
    ]),
    mkDriver(1, 'Marcus Chen', 'CDL-A', 96, 93, EldStatus.connected, 32.0, 2.8, [], 312, 0.98, 11),
    mkDriver(2, 'Amara Okafor', 'CDL-A', 91, 88, EldStatus.connected, 40.5, 4.1, [], 275, 0.96, 9),
    mkDriver(3, 'Sofia Petrov', 'CDL-B', 78, 71, EldStatus.error, 62.0, 7.8, [
      Violation(code: 'SPD-70', title: 'Speeding 12 mph over limit', fineUsd: 340, date: now.subtract(const Duration(days: 12))),
      Violation(code: 'SB-01', title: 'Seatbelt not fastened', fineUsd: 120, date: now.subtract(const Duration(days: 31))),
    ], 198, 0.88),
    mkDriver(4, 'Jamal Washington', 'CDL-A', 89, 85, EldStatus.connected, 28.5, 1.9, [], 301, 0.95, 13),
    mkDriver(5, 'Elena Rodriguez', 'CDL-B', 94, 91, EldStatus.connected, 35.0, 3.3, [], 262, 0.97, 7),
    mkDriver(6, 'Tomás Silva', 'CDL-A', 72, 66, EldStatus.syncing, 66.5, 9.1, [
      Violation(code: 'HOS-70', title: '70-hour cycle violation', fineUsd: 2100, date: now.subtract(const Duration(days: 8))),
    ], 224, 0.84, 6),
    mkDriver(7, 'Priya Sharma', 'CDL-B', 97, 95, EldStatus.connected, 24.0, 2.2, [], 288, 0.99, 10),
    mkDriver(8, 'Devon Miller', 'CDL-A', 83, 79, EldStatus.connected, 47.5, 5.4, [], 246, 0.92, 15),
    mkDriver(9, 'Lena Kowalski', 'CDL-A', 88, 90, EldStatus.connected, 38.0, 3.9, [], 259, 0.96, 5),
  ];

  // ── Vehicles ─────────────────────────────────────────────────────────────
  Vehicle mkV(
    String id,
    String plate,
    String model,
    VehicleType type,
    int year,
    VehicleStatus st,
    VehicleCondition cond,
    Offset pos, {
    String? driver,
    double fuel = 0.6,
    double odo = 180000,
    double eco = 82,
    List<DtcCode> dtc = const [],
    double eff = 2.9,
    double tank = 600,
    double co2 = 62,
    double spd = 0,
    double hdg = 0,
    double et = 82,
  }) =>
      Vehicle(
        id: id,
        plate: plate,
        model: model,
        type: type,
        year: year,
        status: st,
        condition: cond,
        driverId: driver,
        odometerKm: odo,
        speedKmh: spd,
        headingDeg: hdg,
        pos: pos,
        fuelLevelPct: fuel,
        tankCapacityL: tank,
        efficiencyKmpl: eff,
        engineTempC: et,
        ecoScore: eco,
        co2KgPer100Km: co2,
        geofenceId: 'gf-depot',
        dtcCodes: dtc,
        sensors: SensorSnapshot(
          cargoTempC: type == VehicleType.reefer ? -18 + rnd.nextDouble() * 3 : 4 + rnd.nextDouble() * 8,
          humidityPct: 38 + rnd.nextDouble() * 22,
          tirePressurePsi: 96 + rnd.nextDouble() * 14,
          batteryVoltage: 12.4 + rnd.nextDouble() * 0.8,
          cameraFeedOk: true,
          rfidLoadSealed: true,
        ),
        idleMinutesToday: st == VehicleStatus.idle ? 12 + rnd.nextInt(40) : rnd.nextInt(6),
        harshEventsToday: rnd.nextInt(3),
      );

  final vehicles = <Vehicle>[
    // The guide's example truck (p. 26): fuel-tank leak alert, satisfactory.
    mkV('v1', 'NY 0Q 8214', 'Freightliner Cascadia 126', VehicleType.semi, 2022,
        VehicleStatus.onRoute, VehicleCondition.satisfactory, const Offset(0.42, 0.55),
        driver: 'd0', fuel: 0.47, odo: 312480, eco: 78, spd: 84, hdg: 4, et: 88,
        dtc: [const DtcCode(code: 'P0087', description: 'Fuel rail pressure too low')]),
    mkV('v2', 'NY 4K 9921', 'Volvo VNL 860', VehicleType.semi, 2023,
        VehicleStatus.onRoute, VehicleCondition.good, const Offset(0.60, 0.34),
        driver: 'd1', fuel: 0.71, odo: 198220, eco: 93, spd: 91, hdg: 18, eff: 3.2),
    mkV('v3', 'NJ 8T 3345', 'Kenworth T680', VehicleType.semi, 2021,
        VehicleStatus.onRoute, VehicleCondition.urgent, const Offset(0.30, 0.28),
        driver: 'd2', fuel: 0.33, odo: 405910, eco: 81, spd: 76, hdg: 348, et: 94,
        dtc: [
          const DtcCode(code: 'P0401', description: 'EGR flow insufficient'),
          const DtcCode(code: 'P0299', description: 'Turbo underboost', active: false),
        ]),
    mkV('v4', 'NY 2M 5517', 'Peterbilt 579 Reefer', VehicleType.reefer, 2023,
        VehicleStatus.onRoute, VehicleCondition.good, const Offset(0.70, 0.60),
        driver: 'd4', fuel: 0.82, odo: 156300, eco: 87, spd: 79, hdg: 176, eff: 2.6, co2: 71),
    mkV('v5', 'NY 7C 8830', 'Freightliner Cascadia Reefer', VehicleType.reefer, 2020,
        VehicleStatus.onRoute, VehicleCondition.satisfactory, const Offset(0.55, 0.72),
        driver: 'd8', fuel: 0.52, odo: 367540, eco: 79, spd: 81, hdg: 190, eff: 2.5, co2: 73),
    mkV('v6', 'NJ 5R 2216', 'Isuzu NPR-HD', VehicleType.box, 2022,
        VehicleStatus.onRoute, VehicleCondition.good, const Offset(0.26, 0.50),
        driver: 'd5', fuel: 0.64, odo: 98750, eco: 90, spd: 58, hdg: 180, eff: 4.1, tank: 200, co2: 34),
    mkV('v7', 'NY 9X 4402', 'Hino 268', VehicleType.box, 2019,
        VehicleStatus.idle, VehicleCondition.satisfactory, const Offset(0.20, 0.64),
        fuel: 0.38, odo: 221400, eco: 76, eff: 3.8, tank: 200, co2: 36),
    mkV('v8', 'NY 3B 6690', 'Kenworth T880 Tanker', VehicleType.tanker, 2021,
        VehicleStatus.onRoute, VehicleCondition.critical, const Offset(0.80, 0.70),
        driver: 'd9', fuel: 0.29, odo: 289660, eco: 74, spd: 68, hdg: 160, et: 97, eff: 2.7, co2: 68,
        dtc: [const DtcCode(code: 'C1234', description: 'Tire pressure sensor fault — axle 3')]),
    mkV('v9', 'NJ 6H 7754', 'Mack Granite Tanker', VehicleType.tanker, 2020,
        VehicleStatus.onRoute, VehicleCondition.satisfactory, const Offset(0.48, 0.30),
        driver: 'd9', fuel: 0.58, odo: 331200, eco: 77, spd: 72, hdg: 350, eff: 2.8, co2: 66),
    // NOTE: v9 reassigned below — keep d9 on v8 only.
    mkV('v10', 'NY 8V 1183', 'Ford Transit 350', VehicleType.van, 2024,
        VehicleStatus.onRoute, VehicleCondition.good, const Offset(0.36, 0.66),
        driver: 'd7', fuel: 0.77, odo: 42100, eco: 95, spd: 52, hdg: 170, eff: 6.2, tank: 90, co2: 22),
    mkV('v11', 'NY 1P 9027', 'Mercedes Sprinter 2500', VehicleType.van, 2023,
        VehicleStatus.idle, VehicleCondition.good, const Offset(0.24, 0.66),
        fuel: 0.55, odo: 76400, eco: 84, eff: 5.8, tank: 90, co2: 24),
    mkV('v12', 'NJ 0D 3348', 'Mack Anthem 64T', VehicleType.semi, 2018,
        VehicleStatus.maintenance, VehicleCondition.urgent, const Offset(0.19, 0.58),
        odo: 512800, eco: 68, eff: 2.6),
    mkV('v13', 'NY 5W 7761', 'Hino 338', VehicleType.box, 2022,
        VehicleStatus.onRoute, VehicleCondition.good, const Offset(0.64, 0.24),
        driver: 'd3', fuel: 0.69, odo: 133500, eco: 88, spd: 63, hdg: 352, eff: 3.9, tank: 220, co2: 35),
    mkV('v14', 'NY 6Y 2295', 'Peterbilt 389 Reefer', VehicleType.reefer, 2019,
        VehicleStatus.offline, VehicleCondition.urgent, const Offset(0.16, 0.20),
        odo: 448920, eco: 70, eff: 2.3, co2: 78),
  ];
  vehicles[8].driverId = 'd6'; // v9 tanker → Tomás Silva
  vehicles[3].activeTripId = null;

  // ── Trips ────────────────────────────────────────────────────────────────
  Trip mkTrip(
    String id,
    String vid,
    String did,
    String org,
    String dst,
    String cargo,
    double km,
    double prog,
    int eta,
    List<Offset> wp, {
    int dly = 0,
    TripStatus st = TripStatus.enRoute,
    double? setpoint,
    double w = 18,
  }) =>
      Trip(
        id: id,
        vehicleId: vid,
        driverId: did,
        origin: org,
        destination: dst,
        cargo: cargo,
        weightT: w,
        distanceKm: km,
        progressPct: prog,
        etaMinutes: eta,
        delayMinutes: dly,
        status: st,
        waypoints: wp,
        reeferSetpointC: setpoint,
      );

  final trips = <Trip>[
    mkTrip('t1', 'v1', 'd0', 'Central Depot', 'East DC', 'Beverage pallets', 96, 0.38, 64,
        [kDepot, const Offset(0.34, 0.62), const Offset(0.52, 0.55), const Offset(0.66, 0.44), kEastDc],
        w: 21),
    mkTrip('t2', 'v2', 'd1', 'Port Terminal', 'North Warehouse', 'Imported electronics', 154, 0.62, 47,
        [kPort, const Offset(0.76, 0.66), const Offset(0.60, 0.50), const Offset(0.44, 0.30), kNorthWh],
        w: 24),
    mkTrip('t3', 'v3', 'd2', 'North Warehouse', 'Airport Cargo', 'Air-freight transfers', 71, 0.21, 88,
        [kNorthWh, const Offset(0.26, 0.16), kAirport],
        dly: 14, st: TripStatus.atRisk, w: 12),
    mkTrip('t4', 'v4', 'd4', 'East DC', 'Port Terminal', 'Frozen seafood', 118, 0.55, 39,
        [kEastDc, const Offset(0.74, 0.52), const Offset(0.82, 0.64), kPort],
        setpoint: -20, w: 19),
    mkTrip('t5', 'v5', 'd8', 'Central Depot', 'North Warehouse', 'Dairy products', 82, 0.44, 71,
        [kDepot, const Offset(0.28, 0.52), const Offset(0.32, 0.30), kNorthWh],
        setpoint: 2, w: 16),
    mkTrip('t6', 'v6', 'd5', 'Central Depot', 'East DC', 'Parcel freight', 44, 0.72, 26,
        [kDepot, const Offset(0.38, 0.58), const Offset(0.56, 0.46), kEastDc],
        w: 6),
    mkTrip('t8', 'v8', 'd9', 'East DC', 'Port Terminal', 'Bulk lubricants', 88, 0.31, 92,
        [kEastDc, const Offset(0.70, 0.55), const Offset(0.80, 0.66), kPort],
        dly: 22, st: TripStatus.atRisk, w: 27),
    mkTrip('t9', 'v9', 'd6', 'North Warehouse', 'Central Depot', 'Liquid sweeteners', 105, 0.18, 108,
        [kNorthWh, const Offset(0.36, 0.26), const Offset(0.30, 0.44), kDepot],
        w: 25),
    mkTrip('t10', 'v10', 'd7', 'Central Depot', 'Airport Cargo', 'Courier documents', 58, 0.81, 15,
        [kDepot, const Offset(0.18, 0.50), const Offset(0.14, 0.24), kAirport],
        w: 1.2),
    mkTrip('t13', 'v13', 'd3', 'East DC', 'North Warehouse', 'Auto parts', 127, 0.12, 96,
        [kEastDc, const Offset(0.58, 0.26), kNorthWh],
        w: 14),
  ];

  // Bind active trips to vehicles.
  for (final t in trips) {
    final v = vehicles.firstWhere((e) => e.id == t.vehicleId);
    v.activeTripId = t.id;
    v.pos = t.posAt(t.progressPct);
  }

  // ── Maintenance ──────────────────────────────────────────────────────────
  MaintenanceItem mkM(
    String id,
    String vid,
    MaintenanceKind k,
    MaintenanceStatus st,
    String title,
    String part,
    int dkm,
    int cf,
    double cost,
    double dt, {
    DateTime? dd,
  }) =>
      MaintenanceItem(
        id: id, vehicleId: vid, kind: k, status: st, title: title, part: part,
        dueInKm: dkm, confidencePct: cf, costEstUsd: cost, downtimeHours: dt, dueDate: dd,
      );

  final maintenance = <MaintenanceItem>[
    mkM('m1', 'v3', MaintenanceKind.preventive, MaintenanceStatus.predicted, 'DPF filter regeneration required', 'Aftertreatment DPF', 640, 92, 890, 6),
    mkM('m2', 'v8', MaintenanceKind.preventive, MaintenanceStatus.scheduled, 'Axle-3 tire replacement (sensor fault)', 'Drive tires 11R22.5', 180, 97, 2400, 8, dd: now.add(const Duration(days: 2))),
    mkM('m3', 'v1', MaintenanceKind.corrective, MaintenanceStatus.scheduled, 'Fuel tank leak repair — line seal', 'Fuel line seal kit', 0, 99, 620, 5, dd: now.add(const Duration(days: 1))),
    mkM('m4', 'v12', MaintenanceKind.corrective, MaintenanceStatus.inProgress, 'Transmission rebuild', 'Eaton 13-speed', 0, 100, 5800, 42),
    mkM('m5', 'v5', MaintenanceKind.preventive, MaintenanceStatus.predicted, 'Reefer compressor wear detected', 'ThermoKing compressor', 2300, 84, 1900, 10),
    mkM('m6', 'v14', MaintenanceKind.preventive, MaintenanceStatus.scheduled, 'Battery bank replacement', 'AGM 4-bank', 400, 95, 780, 3, dd: now.add(const Duration(days: 4))),
    mkM('m7', 'v9', MaintenanceKind.preventive, MaintenanceStatus.predicted, 'Brake pad wear — rear axle', 'Air disc pads', 1450, 88, 1100, 6),
    mkM('m8', 'v7', MaintenanceKind.preventive, MaintenanceStatus.predicted, 'Coolant flush overdue', 'Cooling system', 200, 76, 340, 4),
    mkM('m9', 'v2', MaintenanceKind.preventive, MaintenanceStatus.completed, 'Scheduled oil service', 'Engine oil + filters', 0, 100, 480, 2),
    mkM('m10', 'v4', MaintenanceKind.preventive, MaintenanceStatus.completed, 'Reefer PM inspection', 'Reefer unit', 0, 100, 350, 3),
    mkM('m11', 'v11', MaintenanceKind.preventive, MaintenanceStatus.completed, 'Brake inspection', 'Hydraulic brakes', 0, 100, 260, 2),
    mkM('m12', 'v6', MaintenanceKind.preventive, MaintenanceStatus.predicted, 'Wheel bearing noise pattern', 'Front bearings', 3100, 81, 920, 7),
  ];

  // ── Fuel history (last 30 days, deterministic) ──────────────────────────
  final stationsNames = ['Fleet Fuel Stop', 'Highway Plaza', 'Port Fuel'];
  final fuelEvents = <FuelEvent>[];
  var fid = 0;
  for (var d = 29; d >= 0; d--) {
    final n = 2 + rnd.nextInt(3);
    for (var k = 0; k < n; k++) {
      final vid = vehicles[rnd.nextInt(vehicles.length)].id;
      final odoBase = vehicles.firstWhere((e) => e.id == vid).odometerKm;
      fuelEvents.add(FuelEvent(
        id: 'fe${fid++}',
        vehicleId: vid,
        date: DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: d))
            .add(Duration(hours: 6 + rnd.nextInt(14))),
        liters: 120 + rnd.nextDouble() * 420,
        costPerLiter: 1.52 + rnd.nextDouble() * 0.22,
        odometerKm: odoBase - (d * 90 + rnd.nextDouble() * 80),
        station: stationsNames[rnd.nextInt(stationsNames.length)],
      ));
    }
  }

  // ── Alerts (history + live) ──────────────────────────────────────────────
  FleetAlert mkA(
    String id,
    AlertType ty,
    AlertSeverity sv,
    String t,
    String m,
    Duration ago, {
    String? vid,
    String? did,
    AlertStatus st = AlertStatus.active,
    Map<String, String> fx = const {},
  }) =>
      FleetAlert(
        id: id, type: ty, severity: sv, title: t, message: m,
        vehicleId: vid, driverId: did,
        timestamp: now.subtract(ago),
        status: st, facts: fx,
      );

  final alerts = <FleetAlert>[
    // The guide's flagship example (p. 26) — live and unresolved.
    mkA('a1', AlertType.fuelLeak, AlertSeverity.urgent, 'Truck fuel tank leakage',
        'Fuel-level sensor reports 4.2% drop per hour while parked. Suspected line seal failure.',
        const Duration(minutes: 14),
        vid: 'v1', did: 'd0',
        fx: {'Condition': 'Satisfactory', 'Truck': 'NY 0Q 8214', 'Driver': 'Derrick Reyes', 'Drop rate': '4.2%/h'}),
    mkA('a2', AlertType.tirePressure, AlertSeverity.urgent, 'Tire pressure fault — axle 3',
        'TPMS sensor reports 68 psi vs 100 psi target on axle 3, inner-left. Risk of blowout at speed.',
        const Duration(minutes: 32),
        vid: 'v8', did: 'd9',
        fx: {'Measured': '68 psi', 'Target': '100 psi', 'Axle': '3 inner-left'}),
    mkA('a3', AlertType.sos, AlertSeverity.critical, 'SOS button pressed',
        'Driver-initiated SOS from I-95 corridor. Automatic assistance dispatch recommended.',
        const Duration(hours: 3),
        vid: 'v11', did: 'd3', st: AlertStatus.resolved,
        fx: {'Location': 'I-95 mm 42', 'Response': 'Roadside dispatched', 'Resolution': 'Flat tire — towed'}),
    mkA('a4', AlertType.eldViolation, AlertSeverity.warning, 'HOS cycle at 95%',
        'Tomás Silva has used 66.5 of 70 cycle hours. Mandatory 34-hour reset required within 3.5 hours.',
        const Duration(hours: 1),
        did: 'd6', vid: 'v9'),
    mkA('a5', AlertType.tempExcursion, AlertSeverity.warning, 'Reefer temp excursion',
        'Cargo temperature -14.8 C exceeded setpoint tolerance (-20 C ± 5) for 22 minutes.',
        const Duration(hours: 2),
        vid: 'v5', did: 'd8', st: AlertStatus.acknowledged,
        fx: {'Setpoint': '-20.0 C', 'Measured': '-14.8 C', 'Duration': '22 min'}),
    mkA('a6', AlertType.harshBraking, AlertSeverity.warning, 'Harsh braking event',
        'Deceleration 0.41 g detected. Speed 58 → 12 mph in 3.1 s.',
        const Duration(hours: 5),
        vid: 'v6', did: 'd5', st: AlertStatus.resolved),
    mkA('a7', AlertType.geofenceExit, AlertSeverity.info, 'After-hours geofence exit',
        'NY 9X 4402 exited Central Depot outside operating window (23:40). Review authorized.',
        const Duration(hours: 9),
        vid: 'v7', st: AlertStatus.acknowledged),
    mkA('a8', AlertType.maintenanceDue, AlertSeverity.info, 'Predicted service window opened',
        'AI model predicts DPF regeneration due within 640 km (92% confidence).',
        const Duration(hours: 11),
        vid: 'v3', st: AlertStatus.acknowledged),
    mkA('a9', AlertType.collision, AlertSeverity.critical, 'Collision detected',
        'Accelerometer signature consistent with low-speed rear impact. Dash-cam clip uploaded.',
        const Duration(days: 2),
        vid: 'v12', did: 'd3', st: AlertStatus.resolved,
        fx: {'Impact speed': '9 mph', 'Airbags': 'Not deployed', 'Video': 'Available', 'Tow': 'Not required'}),
    mkA('a10', AlertType.idling, AlertSeverity.info, 'Excess idling',
        'Engine idled 38 minutes at East DC dock. Idle fuel cost est. \$6.20.',
        const Duration(days: 1),
        vid: 'v7', st: AlertStatus.resolved),
    mkA('a11', AlertType.speeding, AlertSeverity.warning, 'Speeding — 12 mph over limit',
        'Posted 55 mph zone. Speed 67 mph sustained for 4 minutes.',
        const Duration(days: 1, hours: 4),
        vid: 'v5', did: 'd8', st: AlertStatus.resolved),
    mkA('a12', AlertType.eldViolation, AlertSeverity.urgent, 'ELD connection error',
        'Electronic logging device lost connection for 18 minutes during transit.',
        const Duration(hours: 6),
        vid: 'v9', did: 'd6', st: AlertStatus.acknowledged),
  ];

  // Backfill driver vehicle assignments.
  for (final v in vehicles) {
    if (v.driverId != null) {
      drivers.firstWhere((d) => d.id == v.driverId).vehicleId = v.id;
    }
  }

  return SeedData(
    vehicles: vehicles,
    drivers: drivers,
    trips: trips,
    alerts: alerts,
    maintenance: maintenance,
    fuelEvents: fuelEvents,
    geofences: geofences,
    stations: stations,
  );
}
