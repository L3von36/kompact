import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Live fleet map — custom-painted stylized city: road grid, river, park blocks,
// geofence zones, station landmarks, active routes and moving vehicle markers.
// Coordinates live in normalized 0..1 space; painters scale to canvas size.
// ─────────────────────────────────────────────────────────────────────────────

class FleetMap extends StatelessWidget {
  final List<Vehicle> vehicles;
  final List<Geofence> geofences;
  final List<Station> stations;
  final List<Trip> routes;
  final String? selectedVehicleId;
  final ValueChanged<String?> onVehicleTap;
  final bool showRoutes;
  final bool showGeofences;

  const FleetMap({
    super.key,
    required this.vehicles,
    required this.geofences,
    required this.stations,
    required this.routes,
    required this.selectedVehicleId,
    required this.onVehicleTap,
    this.showRoutes = true,
    this.showGeofences = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(K.rMd),
      child: LayoutBuilder(
        builder: (context, c) {
          final size = c.biggest;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                // Hit-test vehicle markers (12px radius in canvas space).
                final hit = _hitTest(d.localPosition, size);
                onVehicleTap(hit);
              },
              child: CustomPaint(
                size: size,
                painter: _FleetMapPainter(
                  palette: p,
                  vehicles: vehicles,
                  geofences: geofences,
                  stations: stations,
                  routes: routes,
                  selected: selectedVehicleId,
                  showRoutes: showRoutes,
                  showGeofences: showGeofences,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _hitTest(Offset local, Size size) {
    for (final v in vehicles) {
      final vp = Offset(v.pos.dx * size.width, v.pos.dy * size.height);
      if ((local - vp).distance <= 13) return v.id;
    }
    return null;
  }
}

class _FleetMapPainter extends CustomPainter {
  final KPallette palette;
  final List<Vehicle> vehicles;
  final List<Geofence> geofences;
  final List<Station> stations;
  final List<Trip> routes;
  final String? selected;
  final bool showRoutes;
  final bool showGeofences;

  _FleetMapPainter({
    required this.palette,
    required this.vehicles,
    required this.geofences,
    required this.stations,
    required this.routes,
    required this.selected,
    required this.showRoutes,
    required this.showGeofences,
  });

  Offset _p(Offset n, Size s) => Offset(n.dx * s.width, n.dy * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;

    // Land.
    final bg = Paint()..color = p.surfaceSunken;
    canvas.drawRect(Offset.zero & size, bg);

    // Water: east bay + river diagonal.
    final water = Paint()..color = _waterColor(p);
    final bay = Path()
      ..moveTo(size.width * 0.93, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.86, size.height)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.5, size.width * 0.93, 0)
      ..close();
    canvas.drawPath(bay, water);
    final river = Path()
      ..moveTo(0, size.height * 0.92)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.86, size.width * 0.55, size.height * 0.97)
      ..lineTo(size.width * 0.55, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(river, water);

    // Park blocks.
    final park = Paint()..color = _parkColor(p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: _p(const Offset(0.27, 0.29), size), width: size.width * 0.11, height: size.height * 0.13), const Radius.circular(4)),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: _p(const Offset(0.62, 0.72), size), width: size.width * 0.09, height: size.height * 0.1), const Radius.circular(4)),
      park,
    );

    // Minor road grid.
    final minor = Paint()
      ..color = _roadMinor(p)
      ..strokeWidth = 1;
    for (var i = 1; i < 10; i++) {
      final y = size.height * i / 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }
    for (var i = 1; i < 14; i++) {
      final x = size.width * i / 14;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
    }

    // Major arteries (thicker).
    final major = Paint()
      ..color = _roadMajor(p)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    for (final y in [0.2, 0.42, 0.64, 0.84]) {
      canvas.drawLine(Offset(0, size.height * y), Offset(size.width * 0.9, size.height * y), major);
    }
    for (final x in [0.12, 0.34, 0.56, 0.78]) {
      canvas.drawLine(Offset(size.width * x, 0), Offset(size.width * x, size.height * 0.94), major);
    }
    // Highway diagonal.
    final hw = Paint()
      ..color = _roadHighway(p)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.64), Offset(size.width * 0.88, size.height * 0.18), hw);

    // Geofences.
    if (showGeofences) {
      for (final g in geofences) {
        final c = _p(g.center, size);
        final r = g.radiusNorm * size.width;
        final zone = Paint()..color = p.primary.withValues(alpha: 0.07);
        canvas.drawCircle(c, r, zone);
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = p.primary.withValues(alpha: 0.55);
        canvas.drawCircle(c, r, ring);
        // Dashed inner ring.
        _dashCircle(canvas, c, r * 0.82, p.primary.withValues(alpha: 0.25));

        // Zone label.
        final tp = TextPainter(
          text: TextSpan(
            text: g.name.toUpperCase(),
            style: TextStyle(
              fontSize: K.micro,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: p.primary.withValues(alpha: 0.9),
              fontFamily: 'Inter',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c.translate(-tp.width / 2, r + 3));
      }
    }

    // Stations.
    for (final s in stations) {
      final c = _p(s.center, size);
      final paint = Paint()..color = s.brand == 'fuel' ? p.accent : p.satisfactory;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 8, height: 8), const Radius.circular(2)),
        paint,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: s.brand == 'fuel' ? 'F' : 'S',
          style: TextStyle(
            fontSize: 6.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c.translate(-tp.width / 2, -tp.height / 2 - 0.5));
    }

    // Active routes.
    if (showRoutes) {
      for (final t in routes) {
        if (t.status == TripStatus.delivered) continue;
        final path = Path();
        final pts = t.waypoints.map((w) => _p(w, size)).toList();
        path.addPolygon(pts, false);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = t.status == TripStatus.atRisk ? 2 : 1.4
            ..color = (t.status == TripStatus.atRisk ? p.critical : p.primary).withValues(alpha: 0.5)
            ..strokeCap = StrokeCap.round,
        );
        // Traveled portion (solid, stronger).
        final partial = Path()..addPolygon(pts, false);
        final metrics = partial.computeMetrics().first;
        final traveled = metrics.extractPath(0, metrics.length * t.progressPct / 100);
        canvas.drawPath(
          traveled,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = t.status == TripStatus.atRisk ? 2.4 : 1.8
            ..color = t.status == TripStatus.atRisk ? p.critical : p.primary
            ..strokeCap = StrokeCap.round,
        );
        // Destination pin.
        _pin(canvas, pts.last, t.status == TripStatus.atRisk ? p.critical : p.primary, p);
      }
    }

    // Vehicle markers.
    for (final v in vehicles) {
      if (v.status == VehicleStatus.offline) continue;
      final c = _p(v.pos, size);
      final sel = v.id == selected;
      final col = _vehicleColor(v);

      if (sel) {
        // Selection halo.
        canvas.drawCircle(c, 13, Paint()..color = col.withValues(alpha: 0.18));
        canvas.drawCircle(c, 13, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = col);
      } else if (v.condition == VehicleCondition.critical || v.condition == VehicleCondition.urgent) {
        // Attention ring for problem vehicles.
        canvas.drawCircle(c, 10, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = col.withValues(alpha: 0.5));
      }

      // Body: rounded square + heading notch.
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 11, height: 11), const Radius.circular(3)),
        Paint()..color = col,
      );
      final dir = Offset(0, -7).rotate(math.pi * v.headingDeg / 180);
      canvas.drawCircle(c + dir, 1.8, Paint()..color = Colors.white.withValues(alpha: 0.9));

      // Plate label for selected or wide maps.
      if (sel && size.width > 340) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${v.plate} · ${v.speedKmh.round()} km/h',
            style: TextStyle(
              fontSize: K.caption,
              fontWeight: FontWeight.w700,
              color: p.text,
              fontFamily: 'Inter',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final box = Rect.fromCenter(
          center: c.translate(0, -17),
          width: tp.width + 10,
          height: tp.height + 5,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(4)),
          Paint()..color = p.surface.withValues(alpha: 0.96),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(4)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = col,
        );
        tp.paint(canvas, box.topLeft.translate(5, 2.5));
      }
    }
  }

  void _dashCircle(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    const segments = 26;
    for (var i = 0; i < segments; i++) {
      final a1 = 2 * math.pi * i / segments;
      final a2 = a1 + 2 * math.pi / segments * 0.5;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a1, a2 - a1, false, paint);
    }
  }

  void _pin(Canvas canvas, Offset c, Color color, KPallette p) {
    canvas.drawCircle(c, 4.5, Paint()..color = color);
    canvas.drawCircle(c, 1.8, Paint()..color = p.surface);
  }

  Color _vehicleColor(Vehicle v) {
    // Priority: condition > status.
    if (v.condition == VehicleCondition.critical) return palette.critical;
    if (v.condition == VehicleCondition.urgent) return palette.urgent;
    return switch (v.status) {
      VehicleStatus.onRoute => palette.good,
      VehicleStatus.idle => palette.textTertiary,
      VehicleStatus.maintenance => palette.urgent,
      VehicleStatus.offline => palette.textTertiary,
    };
  }

  Color _waterColor(KPallette p) => p.surfaceSunken; // subtle in both modes
  Color _parkColor(KPallette p) => p.good.withValues(alpha: 0.10);
  Color _roadMinor(KPallette p) => p.border.withValues(alpha: 0.55);
  Color _roadMajor(KPallette p) => p.border;
  Color _roadHighway(KPallette p) => p.borderStrong;

  @override
  bool shouldRepaint(_FleetMapPainter old) => true; // live updates
}

extension on Offset {
  Offset rotate(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Offset(dx * c - dy * s, dx * s + dy * c);
  }
}

/// Legend strip for the map.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: K.xxs + 1),
            Text(
              label,
              style: TextStyle(
                fontSize: K.caption,
                fontWeight: FontWeight.w600,
                color: p.textTertiary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        );

    return Wrap(
      spacing: K.md,
      runSpacing: K.xs,
      children: [
        item(p.good, 'On route'),
        item(p.textTertiary, 'Idle'),
        item(p.urgent, 'Attention'),
        item(p.critical, 'Critical'),
        item(p.primary, 'Route · zone'),
        item(p.critical, 'At-risk route'),
      ],
    );
  }
}
