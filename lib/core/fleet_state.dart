import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:math';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'seed.dart';

/// Root observable state: fleet data + real-time telematics simulation +
/// persistence + derived analytics used by every screen.
class AppState extends ChangeNotifier {
  AppState() {
    _load();
  }

  static const _storageKey = 'kompact_fms_v2';

  // ── Data ─────────────────────────────────────────────────────────────────
  late List<Vehicle> vehicles;
  late List<Driver> drivers;
  late List<Trip> trips;
  late List<FleetAlert> alerts;
  late List<MaintenanceItem> maintenance;
  late List<FuelEvent> fuelEvents;
  List<Geofence> geofences = [];
  List<Station> stations = [];
  AppSettings settings = AppSettings();

  bool loaded = false;

  // ── Simulation ───────────────────────────────────────────────────────────
  Timer? _timer;
  final Random _rnd = Random();
  int _tick = 0;
  int _tripSeq = 100;
  int _alertSeq = 100;

  /// Live sparkline buffers (last 60 samples ≈ 2 min at default speed).
  final List<double> fleetSpeedHistory = [];
  final List<double> onRouteHistory = [];

  double litersConsumedToday = 0;
  double kmDrivenToday = 0;
  double co2KgToday = 0;

  /// Deterministic utilization heatmap: 7 days × 24 hours, 0..1.
  late final List<List<double>> utilizationHeat = _buildHeat();

