import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Custom-painted compact charts. No chart dependencies — full control of the
// dense look: 2px strokes, tiny labels, hairline grids.
// ─────────────────────────────────────────────────────────────────────────────

/// Inline sparkline for live series.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color? color;
  final double height;
  final bool fill;

  const Sparkline({super.key, required this.values, this.color, this.height = 30, this.fill = true});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (values.length < 2) return SizedBox(height: height);
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, c) => CustomPaint(
          size: c.biggest,
          painter: _SparkPainter(
            values: values,
            stroke: color ?? p.primary,
            fillArea: fill,
            fillGradient: true,
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color stroke;
  final bool fillArea;
  final bool fillGradient;

  _SparkPainter({required this.values, required this.stroke, required this.fillArea, this.fillGradient = false});

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV) == 0 ? 1.0 : maxV - minV;
    final h = size.height - 3;
    final w = size.width;

    final pts = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = w * i / (values.length - 1);
      final y = 1.5 + h - (values[i] - minV) / span * h;
      pts.add(Offset(x, y));
    }

    final path = Path()..addPolygon(pts, false);
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    if (fillArea) {
      final area = Path.from(path)
        ..lineTo(w, size.height)
        ..lineTo(0, size.height)
        ..close();
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = fillGradient
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [stroke.withValues(alpha: 0.22), stroke.withValues(alpha: 0.02)],
              ).createShader(Offset.zero & size)
            : null
        ..color = stroke.withValues(alpha: 0.12);
      canvas.drawPath(area, paint);
    }

    // End dot.
    canvas.drawCircle(pts.last, 2, Paint()..color = stroke);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values.length != values.length || old.values.last != values.last || old.stroke != stroke;
}

/// Compact vertical bar chart with optional last-bar highlight + baseline.
class MiniBars extends StatelessWidget {
  final List<double> values;
  final Color? color;
  final Color? highlightColor;
  final int highlightIndex;
  final double height;

