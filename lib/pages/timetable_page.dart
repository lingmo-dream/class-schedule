// 周课表页面：负责周次控制、导入导出和课表网格组合。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_schedule.dart';
import '../state/app_state.dart';
import '../utils/identifiers.dart';
import '../widgets/add_course_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/week_grid.dart';

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  Future<void> _add(BuildContext context, ({int day, int period}) slot) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AddCourseDialog(
        initialWeekday: slot.day,
        initialStartPeriod: slot.period,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.isLoading)
          return const Center(child: CircularProgressIndicator());
        final term = state.currentTerm;
        if (term == null)
          return const EmptyState(title: '还没有学期', actionLabel: '创建学期');
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Toolbar(
                termName: term.name,
                week: state.currentWeek,
                totalWeeks: term.totalWeeks,
                onWeekChanged: state.setCurrentWeek,
                onImport: () async {
                  await state.importData();
                },
                onExport: state.exportData,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .025),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: WeekGrid(
                    key: ValueKey(
                      '${state.currentTermId}-${state.currentWeek}',
                    ),
                    onAdd: (slot) => _add(context, slot),
                    onEdit: (schedule) => showDialog<void>(
                      context: context,
                      builder: (_) => AddCourseDialog(schedule: schedule),
                    ),
                    onDelete: (schedule) => state.deleteSchedule(schedule.id),
                    onCopy: (schedule) => state.addSchedule(
                      CourseSchedule(
                        id: createId(),
                        courseId: schedule.courseId,
                        termId: schedule.termId,
                        weekday: schedule.weekday,
                        startPeriod: schedule.startPeriod,
                        endPeriod: schedule.endPeriod,
                        weekType: schedule.weekType,
                        customWeeks: schedule.customWeeks,
                        weekFrom: schedule.weekFrom,
                        weekTo: schedule.weekTo,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.termName,
    required this.week,
    required this.totalWeeks,
    required this.onWeekChanged,
    required this.onImport,
    required this.onExport,
  });
  final String termName;
  final int week;
  final int totalWeeks;
  final ValueChanged<int> onWeekChanged;
  final VoidCallback onImport;
  final Future<bool> Function() onExport;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            termName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text('本周安排与学习节奏', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      const SizedBox(width: 8),
      SegmentedButton<int>(
        emptySelectionAllowed: true,
        segments: const [
          ButtonSegment(
            value: -1,
            icon: Icon(Icons.chevron_left),
            label: Text('上一周'),
          ),
          ButtonSegment(value: 0, label: Text('今天')),
          ButtonSegment(
            value: 1,
            icon: Icon(Icons.chevron_right),
            label: Text('下一周'),
          ),
        ],
        selected: const {},
        onSelectionChanged: (values) {
          final value = values.first;
          if (value == -1 && week > 1) onWeekChanged(week - 1);
          if (value == 0) onWeekChanged(1);
          if (value == 1 && week < totalWeeks) onWeekChanged(week + 1);
        },
      ),
      DropdownButton<int>(
        value: week,
        underline: const SizedBox.shrink(),
        items: List.generate(
          totalWeeks,
          (index) => DropdownMenuItem(
            value: index + 1,
            child: Text('第 ${index + 1} 周'),
          ),
        ),
        onChanged: (value) {
          if (value != null) onWeekChanged(value);
        },
      ),
      Text(
        '第 $week 周 / 总 $totalWeeks 周',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      IconButton(
        tooltip: '导入 JSON',
        onPressed: onImport,
        icon: const Icon(Icons.file_upload_outlined),
      ),
      IconButton(
        tooltip: '导出 JSON',
        onPressed: () async {
          await onExport();
        },
        icon: const Icon(Icons.file_download_outlined),
      ),
    ],
  );
}
