import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';

/// Animated rounded bar chart for weekday completions.
class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({super.key, required this.data, this.height = 132});

  final List<DayCount> data;
  final double height;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < widget.data.length; i++) ...[
                if (i > 0) const SizedBox(width: K.s),
                Expanded(child: _bar(context, widget.data[i], t, scheme)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _bar(BuildContext context, DayCount d, double t, ColorScheme scheme) {
    final maxCount = widget.data.map((e) => e.count).fold(1, math.max);
    final h = (d.count / maxCount) * 86 * t;
    final barColor = d.count == 0
        ? scheme.onSurfaceVariant.withValues(alpha: 0.15)
        : d.isToday
            ? scheme.primary
            : scheme.primary.withValues(alpha: 0.45);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (d.count > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${d.count}',
              style: TextStyle(
                fontFamily: K.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        Container(
          height: h.clamp(4.0, double.infinity),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          d.label,
          style: TextStyle(
            fontFamily: K.fontFamily,
            fontSize: 10,
            fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.3,
            color: d.isToday ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Animated donut chart for category distribution.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.centerValue,
    required this.centerLabel,
    this.size = 132,
  });

  final List<(Color, int)> slices;
  final String centerValue;
  final String centerLabel;
  final double size;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _DonutPainter(
          slices: widget.slices,
          progress: Curves.easeOutCubic.transform(_controller.value),
          track: scheme.onSurfaceVariant.withValues(alpha: 0.10),
        ),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.centerValue,
                  style: TextStyle(
                    fontFamily: 'InterDisplay',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.centerLabel,
                  style: microLabel(context).copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.progress,
    required this.track,
  });

  final List<(Color, int)> slices;
  final double progress;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.map((s) => s.$2).fold(0, (a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 9;
    const stroke = 11.0;
    final gap = slices.length > 1 ? 0.05 : 0.0; // radians between slices

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (total == 0 || progress == 0) return;

    var start = -math.pi / 2;
    for (final (color, value) in slices) {
      final sweep = (value / total) * 2 * math.pi * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      final effectiveGap = sweep > 0.15 ? gap : 0;
      final paintColored = paint..color = color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          start + effectiveGap / 2, sweep - effectiveGap, false, paintColored);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.slices != slices || old.progress != progress;
}

/// Tiny inline sparkline for KPI cards.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.width = 74, this.height = 26});

  final List<int> values;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size(width, height),
      painter: _SparkPainter(
        values: values,
        color: scheme.primary,
        fill: scheme.primary.withValues(alpha: 0.12),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.values, required this.color, required this.fill});

  final List<int> values;
  final Color color;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final vals = values;
    final maxV = vals.fold(1, math.max).toDouble();
    final w = size.width;
    final h = size.height;
    final dx = w / (vals.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < vals.length; i++) {
      final y = h - 3 - (vals[i] / maxV) * (h - 6);
      points.add(Offset(i * dx, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final areaPath = Path.from(path)
      ..lineTo(points.last.dx, h)
      ..lineTo(points.first.dx, h)
      ..close();

    canvas.drawPath(areaPath, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawCircle(points.last, 2.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color;
}

/// GitHub-style activity strip: last [weeks] weeks × 7 days of completions.
class ActivityStrip extends StatelessWidget {
  const ActivityStrip({super.key, required this.values, this.weeks = 14});

  /// Oldest-first daily completion counts, length = weeks * 7.
  final List<int> values;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    const cell = 9.0;
    const gap = 2.5;

    // values is oldest-first; group into week columns (Mon..Sun rows).
    final columns = <List<int>>[];
    for (var i = 0; i < values.length; i += 7) {
      columns.add(values.sublist(
          i, math.min(i + 7, values.length)));
    }

    return SizedBox(
      height: 7 * (cell + gap),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final week in columns)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final v in week)
                  Container(
                    width: cell,
                    height: cell,
                    decoration: BoxDecoration(
                      color: v == 0
                          ? scheme.onSurfaceVariant.withValues(alpha: 0.10)
                          : v == 1
                              ? accent.withValues(alpha: 0.35)
                              : v == 2
                                  ? accent.withValues(alpha: 0.60)
                                  : accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
