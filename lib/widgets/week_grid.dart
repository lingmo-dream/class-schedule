// 响应式周课表网格：星期标题、日期、空白格和跨节课程块统一布局。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_schedule.dart';
import '../state/app_state.dart';
import '../state/time_settings.dart';
import '../utils/app_constants.dart';
import 'course_block.dart';
import 'detail_bottom_sheet.dart';
import 'empty_state.dart';
import 'period_column.dart';

class WeekGrid extends StatelessWidget {
  const WeekGrid({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
  });
  final ValueChanged<({int day, int period})> onAdd;
  final ValueChanged<CourseSchedule> onEdit;
  final ValueChanged<CourseSchedule> onDelete;
  final ValueChanged<CourseSchedule> onCopy;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final timeSettings = context.watch<TimeSettings>();
    final term = state.currentTerm;
    if (term == null)
      return const EmptyState(title: '还没有学期', subtitle: '先创建一个学期，再安排你的课程');
    final termSchedules = state.schedules
        .where((item) => item.termId == state.currentTermId)
        .toList();
    if (state.courses.isEmpty)
      return EmptyState(
        title: '添加你的第一节课',
        subtitle: '从一节课程开始，建立清晰的每周节奏',
        actionLabel: '添加课程',
        onAction: () => onAdd((day: 1, period: 1)),
        icon: Icons.event_available_outlined,
      );
    if (termSchedules.isEmpty)
      return EmptyState(
        title: '本周暂无课程',
        subtitle: '可以切换到其他周，或点击下方按钮添加安排',
        actionLabel: '添加课程',
        onAction: () => onAdd((day: 1, period: 1)),
        icon: Icons.free_breakfast_outlined,
      );

    final weekStart = term.startDate.add(
      Duration(days: (state.currentWeek - 1) * 7),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final periodCount = [
          timeSettings.periods.length,
          ...termSchedules.map((item) => item.endPeriod),
        ].reduce((a, b) => a > b ? a : b);
        final laneCounts = <String, int>{};
        for (final schedule in termSchedules) {
          final key = '${schedule.weekday}-${schedule.startPeriod}';
          laneCounts[key] = (laneCounts[key] ?? 0) + 1;
        }
        final laneIndexes = <String, int>{};
        final cellWidth = ((constraints.maxWidth - 76) / 7).clamp(92.0, 220.0);
        final gridWidth = 76.0 + cellWidth * 7;
        return SingleChildScrollView(
          child: SizedBox(
            width: gridWidth,
            height: 36.0 + periodCount * 76,
            child: Stack(
              children: [
                _GridBackground(
                  width: cellWidth,
                  weekStart: weekStart,
                  periods: timeSettings.periods,
                  count: periodCount,
                ),
                _TimeProgressPointer(
                  periods: timeSettings.periods,
                  width: gridWidth,
                ),
                ...termSchedules.map((schedule) {
                  final course = state.courseById(schedule.courseId);
                  if (course == null) return const SizedBox.shrink();
                  final laneKey = '${schedule.weekday}-${schedule.startPeriod}';
                  final lane = laneIndexes[laneKey] ?? 0;
                  laneIndexes[laneKey] = lane + 1;
                  final laneCount = laneCounts[laneKey] ?? 1;
                  final laneWidth = cellWidth / laneCount;
                  return Positioned(
                    left:
                        76.0 +
                        (schedule.weekday - 1) * cellWidth +
                        lane * laneWidth,
                    top: 36.0 + (schedule.startPeriod - 1) * 76,
                    width: laneWidth,
                    height:
                        (schedule.endPeriod - schedule.startPeriod + 1) * 76.0,
                    child: CourseBlock(
                      course: course,
                      schedule: schedule,
                      width: laneWidth - 4,
                      isCurrentWeek: schedule.isVisibleInWeek(
                        state.currentWeek,
                      ),
                      onTap: () => _showDetail(context, course.id, schedule),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetail(
    BuildContext context,
    String courseId,
    CourseSchedule schedule,
  ) {
    final state = context.read<AppState>();
    final course = state.courseById(courseId);
    if (course == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => DetailBottomSheet(
        course: course,
        schedule: schedule,
        onEdit: () => onEdit(schedule),
        onDelete: () => onDelete(schedule),
        onCopy: () => onCopy(schedule),
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground({
    required this.width,
    required this.weekStart,
    required this.periods,
    required this.count,
  });
  final double width;
  final DateTime weekStart;
  final List<PeriodSlot> periods;
  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 36,
        child: Row(
          children: [
            const SizedBox(width: 76),
            ...List.generate(7, (index) {
              final date = weekStart.add(Duration(days: index));
              return SizedBox(
                width: width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdays[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${date.month}/${date.day}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      ...List.generate(
        count,
        (index) => SizedBox(
          height: 76,
          child: Row(
            children: [
              PeriodColumn(
                period: index + 1,
                slot: index < periods.length
                    ? periods[index]
                    : const PeriodSlot(start: '', end: ''),
              ),
              ...List.generate(
                7,
                (day) => SizedBox(
                  width: width,
                  child: InkWell(
                    onTap: () => context
                        .findAncestorWidgetOfExactType<WeekGrid>()
                        ?.onAdd((day: day + 1, period: index + 1)),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: .65),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _TimeProgressPointer extends StatelessWidget {
  const _TimeProgressPointer({required this.periods, required this.width});
  final List<PeriodSlot> periods;
  final double width;

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final minutes = now.hour * 60 + now.minute;
    for (var index = 0; index < periods.length; index++) {
      final start = _minutes(periods[index].start);
      final end = _minutes(periods[index].end);
      if (minutes >= start && minutes <= end) {
        final progress = (minutes - start) / (end - start);
        return Positioned(
          left: 0,
          width: 76,
          top: 36 + index * 76 + progress * 76,
          child: IgnorePointer(
            child: Row(
              children: [
                Container(width: 62, height: 2, color: Colors.red),
                const Icon(Icons.play_arrow, color: Colors.red, size: 16),
              ],
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  int _minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
