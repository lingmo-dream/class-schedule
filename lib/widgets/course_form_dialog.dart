// 新增或编辑课程及其课程安排的共用表单。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';
import '../state/app_state.dart';
import '../utils/app_constants.dart';
import '../utils/identifiers.dart';

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
  late final TextEditingController name = TextEditingController();
  late final TextEditingController teacher = TextEditingController();
  late final TextEditingController location = TextEditingController();
  late int colorIndex;
  late int weekday;
  late int startPeriod;
  late int endPeriod;
  late WeekType weekType;
  late Set<int> customWeeks;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final existing =
        widget.course ??
        (widget.schedule == null
            ? null
            : context.read<AppState>().courseById(widget.schedule!.courseId));
    final schedule = widget.schedule;
    name.text = existing?.name ?? '';
    teacher.text = existing?.teacher ?? '';
    location.text = existing?.location ?? '';
    colorIndex = existing?.colorIndex ?? 0;
    weekday = schedule?.weekday ?? widget.initialWeekday ?? 1;
    startPeriod = schedule?.startPeriod ?? widget.initialStartPeriod ?? 1;
    endPeriod = schedule?.endPeriod ?? startPeriod;
    weekType = schedule?.weekType ?? WeekType.all;
    customWeeks = {...(schedule?.customWeeks ?? const <int>[])};
  }

  @override
  void dispose() {
    name.dispose();
    teacher.dispose();
    location.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate() || startPeriod > endPeriod) return;
    final state = context.read<AppState>();
    final course = Course(
      id: widget.course?.id ?? widget.schedule?.courseId ?? createId(),
      name: name.text.trim(),
      teacher: teacher.text.trim(),
      location: location.text.trim(),
      colorIndex: colorIndex,
    );
    if (widget.course == null && widget.schedule == null) {
      await state.addCourse(course);
    } else {
      await state.updateCourse(course);
    }
    if (widget.schedule != null || widget.initialWeekday != null) {
      final schedule = CourseSchedule(
        id: widget.schedule?.id ?? createId(),
        termId: state.currentTermId!,
        courseId: course.id,
        weekday: weekday,
        startPeriod: startPeriod,
        endPeriod: endPeriod,
        weekType: weekType,
        customWeeks: customWeeks.toList()..sort(),
      );
      if (widget.schedule == null) {
        await state.addSchedule(schedule);
      } else {
        await state.updateSchedule(schedule);
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final weeks = context.read<AppState>().currentTerm?.totalWeeks ?? 20;
    return AlertDialog(
      title: Text(
        widget.schedule == null && widget.course == null ? '添加课程' : '编辑课程',
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: '课程名称 *'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入课程名称' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: teacher,
                  decoration: const InputDecoration(labelText: '教师'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: location,
                  decoration: const InputDecoration(labelText: '地点'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: List.generate(
                      courseColors.length,
                      (index) => InkWell(
                        onTap: () => setState(() => colorIndex = index),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: courseColors[index],
                          child: colorIndex == index
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                if (startPeriod > endPeriod)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '开始节次不能大于结束节次',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 12),
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
                if (weekType == WeekType.custom)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      children: List.generate(weeks, (index) {
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
                  ),
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
        FilledButton(onPressed: submit, child: const Text('保存')),
      ],
    );
  }
}
