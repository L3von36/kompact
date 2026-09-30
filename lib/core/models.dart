import 'dart:math';

/// Task priority levels.
enum Priority { low, medium, high }

Priority priorityFromName(String name) => Priority.values.firstWhere(
      (p) => p.name == name,
      orElse: () => Priority.medium,
    );

/// A task item.
class Task {
  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    this.dueDate,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  String category;
  Priority priority;
  DateTime? dueDate;
  final DateTime createdAt;
  DateTime? completedAt;

  bool get done => completedAt != null;

  bool get isOverdue {
    if (done || dueDate == null) return false;
    final today = DateTime.now();
    return dueDate!.isBefore(DateTime(today.year, today.month, today.day));
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  /// Days until due (negative = overdue). Null when no due date.
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    return due.difference(today).inDays;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        priority: priorityFromName(json['priority'] as String? ?? 'medium'),
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate'] as String),
        createdAt: json['createdAt'] == null
            ? DateTime.now()
            : DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );

  Task copyWith({String? title, String? category, Priority? priority, DateTime? dueDate}) =>
      Task(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt,
        completedAt: completedAt,
      );
}

/// A quick note.
class Note {
  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.colorIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  String title;
  String body;
  int colorIndex;
  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'colorIndex': colorIndex,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] == null
            ? DateTime.now()
            : DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.parse(json['updatedAt'] as String),
      );
}

/// Visual density preference.
enum DensityMode { compact, comfortable }

DensityMode densityFromName(String? name) => DensityMode.values.firstWhere(
      (d) => d.name == name,
      orElse: () => DensityMode.compact,
    );

/// User-adjustable app settings.
class AppSettings {
  AppSettings({
    this.themeModeIndex = 0, // 0 system, 1 light, 2 dark
    this.accentIndex = 0,
    this.density = DensityMode.compact,
  });

  int themeModeIndex;
  int accentIndex;
  DensityMode density;

  Map<String, dynamic> toJson() => {
        'themeModeIndex': themeModeIndex,
        'accentIndex': accentIndex,
        'density': density.name,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeModeIndex: (json['themeModeIndex'] as num?)?.toInt() ?? 0,
        accentIndex: (json['accentIndex'] as num?)?.toInt() ?? 0,
        density: densityFromName(json['density'] as String?),
      );
}

String newId() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
    Random().nextInt(1 << 32).toRadixString(36);
