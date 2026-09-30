import 'package:flutter/material.dart';

/// ── Enums ──────────────────────────────────────────────────────────────────

/// Vehicle condition ladder used across the remote dashboard (guide p. 26).
enum VehicleCondition { good, satisfactory, urgent, critical }

/// Operator personas served by the FMS. Each role gets a dedicated
/// dashboard and a role-filtered navigation set — the same telematics
/// pipeline, framed for the decisions that role actually makes.
enum FleetRole {
  ops,
  dispatcher,
  driver,
  maintenance,
  safety,
  finance,
  executive,
}

/// Live operational status of a vehicle.
enum VehicleStatus { onRoute, idle, maintenance, offline }

/// Fleet asset classes.
enum VehicleType { semi, reefer, box, tanker, van }

/// Alert severity ladder (guide p. 12: real-time violation notifications).
enum AlertSeverity { critical, urgent, warning, info }

/// Telematics event types surfaced by the alert center.
enum AlertType {
  fuelLeak,
  sos,
  collision,
  geofenceExit,
  harshBraking,
  speeding,
  tirePressure,
  eldViolation,
  maintenanceDue,
  tempExcursion,
  idling,
}

enum AlertStatus { active, acknowledged, resolved }

/// Predictive maintenance pipeline (guide p. 23: corrective vs preventive).
enum MaintenanceKind { preventive, corrective }
enum MaintenanceStatus { predicted, scheduled, inProgress, completed }

enum TripStatus { planned, enRoute, atRisk, delivered }

enum EldStatus { connected, syncing, error }

/// ELD duty-status clock states a driver cycles through on a shift.
enum DutyStatus { offDuty, sleeperBerth, onDuty, driving }

/// Work-order priority classes (Fleetio-style shop triage).
enum MaintenancePriority { scheduled, nonScheduled, emergency }

/// Safety-event detection types surfaced in the Safety Inbox.
enum SafetyEventType {
  collision,
  drowsiness,
  distraction,
  harshBraking,
  harshCornering,
  speeding,
  seatbelt,
  followingDistance,
}

/// Triage state of a safety event in the review workflow.
enum SafetyEventStatus { pending, coached, dismissed, recognized }

/// ── Extensions ─────────────────────────────────────────────────────────────

extension FleetRoleX on FleetRole {
  /// Long display name of the persona.
  String get label => switch (this) {
        FleetRole.ops => 'Fleet Manager',
        FleetRole.dispatcher => 'Dispatcher',
        FleetRole.driver => 'Driver',
        FleetRole.maintenance => 'Maintenance Manager',
        FleetRole.safety => 'Safety & Compliance',
        FleetRole.finance => 'Finance & Admin',
        FleetRole.executive => 'Executive',
      };

  /// Short chip label used where horizontal space is scarce.
  String get shortLabel => switch (this) {
        FleetRole.ops => 'Ops',
        FleetRole.dispatcher => 'Dispatch',
        FleetRole.driver => 'Driver',
        FleetRole.maintenance => 'Shop',
        FleetRole.safety => 'Safety',
        FleetRole.finance => 'Finance',
        FleetRole.executive => 'Exec',
      };

  /// Demo operator identity for the role workspace.
  String get demoUser => switch (this) {
        FleetRole.ops => 'Dana Whitfield',
        FleetRole.dispatcher => 'Ray Kowalski',
        FleetRole.driver => 'Derrick Reyes',
        FleetRole.maintenance => 'Sam Okafor',
        FleetRole.safety => 'Priya Sharma',
        FleetRole.finance => 'Elena Marsh',
        FleetRole.executive => 'J. Abernathy',
      };

  /// One-line summary of what this role's dashboard optimizes for.
  String get mandate => switch (this) {
        FleetRole.ops =>
          'Total fleet oversight — utilization, condition, alerts and dispatch health in one board.',
        FleetRole.dispatcher =>
          'Assign drivers to loads, watch ETAs and keep every vehicle earning.',
        FleetRole.driver =>
          'Your vehicle, your trip, your hours — everything needed for a compliant shift.',
        FleetRole.maintenance =>
          'Predictive work orders, vehicle health ranking and shop throughput.',
        FleetRole.safety =>
          'Driver behavior, HOS compliance, violations and incident exposure.',
        FleetRole.finance =>
          'Fuel spend, cost per kilometer, maintenance exposure and tax estimates.',
        FleetRole.executive =>
          'Fleet performance, cost trends and green-initiative progress at a glance.',
      };

