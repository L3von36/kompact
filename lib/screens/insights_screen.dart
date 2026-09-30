import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../ui/adaptive_scaffold.dart';
import '../ui/charts.dart';
import '../ui/widgets.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 1080;
    final last14 = state.completionsPerDay(14);
    final total14 = last14.fold(0, (a, b) => a + b);
    final best = last14.fold(0, math.max);
    final avg = (total14 / 14 * 10).round() / 10;

    return PagePadding(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'Insights',
              subtitle: 'Momentum over the last 14 days',
            ),
          ),
          SliverToBoxAdapter(
            child: _statRow(context, total14, avg, best, state.streak,
                (state.completionRate7d * 100).round()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.m)),
          SliverToBoxAdapter(
            child: _trendCard(context, last14),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.m)),
          SliverToBoxAdapter(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _weekCard(context, state)),
                      const SizedBox(width: K.m),
                      Expanded(child: _categoryCard(context, state)),
                    ],
                  )
                : Column(children: [
                    _weekCard(context, state),
                    const SizedBox(height: K.m),
                    _categoryCard(context, state),
                  ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.l)),
        ],
      ),
    );
  }

  Widget _statRow(
      BuildContext context, int total, double avg, int best, int streak, int rate) {
    return Row(
      children: [
        Expanded(child: _Stat('COMPLETED 14D', '$total', 'tasks')),
        const SizedBox(width: K.m),
        Expanded(child: _Stat('DAILY AVERAGE', '$avg', 'per day')),
        const SizedBox(width: K.m),
        Expanded(child: _Stat('BEST DAY', '$best', 'in one day')),
        const SizedBox(width: K.m),
        Expanded(child: _Stat('CURRENT STREAK', '$streak', 'days')),
        const SizedBox(width: K.m),
        Expanded(child: _Stat('7D RATE', '$rate%', 'completion')),
      ],
    );
  }

  Widget _trendCard(BuildContext context, List<int> values) {
    final scheme = Theme.of(context).colorScheme;
    final maxV = values.fold(1, math.max);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Momentum',
            trailing: Text(
              'max $maxV/day',
              style: microLabel(context).copyWith(color: scheme.primary),
            ),
          ),
          const SizedBox(height: K.xs),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Expanded(
                    child: Tooltip(
                      message:
                          '${_dayLabel(i, values.length)}: ${values[i]}',
                      waitDuration: const Duration(milliseconds: 300),
                      child: _TrendBar(
                        value: values[i],
                        max: maxV,
                        isToday: i == values.length - 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: K.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_dayLabel(0, values.length),
                  style: microLabel(context).copyWith(fontSize: 9)),
              Text(_dayLabel(values.length - 1, values.length),
                  style: microLabel(context).copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  static String _dayLabel(int indexFromOldest, int total) {
    final d = DateTime.now().subtract(Duration(days: total - 1 - indexFromOldest));
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  Widget _weekCard(BuildContext context, AppState state) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Weekday rhythm'),
          const SizedBox(height: K.xs),
          WeeklyBarChart(data: state.weekdayCompletions(), height: 150),
          const SizedBox(height: K.s),
          Text('Completions per weekday · last 7 days',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _categoryCard(BuildContext context, AppState state) {
    final cats = state.categoryCounts();
    final active = state.activeTasks.length;
    final slices = <(Color, int)>[
      for (final c in cats.take(6)) (K.categoryColor(c.category), c.count),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Where work sits'),
          const SizedBox(height: K.m),
          if (cats.isEmpty)
            Text('No active tasks to distribute.',
                style: Theme.of(context).textTheme.bodySmall!)
          else
            Wrap(
              spacing: K.xl,
              runSpacing: K.l,
              children: [
                DonutChart(
                  slices: slices,
                  centerValue: '$active',
                  centerLabel: 'ACTIVE',
                  size: 128,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    children: [
                      for (final c in cats)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: K.categoryColor(c.category),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(c.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.1)),
                              ),
                              Text('${c.count}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.unit);

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: microLabel(context)),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'InterDisplay',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.05,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            unit,
            style: TextStyle(
              fontFamily: K.fontFamily,
              fontSize: 10.5,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.value,
    required this.max,
    required this.isToday,
  });

  final int value;
  final int max;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = (value / max) * 118;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (value > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '$value',
              style: TextStyle(
                fontFamily: K.fontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isToday
                    ? scheme.primary
                    : scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
        Container(
          height: h.clamp(3.0, double.infinity),
          decoration: BoxDecoration(
            color: value == 0
                ? scheme.onSurfaceVariant.withValues(alpha: 0.13)
                : isToday
                    ? scheme.primary
                    : scheme.primary.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ),
      ],
    );
  }
}
