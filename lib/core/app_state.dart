import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'seed.dart';

/// Central observable application state with persistence.
class AppState extends ChangeNotifier {
  AppState() {
    _load();
  }

  final List<Task> _tasks = [];
  final List<Note> _notes = [];
  AppSettings settings = AppSettings();

  bool loaded = false;

  // ---------------------------------------------------------------- getters

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Note> get notes => List.unmodifiable(_notes);

  List<Task> get activeTasks =>
      _tasks.where((t) => !t.done).toList()
        ..sort(TaskCompare.byPriorityThenDue);

  List<Task> get completedTasks {
    final done = _tasks.where((t) => t.done).toList();
    done.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return done;
  }

  int get doneToday => _tasks
      .where((t) => t.done && _sameDay(t.completedAt!, DateTime.now()))
      .length;

  int get overdueCount =>
      _tasks.where((t) => t.isOverdue).length;

  /// Consecutive days (ending today or yesterday) with at least one completion.
  int get streak {
    final days = _completionDays();
    if (days.isEmpty) return 0;
    var streak = 0;
    var cursor = DateTime.now();
    if (!days.contains(_dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(_dayKey(cursor))) return 0;
    }
    while (days.contains(_dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Completions per day for the last [days] days, oldest first.
  List<int> completionsPerDay(int days) {
    final counts = <String, int>{};
    for (final t in _tasks) {
      if (t.done) {
        final key = _dayKey(t.completedAt!);
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final now = DateTime.now();
    return List.generate(days, (i) {
      final d = now.subtract(Duration(days: days - 1 - i));
      return counts[_dayKey(d)] ?? 0;
    });
  }

  /// Completions per weekday for the last 7 days, oldest first, with labels.
  List<DayCount> weekdayCompletions() {
    final counts = <String, int>{};
    for (final t in _tasks) {
      if (t.done) {
        final key = _dayKey(t.completedAt!);
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    // weekday: Mon=1..Sun=7. Align the last 7 days so index 0 is 6 days ago.
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DayCount(labels[d.weekday - 1], counts[_dayKey(d)] ?? 0,
          isToday: i == 6);
    });
  }

  /// Active-task count per category, sorted desc.
  List<CategoryCount> categoryCounts() {
    final counts = <String, int>{};
    for (final t in _tasks) {
      if (!t.done) counts[t.category] = (counts[t.category] ?? 0) + 1;
    }
    final list = counts.entries
        .map((e) => CategoryCount(e.key, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  double get completionRate7d {
    final created = _tasks
        .where((t) => t.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;
    final done = _tasks
        .where((t) =>
            t.done &&
            t.completedAt!
                .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;
    if (created + done == 0) return 0;
    return (done / (created + done)).clamp(0.0, 1.0);
  }

  int get totalCompleted => _tasks.where((t) => t.done).length;

  Set<String> _completionDays() => _tasks
      .where((t) => t.done)
      .map((t) => _dayKey(t.completedAt!))
      .toSet();

  // ------------------------------------------------------------- mutations

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    notifyListeners();
    await _persist();
  }

  Future<void> updateTask(Task task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i >= 0) {
      _tasks[i] = task;
      notifyListeners();
      await _persist();
    }
  }

  Future<void> toggleTask(String id) async {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final t = _tasks[i];
    if (t.done) {
      t.completedAt = null;
    } else {
      t.completedAt = DateTime.now();
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> addNote(Note note) async {
    _notes.insert(0, note);
    notifyListeners();
    await _persist();
  }

  Future<void> updateNote(Note note) async {
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (i >= 0) {
      note.updatedAt = DateTime.now();
      _notes[i] = note;
      notifyListeners();
      await _persist();
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    await _persist();
  }

  void setThemeMode(int index) {
    settings.themeModeIndex = index;
    notifyListeners();
    _persist();
  }

  void setAccent(int index) {
    settings.accentIndex = index;
    notifyListeners();
    _persist();
  }

  void setDensity(DensityMode mode) {
    settings.density = mode;
    notifyListeners();
    _persist();
  }

  Future<void> loadDemoData() async {
    _tasks
      ..clear()
      ..addAll(seedTasks());
    _notes
      ..clear()
      ..addAll(seedNotes());
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    _tasks.clear();
    _notes.clear();
    notifyListeners();
    await _persist();
  }

  // ------------------------------------------------------------ persistence

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksRaw = prefs.getString('kompact.tasks');
      final notesRaw = prefs.getString('kompact.notes');
      final settingsRaw = prefs.getString('kompact.settings');
      final seeded = prefs.getBool('kompact.seeded') ?? false;

      if (tasksRaw != null) {
        final list = jsonDecode(tasksRaw) as List<dynamic>;
        _tasks.addAll(list.map((e) => Task.fromJson(e as Map<String, dynamic>)));
      }
      if (notesRaw != null) {
        final list = jsonDecode(notesRaw) as List<dynamic>;
        _notes.addAll(list.map((e) => Note.fromJson(e as Map<String, dynamic>)));
      }
      if (settingsRaw != null) {
        settings =
            AppSettings.fromJson(jsonDecode(settingsRaw) as Map<String, dynamic>);
      }

      // First run: load friendly demo content so the app feels alive.
      if (!seeded && _tasks.isEmpty && _notes.isEmpty) {
        await prefs.setBool('kompact.seeded', true);
        _tasks.addAll(seedTasks());
        _notes.addAll(seedNotes());
        await _persist();
      }
      loaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Kompact: failed to load state: $e');
      }
      loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'kompact.tasks', jsonEncode(_tasks.map((t) => t.toJson()).toList()));
      await prefs.setString(
          'kompact.notes', jsonEncode(_notes.map((n) => n.toJson()).toList()));
      await prefs.setString('kompact.settings', jsonEncode(settings.toJson()));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Kompact: failed to persist state: $e');
      }
    }
  }

  /// JSON export of everything (used by Settings → Export).
  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'exportedAt': DateTime.now().toIso8601String(),
        'tasks': _tasks.map((t) => t.toJson()).toList(),
        'notes': _notes.map((n) => n.toJson()).toList(),
        'settings': settings.toJson(),
      });

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class TaskCompare {
  static int byPriorityThenDue(Task a, Task b) {
    final p = b.priority.index.compareTo(a.priority.index); // high first
    if (p != 0) return p;
    final ad = a.dueDate, bd = b.dueDate;
    if (ad == null && bd == null) return b.createdAt.compareTo(a.createdAt);
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  }
}

class DayCount {
  DayCount(this.label, this.count, {this.isToday = false});
  final String label;
  final int count;
  final bool isToday;
}

class CategoryCount {
  CategoryCount(this.category, this.count);
  final String category;
  final int count;
}
