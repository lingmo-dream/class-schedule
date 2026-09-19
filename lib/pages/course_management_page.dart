// 课程管理：维护课程基本信息，并查看和编辑课程安排。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';
import '../state/app_state.dart';
import '../utils/app_constants.dart';
import '../widgets/course_form_dialog.dart';

class CourseManagementPage extends StatelessWidget {
  const CourseManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('课程管理', style: Theme.of(context).textTheme.titleLarge),
                FilledButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const CourseFormDialog(),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('新增课程'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.courses.isEmpty
                  ? const Center(child: Text('还没有课程，点击右上角新增'))
                  : ListView.builder(
                      itemCount: state.courses.length,
                      itemBuilder: (context, index) =>
                          _CourseTile(course: state.courses[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final schedules = state.schedules
        .where((item) => item.courseId == course.id)
        .toList();
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              courseColors[course.colorIndex % courseColors.length],
        ),
        title: Text(course.name),
        subtitle: Text(
          [
            course.teacher,
            course.location,
          ].where((item) => item.isNotEmpty).join(' · '),
        ),
        trailing: Wrap(
          children: [
            IconButton(
              tooltip: '编辑',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => CourseFormDialog(course: course),
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '删除',
              onPressed: () => state.deleteCourse(course.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        children: schedules.isEmpty
            ? [const ListTile(title: Text('暂无时间安排'))]
            : schedules
                  .map(
                    (schedule) => ListTile(
                      dense: true,
                      title: Text(
                        '${weekdays[schedule.weekday - 1]} · 第${schedule.startPeriod}-${schedule.endPeriod}节',
                      ),
                      subtitle: Text(schedule.weekType.label),
                      trailing: IconButton(
                        tooltip: '编辑安排',
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => CourseFormDialog(schedule: schedule),
                        ),
                        icon: const Icon(Icons.edit_calendar_outlined),
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
  }
}
