import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'widgets.dart';

/// Human-friendly relative date label.
String dueLabel(Task t) {
  final d = t.daysUntilDue;
  if (d == null) return '';
  if (d == 0) return 'Today';
  if (d == 1) return 'Tomorrow';
  if (d == -1) return '1d overdue';
  if (d < 0) return '${-d}d overdue';
  if (d < 7) return '${d}d';
  return 'w${(d / 7).ceil()}';
}

/// Compact task row: checkbox, title, meta chips, overflow menu.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.showCategory = true,
    this.onChanged,
  });

  final Task task;
  final bool showCategory;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = task.done;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // priority edge
          Container(
            width: 3,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: K.priorityColor(task.priority)
                  .withValues(alpha: done ? 0.25 : 0.9),
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(2)),
            ),
            height: 34,
          ),
          InkWell(
            onTap: () => (onChanged ?? _defaultToggle)(!done),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _AnimatedCheck(checked: done, size: 17),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 9, 6, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: K.fontFamily,
                      fontSize: 13,
                      fontWeight: done ? FontWeight.w400 : FontWeight.w500,
                      letterSpacing: -0.1,
                      height: 1.25,
                      color: done
                          ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
                          : scheme.onSurface,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor:
                          scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      if (showCategory)
                        PillChip(
                          task.category,
                          color: K.categoryColor(task.category),
                          dense: true,
                        ),
                      if (task.daysUntilDue != null)
                        PillChip(
                          dueLabel(task),
                          icon: Icons.schedule,
                          color: task.isOverdue
                              ? K.danger
                              : task.isDueToday
                                  ? scheme.primary
                                  : null,
                          dense: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          TaskMenu(task: task),
        ],
      ),
    );
  }

  void _defaultToggle(bool v) {}
}

/// Trailing overflow menu (edit / delete).
class TaskMenu extends StatelessWidget {
  const TaskMenu({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: 'Task options',
      icon: Icon(Icons.more_horiz,
          size: 18, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 160),
      onSelected: (value) {
        final state = context.read<AppState>();
        if (value == 'edit') {
          showTaskEditor(context, existing: task);
        } else if (value == 'delete') {
          state.deleteTask(task.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${_short(task.title)}"'),
              width: 420,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () => state.addTask(task),
              ),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          height: 38,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 10),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 38,
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 16, color: K.danger),
              const SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: scheme.error)),
            ],
          ),
        ),
      ],
    );
  }

  static String _short(String s) =>
      s.length > 28 ? '${s.substring(0, 28)}…' : s;
}

/// Compact animated check glyph.
class _AnimatedCheck extends StatefulWidget {
  const _AnimatedCheck({required this.checked, required this.size});

  final bool checked;
  final double size;

  @override
  State<_AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<_AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

  @override
  void initState() {
    super.initState();
    if (widget.checked) _controller.value = 1;
  }

  @override
  void didUpdateWidget(_AnimatedCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checked != oldWidget.checked) {
      widget.checked ? _controller.forward() : _controller.reverse();
    }
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
        final t = Curves.easeOut.transform(_controller.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.transparent,
              scheme.primary,
              t,
            ),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Color.lerp(
                scheme.onSurfaceVariant.withValues(alpha: 0.5),
                scheme.primary,
                t,
              )!,
              width: 1.6,
            ),
          ),
          child: t > 0.4
              ? Transform.scale(
                  scale: ((t - 0.4) / 0.6).clamp(0.0, 1.0),
                  child: Icon(Icons.check,
                      size: widget.size - 5,
                      color: Colors.white,
                      weight: 700),
                )
              : null,
        );
      },
    );
  }
}

/// Opens the compact task editor (create or edit).
Future<void> showTaskEditor(
  BuildContext context, {
  Task? existing,
  String presetCategory = 'Development',
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _TaskEditorDialog(existing: existing, presetCategory: presetCategory),
  );
}

class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog({this.existing, this.presetCategory = 'Development'});

  final Task? existing;
  final String presetCategory;

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _category;
  late Priority _priority;
  DateTime? _due;
  late final FocusNode _titleFocus;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _category =
        TextEditingController(text: widget.existing?.category ?? widget.presetCategory);
    _priority = widget.existing?.priority ?? Priority.medium;
    _due = widget.existing?.dueDate;
    _titleFocus = FocusNode();
    if (widget.existing == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _titleFocus.requestFocus());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 560;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(K.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.existing == null ? 'New task' : 'Edit task'),
                const SizedBox(height: K.m),
                TextField(
                  controller: _title,
                  focusNode: _titleFocus,
                  autofocus: widget.existing == null,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: const InputDecoration(
                    hintText: 'What needs to be done?',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _save(),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: K.m),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _categoryField()),
                      const SizedBox(width: K.m),
                      Expanded(child: _dueField()),
                    ],
                  )
                else ...[
                  _categoryField(),
                  const SizedBox(height: K.m),
                  _dueField(),
                ],
                const SizedBox(height: K.m),
                SectionHeader('Priority'),
                SegmentedButton<Priority>(
                  segments: const [
                    ButtonSegment(
                        value: Priority.low,
                        label: Text('Low'),
                        icon: Icon(Icons.flag_outlined, size: 14)),
                    ButtonSegment(
                        value: Priority.medium,
                        label: Text('Med'),
                        icon: Icon(Icons.flag, size: 14)),
                    ButtonSegment(
                        value: Priority.high,
                        label: Text('High'),
                        icon: Icon(Icons.flag, size: 14)),
                  ],
                  selected: {_priority},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _priority = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    side: WidgetStatePropertyAll(
                        BorderSide(color: scheme.outline)),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? scheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: K.l),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: K.s),
                    FilledButton(
                      onPressed: _save,
                      child: Text(widget.existing == null ? 'Add task' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Category'),
        TextField(
          controller: _category,
          style: const TextStyle(fontSize: 13.5),
          decoration: const InputDecoration(isDense: true),
        ),
      ],
    );
  }

  Widget _dueField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Due'),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(K.rS),
          child: Container(
            height: K.inputH,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(K.rS),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  _due == null
                      ? 'No due date'
                      : '${_due!.month}/${_due!.day}/${_due!.year}',
                  style: TextStyle(
                    fontFamily: K.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (_due != null)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 14,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _due = null),
                  ),
              ],
            ),
          ),
        ),
        if (_due == null) ...[
          const SizedBox(height: K.s),
          Wrap(
            spacing: 6,
            children: [
              PillChip('Today',
                  onTap: () => setState(
                      () => _due = _dayFromNow(0)),
                  selected: false),
              PillChip('Tomorrow',
                  onTap: () => setState(() => _due = _dayFromNow(1))),
              PillChip('Next week',
                  onTap: () => setState(() => _due = _dayFromNow(7))),
            ],
          ),
        ],
      ],
    );
  }

  static DateTime _dayFromNow(int days) {
    final n = DateTime.now().add(Duration(days: days));
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'SELECT DUE DATE',
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.r),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _due = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _titleFocus.requestFocus();
      return;
    }
    final state = context.read<AppState>();
    final existing = widget.existing;
    if (existing == null) {
      state.addTask(Task(
        id: newId(),
        title: title,
        category: _category.text.trim().isEmpty
            ? 'Development'
            : _category.text.trim(),
        priority: _priority,
        dueDate: _due,
      ));
    } else {
      state.updateTask(existing.copyWith(
        title: title,
        category: _category.text.trim().isEmpty ? 'Development' : _category.text.trim(),
        priority: _priority,
        dueDate: _due,
      ));
    }
    Navigator.of(context).pop();
  }
}
