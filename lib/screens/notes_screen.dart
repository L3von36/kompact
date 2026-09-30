import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../ui/adaptive_scaffold.dart';
import '../ui/widgets.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final crossAxisCount = wide ? 4 : (MediaQuery.sizeOf(context).width >= 720 ? 3 : 2);

    final q = _search.text.trim().toLowerCase();
    final notes = q.isEmpty
        ? state.notes
        : state.notes
            .where((n) =>
                n.title.toLowerCase().contains(q) ||
                n.body.toLowerCase().contains(q))
            .toList();

    return PagePadding(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'Notes',
              subtitle: '${state.notes.length} saved',
              trailing: HeaderAction(
                icon: Icons.add,
                tooltip: 'New note',
                onTap: () => _openEditor(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              width: 340,
              child: SearchField(controller: _search, hint: 'Search notes…'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: K.m)),
          if (notes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.sticky_note_2_outlined,
                title: q.isEmpty ? 'No notes yet' : 'Nothing found',
                message: q.isEmpty
                    ? 'Capture quick thoughts — they stay on this device.'
                    : 'No note matches "$q".',
                action: FilledButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New note'),
                ),
              ),
            )
          else
            SliverGrid.builder(
              itemCount: notes.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: K.m,
                crossAxisSpacing: K.m,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, i) => _NoteCard(
                note: notes[i],
                onTap: () => _openEditor(context, existing: notes[i]),
                onChanged: () => setState(() {}),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: K.l)),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, {Note? existing}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _NoteEditorDialog(existing: existing),
    );
    if (mounted) setState(() {});
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap, this.onChanged});

  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = K.noteTints[note.colorIndex % K.noteTints.length];
    return AppCard(
      onTap: onTap,
      hoverable: true,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(K.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tint.withValues(alpha: scheme.brightness == Brightness.dark ? 0.10 : 0.14),
                    tint.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(K.m, K.m, K.m, K.s + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Expanded(
                  child: Text(
                    note.body,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      letterSpacing: -0.05,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _ago(note.updatedAt),
                  style: TextStyle(
                    fontFamily: K.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

class _NoteEditorDialog extends StatefulWidget {
  const _NoteEditorDialog({this.existing});

  final Note? existing;

  @override
  State<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<_NoteEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late int _colorIndex;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _body = TextEditingController(text: widget.existing?.body ?? '');
    _colorIndex = widget.existing?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(K.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing == null ? 'New note' : 'Edit note'),
              const SizedBox(height: K.m),
              TextField(
                controller: _title,
                autofocus: true,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                    hintText: 'Title', isDense: true),
              ),
              const SizedBox(height: K.s),
              Expanded(
                child: TextField(
                  controller: _body,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                  decoration: const InputDecoration(
                      hintText: 'Write anything…', isDense: true),
                ),
              ),
              const SizedBox(height: K.m),
              Row(
                children: [
                  for (var i = 0; i < K.noteTints.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: _ColorDot(
                        color: K.noteTints[i],
                        selected: _colorIndex == i,
                        onTap: () => setState(() => _colorIndex = i),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: K.s),
                  FilledButton(
                    onPressed: _save,
                    child: Text(widget.existing == null ? 'Save' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final state = context.read<AppState>();
    final existing = widget.existing;
    if (existing == null) {
      if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      state.addNote(Note(
        id: newId(),
        title: _title.text.trim(),
        body: _body.text.trimRight(),
        colorIndex: _colorIndex,
      ));
    } else {
      existing
        ..title = _title.text.trim()
        ..body = _body.text.trimRight()
        ..colorIndex = _colorIndex;
      state.updateNote(existing);
    }
    Navigator.of(context).pop();
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.22),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}