  const MiniBars({
    super.key,
    required this.values,
    this.color,
    this.highlightColor,
    this.highlightIndex = -1,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, c) => CustomPaint(
          size: c.biggest,
          painter: _BarsPainter(
            values: values,
            base: color ?? p.primary,
            hi: highlightColor ?? p.accent,
            hiIndex: highlightIndex,
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<double> values;
  final Color base;
  final Color hi;
  final int hiIndex;

  _BarsPainter({required this.values, required this.base, required this.hi, required this.hiIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce(math.max);
    final span = maxV == 0 ? 1.0 : maxV;
    final gap = math.max(1.0, size.width * 0.02);
    final bw = (size.width - gap * (values.length - 1)) / values.length;
    for (var i = 0; i < values.length; i++) {
      final h = values[i] / span * (size.height - 2);
      final rect = Rect.fromLTWH(i * (bw + gap), size.height - h, bw, h);
      final c = i == hiIndex ? hi : base;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        Paint()..color = i == hiIndex ? c : c.withValues(alpha: 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.values != values;
}

/// Horizontal stacked distribution bar (e.g. condition mix).
class DistributionBar extends StatelessWidget {
  final List<(double value, Color color, String label)> segments;
  final double height;
  final void Function(int index)? onTap;

  const DistributionBar({super.key, required this.segments, this.height = 8, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final total = segments.fold<double>(0, (s, e) => s + e.$1);
    return LayoutBuilder(
      builder: (context, c) {
        if (total == 0) {
          return Container(
            height: height,
            decoration: BoxDecoration(color: p.surfaceSunken, borderRadius: BorderRadius.circular(3)),
          );
        }
        var x = 0.0;
        return SizedBox(
          height: height,
          width: c.maxWidth,
          child: Stack(
            children: [
              for (var i = 0; i < segments.length; i++)
                Positioned(
                  left: x,
                  width: segments[i].$1 / total * c.maxWidth,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: onTap == null ? null : () => onTap!(i),
                    child: Tooltip(
                      message: '${segments[i].$3}: ${segments[i].$1.round()}',
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(color: segments[i].$2, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Donut chart with center label — condition mix / severity mix.
class Donut extends StatelessWidget {
  final List<(double value, Color color)> slices;
  final String? centerTop;
  final String? centerBottom;
  final double size;

  const Donut({
    super.key,
    required this.slices,
    this.centerTop,
    this.centerBottom,
    this.size = 108,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(slices: slices, track: p.surfaceSunken),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerTop != null)
                Text(
                  centerTop!,
                  style: TextStyle(
                    fontSize: K.headline,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -0.4,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
              if (centerBottom != null)
                Text(
                  centerBottom!,
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w600,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> slices;
  final Color track;

  _DonutPainter({required this.slices, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final stroke = radius * 0.3;
    final total = slices.fold<double>(0, (s, e) => s + e.$1);
    final rect = Rect.fromCircle(center: c, radius: radius - stroke / 2);

    canvas.drawCircle(
      c,
      radius - stroke / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    if (total == 0) return;
    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = s.$1 / total * 2 * math.pi;
      if (sweep <= 0) continue;
      canvas.drawArc(
        rect,
        start,
        sweep - 0.04,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = s.$2,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.slices != slices;
}

/// Radial gauge — fuel level, score dials.
class Gauge extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final String label;
  final String? sublabel;
  final double size;

  const Gauge({
    super.key,
    required this.value,
    required this.color,
    required this.label,
    this.sublabel,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _GaugePainter(value: value.clamp(0, 1), color: color, track: p.surfaceSunken),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: K.title,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: p.text,
                  fontFamily: 'Inter',
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: TextStyle(
                    fontSize: K.micro,
                    fontWeight: FontWeight.w600,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;

  _GaugePainter({required this.value, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final stroke = radius * 0.16;
    final rect = Rect.fromCircle(center: c, radius: radius - stroke / 2 - 1);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, math.pi * 0.75, math.pi * 1.5, false, trackPaint);

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, math.pi * 0.75, math.pi * 1.5 * value, false, fill);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}

/// Utilization heatmap: 7 days × 24 hours.
class Heatmap extends StatelessWidget {
  final List<List<double>> data; // [7][24], 0..1
  final double cellGap;

  const Heatmap({super.key, required this.data, this.cellGap = 2});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 26,
              child: Text('', style: TextStyle(fontSize: K.micro, fontFamily: 'Inter')),
            ),
            Expanded(child: _hourAxis(p)),
          ],
        ),
        for (var d = 0; d < 7; d++)
          Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  days[d],
                  style: TextStyle(
                    fontSize: K.micro,
                    fontWeight: FontWeight.w600,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cw = (c.maxWidth - cellGap * 23) / 24;
                    return SizedBox(
                      height: cw + 2,
                      child: Row(
                        children: [
                          for (var h = 0; h < 24; h++)
                            Expanded(
                              child: Tooltip(
                                message: '${days[d]} ${h.toString().padLeft(2, '0')}:00 · ${(data[d][h] * 100).round()}% utilized',
                                child: Container(
                                  margin: EdgeInsets.only(right: h == 23 ? 0 : cellGap),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(1.5),
                                    color: Color.lerp(
                                      p.surfaceSunken,
                                      p.primary,
                                      data[d][h].clamp(0, 1) * 0.95,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _hourAxis(KPallette p) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final h in const ['00', '06', '12', '18', '23'])
              Text(
                h,
                style: TextStyle(
                  fontSize: K.micro,
                  fontWeight: FontWeight.w600,
                  color: p.textTertiary,
                  fontFamily: 'Inter',
                ),
              ),
          ],
        ),
      );
}

/// Tiny horizontal bar with label + value — driver leaderboard rows.
class LabelBar extends StatelessWidget {
  final String label;
  final double value; // 0..1
  final String valueText;
  final Color color;

  const LabelBar({
    super.key,
    required this.label,
    required this.value,
    required this.valueText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                fontSize: K.label,
                color: p.textSecondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: KProgress(value: value, color: color),
          ),
          const SizedBox(width: K.xs + 2),
          SizedBox(
            width: 40,
            child: Text(
              valueText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: K.label,
                color: p.text,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
