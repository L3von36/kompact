import 'models.dart';

DateTime _daysAgo(int d, [int hour = 10]) =>
    DateTime.now().subtract(Duration(days: d)).copyWith(hour: hour);

DateTime _inDays(int d) =>
    DateTime.now().add(Duration(days: d)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

List<Task> seedTasks() => [
      // ---- active ----
      Task(
        id: 't1',
        title: 'Finalize compact layout system tokens',
        category: 'Design',
        priority: Priority.high,
        dueDate: _inDays(0),
        createdAt: _daysAgo(2),
      ),
      Task(
        id: 't2',
        title: 'Wire CI matrix for all six targets',
        category: 'Development',
        priority: Priority.high,
        dueDate: _inDays(1),
        createdAt: _daysAgo(1),
      ),
      Task(
        id: 't3',
        title: 'Audit spacing on 320dp-wide screens',
        category: 'Design',
        priority: Priority.medium,
        dueDate: _inDays(2),
        createdAt: _daysAgo(1),
      ),
      Task(
        id: 't4',
        title: 'Compare state containers under 60fps budget',
        category: 'Research',
        priority: Priority.low,
        createdAt: _daysAgo(3),
      ),
      Task(
        id: 't5',
        title: 'Ship release notes template',
        category: 'Ops',
        priority: Priority.medium,
        dueDate: _inDays(4),
        createdAt: _daysAgo(2),
      ),
      Task(
        id: 't6',
        title: 'Evening walk — 30 minutes',
        category: 'Personal',
        priority: Priority.low,
        dueDate: _inDays(0),
        createdAt: _daysAgo(0, 8),
      ),
      Task(
        id: 't7',
        title: 'Refactor persistence layer to typed adapters',
        category: 'Development',
        priority: Priority.medium,
        createdAt: _daysAgo(5),
      ),
      Task(
        id: 't8',
        title: 'Collect feedback on the dense table view',
        category: 'Research',
        priority: Priority.low,
        dueDate: _inDays(6),
        createdAt: _daysAgo(2),
      ),
      Task(
        id: 't9',
        title: 'Set up crash reporting for desktop builds',
        category: 'Ops',
        priority: Priority.low,
        createdAt: _daysAgo(6),
      ),
      Task(
        id: 't10',
        title: 'Sketch 3 dashboard variants',
        category: 'Design',
        priority: Priority.medium,
        dueDate: _inDays(3),
        createdAt: _daysAgo(1),
      ),
      // ---- completed (spread over the last two weeks for alive charts) ----
      Task(
        id: 't11',
        title: 'Pick the accent palette (6 options)',
        category: 'Design',
        priority: Priority.medium,
        createdAt: _daysAgo(12),
        completedAt: _daysAgo(12, 15),
      ),
      Task(
        id: 't12',
        title: 'Bundled Inter static weights',
        category: 'Development',
        priority: Priority.high,
        createdAt: _daysAgo(11),
        completedAt: _daysAgo(11, 11),
      ),
      Task(
        id: 't13',
        title: 'Read up on visual density guidelines',
        category: 'Research',
        priority: Priority.low,
        createdAt: _daysAgo(10),
        completedAt: _daysAgo(10, 16),
      ),
      Task(
        id: 't14',
        title: 'Draft compact KPI card component',
        category: 'Design',
        priority: Priority.high,
        createdAt: _daysAgo(9),
        completedAt: _daysAgo(9, 10),
      ),
      Task(
        id: 't15',
        title: 'Book dentist appointment',
        category: 'Personal',
        priority: Priority.medium,
        createdAt: _daysAgo(8),
        completedAt: _daysAgo(8, 9),
      ),
      Task(
        id: 't16',
        title: 'Scaffold adaptive navigation shell',
        category: 'Development',
        priority: Priority.high,
        createdAt: _daysAgo(7),
        completedAt: _daysAgo(7, 13),
      ),
      Task(
        id: 't17',
        title: 'Trim startup time below 400ms',
        category: 'Development',
        priority: Priority.medium,
        createdAt: _daysAgo(6),
        completedAt: _daysAgo(6, 17),
      ),
      Task(
        id: 't18',
        title: 'Weekly review — priorities reset',
        category: 'Personal',
        priority: Priority.low,
        createdAt: _daysAgo(5),
        completedAt: _daysAgo(5, 18),
      ),
      Task(
        id: 't19',
        title: 'Add keyboard shortcuts reference',
        category: 'Development',
        priority: Priority.medium,
        createdAt: _daysAgo(4),
        completedAt: _daysAgo(4, 12),
      ),
      Task(
        id: 't20',
        title: 'Test dark theme contrast ratios',
        category: 'Design',
        priority: Priority.high,
        createdAt: _daysAgo(3),
        completedAt: _daysAgo(3, 14),
      ),
      Task(
        id: 't21',
        title: 'Cleanup unused icon imports',
        category: 'Ops',
        priority: Priority.low,
        createdAt: _daysAgo(2),
        completedAt: _daysAgo(2, 16),
      ),
      Task(
        id: 't22',
        title: 'Sync device frames for screenshots',
        category: 'Ops',
        priority: Priority.medium,
        createdAt: _daysAgo(1),
        completedAt: _daysAgo(1, 15),
      ),
      Task(
        id: 't23',
        title: 'Morning deep-work block',
        category: 'Personal',
        priority: Priority.medium,
        createdAt: _daysAgo(0, 7),
        completedAt: _daysAgo(0, 9),
      ),
    ];

List<Note> seedNotes() => [
      Note(
        id: 'n1',
        title: 'Compact design principles',
        body:
            'Less space, full function.\n'
            '· 4px grid, no exception\n'
            '· one accent hue, neutral everything else\n'
            '· hairlines over shadows\n'
            '· density is a feature, not a compromise',
        colorIndex: 0,
        createdAt: _daysAgo(6),
      ),
      Note(
        id: 'n2',
        title: 'Release checklist',
        body:
            '1. Bump version\n'
            '2. Push to main\n'
            '3. CI builds all six targets\n'
            '4. Attach artifacts to the GitHub release\n'
            '5. Paste the Pages URL into the changelog',
        colorIndex: 2,
        createdAt: _daysAgo(4),
      ),
      Note(
        id: 'n3',
        title: 'Sprint retro ideas',
        body:
            'Keep: tight scope, dense UI reviews.\n'
            'Drop: long status meetings.\n'
            'Try: async demos recorded per platform.',
        colorIndex: 1,
        createdAt: _daysAgo(3),
      ),
      Note(
        id: 'n4',
        title: 'Keyboard-first flows',
        body:
            'N to add a note, T for task, / to focus search. '
            'Esc always closes. Every list action reachable without the mouse.',
        colorIndex: 4,
        createdAt: _daysAgo(2),
      ),
      Note(
        id: 'n5',
        title: 'Reading list',
        body:
            '· Visual density across platforms\n'
            '· The 80/20 of dashboards\n'
            '· Typography at small sizes',
        colorIndex: 5,
        createdAt: _daysAgo(1),
      ),
      Note(
        id: 'n6',
        title: 'Water the plants 🌱',
        body: 'Fern twice a week. Succulent when guilty.',
        colorIndex: 3,
        createdAt: _daysAgo(0, 8),
      ),
    ];