  IconData get icon => switch (this) {
        FleetRole.ops => Icons.space_dashboard_rounded,
        FleetRole.dispatcher => Icons.alt_route_rounded,
        FleetRole.driver => Icons.person_rounded,
        FleetRole.maintenance => Icons.build_rounded,
        FleetRole.safety => Icons.health_and_safety_rounded,
        FleetRole.finance => Icons.payments_rounded,
        FleetRole.executive => Icons.insights_rounded,
      };
}

extension DutyStatusX on DutyStatus {
  String get label => switch (this) {
        DutyStatus.offDuty => 'Off Duty',
        DutyStatus.sleeperBerth => 'Sleeper',
        DutyStatus.onDuty => 'On Duty',
        DutyStatus.driving => 'Driving',
      };

  IconData get icon => switch (this) {
        DutyStatus.offDuty => Icons.power_settings_new_rounded,
        DutyStatus.sleeperBerth => Icons.bedtime_rounded,
        DutyStatus.onDuty => Icons.work_outline_rounded,
        DutyStatus.driving => Icons.directions_car_rounded,
      };
}

extension MaintenancePriorityX on MaintenancePriority {
  String get label => switch (this) {
        MaintenancePriority.scheduled => 'Scheduled',
        MaintenancePriority.nonScheduled => 'Non-scheduled',
        MaintenancePriority.emergency => 'Emergency',
      };

  String get short => switch (this) {
        MaintenancePriority.scheduled => 'PM',
        MaintenancePriority.nonScheduled => 'NS',
        MaintenancePriority.emergency => 'EMG',
      };
}

extension SafetyEventTypeX on SafetyEventType {
  String get label => switch (this) {
        SafetyEventType.collision => 'Collision',
        SafetyEventType.drowsiness => 'Drowsiness',
        SafetyEventType.distraction => 'Distraction',
        SafetyEventType.harshBraking => 'Harsh braking',
        SafetyEventType.harshCornering => 'Harsh cornering',
        SafetyEventType.speeding => 'Speeding',
        SafetyEventType.seatbelt => 'Seatbelt',
        SafetyEventType.followingDistance => 'Following distance',
      };

  IconData get icon => switch (this) {
        SafetyEventType.collision => Icons.car_crash_rounded,
        SafetyEventType.drowsiness => Icons.remove_red_eye_outlined,
        SafetyEventType.distraction => Icons.smartphone_rounded,
        SafetyEventType.harshBraking => Icons.compress_rounded,
        SafetyEventType.harshCornering => Icons.u_turn_left_rounded,
        SafetyEventType.speeding => Icons.speed_rounded,
        SafetyEventType.seatbelt => Icons.health_and_safety_outlined,
        SafetyEventType.followingDistance => Icons.social_distance_rounded,
      };

  /// Sort rank used by the Safety Inbox — worst first.
  int get triageRank => switch (this) {
        SafetyEventType.collision => 0,
        SafetyEventType.drowsiness => 1,
        SafetyEventType.distraction => 2,
        SafetyEventType.speeding => 3,
        SafetyEventType.followingDistance => 4,
        SafetyEventType.harshBraking => 5,
        SafetyEventType.harshCornering => 6,
        SafetyEventType.seatbelt => 7,
      };
}

extension VehicleConditionX on VehicleCondition {
  String get label => switch (this) {
        VehicleCondition.good => 'Good',
        VehicleCondition.satisfactory => 'Satisfactory',
        VehicleCondition.urgent => 'Urgent',
        VehicleCondition.critical => 'Critical',
      };
  int get rank => switch (this) {
        VehicleCondition.good => 0,
        VehicleCondition.satisfactory => 1,
        VehicleCondition.urgent => 2,
        VehicleCondition.critical => 3,
      };
}

extension VehicleStatusX on VehicleStatus {
  String get label => switch (this) {
        VehicleStatus.onRoute => 'On route',
        VehicleStatus.idle => 'Idle · depot',
        VehicleStatus.maintenance => 'In shop',
        VehicleStatus.offline => 'Offline',
      };
}

extension VehicleTypeX on VehicleType {
  String get label => switch (this) {
        VehicleType.semi => 'Semi truck',
        VehicleType.reefer => 'Reefer',
        VehicleType.box => 'Box truck',
        VehicleType.tanker => 'Tanker',
        VehicleType.van => 'Cargo van',
      };
  String get short => switch (this) {
        VehicleType.semi => 'SEMI',
        VehicleType.reefer => 'REEF',
        VehicleType.box => 'BOX',
        VehicleType.tanker => 'TNKR',
        VehicleType.van => 'VAN',
      };
}