  // ── Load / persist ───────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        _fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } else {
        _installSeed();
        await _persist();
      }
    } catch (_) {
      _installSeed();
    }
    loaded = true;
    _startTimer();
    notifyListeners();
  }

  void _installSeed() {
    final s = buildSeed();
    vehicles = s.vehicles;
    drivers = s.drivers;
    trips = s.trips;
    alerts = s.alerts;
    maintenance = s.maintenance;
    fuelEvents = s.fuelEvents;
    geofences = s.geofences;
    stations = s.stations;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(toMap()));
    } catch (_) {
      // Persistence is best-effort; the demo fleet re-seeds if unavailable.
    }
  }

  Map<String, dynamic> toMap() => {
        'v': 2,
        'vehicles': vehicles.map((e) => e.toJson()).toList(),
        'drivers': drivers.map((e) => e.toJson()).toList(),
        'trips': trips.map((e) => e.toJson()).toList(),
        'alerts': alerts.map((e) => e.toJson()).toList(),
        'maintenance': maintenance.map((e) => e.toJson()).toList(),
        'fuel': fuelEvents.map((e) => e.toJson()).toList(),
        'geofences': geofences.map((e) => e.toJson()).toList(),
        'settings': settings.toJson(),
        'seq': {'trip': _tripSeq, 'alert': _alertSeq, 'tick': _tick},
        'today': {'l': litersConsumedToday, 'km': kmDrivenToday, 'co2': co2KgToday},
      };

  void _fromJson(Map<String, dynamic> j) {
    _installSeed(); // geofences/stations are static
    if (j['v'] != 2) return;
    vehicles = _list(j['vehicles'], Vehicle.fromJson) ?? vehicles;
    drivers = _list(j['drivers'], Driver.fromJson) ?? drivers;
    trips = _list(j['trips'], Trip.fromJson) ?? trips;
    alerts = _list(j['alerts'], FleetAlert.fromJson) ?? alerts;
    maintenance = _list(j['maintenance'], MaintenanceItem.fromJson) ?? maintenance;
    fuelEvents = _list(j['fuel'], FuelEvent.fromJson) ?? fuelEvents;
    final gf = _list(j['geofences'], Geofence.fromJson);
    if (gf != null && gf.isNotEmpty) geofences = gf;
    settings = AppSettings.fromJson(Map<String, dynamic>.from(j['settings'] as Map));
    final seq = (j['seq'] as Map?)?.cast<String, dynamic>();
    _tripSeq = (seq?['trip'] as int?) ?? 100;
    _alertSeq = (seq?['alert'] as int?) ?? 100;
    _tick = (seq?['tick'] as int?) ?? 0;
    final today = (j['today'] as Map?)?.cast<String, dynamic>();
    litersConsumedToday = (today?['l'] as num?)?.toDouble() ?? 0;
    kmDrivenToday = (today?['km'] as num?)?.toDouble() ?? 0;
    co2KgToday = (today?['co2'] as num?)?.toDouble() ?? 0;
  }

  static List<T>? _list<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw is! List) return null;
    try {
      return raw.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> resetDemoData() async {
    _installSeed();
    litersConsumedToday = 0;
    kmDrivenToday = 0;
    co2KgToday = 0;
    fleetSpeedHistory.clear();
    onRouteHistory.clear();
    _tick = 0;
    await _persist();
    notifyListeners();
  }

  // ── Timer ────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _advance());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void setSimRunning(bool running) {
    settings.simRunning = running;
    _persist();
    notifyListeners();
  }

  void setSimSpeed(double speed) {
    settings.simSpeed = speed;
    _persist();
    notifyListeners();
  }

  // ── Simulation tick ──────────────────────────────────────────────────────

  void _advance() {
    if (!settings.simRunning || !loaded) return;
    final mult = settings.simSpeed;
    _tick++;

    final onRoute = <Vehicle>[];
    for (final v in vehicles) {
      switch (v.status) {
        case VehicleStatus.onRoute:
          onRoute.add(v);
          _advanceOnRoute(v, mult);
        case VehicleStatus.idle:
          v.idleMinutesToday += (2 * mult).round();
          if (v.idleMinutesToday > 45 && _rnd.nextDouble() < 0.06 * mult) {
            _emitAlert(
              type: AlertType.idling,
              severity: AlertSeverity.info,
              title: 'Excess idling',
              message:
                  '${v.plate} idled ${v.idleMinutesToday} min at ${_geofenceName(v.geofenceId)}. Idle cost est. \$${(v.idleMinutesToday * 0.16).toStringAsFixed(2)}.',
              vehicle: v,
            );
            v.idleMinutesToday = 0;
          }
        case VehicleStatus.maintenance:
          if (_tick % 15 == 0) {
            final item = maintenance
                .where((m) => m.vehicleId == v.id && m.status == MaintenanceStatus.inProgress)
                .firstOrNull;
            if (item != null) {
              item.status = MaintenanceStatus.completed;
              v.condition = VehicleCondition.satisfactory;
              v.status = VehicleStatus.idle;
              v.dtcCodes = v.dtcCodes
                  .map((c) => c.active ? DtcCode(code: c.code, description: c.description, active: false) : c)
                  .toList();
            }
          }
        case VehicleStatus.offline:
          break;
      }
    }

    // Sparkline buffers.
    final avgSpeed = onRoute.isEmpty ? 0.0 : onRoute.map((v) => v.speedKmh).reduce((a, b) => a + b) / onRoute.length;
    fleetSpeedHistory.add(avgSpeed);
    onRouteHistory.add(onRoute.length.toDouble());
    if (fleetSpeedHistory.length > 60) fleetSpeedHistory.removeAt(0);
    if (onRouteHistory.length > 60) onRouteHistory.removeAt(0);

    // Random live events.
    if (settings.alertsEnabled && onRoute.isNotEmpty && _rnd.nextDouble() < 0.10 * mult) {
      _emitRandomEvent(onRoute);
    }

    if (_tick % 30 == 0) _persist();
    notifyListeners();
  }

  void _advanceOnRoute(Vehicle v, double mult) {
    final trip = trips.where((t) => t.id == v.activeTripId).firstOrNull;
    if (trip == null) return;

    // Speed model: relax toward cruise speed with jitter.
    final cruise = v.type == VehicleType.van ? 62.0 : 78.0;
    v.speedKmh = (v.speedKmh * 0.6 + cruise * 0.4 + (_rnd.nextDouble() * 10 - 5)).clamp(28, 96);
    v.engineTempC = (v.engineTempC * 0.85 + (84 + _rnd.nextDouble() * 6) * 0.15).clamp(78, 102);
    v.headingDeg = _headingToward(trip.waypoints, trip.progressPct);

    final hoursAdvanced = (v.speedKmh / 3600) * 2 * mult;
    final km = v.speedKmh / 3600 * 2 * mult;
    v.odometerKm += km;
    kmDrivenToday += km;
    co2KgToday += km * v.co2KgPer100Km / 100;

    final liters = km / v.efficiencyKmpl;
    litersConsumedToday += liters;
    v.fuelLevelPct = (v.fuelLevelPct - liters / v.tankCapacityL * 100).clamp(2, 100);
    v.sensors = v.sensors.copyWith(
      cargoTempC: (v.sensors.cargoTempC * 0.9 + _targetTemp(v) * 0.1),
      tirePressurePsi: (v.sensors.tirePressurePsi * 0.95 + (98 + _rnd.nextDouble() * 8) * 0.05),
      batteryVoltage: (v.sensors.batteryVoltage * 0.9 + (13.4 + _rnd.nextDouble() * 0.6) * 0.1),
    );

    // Trip progress.
    final totalKm = max(trip.distanceKm, 1);
    trip.progressPct = (trip.progressPct + km / totalKm * 100).clamp(0, 100);
    v.pos = trip.posAt(trip.progressPct / 100);
    final remainingKm = totalKm * (1 - trip.progressPct / 100);
    trip.etaMinutes = max(1, (remainingKm / max(v.speedKmh, 30) * 60).round());
    if (trip.delayMinutes > 0 && _rnd.nextBool()) trip.delayMinutes--;

    // Driver HOS accumulates while driving.
    final d = drivers.where((x) => x.id == v.driverId).firstOrNull;
    if (d != null) {
      d.hosHoursToday += hoursAdvanced;
      d.hosCycleUsed = min(d.hosCycleLimit, d.hosCycleUsed + hoursAdvanced);
      if (d.hosRisk && _rnd.nextDouble() < 0.02) {
        _emitAlert(
          type: AlertType.eldViolation,
          severity: AlertSeverity.warning,
          title: 'HOS limit approaching',
          message:
              '${d.name} has ${d.hosRemaining.toStringAsFixed(1)} cycle-hours remaining. Plan a reset.',
          vehicle: v,
          driver: d,
        );
      }
    }

    // Arrival.
    if (trip.progressPct >= 99.9) {
      _completeTrip(trip, v);
    }
  }

  double _targetTemp(Vehicle v) {
    final trip = trips.where((t) => t.id == v.activeTripId).firstOrNull;
    if (v.type == VehicleType.reefer && trip?.reeferSetpointC != null) {
      return trip!.reeferSetpointC! + _rnd.nextDouble() * 2;
    }
    return 6 + _rnd.nextDouble() * 6;
  }

  double _headingToward(List<Offset> wp, double t) {
    if (wp.length < 2) return 0;
    final segCount = wp.length - 1;
    final scaled = (t.clamp(0.0, 0.999)) * segCount;
    final i = scaled.floor().clamp(0, segCount - 1);
    final a = wp[i], b = wp[i + 1];
    final deg = atan2(b.dy - a.dy, b.dx - a.dx) * 180 / pi;
    return (deg + 90) % 360; // 0 = up
  }

  void _completeTrip(Trip trip, Vehicle v) {
    trip.status = TripStatus.delivered;
    trip.etaMinutes = 0;
    v.status = VehicleStatus.idle;
    v.speedKmh = 0;
    v.activeTripId = null;
    v.idleMinutesToday = 0;
    v.pos = trip.waypoints.last;

    final gf = _nearestGeofence(v.pos);
    if (gf != null) v.geofenceId = gf.id;

    final d = drivers.where((x) => x.id == trip.driverId).firstOrNull;
    if (d != null) d.tripsCompleted++;

    _emitAlert(
      type: AlertType.geofenceExit,
      severity: AlertSeverity.info,
      title: 'Delivery completed',
      message:
          '${v.plate} arrived at ${trip.destination} (${trip.cargo}, ${trip.weightT.toStringAsFixed(1)} t). POD captured via e-signature.',
      vehicle: v,
      driver: d,
    );

    // Trim old delivered trips, then dispatch a fresh load after a rest.
    if (trips.length > 14) {
      trips.removeWhere((t) => t.status == TripStatus.delivered && t.id != trip.id);
    }
    final restSeconds = (14 / settings.simSpeed).round();
    Future.delayed(Duration(seconds: restSeconds), () {
      if (v.status == VehicleStatus.idle) _dispatchNewTrip(v);
      notifyListeners();
    });
  }

  void _dispatchNewTrip(Vehicle v) {
    final from = _nearestGeofence(v.pos) ?? geofences.first;
    final to = geofences.where((g) => g.id != from.id).toList()..shuffle(_rnd);
    if (to.isEmpty) return;
    final dest = to.first;
    final via = Offset(
      (from.center.dx + dest.center.dx) / 2 + (_rnd.nextDouble() * 0.12 - 0.06),
      (from.center.dy + dest.center.dy) / 2 + (_rnd.nextDouble() * 0.12 - 0.06),
    );
    final km = (from.center - dest.center).distance * 320 + 28;
    final d = drivers.where((x) => x.id == v.driverId).firstOrNull;
    final trip = Trip(
      id: 't${_tripSeq++}',
      vehicleId: v.id,
      driverId: d?.id ?? drivers.first.id,
      origin: from.name,
      destination: dest.name,
      cargo: _randomCargo(v.type),
      weightT: (4 + _rnd.nextDouble() * 22),
      distanceKm: km,
      progressPct: 0,
      etaMinutes: (km / 70 * 60).round(),
      delayMinutes: 0,
      status: TripStatus.enRoute,
      waypoints: [from.center, via, dest.center],
      reeferSetpointC: v.type == VehicleType.reefer ? -20 : null,
    );
    trips.add(trip);
    v.activeTripId = trip.id;
    v.status = VehicleStatus.onRoute;
    v.geofenceId = from.id;
    v.speedKmh = 40;
    notifyListeners();
  }

  String _randomCargo(VehicleType t) => switch (t) {
        VehicleType.reefer => ['Frozen vegetables', 'Ice cream', 'Fresh meat', 'Dairy', 'Pharma cold-chain'][_rnd.nextInt(5)],
        VehicleType.tanker => ['Bulk lubricants', 'Liquid sweeteners', 'Water treatment chems', 'Molasses'][_rnd.nextInt(4)],
        VehicleType.van => ['Courier parcels', 'Spare parts', 'Documents', 'Lab samples'][_rnd.nextInt(4)],
        _ => ['Beverage pallets', 'Building materials', 'Retail freight', 'Auto parts', 'Paper products'][_rnd.nextInt(5)],
      };

  Geofence? _nearestGeofence(Offset p) {
    Geofence? best;
    var bestD = double.infinity;
    for (final g in geofences) {
      final d = (g.center - p).distance;
      if (d < bestD) {
        bestD = d;
        best = g;
      }
    }
    return best;
  }

  String _geofenceName(String id) => geofences.where((g) => g.id == id).firstOrNull?.name ?? 'depot';

  // ── Random event engine ──────────────────────────────────────────────────

  void _emitRandomEvent(List<Vehicle> onRoute) {
    final v = onRoute[_rnd.nextInt(onRoute.length)];
    final d = drivers.where((x) => x.id == v.driverId).firstOrNull;
    final roll = _rnd.nextDouble();
    if (roll < 0.30) {
      v.harshEventsToday++;
      if (d != null) {
        d.behavior = DriverBehavior(
          harshBraking30d: d.behavior.harshBraking30d + 1,
          harshAccel30d: d.behavior.harshAccel30d,
          speeding30d: d.behavior.speeding30d,
          seatbeltViolations30d: d.behavior.seatbeltViolations30d,
        );
        d.safetyScore = (d.safetyScore - 0.4).clamp(40, 100);
      }
      _emitAlert(
        type: AlertType.harshBraking,
        severity: AlertSeverity.warning,
        title: 'Harsh braking event',
        message:
            'Deceleration ${0.3 + _rnd.nextDouble() * 0.15} g detected. Speed ${v.speedKmh.round()} → ${(v.speedKmh * 0.3).round()} km/h.',
        vehicle: v,
        driver: d,
      );
    } else if (roll < 0.52) {
      if (d != null) {
        d.behavior = DriverBehavior(
          harshBraking30d: d.behavior.harshBraking30d,
          harshAccel30d: d.behavior.harshAccel30d,
          speeding30d: d.behavior.speeding30d + 1,
          seatbeltViolations30d: d.behavior.seatbeltViolations30d,
        );
      }
      _emitAlert(
        type: AlertType.speeding,
        severity: AlertSeverity.warning,
        title: 'Speeding event',
        message:
            'Speed ${v.speedKmh.round()} km/h in an ${(v.speedKmh - 14).round()} km/h zone, sustained ${2 + _rnd.nextInt(4)} min.',
        vehicle: v,
        driver: d,
      );
    } else if (roll < 0.66 && v.type == VehicleType.reefer) {
      _emitAlert(
        type: AlertType.tempExcursion,
        severity: AlertSeverity.warning,
        title: 'Reefer temp excursion',
        message: 'Cargo temperature ${(-12 + _rnd.nextDouble() * 6).toStringAsFixed(1)} C outside tolerance band.',
        vehicle: v,
        driver: d,
        facts: {'Measured': '${(-12 + _rnd.nextDouble() * 6).toStringAsFixed(1)} C', 'Setpoint': '-20.0 C'},
      );
    } else if (roll < 0.78) {
      _emitAlert(
        type: AlertType.geofenceExit,
        severity: AlertSeverity.info,
        title: 'Geofence event',
        message: '${v.plate} crossed ${_geofenceName(v.geofenceId)} boundary. Route adherence nominal.',
        vehicle: v,
        driver: d,
      );
    } else if (roll < 0.90) {
      _emitAlert(
        type: AlertType.tirePressure,
        severity: AlertSeverity.urgent,
        title: 'Tire pressure dropping',
        message:
            'TPMS reports ${(70 + _rnd.nextDouble() * 15).toStringAsFixed(0)} psi on a drive axle (target 100 psi). Inspect at next stop.',
        vehicle: v,
        driver: d,
      );
    } else {
      _emitAlert(
        type: AlertType.sos,
        severity: AlertSeverity.critical,
        title: 'SOS button pressed',
        message: 'Driver-initiated emergency. Location, telemetry and dash-cam clip attached for responders.',
        vehicle: v,
        driver: d,
        facts: {
          'Location': '${_geofenceName(v.geofenceId)} corridor',
          'Speed': '${v.speedKmh.round()} km/h',
          'Video': 'Uploading',
        },
      );
    }
  }

  void _emitAlert({
    required AlertType type,
    required AlertSeverity severity,
    required String title,
    required String message,
    Vehicle? vehicle,
    Driver? driver,
    Map<String, String> facts = const {},
  }) {
    alerts.insert(
      0,
      FleetAlert(
        id: 'a${_alertSeq++}',
        type: type,
        severity: severity,
        title: title,
        message: message,
        vehicleId: vehicle?.id,
        driverId: driver?.id,
        timestamp: DateTime.now(),
        facts: facts,
      ),
    );
    if (alerts.length > 80) alerts.removeRange(80, alerts.length);
  }

  // ── User actions ─────────────────────────────────────────────────────────

  void acknowledgeAlert(String id) {
    final a = alerts.where((x) => x.id == id).firstOrNull;
    if (a == null) return;
    a.status = AlertStatus.acknowledged;
    _persist();
    notifyListeners();
  }

  void resolveAlert(String id) {
    final a = alerts.where((x) => x.id == id).firstOrNull;
    if (a == null) return;
    a.status = AlertStatus.resolved;
    _persist();
    notifyListeners();
  }

  /// Dispatch roadside assistance for an SOS / critical alert (guide p. 17).
  void dispatchRoadside(String alertId) {
    final a = alerts.where((x) => x.id == alertId).firstOrNull;
    if (a == null) return;
    a.status = AlertStatus.acknowledged;
    alerts.insert(
      0,
      FleetAlert(
        id: 'a${_alertSeq++}',
        type: AlertType.sos,
        severity: AlertSeverity.info,
        title: 'Roadside assistance dispatched',
        message:
            '24/7 helpline unit en route to ${a.facts['Location'] ?? 'last known position'}. ETA 28 min. Towing + battery service on standby.',
        vehicleId: a.vehicleId,
        driverId: a.driverId,
        timestamp: DateTime.now(),
      ),
    );
    _persist();
    notifyListeners();
  }

  void scheduleMaintenance(String id) {
    final m = maintenance.where((x) => x.id == id).firstOrNull;
    if (m == null) return;
    m.status = MaintenanceStatus.scheduled;
    m.dueDate ??= DateTime.now().add(const Duration(days: 3));
    _persist();
    notifyListeners();
  }

  void startMaintenance(String id) {
    final m = maintenance.where((x) => x.id == id).firstOrNull;
    if (m == null) return;
    m.status = MaintenanceStatus.inProgress;
    final v = vehicles.where((x) => x.id == m.vehicleId).firstOrNull;
    if (v != null) {
      v.status = VehicleStatus.maintenance;
      v.speedKmh = 0;
      v.activeTripId = null;
    }
    _persist();
    notifyListeners();
  }

  void completeMaintenance(String id) {
    final m = maintenance.where((x) => x.id == id).firstOrNull;
    if (m == null) return;
    m.status = MaintenanceStatus.completed;
    final v = vehicles.where((x) => x.id == m.vehicleId).firstOrNull;
    if (v != null) {
      v.status = VehicleStatus.idle;
      v.dtcCodes = v.dtcCodes
          .map((c) => c.active ? DtcCode(code: c.code, description: c.description, active: false) : c)
          .toList();
      if (v.condition == VehicleCondition.critical || v.condition == VehicleCondition.urgent) {
        v.condition = VehicleCondition.satisfactory;
      }
    }
    _persist();
    notifyListeners();
  }

  /// Plan a refuel stop using the closest-point spatial op (guide p. 25).
  Station? closestFuelStation(Vehicle v) {
    Station? best;
    var bestD = double.infinity;
    for (final s in stations.where((s) => s.brand == 'fuel')) {
      final d = (s.center - v.pos).distance;
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
    return best;
  }

  /// Simulated refuel action on a vehicle.
  void refuelVehicle(String vehicleId) {
    final v = vehicles.where((x) => x.id == vehicleId).firstOrNull;
    if (v == null) return;
    final station = closestFuelStation(v);
    final liters = v.tankCapacityL * (1 - v.fuelLevelPct / 100);
    fuelEvents.add(FuelEvent(
      id: 'fe${DateTime.now().millisecondsSinceEpoch}',
      vehicleId: v.id,
      date: DateTime.now(),
      liters: liters,
      costPerLiter: 1.58,
      odometerKm: v.odometerKm,
      station: station?.name ?? 'Fleet Fuel Stop',
    ));
    v.fuelLevelPct = 100;
    _persist();
    notifyListeners();
  }

  void updateSettings(AppSettings next) {
    settings = next;
    _persist();
    notifyListeners();
  }

  // ── Derived analytics ────────────────────────────────────────────────────

  Vehicle? vehicleById(String? id) => id == null ? null : vehicles.where((v) => v.id == id).firstOrNull;
  Driver? driverById(String? id) => id == null ? null : drivers.where((d) => d.id == id).firstOrNull;
  Trip? tripById(String? id) => id == null ? null : trips.where((t) => t.id == id).firstOrNull;
  Trip? tripForVehicle(String? vid) =>
      vid == null ? null : trips.where((t) => t.vehicleId == vid && t.status != TripStatus.delivered).firstOrNull;

  int get onRouteCount => vehicles.where((v) => v.status == VehicleStatus.onRoute).length;
  int get idleCount => vehicles.where((v) => v.status == VehicleStatus.idle).length;
  int get inShopCount => vehicles.where((v) => v.status == VehicleStatus.maintenance).length;
  int get offlineCount => vehicles.where((v) => v.status == VehicleStatus.offline).length;

  int get activeAlertCount => alerts.where((a) => a.status == AlertStatus.active).length;
  int get criticalAlertCount =>
      alerts.where((a) => a.status == AlertStatus.active && a.severity == AlertSeverity.critical).length;
  int get urgentAlertCount =>
      alerts.where((a) => a.status == AlertStatus.active && a.severity == AlertSeverity.urgent).length;

  Map<VehicleCondition, int> get conditionCounts {
    final m = {for (final c in VehicleCondition.values) c: 0};
    for (final v in vehicles) {
      m[v.condition] = (m[v.condition] ?? 0) + 1;
    }
    return m;
  }

  double _avg(Iterable<double> xs) => xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  double get avgSafetyScore => _avg(drivers.map((d) => d.safetyScore));
  double get avgEcoScore => _avg(drivers.map((d) => d.ecoScore));
  double get avgOnTimeRate => _avg(drivers.map((d) => d.onTimeRate));

  double get fleetUtilization => vehicles.isEmpty ? 0 : onRouteCount / vehicles.length;

  double get avgFuelLevel => _avg(vehicles.map((v) => v.fuelLevelPct));

  List<Driver> get driverLeaderboard => [...drivers]..sort((a, b) => b.safetyScore.compareTo(a.safetyScore));

  /// Fuel spend grouped per day for the last [days] days (oldest → newest).
  List<double> fuelCostPerDay(int days) {
    final now = DateTime.now();
    final out = List.filled(days, 0.0);
    for (final e in fuelEvents) {
      final d = DateTime(now.year, now.month, now.day)
          .difference(DateTime(e.date.year, e.date.month, e.date.day))
          .inDays;
      if (d >= 0 && d < days) out[days - 1 - d] += e.totalCost;
    }
    return out;
  }

  double get fuelCost30d => fuelEvents
      .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
      .fold(0, (s, e) => s + e.totalCost);

  double get liters30d => fuelEvents
      .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
      .fold(0, (s, e) => s + e.liters);

  /// Idle-waste estimate for today (guide p. 9: telematics cuts idling).
  double get idleCostToday => vehicles.fold(0, (s, v) => s + v.idleMinutesToday) * 0.16;

  /// CO2 in kg over the last 30 days (guide p. 9: green initiatives).
  double get co2Kg30d {
    var km = 0.0;
    for (final v in vehicles) {
      km += 90 * 30 * (v.status == VehicleStatus.offline ? 0.15 : 1);
    }
    final avgCo2 = _avg(vehicles.map((v) => v.co2KgPer100Km));
    return km * avgCo2 / 100;
  }

  /// Predicted maintenance exposure (open items).
  double get openMaintenanceCost => maintenance
      .where((m) => m.status != MaintenanceStatus.completed)
      .fold(0, (s, m) => s + m.costEstUsd);

  List<List<double>> _buildHeat() {
    final r = Random(11);
    return List.generate(7, (d) => List.generate(24, (h) {
          var v = 0.32 + r.nextDouble() * 0.2;
          if (h >= 7 && h <= 9) v += 0.35;
          if (h >= 16 && h <= 18) v += 0.3;
          if (h >= 10 && h <= 15) v += 0.18;
          if (h >= 22 || h <= 4) v -= 0.12;
          if (d >= 5) v -= 0.08; // weekends
          return v.clamp(0.05, 1.0);
        }));
  }
}
