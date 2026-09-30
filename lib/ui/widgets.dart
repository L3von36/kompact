import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Compact UI component library — dense building blocks shared by all screens.
// ─────────────────────────────────────────────────────────────────────────────

/// Flat surface card with hairline border (no chunky shadows).
class KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final Color? borderColor;

  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(K.md),
    this.margin,
    this.color,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final body = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(K.rMd),
        border: Border.all(color: borderColor ?? p.border),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(K.rMd),
        hoverColor: p.surfaceAlt,
        child: body,
      ),
    );
  }
}

/// Screen-level section header: eyebrow + title + optional action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final Widget? action;
  final bool live;

  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.action,
    this.live = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: K.sm),
      child: Row(
        children: [
          if (live) ...[
            const LiveDot(size: 6),
            const SizedBox(width: K.xs + 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: TextStyle(
                      fontSize: K.micro,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 1),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: K.subtitle,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: K.sm), action!],
        ],
      ),
    );
  }
}

/// Pulsing "live telemetry" indicator.
class LiveDot extends StatefulWidget {
  final double size;
  final Color? color;

  const LiveDot({super.key, this.size = 7, this.color});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.pal.good;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        return Container(
          width: widget.size + 5,
          height: widget.size + 5,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t) * 0.5,
                child: Container(
                  width: widget.size + 5 * t + 2,
                  height: widget.size + 5 * t + 2,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Status mapping ───────────────────────────────────────────────────────────

Color conditionColor(BuildContext c, VehicleCondition v) => switch (v) {
      VehicleCondition.good => c.pal.good,
      VehicleCondition.satisfactory => c.pal.satisfactory,
      VehicleCondition.urgent => c.pal.urgent,
      VehicleCondition.critical => c.pal.critical,
    };

Color conditionSoftColor(BuildContext c, VehicleCondition v) => switch (v) {
      VehicleCondition.good => c.pal.goodSoft,
      VehicleCondition.satisfactory => c.pal.satisfactorySoft,
      VehicleCondition.urgent => c.pal.urgentSoft,
      VehicleCondition.critical => c.pal.criticalSoft,
    };

Color severityColor(BuildContext c, AlertSeverity v) => switch (v) {
      AlertSeverity.critical => c.pal.critical,
      AlertSeverity.urgent => c.pal.urgent,
      AlertSeverity.warning => c.pal.accent,
      AlertSeverity.info => c.pal.info,
    };

Color severitySoftColor(BuildContext c, AlertSeverity v) => switch (v) {
      AlertSeverity.critical => c.pal.criticalSoft,
      AlertSeverity.urgent => c.pal.urgentSoft,
      AlertSeverity.warning => c.pal.accentSoft,
      AlertSeverity.info => c.pal.infoSoft,
    };

Color statusColor(BuildContext c, VehicleStatus v) => switch (v) {
      VehicleStatus.onRoute => c.pal.good,
      VehicleStatus.idle => c.pal.textSecondary,
      VehicleStatus.maintenance => c.pal.urgent,
      VehicleStatus.offline => c.pal.textTertiary,
    };

/// Dense status chip — color + optional dot + label (never color alone).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color soft;
  final bool dot;
  final double? fontSize;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.soft,
    this.dot = true,
    this.fontSize,
  });

  factory StatusChip.condition(BuildContext c, VehicleCondition v) => StatusChip(
        label: v.label,
        color: conditionColor(c, v),
        soft: conditionSoftColor(c, v),
      );

  factory StatusChip.severity(BuildContext c, AlertSeverity v) => StatusChip(
        label: v.label,
        color: severityColor(c, v),
        soft: severitySoftColor(c, v),
      );

  factory StatusChip.status(BuildContext c, VehicleStatus v) => StatusChip(
        label: v.label,
        color: statusColor(c, v),
        soft: c.pal.surfaceAlt,
      );

  factory StatusChip.plain(BuildContext c, String label, Color color) =>
      StatusChip(label: label, color: color, soft: c.pal.surfaceAlt);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: K.xs + 2, vertical: 2),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(K.rSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: K.xxs + 1),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize ?? K.micro,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact KPI metric tile with value, unit, delta and optional inline chart.
class KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String? delta;
  final bool deltaUpGood;
  final IconData? icon;
  final Color? accent;
  final Widget? trailing;

  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.delta,
    this.deltaUpGood = true,
    this.icon,
    this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final acc = accent ?? p.primary;
    return KCard(
      padding: const EdgeInsets.symmetric(horizontal: K.md, vertical: K.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: acc),
                const SizedBox(width: K.xs),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: K.micro,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: K.xxs + 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: K.headline,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: K.xxs + 1),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: K.caption,
                    fontWeight: FontWeight.w600,
                    color: p.textTertiary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
              if (delta != null) ...[
                const Spacer(),
                _Delta(delta: delta!, upGood: deltaUpGood),
              ] else if (trailing != null) ...[
                const Spacer(),
                SizedBox(width: 46, child: trailing!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  final String delta;
  final bool upGood;

  const _Delta({required this.delta, required this.upGood});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final up = delta.startsWith('+');
    final good = up == upGood;
    final color = good ? p.good : p.critical;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 13, color: color),
        Text(
          delta.replaceFirst(RegExp(r'^[+-]'), ''),
          style: TextStyle(
            fontSize: K.caption,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

/// Dense label → value row used in detail panels.
class MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final Color? valueColor;

  const MetricRow({super.key, required this.label, required this.value, this.trailing, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.xxs + 1),
      child: Row(
        children: [
          SizedBox(
            width: 136,
            child: Text(
              label,
              style: TextStyle(
                fontSize: K.label,
                color: p.textTertiary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: K.label,
                color: valueColor ?? p.text,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: K.xs), trailing!],
        ],
      ),
    );
  }
}

/// Hairline progress bar (3px).
class KProgress extends StatelessWidget {
  final double value; // 0..1
  final Color? color;
  final double height;

  const KProgress({super.key, required this.value, this.color, this.height = 3});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        color: color ?? p.primary,
        backgroundColor: p.surfaceSunken,
      ),
    );
  }
}

/// Driver avatar — initials on hue-tinted disc.
class DriverAvatar extends StatelessWidget {
  final String name;
  final int hue;
  final double size;

  const DriverAvatar({super.key, required this.name, required this.hue, this.size = 26});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    final fg = HSLColor.fromColor(Colors.white).withLightness(0.99).toColor();
    final bg = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.42).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.2,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

/// Segmented filter row (chips) — compact control for list filtering.
class FilterRow<T> extends StatelessWidget {
  final List<(T value, String label)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const FilterRow({super.key, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: K.xs),
        itemBuilder: (_, i) {
          final o = options[i];
          final on = o.$1 == selected;
          return Material(
            color: on ? p.primary : p.surfaceAlt,
            borderRadius: BorderRadius.circular(K.rSm),
            child: InkWell(
              onTap: () => onChanged(o.$1),
              borderRadius: BorderRadius.circular(K.rSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: K.sm + 2),
                child: Center(
                  child: Text(
                    o.$2,
                    style: TextStyle(
                      fontSize: K.label,
                      fontWeight: FontWeight.w600,
                      color: on ? p.primaryFg : p.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Empty / no-data state.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(K.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: p.textTertiary),
            const SizedBox(height: K.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: K.subtitle,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: K.xxs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: K.label,
                  color: p.textTertiary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Key/value fact pair grid (used in alert detail facts).
class FactGrid extends StatelessWidget {
  final Map<String, String> facts;

  const FactGrid({super.key, required this.facts});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final entries = facts.entries.toList();
    return Wrap(
      spacing: K.xs,
      runSpacing: K.xs,
      children: entries
          .map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: K.xs + 2, vertical: K.xxs + 1),
              decoration: BoxDecoration(
                color: p.surfaceSunken,
                borderRadius: BorderRadius.circular(K.rSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${e.key}: ',
                    style: TextStyle(
                      fontSize: K.caption,
                      color: p.textTertiary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    e.value,
                    style: TextStyle(
                      fontSize: K.caption,
                      color: p.text,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Compact page title bar with optional actions.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(K.lg, K.md, K.lg, K.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: K.headline,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: p.text,
                    fontFamily: 'Inter',
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: K.label,
                      color: p.textTertiary,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          ...actions.map((a) => Padding(padding: const EdgeInsets.only(left: K.xs), child: a)),
        ],
      ),
    );
  }
}

/// Formats a duration into a compact relative time label.
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return '${d.inSeconds}s ago';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

/// Formats clock time as HH:MM.
String clockOf(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Money formatter.
String usd(double v) {
  if (v >= 100000) return '\$${(v / 1000).toStringAsFixed(0)}k';
  if (v >= 10000) return '\$${(v / 1000).toStringAsFixed(1)}k';
  if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(2)}k';
  return '\$${v.toStringAsFixed(v < 100 ? 2 : 0)}';
}

/// Distance formatter (km with thousand separators).
String kmFmt(double v) {
  final n = v.round();
  final s = n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '$s km';
}
