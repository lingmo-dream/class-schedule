// 周课表：按星期和节次展示当前周的课程安排。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_schedule.dart';
import '../state/app_state.dart';
import '../utils/app_constants.dart';
import '../widgets/course_form_dialog.dart';

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final term = state.currentTerm;
        if (term == null) return const Center(child: Text('请先创建一个学期'));
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    term.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Chip(label: Text('第 ${state.currentWeek} 周')),
                  OutlinedButton.icon(
                    onPressed: state.currentWeek > 1
                        ? () => state.setCurrentWeek(state.currentWeek - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('上一周'),
                  ),
                  OutlinedButton.icon(
                    onPressed: state.currentWeek < term.totalWeeks
                        ? () => state.setCurrentWeek(state.currentWeek + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('下一周'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _ScheduleGrid(state: state)),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleGrid extends StatelessWidget {
  const _ScheduleGrid({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final periodWidth = (constraints.maxWidth - 76) / 7;
        return SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 76),
                  ...weekdays.map(
                    (day) => SizedBox(
                      width: periodWidth,
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(
                periodTimes.length,
                (index) => _PeriodRow(
                  period: index + 1,
                  width: periodWidth,
                  schedules: state.schedules,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({
    required this.period,
    required this.width,
    required this.schedules,
  });
  final int period;
  final double width;
  final List<CourseSchedule> schedules;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$period\n${periodTimes[period - 1].start}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
        ...List.generate(7, (dayIndex) {
          final matches = schedules
              .where(
                (item) =>
                    item.weekday == dayIndex + 1 &&
                    item.startPeriod == period &&
                    item.isVisibleInWeek(context.read<AppState>().currentWeek),
              )
              .toList();
          return SizedBox(
            width: width,
            child: _ScheduleCell(
              day: dayIndex + 1,
              period: period,
              schedule: matches.firstOrNull,
            ),
          );
        }),
      ],
    ),
  );
}

class _ScheduleCell extends StatelessWidget {
  const _ScheduleCell({required this.day, required this.period, this.schedule});
  final int day;
  final int period;
  final CourseSchedule? schedule;

  Future<void> _open(BuildContext context) async {
    final state = context.read<AppState>();
    if (schedule == null) {
      await showDialog<void>(
        context: context,
        builder: (_) =>
            CourseFormDialog(initialWeekday: day, initialStartPeriod: period),
      );
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑课程安排'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('删除课程安排'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'edit' && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => CourseFormDialog(schedule: schedule),
      );
    }
    if (action == 'delete') await state.deleteSchedule(schedule!.id);
  }

  @override
  Widget build(BuildContext context) {
    final course = schedule == null
        ? null
        : context.read<AppState>().courseById(schedule!.courseId);
    return InkWell(
      onTap: () => _open(context),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(6),
          color: course == null
              ? Colors.white
              : courseColors[course.colorIndex % courseColors.length]
                    .withValues(alpha: .88),
        ),
        child: course == null
            ? const Icon(Icons.add, size: 16, color: Colors.black26)
            : Text(
                '${course.name}\n${course.location}\n${course.teacher}',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
      ),
    );
  }
}
