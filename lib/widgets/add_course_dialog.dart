// 新增或编辑课程安排的 Material 3 表单弹窗。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';
import '../state/app_state.dart';
import '../utils/app_constants.dart';
import '../utils/identifiers.dart';
import 'color_picker.dart';

class CourseFormDialog extends StatefulWidget {
  const CourseFormDialog({
    super.key,
    this.course,
    this.schedule,
    this.initialWeekday,
    this.initialStartPeriod,
  });
  final Course? course;
  final CourseSchedule? schedule;
  final int? initialWeekday;
  final int? initialStartPeriod;

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController teacher;
  late final TextEditingController location;
  late final TextEditingController remark;
  late int colorIndex;
  late int weekday;
  late int startPeriod;
  late int endPeriod;
  late WeekType weekType;
  late Set<int> customWeeks;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final oldCourse =
        widget.course ??
        (widget.schedule == null
            ? null
            : state.courseById(widget.schedule!.courseId));
    name = TextEditingController(text: oldCourse?.name ?? '');
    teacher = TextEditingController(text: oldCourse?.teacher ?? '');
    location = TextEditingController(text: oldCourse?.location ?? '');
    remark = TextEditingController(text: oldCourse?.remark ?? '');
    colorIndex = oldCourse?.colorIndex ?? 0;
    weekday = widget.schedule?.weekday ?? widget.initialWeekday ?? 1;
    startPeriod =
        widget.schedule?.startPeriod ?? widget.initialStartPeriod ?? 1;
    endPeriod = widget.schedule?.endPeriod ?? startPeriod;
    weekType = widget.schedule?.weekType ?? WeekType.all;
    customWeeks = {...(widget.schedule?.customWeeks ?? const <int>[])};
  }

  @override
  void dispose() {
    name.dispose();
    teacher.dispose();
    location.dispose();
    remark.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (startPeriod > endPeriod) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('节次范围不正确')));
      return;
    }
    final state = context.read<AppState>();
    final course = Course(
      id: widget.course?.id ?? widget.schedule?.courseId ?? createId(),
      name: name.text.trim(),
      teacher: teacher.text.trim(),
      location: location.text.trim(),
      colorIndex: colorIndex,
      remark: remark.text.trim(),
    );
    if (widget.course == null && widget.schedule == null) {
      await state.addCourse(course);
    } else {
      await state.editCourse(course);
    }
    if (widget.schedule != null || widget.initialWeekday != null) {
      final schedule = CourseSchedule(
        id: widget.schedule?.id ?? createId(),
        courseId: course.id,
        termId: state.currentTermId,
        weekday: weekday,
        startPeriod: startPeriod,
        endPeriod: endPeriod,
        weekType: weekType,
        customWeeks: customWeeks.toList()..sort(),
        weekFrom: 1,
        weekTo: state.currentTerm?.totalWeeks ?? 20,
      );
      if (widget.schedule == null) {
        await state.addSchedule(schedule);
      } else {
        await state.editSchedule(schedule);
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final totalWeeks = context.read<AppState>().currentTerm?.totalWeeks ?? 20;
    return AlertDialog(
      title: Text(
        widget.schedule == null && widget.course == null ? '添加课程' : '编辑课程',
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('基本信息', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: '课程名称 *'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入课程名称' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: teacher,
                        decoration: const InputDecoration(labelText: '教师'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: location,
                        decoration: const InputDecoration(labelText: '地点'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: remark,
                  decoration: const InputDecoration(labelText: '备注'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CourseColorPicker(
                  value: colorIndex,
                  onChanged: (value) => setState(() => colorIndex = value),
                ),
                const Divider(height: 28),
                Text('上课时间', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: weekday,
                        decoration: const InputDecoration(labelText: '星期'),
                        items: List.generate(
                          7,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(weekdays[index]),
                          ),
                        ),
                        onChanged: (value) => setState(() => weekday = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: startPeriod,
                        decoration: const InputDecoration(labelText: '开始节次'),
                        items: List.generate(
                          10,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('第${index + 1}节'),
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => startPeriod = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: endPeriod,
                        decoration: const InputDecoration(labelText: '结束节次'),
                        items: List.generate(
                          10,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('第${index + 1}节'),
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => endPeriod = value!),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Text('周次安排', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                DropdownButtonFormField<WeekType>(
                  initialValue: weekType,
                  decoration: const InputDecoration(labelText: '周类型'),
                  items: WeekType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => weekType = value!),
                ),
                if (weekType == WeekType.custom) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(totalWeeks, (index) {
                      final week = index + 1;
                      return FilterChip(
                        label: Text('$week'),
                        selected: customWeeks.contains(week),
                        onSelected: (selected) => setState(
                          () => selected
                              ? customWeeks.add(week)
                              : customWeeks.remove(week),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.check),
          label: const Text('保存'),
        ),
      ],
    );
  }
}

class AddCourseDialog extends CourseFormDialog {
  const AddCourseDialog({
    super.key,
    super.course,
    super.schedule,
    super.initialWeekday,
    super.initialStartPeriod,
  });
}
