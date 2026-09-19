// 课程详情操作面板：提供编辑、删除和复制到下一周入口。
import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';

class DetailBottomSheet extends StatelessWidget {
  const DetailBottomSheet({
    super.key,
    required this.course,
    required this.schedule,
    this.onEdit,
    this.onDelete,
    this.onCopy,
  });
  final Course course;
  final CourseSchedule schedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Wrap(
        runSpacing: 4,
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(
              course.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${course.teacher.isEmpty ? '未填写教师' : course.teacher} · ${course.location.isEmpty ? '未填写地点' : course.location}',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('编辑课程安排'),
            onTap: onEdit == null
                ? null
                : () {
                    Navigator.pop(context);
                    onEdit!();
                  },
          ),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('复制到下一周'),
            onTap: onCopy == null
                ? null
                : () {
                    Navigator.pop(context);
                    onCopy!();
                  },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '删除课程安排',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: onDelete == null
                ? null
                : () {
                    Navigator.pop(context);
                    onDelete!();
                  },
          ),
        ],
      ),
    ),
  );
}
