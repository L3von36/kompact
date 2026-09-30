import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../ui/adaptive_scaffold.dart';
import '../ui/charts.dart';
import '../ui/task_widgets.dart';
import '../ui/widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 1080;

    return PagePadding(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'Overview',
              subtitle: _dateLine(),
              trailing: HeaderAction(
                icon: Icons.add,
                tooltip: 'New task',
                onTap: () => showTaskEditor(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _kpiRow(context, state, wide),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.m)),
          SliverToBoxAdapter(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _focusCard(context, state)),
                      const SizedBox(width: K.m),
                      Expanded(flex: 2, child: _weeklyCard(context, state)),
                    ],
                  )
                : Column(children: [
                    _focusCard(context, state),
                    const SizedBox(height: K.m),
                    _weeklyCard(context, state),
                  ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.m)),
          SliverToBoxAdapter(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _activityCard(context, state)),
                      const SizedBox(width: K.m),
                      Expanded(flex: 2, child: _categoryCard(context, state)),
                    ],
                  )
                : Column(children: [
                    _activityCard(context, state),
                    const SizedBox(height: K.m),
                    _categoryCard(context, state),
                  ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.l)),
        ],
      ),
    );
  }

  static String _dateLine() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _kpiRow(BuildContext context, AppState state, bool wide) {
    final spark14 = state.completionsPerDay(14);
    final spark7 = spark14.sublist(7);
    return Row(
      children: [
        Expanded(
          child: _Kpi(
            label: 'ACTIVE',
            value: state.activeTasks.length,
            sub: '${state.overdueCount} overdue',
            subColor: state.overdueCount > 0 ? K.danger : null,
            spark: spark7,
          ),
        ),
        const SizedBox(width: K.m),
        Expanded(
          child: _Kpi(
            label: 'DONE TODAY',
            value: state.doneToday,
            sub: '${state.totalCompleted} all time',
            spark: spark7,
          ),
        ),
        const SizedBox(width: K.m),
        Expanded(
          child: _Kpi(
            label: 'STREAK',
            value: state.streak,
            sub: state.streak == 1 ? 'day in a row' : 'days in a row',
            spark: spark7,
          ),
        ),
        const SizedBox(width: K.m),
        Expanded(
          child: _Kpi(
            label: '7D RATE',
            value: (state.completionRate7d * 100).round(),
            suffix: '%',
            sub: 'completion',
            spark: spark7,
          ),
        ),
      ],
    );
  }

  Widget _focusCard(BuildContext context, AppState state) {
    final focus = state.activeTasks.take(4).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Focus now',
            trailing: Text(
              '${state.activeTasks.length} active',
              style: microLabel(context).copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (focus.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: K.xl),
              child: EmptyState(
                icon: Icons.task_alt,
                title: 'All clear',
                message: 'Nothing pending. Add a task to keep the momentum going.',
                action: FilledButton.icon(
                  onPressed: () => showTaskEditor(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New task'),
                ),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < focus.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  TaskTile(
                    task: focus[i],
                    onChanged: (_) => state.toggleTask(focus[i].id),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _weeklyCard(BuildContext context, AppState state) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('This week'),
          const SizedBox(height: K.xs),
          WeeklyBarChart(data: state.weekdayCompletions()),
          const SizedBox(height: K.s),
          Text(
            'Completed per day · today highlighted',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _activityCard(BuildContext context, AppState state) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Activity',
            trailing: _legend(context),
          ),
          const SizedBox(height: K.s),
          ActivityStrip(values: state.completionsPerDay(14 * 7)),
          const SizedBox(height: K.s),
          Text(
            'Last 14 weeks · completions per day',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('less', style: microLabel(context).copyWith(fontSize: 9)),
        const SizedBox(width: 4),
        for (final a in [0.10, 0.35, 0.60, 1.0])
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: a),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        Text('more', style: microLabel(context).copyWith(fontSize: 9)),
      ],
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
          const SectionHeader('Load by category'),
          const SizedBox(height: K.s),
          Row(
            children: [
              DonutChart(
                slices: slices,
                centerValue: '$active',
                centerLabel: 'ACTIVE',
                size: 118,
              ),
              const SizedBox(width: K.l),
              Expanded(
                child: Column(
                  children: [
                    for (final c in cats.take(5))
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
                              child: Text(
                                c.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            Text(
                              '${c.count}',
                              style: TextStyle(
                                fontFamily: K.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color:
                                    Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
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

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.sub,
    required this.spark,
    this.suffix = '',
    this.subColor,
  });

  final String label;
  final int value;
  final String sub;
  final List<int> spark;
  final String suffix;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: microLabel(context)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCounter(
                value,
                style: TextStyle(
                  fontFamily: 'InterDisplay',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  height: 1.05,
                  color: scheme.onSurface,
                ),
              ),
              if (suffix.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      fontFamily: K.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              fontFamily: K.fontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.05,
              color: subColor ??
                  scheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Sparkline(values: spark),
        ],
      ),
    );
  }
}