extension AlertSeverityX on AlertSeverity {
  String get label => name[0].toUpperCase() + name.substring(1);
  int get rank => switch (this) {
        AlertSeverity.critical => 0,
        AlertSeverity.urgent => 1,
        AlertSeverity.warning => 2,
        AlertSeverity.info => 3,
      };
}

extension AlertTypeX on AlertType {
  String get label => switch (this) {
        AlertType.fuelLeak => 'Fuel leak',
        AlertType.sos => 'SOS',
        AlertType.collision => 'Collision',
        AlertType.geofenceExit => 'Geofence exit',
        AlertType.harshBraking => 'Harsh braking',
        AlertType.speeding => 'Speeding',
        AlertType.tirePressure => 'Tire pressure',
        AlertType.eldViolation => 'ELD violation',
        AlertType.maintenanceDue => 'Maintenance due',
        AlertType.tempExcursion => 'Temp excursion',
        AlertType.idling => 'Excess idling',
      };
}

/// ── Models ─────────────────────────────────────────────────────────────────

/// On-board diagnostic trouble code read via telematics.
class DtcCode {
  final String code;
  final String description;
  final bool active;

  const DtcCode({required this.code, required this.description, this.active = true});

  factory DtcCode.fromJson(Map<String, dynamic> j) => DtcCode(
        code: j['code'] as String,
        description: j['description'] as String,
        active: j['active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {'code': code, 'description': description, 'active': active};
}

/// IoT sensor snapshot transmitted by the tracking device (guide p. 12, p. 22).
class SensorSnapshot {
  final double cargoTempC;
  final double humidityPct;
  final double tirePressurePsi;
  final double batteryVoltage;
  final bool cameraFeedOk;
  final bool rfidLoadSealed;

  const SensorSnapshot({
    required this.cargoTempC,
    required this.humidityPct,
    required this.tirePressurePsi,
    required this.batteryVoltage,
    this.cameraFeedOk = true,
    this.rfidLoadSealed = true,
  });

  SensorSnapshot copyWith({
    double? cargoTempC,
    double? humidityPct,
    double? tirePressurePsi,
    double? batteryVoltage,
    bool? cameraFeedOk,
    bool? rfidLoadSealed,
  }) =>
      SensorSnapshot(
        cargoTempC: cargoTempC ?? this.cargoTempC,
        humidityPct: humidityPct ?? this.humidityPct,
        tirePressurePsi: tirePressurePsi ?? this.tirePressurePsi,
        batteryVoltage: batteryVoltage ?? this.batteryVoltage,
        cameraFeedOk: cameraFeedOk ?? this.cameraFeedOk,
        rfidLoadSealed: rfidLoadSealed ?? this.rfidLoadSealed,
      );

  factory SensorSnapshot.fromJson(Map<String, dynamic> j) => SensorSnapshot(
        cargoTempC: (j['t'] as num).toDouble(),
        humidityPct: (j['h'] as num).toDouble(),
        tirePressurePsi: (j['tp'] as num).toDouble(),
        batteryVoltage: (j['bv'] as num).toDouble(),
        cameraFeedOk: j['cam'] as bool? ?? true,
        rfidLoadSealed: j['rfid'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        't': cargoTempC,
        'h': humidityPct,
        'tp': tirePressurePsi,
        'bv': batteryVoltage,
        'cam': cameraFeedOk,
        'rfid': rfidLoadSealed,
      };
}

/// A fleet vehicle with live telematics state.
class Vehicle {
  final String id;
  final String plate;
  final String model;
  final VehicleType type;
  final int year;

  VehicleStatus status;
  VehicleCondition condition;
  String? driverId;

  double odometerKm;
  double speedKmh; // live
  double headingDeg; // live
  Offset pos; // normalized 0..1 map space (live)

  double fuelLevelPct; // live
  final double tankCapacityL;
  final double efficiencyKmpl;

  double engineTempC; // live
  double ecoScore;
  final double co2KgPer100Km;

  String geofenceId; // home zone (mutable: reassigned on arrival)
  String? activeTripId;
  List<DtcCode> dtcCodes;
  SensorSnapshot sensors;
  int idleMinutesToday;
  int harshEventsToday;

  Vehicle({
    required this.id,
    required this.plate,
    required this.model,
    required this.type,
    required this.year,
    required this.status,
    required this.condition,
    this.driverId,
    required this.odometerKm,
    required this.speedKmh,
    required this.headingDeg,
    required this.pos,
    required this.fuelLevelPct,
    required this.tankCapacityL,
    required this.efficiencyKmpl,
    required this.engineTempC,
    required this.ecoScore,
    required this.co2KgPer100Km,
    required this.geofenceId,
    this.activeTripId,
    required this.dtcCodes,
    required this.sensors,
    this.idleMinutesToday = 0,
    this.harshEventsToday = 0,
  });

  bool get hasActiveDtc => dtcCodes.any((c) => c.active);

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        plate: j['plate'] as String,
        model: j['model'] as String,
        type: VehicleType.values.byName(j['type'] as String),
        year: j['year'] as int,
        status: VehicleStatus.values.byName(j['status'] as String),
        condition: VehicleCondition.values.byName(j['condition'] as String),
        driverId: j['driverId'] as String?,
        odometerKm: (j['odo'] as num).toDouble(),
        speedKmh: (j['spd'] as num).toDouble(),
        headingDeg: (j['hdg'] as num).toDouble(),
        pos: Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()),
        fuelLevelPct: (j['fuel'] as num).toDouble(),
        tankCapacityL: (j['tank'] as num).toDouble(),
        efficiencyKmpl: (j['eff'] as num).toDouble(),
        engineTempC: (j['et'] as num).toDouble(),
        ecoScore: (j['eco'] as num).toDouble(),
        co2KgPer100Km: (j['co2'] as num).toDouble(),
        geofenceId: j['gf'] as String,
        activeTripId: j['trip'] as String?,
        dtcCodes: [(j['dtc'] as List?) ?? []].expand((l) => l).map((e) => DtcCode.fromJson(e as Map<String, dynamic>)).toList(),
        sensors: SensorSnapshot.fromJson(j['sen'] as Map<String, dynamic>),
        idleMinutesToday: j['idle'] as int? ?? 0,
        harshEventsToday: j['harsh'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plate': plate,
        'model': model,
        'type': type.name,
        'year': year,
        'status': status.name,
        'condition': condition.name,
        'driverId': driverId,
        'odo': odometerKm,
        'spd': speedKmh,
        'hdg': headingDeg,
        'x': pos.dx,
        'y': pos.dy,
        'fuel': fuelLevelPct,
        'tank': tankCapacityL,
        'eff': efficiencyKmpl,
        'et': engineTempC,
        'eco': ecoScore,
        'co2': co2KgPer100Km,
        'gf': geofenceId,
        'trip': activeTripId,
        'dtc': dtcCodes.map((e) => e.toJson()).toList(),
        'sen': sensors.toJson(),
        'idle': idleMinutesToday,
        'harsh': harshEventsToday,
      };
}

/// Hours-of-service ledger + behavior record for a driver.
class DriverBehavior {
  final int harshBraking30d;
  final int harshAccel30d;
  final int speeding30d;
  final int seatbeltViolations30d;

  const DriverBehavior({
    required this.harshBraking30d,
    required this.harshAccel30d,
    required this.speeding30d,
    required this.seatbeltViolations30d,
  });

  factory DriverBehavior.fromJson(Map<String, dynamic> j) => DriverBehavior(
        harshBraking30d: j['hb'] as int,
        harshAccel30d: j['ha'] as int,
        speeding30d: j['sp'] as int,
        seatbeltViolations30d: j['sb'] as int,
      );

  Map<String, dynamic> toJson() =>
      {'hb': harshBraking30d, 'ha': harshAccel30d, 'sp': speeding30d, 'sb': seatbeltViolations30d};

  /// Total harsh events across the ABC'S set (acceleration, braking,
  /// cornering proxy, speeding) over the trailing 30 days.
  int get behaviorTotal =>
      harshBraking30d + harshAccel30d + speeding30d + seatbeltViolations30d;
}

/// A regulatory violation attached to a driver (guide p. 6: compliance).
class Violation {
  final String code;
  final String title;
  final double fineUsd;
  final DateTime date;

  const Violation({required this.code, required this.title, required this.fineUsd, required this.date});

  factory Violation.fromJson(Map<String, dynamic> j) => Violation(
        code: j['code'] as String,
        title: j['title'] as String,
        fineUsd: (j['fine'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(j['d'] as int),
      );

  Map<String, dynamic> toJson() =>
      {'code': code, 'title': title, 'fine': fineUsd, 'd': date.millisecondsSinceEpoch};
}

/// Driver profile with safety scores and ELD/HOS state (guide p. 10, p. 16).
class Driver {
  final String id;
  final String name;
  final String license;
  final String phone;
  final int hue;

  double safetyScore;
  double ecoScore;
  DriverBehavior behavior;
  EldStatus eldStatus;

  double hosHoursToday; // live, accumulates while on route
  final double hosCycleLimit; // 70h / 8 days
  double hosCycleUsed;

  List<Violation> violations;
  int tripsCompleted;
  double onTimeRate;
  String? vehicleId;
  int yearsExperience;
  DutyStatus dutyStatus; // live ELD clock state
  int coachingCount30d; // assigned coaching sessions, last 30 days
  int kudosCount30d; // recognition events from safety team

  Driver({
    required this.id,
    required this.name,
    required this.license,
    required this.phone,
    required this.hue,
    required this.safetyScore,
    required this.ecoScore,
    required this.behavior,
    required this.eldStatus,
    required this.hosHoursToday,
    required this.hosCycleLimit,
    required this.hosCycleUsed,
    required this.violations,
    required this.tripsCompleted,
    required this.onTimeRate,
    this.vehicleId,
    required this.yearsExperience,
    this.dutyStatus = DutyStatus.driving,
    this.coachingCount30d = 0,
    this.kudosCount30d = 0,
  });

  double get hosRemaining => (hosCycleLimit - hosCycleUsed).clamp(0, hosCycleLimit);
  double get hosTodayRemaining => (11 - hosHoursToday).clamp(0, 11);
  bool get hosRisk => hosCycleUsed / hosCycleLimit > 0.85 || hosHoursToday > 9.5;

  factory Driver.fromJson(Map<String, dynamic> j) => Driver(
        id: j['id'] as String,
        name: j['name'] as String,
        license: j['lic'] as String,
        phone: j['ph'] as String,
        hue: j['hue'] as int,
        safetyScore: (j['saf'] as num).toDouble(),
        ecoScore: (j['eco'] as num).toDouble(),
        behavior: DriverBehavior.fromJson(j['beh'] as Map<String, dynamic>),
        eldStatus: EldStatus.values.byName(j['eld'] as String),
        hosHoursToday: (j['ht'] as num).toDouble(),
        hosCycleLimit: (j['hcl'] as num).toDouble(),
        hosCycleUsed: (j['hcu'] as num).toDouble(),
        violations: [(j['vio'] as List?) ?? []]
            .expand((l) => l)
            .map((e) => Violation.fromJson(e as Map<String, dynamic>))
            .toList(),
        tripsCompleted: j['tc'] as int,
        onTimeRate: (j['otr'] as num).toDouble(),
        vehicleId: j['vid'] as String?,
        yearsExperience: j['yx'] as int,
        dutyStatus: DutyStatus.values.byName(j['duty'] as String? ?? 'driving'),
        coachingCount30d: j['cch'] as int? ?? 0,
        kudosCount30d: j['kud'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lic': license,
        'ph': phone,
        'hue': hue,
        'saf': safetyScore,
        'eco': ecoScore,
        'beh': behavior.toJson(),
        'eld': eldStatus.name,
        'ht': hosHoursToday,
        'hcl': hosCycleLimit,
        'hcu': hosCycleUsed,
        'vio': violations.map((e) => e.toJson()).toList(),
        'tc': tripsCompleted,
        'otr': onTimeRate,
        'vid': vehicleId,
        'yx': yearsExperience,
        'duty': dutyStatus.name,
        'cch': coachingCount30d,
        'kud': kudosCount30d,
      };
}

/// A dispatched trip with live ETA (guide p. 6: predict ETAs accurately).
class Trip {
  final String id;
  final String vehicleId;
  String driverId;
  final String origin;
  final String destination;
  final String cargo;
  String customer;
  String loadId; // dispatch load reference, e.g. LD-2418
  final double weightT;
  final double distanceKm;
  double progressPct; // live
  int etaMinutes; // live
  int delayMinutes;
  TripStatus status;
  final List<Offset> waypoints; // normalized map space
  final double? reeferSetpointC;

  Trip({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.origin,
    required this.destination,
    required this.cargo,
    required this.weightT,
    required this.distanceKm,
    required this.progressPct,
    required this.etaMinutes,
    required this.delayMinutes,
    required this.status,
    required this.waypoints,
    this.reeferSetpointC,
    this.customer = 'Kompact Logistics',
    this.loadId = 'LD-0000',
  });

  Offset posAt(double t) {
    if (waypoints.isEmpty) return Offset.zero;
    final clamped = t.clamp(0.0, 1.0);
    final segCount = waypoints.length - 1;
    if (segCount <= 0) return waypoints.first;
    final scaled = clamped * segCount;
    final i = scaled.floor().clamp(0, segCount - 1);
    final f = scaled - i;
    return Offset(
      waypoints[i].dx + (waypoints[i + 1].dx - waypoints[i].dx) * f,
      waypoints[i].dy + (waypoints[i + 1].dy - waypoints[i].dy) * f,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: j['id'] as String,
        vehicleId: j['vid'] as String,
        driverId: j['did'] as String,
        origin: j['org'] as String,
        destination: j['dst'] as String,
        cargo: j['crg'] as String,
        weightT: (j['w'] as num).toDouble(),
        distanceKm: (j['km'] as num).toDouble(),
        progressPct: (j['p'] as num).toDouble(),
        etaMinutes: j['eta'] as int,
        delayMinutes: j['dly'] as int,
        status: TripStatus.values.byName(j['st'] as String),
        waypoints: [(j['wp'] as List?) ?? []]
            .expand((l) => l)
            .map((e) {
              final m = e as Map<String, dynamic>;
              return Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble());
            })
            .toList(),
        reeferSetpointC: (j['sp'] as num?)?.toDouble(),
        customer: j['cus'] as String? ?? 'Kompact Logistics',
        loadId: j['lid'] as String? ?? 'LD-0000',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vid': vehicleId,
        'did': driverId,
        'org': origin,
        'dst': destination,
        'crg': cargo,
        'w': weightT,
        'km': distanceKm,
        'p': progressPct,
        'eta': etaMinutes,
        'dly': delayMinutes,
        'st': status.name,
        'wp': waypoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'sp': reeferSetpointC,
        'cus': customer,
        'lid': loadId,
      };
}

/// Real-time alert pushed by the telematics pipeline (guide p. 12).
class FleetAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? vehicleId;
  final String? driverId;
  final DateTime timestamp;
  AlertStatus status;

  /// Extra context for collision alerts (guide p. 17: accident tracking).
  final Map<String, String> facts;

  FleetAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.vehicleId,
    this.driverId,
    required this.timestamp,
    this.status = AlertStatus.active,
    this.facts = const {},
  });

  factory FleetAlert.fromJson(Map<String, dynamic> j) => FleetAlert(
        id: j['id'] as String,
        type: AlertType.values.byName(j['ty'] as String),
        severity: AlertSeverity.values.byName(j['sv'] as String),
        title: j['t'] as String,
        message: j['m'] as String,
        vehicleId: j['vid'] as String?,
        driverId: j['did'] as String?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
        status: AlertStatus.values.byName(j['st'] as String),
        facts: (j['fx'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ty': type.name,
        'sv': severity.name,
        't': title,
        'm': message,
        'vid': vehicleId,
        'did': driverId,
        'ts': timestamp.millisecondsSinceEpoch,
        'st': status.name,
        'fx': facts,
      };
}

/// Predictive or corrective maintenance work item (guide p. 11, p. 23).
class MaintenanceItem {
  final String id;
  final String vehicleId;
  final MaintenanceKind kind;
  MaintenanceStatus status;
  final String title;
  final String part;
  final int dueInKm;
  DateTime? dueDate;
  final int confidencePct; // AI prediction confidence
  final double costEstUsd;
  final double downtimeHours;
  MaintenancePriority priority; // shop triage class
  String? tech; // assigned technician
  final double laborHoursEst;
  double laborHoursActual; // live, logged while in progress
  bool approved; // finance gate for repair orders over threshold

  MaintenanceItem({
    required this.id,
    required this.vehicleId,
    required this.kind,
    required this.status,
    required this.title,
    required this.part,
    required this.dueInKm,
    this.dueDate,
    required this.confidencePct,
    required this.costEstUsd,
    required this.downtimeHours,
    this.priority = MaintenancePriority.scheduled,
    this.tech,
    this.laborHoursEst = 2,
    this.laborHoursActual = 0,
    this.approved = false,
  });

  /// Repair orders above this estimate need finance approval before work.
  static const double approvalThresholdUsd = 500;

  bool get needsApproval =>
      status != MaintenanceStatus.completed && costEstUsd >= approvalThresholdUsd && !approved;

  factory MaintenanceItem.fromJson(Map<String, dynamic> j) => MaintenanceItem(
        id: j['id'] as String,
        vehicleId: j['vid'] as String,
        kind: MaintenanceKind.values.byName(j['k'] as String),
        status: MaintenanceStatus.values.byName(j['st'] as String),
        title: j['t'] as String,
        part: j['p'] as String,
        dueInKm: j['dkm'] as int,
        dueDate: j['dd'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['dd'] as int),
        confidencePct: j['cf'] as int,
        costEstUsd: (j['c'] as num).toDouble(),
        downtimeHours: (j['dt'] as num).toDouble(),
        priority: MaintenancePriority.values.byName(j['pri'] as String? ?? 'scheduled'),
        tech: j['tec'] as String?,
        laborHoursEst: (j['lhe'] as num?)?.toDouble() ?? 2,
        laborHoursActual: (j['lha'] as num?)?.toDouble() ?? 0,
        approved: j['apv'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vid': vehicleId,
        'k': kind.name,
        'st': status.name,
        't': title,
        'p': part,
        'dkm': dueInKm,
        'dd': dueDate?.millisecondsSinceEpoch,
        'cf': confidencePct,
        'c': costEstUsd,
        'dt': downtimeHours,
        'pri': priority.name,
        'tec': tech,
        'lhe': laborHoursEst,
        'lha': laborHoursActual,
        'apv': approved,
      };
}

/// A fueling event captured by the fuel-card / telematics integration.
class FuelEvent {
  final String id;
  final String vehicleId;
  final DateTime date;
  final double liters;
  final double costPerLiter;
  final double odometerKm;
  final String station;

  const FuelEvent({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.liters,
    required this.costPerLiter,
    required this.odometerKm,
    required this.station,
  });

  double get totalCost => liters * costPerLiter;

  factory FuelEvent.fromJson(Map<String, dynamic> j) => FuelEvent(
        id: j['id'] as String,
        vehicleId: j['vid'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(j['d'] as int),
        liters: (j['l'] as num).toDouble(),
        costPerLiter: (j['cpl'] as num).toDouble(),
        odometerKm: (j['odo'] as num).toDouble(),
        station: j['s'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vid': vehicleId,
        'd': date.millisecondsSinceEpoch,
        'l': liters,
        'cpl': costPerLiter,
        'odo': odometerKm,
        's': station,
      };
}

/// Geofenced zone used for spatial operations (guide p. 25).
class Geofence {
  final String id;
  final String name;
  final String kind; // depot, customer, port, warehouse
  final Offset center; // normalized map space
  final double radiusNorm;
  final int entriesToday;
  final int exitsToday;

  const Geofence({
    required this.id,
    required this.name,
    required this.kind,
    required this.center,
    required this.radiusNorm,
    this.entriesToday = 0,
    this.exitsToday = 0,
  });

  bool contains(Offset p) => (p - center).distance <= radiusNorm;

  factory Geofence.fromJson(Map<String, dynamic> j) => Geofence(
        id: j['id'] as String,
        name: j['n'] as String,
        kind: j['k'] as String,
        center: Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()),
        radiusNorm: (j['r'] as num).toDouble(),
        entriesToday: j['en'] as int? ?? 0,
        exitsToday: j['ex'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'n': name, 'k': kind, 'x': center.dx, 'y': center.dy, 'r': radiusNorm, 'en': entriesToday, 'ex': exitsToday};
}

/// A fuel / service station landmark on the map for closest-point ops.
class Station {
  final String name;
  final String brand; // fuel, service
  final Offset center;

  const Station({required this.name, required this.brand, required this.center});
}

/// A user account that can sign in to the FMS. Every role has at least one
/// demo persona so the login screen can showcase the full RBAC matrix.
class FleetUser {
  final String id;
  final String name;
  final String email;
  final FleetRole role;
  final String title; // job title shown on the login card
  final int hue; // avatar hue

  const FleetUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.title,
    required this.hue,
  });

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

/// Demo account directory — one persona per role (passwords are simulated).
const kFleetUsers = <FleetUser>[
  FleetUser(id: 'u-ops', name: 'Dana Whitfield', email: 'dana.whitfield@kompactfleet.io', role: FleetRole.ops, title: 'Director, Fleet Operations', hue: 214),
  FleetUser(id: 'u-dis', name: 'Ray Kowalski', email: 'ray.kowalski@kompactfleet.io', role: FleetRole.dispatcher, title: 'Senior Dispatcher', hue: 194),
  FleetUser(id: 'u-drv', name: 'Derrick Reyes', email: 'derrick.reyes@kompactfleet.io', role: FleetRole.driver, title: 'Line-haul Driver · Class A CDL', hue: 152),
  FleetUser(id: 'u-mnt', name: 'Sam Okafor', email: 'sam.okafor@kompactfleet.io', role: FleetRole.maintenance, title: 'Shop Manager', hue: 36),
  FleetUser(id: 'u-saf', name: 'Priya Sharma', email: 'priya.sharma@kompactfleet.io', role: FleetRole.safety, title: 'Safety & Compliance Lead', hue: 4),
  FleetUser(id: 'u-fin', name: 'Elena Marsh', email: 'elena.marsh@kompactfleet.io', role: FleetRole.finance, title: 'Fleet Finance Controller', hue: 24),
  FleetUser(id: 'u-exe', name: 'Jordan Abernathy', email: 'j.abernathy@kompactfleet.io', role: FleetRole.executive, title: 'Chief Operating Officer', hue: 262),
];

/// An AI-detected safety event awaiting review in the Safety Inbox
/// (Samsara-style triage queue with context labels).
class SafetyEvent {
  final String id;
  final SafetyEventType type;
  final String driverId;
  final String vehicleId;
  final DateTime timestamp;
  final String location;
  final int severity; // 1..3 (3 = highest)
  final String aiContext; // plain-language explanation
  final int confidencePct; // detection confidence (EVE-style)
  final bool hasClip; // dash-camera footage attached
  SafetyEventStatus status;

  SafetyEvent({
    required this.id,
    required this.type,
    required this.driverId,
    required this.vehicleId,
    required this.timestamp,
    required this.location,
    required this.severity,
    required this.aiContext,
    required this.confidencePct,
    this.hasClip = true,
    this.status = SafetyEventStatus.pending,
  });

  factory SafetyEvent.fromJson(Map<String, dynamic> j) => SafetyEvent(
        id: j['id'] as String,
        type: SafetyEventType.values.byName(j['ty'] as String),
        driverId: j['did'] as String,
        vehicleId: j['vid'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
        location: j['loc'] as String,
        severity: j['sev'] as int,
        aiContext: j['ctx'] as String,
        confidencePct: j['cf'] as int,
        hasClip: j['clip'] as bool? ?? true,
        status: SafetyEventStatus.values.byName(j['st'] as String? ?? 'pending'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ty': type.name,
        'did': driverId,
        'vid': vehicleId,
        'ts': timestamp.millisecondsSinceEpoch,
        'loc': location,
        'sev': severity,
        'ctx': aiContext,
        'cf': confidencePct,
        'clip': hasClip,
        'st': status.name,
      };
}

/// A dispatch ↔ driver message shown in the driver cockpit inbox.
class DispatchMessage {
  final String id;
  final String from;
  final String text;
  final DateTime time;
  final bool urgent;
  bool read;

  DispatchMessage({
    required this.id,
    required this.from,
    required this.text,
    required this.time,
    this.urgent = false,
    this.read = false,
  });

  factory DispatchMessage.fromJson(Map<String, dynamic> j) => DispatchMessage(
        id: j['id'] as String,
        from: j['f'] as String,
        text: j['tx'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(j['t'] as int),
        urgent: j['u'] as bool? ?? false,
        read: j['r'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'f': from, 'tx': text, 't': time.millisecondsSinceEpoch, 'u': urgent, 'r': read};
}

class AppSettings {
  int themeModeIndex; // 0 system, 1 light, 2 dark
  int accentIndex; // 0 blue, 1 indigo, 2 teal
  int densityIndex; // 0 compact, 1 comfortable
  int roleIndex; // active FleetRole workspace
  bool useMetric;
  bool alertsEnabled;
  bool simRunning;
  double simSpeed; // multiplier
  String? signedInUserId; // active session (null → login screen)

  AppSettings({
    this.themeModeIndex = 0,
    this.accentIndex = 0,
    this.densityIndex = 0,
    this.roleIndex = 0,
    this.useMetric = true,
    this.alertsEnabled = true,
    this.simRunning = true,
    this.simSpeed = 1.0,
    this.signedInUserId,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    final roleIdx = j['role'] as int? ?? 0;
    return AppSettings(
      themeModeIndex: j['theme'] as int? ?? 0,
      accentIndex: j['accent'] as int? ?? 0,
      densityIndex: j['density'] as int? ?? 0,
      // Unknown role indexes (e.g. from a newer build) fall back to Ops.
      roleIndex:
          roleIdx >= 0 && roleIdx < FleetRole.values.length ? roleIdx : 0,
      useMetric: j['metric'] as bool? ?? true,
      alertsEnabled: j['alerts'] as bool? ?? true,
      simRunning: j['sim'] as bool? ?? true,
      simSpeed: (j['simspd'] as num?)?.toDouble() ?? 1.0,
      signedInUserId: j['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': themeModeIndex,
        'accent': accentIndex,
        'density': densityIndex,
        'role': roleIndex,
        'metric': useMetric,
        'alerts': alertsEnabled,
        'sim': simRunning,
        'simspd': simSpeed,
        'user': signedInUserId,
      };
}
