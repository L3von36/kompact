import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/adaptive_scaffold.dart';
import '../ui/task_widgets.dart';
import '../ui/widgets.dart';

enum _TaskFilter { all, today, upcoming, overdue, done }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _search = TextEditingController();
  _TaskFilter _filter = _TaskFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final list = _filteredList(state);
    final grouped = _grouped(list);

    return PagePadding(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'Tasks',
              subtitle: '${state.activeTasks.length} active · ${state.totalCompleted} completed',
              trailing: HeaderAction(
                icon: Icons.add,
                tooltip: 'New task',
                onTap: () => showTaskEditor(context),
              ),
            ),
          ),
          // search + filters
          SliverToBoxAdapter(
            child: wide
                ? Row(
                    children: [
                      SizedBox(width: 340, child: _searchField()),
                      const SizedBox(width: K.m),
                      Expanded(child: _filterChips()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _searchField(),
                      const SizedBox(height: K.s),
                      _filterChips(),
                    ],
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.m)),
          if (grouped.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'No matching tasks',
                message: _filter == _TaskFilter.all
                    ? 'Add your first task to get started.'
                    : 'Try a different filter or search term.',
                action: FilledButton.icon(
                  onPressed: () => showTaskEditor(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New task'),
                ),
              ),
            )
          else
            ...grouped.map(
              (g) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: K.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader('${g.label} · ${g.items.length}'),
                      for (var i = 0; i < g.items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        TaskTile(
                          task: g.items[i],
                          onChanged: (_) => state.toggleTask(g.items[i].id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: K.l)),
        ],
      ),
    );
  }

  Widget _searchField() {
    return SearchField(
      controller: _search,
      hint: 'Search tasks…',
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: K.inputH,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final f in _TaskFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: PillChip(
                _label(f),
                selected: _filter == f,
                onTap: () => setState(() => _filter = f),
              ),
            ),
        ],
      ),
    );
  }

  static String _label(_TaskFilter f) => switch (f) {
        _TaskFilter.all => 'All',
        _TaskFilter.today => 'Today',
        _TaskFilter.upcoming => 'Upcoming',
        _TaskFilter.overdue => 'Overdue',
        _TaskFilter.done => 'Done',
      };

  List<Task> _filteredList(AppState state) {
    final q = _search.text.trim().toLowerCase();
    Iterable<Task> tasks;
    switch (_filter) {
      case _TaskFilter.all:
        tasks = state.activeTasks;
      case _TaskFilter.today:
        tasks = state.activeTasks.where((t) => t.isDueToday || t.isOverdue);
      case _TaskFilter.upcoming:
        tasks = state.activeTasks
            .where((t) => t.dueDate != null && !t.isDueToday && !t.isOverdue);
      case _TaskFilter.overdue:
        tasks = state.activeTasks.where((t) => t.isOverdue);
      case _TaskFilter.done:
        tasks = state.completedTasks.take(50);
    }
    if (q.isNotEmpty) {
      tasks = tasks.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q));
    }
    return tasks.toList();
  }

  List<_Group> _grouped(List<Task> tasks) {
    if (_filter == _TaskFilter.done) {
      const labels = ['Today', 'Yesterday', 'Earlier'];
      final now = DateTime.now();
      final groups = <_Group>[
        for (final l in labels) _Group(l, []),
      ];
      for (final t in tasks) {
        final d = t.completedAt!;
        final diff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(d.year, d.month, d.day))
            .inDays;
        if (diff <= 0) {
          groups[0].items.add(t);
        } else if (diff == 1) {
          groups[1].items.add(t);
        } else {
          groups[2].items.add(t);
        }
      }
      return groups.where((g) => g.items.isNotEmpty).toList();
    }

    if (_filter == _TaskFilter.today || _filter == _TaskFilter.overdue) {
      final g = _Group(_label(_filter), tasks);
      return g.items.isEmpty ? [] : [g];
    }

    const labels = ['Overdue', 'Today', 'Upcoming', 'No date'];
    final groups = <_Group>[
      for (final l in labels) _Group(l, []),
    ];
    for (final t in tasks) {
      if (t.isOverdue) {
        groups[0].items.add(t);
      } else if (t.isDueToday) {
        groups[1].items.add(t);
      } else if (t.dueDate != null) {
        groups[2].items.add(t);
      } else {
        groups[3].items.add(t);
      }
    }
    return groups.where((g) => g.items.isNotEmpty).toList();
  }
}

class _Group {
  _Group(this.label, this.items);
  final String label;
  final List<Task> items;
}
