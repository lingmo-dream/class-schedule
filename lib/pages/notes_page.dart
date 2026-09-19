// 笔记页面：左侧课程分类，右侧笔记内容，移动端自动上下排列。
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../state/app_state.dart';
import '../utils/identifiers.dart';
import '../widgets/empty_state.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String? selectedCourse;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notes = state.notes
        .where(
          (note) => selectedCourse == null || note.courseId == selectedCourse,
        )
        .toList();
    final categories = <Widget>[
      ListTile(
        selected: selectedCourse == null,
        leading: const Icon(Icons.all_inclusive),
        title: const Text('全部笔记'),
        onTap: () => setState(() => selectedCourse = null),
      ),
      ...state.courses.map(
        (course) => ListTile(
          selected: selectedCourse == course.id,
          leading: const Icon(Icons.menu_book_outlined),
          title: Text(course.name),
          onTap: () => setState(() => selectedCourse = course.id),
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '学习笔记',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('写笔记'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final list = ListView.separated(
                  shrinkWrap: !wide,
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _NoteCard(
                    note: notes[index],
                    onEdit: () => _edit(notes[index]),
                  ),
                );
                final sidebar = Card(
                  child: ListView(shrinkWrap: true, children: categories),
                );
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 220, child: sidebar),
                          const SizedBox(width: 16),
                          Expanded(
                            child: notes.isEmpty
                                ? const EmptyState(
                                    title: '还没有笔记',
                                    actionLabel: '写第一条笔记',
                                    onAction: null,
                                    icon: Icons.notes_outlined,
                                  )
                                : list,
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          sidebar,
                          const SizedBox(height: 12),
                          if (notes.isEmpty)
                            const SizedBox(
                              height: 260,
                              child: EmptyState(
                                title: '还没有笔记',
                                icon: Icons.notes_outlined,
                              ),
                            )
                          else
                            list,
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit([Note? note]) async {
    final state = context.read<AppState>();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(note: note),
    );
    if (result == null || result.trim().isEmpty) return;
    if (note == null) {
      await state.addNote(
        Note(
          id: createId(),
          courseId: selectedCourse,
          content: result.trim(),
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await state.editNote(
        Note(
          id: note.id,
          courseId: note.courseId,
          content: result.trim(),
          createdAt: note.createdAt,
        ),
      );
    }
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onEdit});
  final Note note;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.content, maxLines: 5, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(note.createdAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    ),
  );
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({this.note});
  final Note? note;
  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.note?.content ?? '',
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.note == null ? '写笔记' : '编辑笔记'),
    content: TextField(
      controller: controller,
      autofocus: true,
      maxLines: 8,
      decoration: const InputDecoration(hintText: '记录课程重点、作业或灵感'),
    ),
    actions: [
      IconButton(
        tooltip: '图片功能暂未开放',
        onPressed: null,
        icon: const Icon(Icons.image_outlined),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text),
        child: const Text('保存'),
      ),
    ],
  );
}
