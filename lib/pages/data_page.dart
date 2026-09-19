// 数据中心：支持 JSON、粘贴课表文字和 PDF 课表导入。
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/term.dart';
import '../services/schedule_import_service.dart';
import '../state/app_state.dart';
import '../utils/app_constants.dart';
import '../utils/identifiers.dart';
import '../widgets/empty_state.dart';

class DataPage extends StatelessWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '数据中心',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text('推荐使用结构化课表 JSON 导入，星期、节次和周次可准确保留。'),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 28,
              runSpacing: 18,
              children: [
                _Stat(
                  label: '学期',
                  value: state.terms.length,
                  icon: Icons.event_note_outlined,
                ),
                _Stat(
                  label: '课程',
                  value: state.courses.length,
                  icon: Icons.menu_book_outlined,
                ),
                _Stat(
                  label: '课程安排',
                  value: state.schedules.length,
                  icon: Icons.calendar_view_week_outlined,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _ImportCard(onJsonSchedule: () => _openScheduleJsonImport(context)),
        const SizedBox(height: 14),
        _JsonCard(
          onImport: () => _openJsonImport(context),
          onExport: () => _export(context),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    final ok = await context.read<AppState>().exportData();
    if (context.mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ok ? '导出成功' : '已取消导出')));
  }

  Future<void> _openJsonImport(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认导入'),
        content: const Text('导入将覆盖当前所有数据，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await context.read<AppState>().importData();
    if (context.mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ok ? '导入成功' : '文件格式无效')));
  }

  Future<void> _openScheduleJsonImport(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null ||
        result.files.single.bytes == null ||
        !context.mounted) {
      return;
    }
    try {
      final source = utf8.decode(
        result.files.single.bytes!,
        allowMalformed: false,
      );
      final parsed = ScheduleImportService.parseJson(source);
      if (parsed.items.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('JSON 中没有识别到有效课程安排')));
        return;
      }
      final items = await showDialog<List<ParsedSchedule>>(
        context: context,
        builder: (_) => _ScheduleTextDialog(
          initialText: source,
          initialResult: ScheduleImportResult(
            items: parsed.items,
            warning: parsed.termName == null
                ? '未提供学期名称，将导入到当前学期。'
                : '将导入到学期：${parsed.termName}',
          ),
        ),
      );
      if (items == null || !context.mounted) return;
      await _saveParsed(
        context,
        items,
        termName: parsed.termName,
        replaceCurrentTerm: true,
      );
    } on FormatException {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('JSON 格式无效')));
    } on TypeError {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('JSON 字段格式不符合课表结构')));
    }
  }

  Future<void> _saveParsed(
    BuildContext context,
    List<ParsedSchedule> items, {
    String? termName,
    bool replaceCurrentTerm = false,
  }) async {
    final state = context.read<AppState>();
    if (termName != null &&
        termName.trim().isNotEmpty &&
        state.currentTerm != null) {
      final current = state.currentTerm!;
      await state.editTerm(
        Term(
          id: current.id,
          name: termName.trim(),
          startDate: current.startDate,
          totalWeeks: current.totalWeeks,
          isCurrent: true,
        ),
      );
    }
    final coursesByKey = <String, Course>{
      for (final course in state.courses)
        '${course.name}|${course.teacher}|${course.location}': course,
    };
    final importedSchedules = <CourseSchedule>[];
    for (final item in items) {
      final key = '${item.courseName}|${item.teacher}|${item.location}';
      final existing = coursesByKey[key];
      final course =
          existing ??
          Course(
            id: createId(),
            name: item.courseName,
            teacher: item.teacher,
            location: item.location,
            colorIndex: coursesByKey.length % 8,
          );
      if (existing == null) {
        coursesByKey[key] = course;
        await state.addCourse(course);
      } else if (existing.location != item.location) {
        await state.updateCourse(
          Course(
            id: existing.id,
            name: existing.name,
            teacher: existing.teacher,
            location: item.location,
            colorIndex: existing.colorIndex,
          ),
        );
      }
      importedSchedules.add(
        CourseSchedule(
          id: createId(),
          courseId: course.id,
          termId: state.currentTermId,
          weekday: item.weekday,
          startPeriod: item.startPeriod,
          endPeriod: item.endPeriod,
          weekType: item.weekType,
          customWeeks: item.customWeeks.toList()..sort(),
          weekFrom: item.weekFrom,
          weekTo: item.weekTo,
        ),
      );
    }
    if (replaceCurrentTerm) {
      await state.replaceCurrentTermSchedules(importedSchedules);
    } else {
      for (final schedule in importedSchedules) {
        await state.addSchedule(schedule);
      }
    }
    final firstWeek = items
        .map(
          (item) =>
              item.customWeeks.isEmpty ? item.weekFrom : item.customWeeks.first,
        )
        .reduce((a, b) => a < b ? a : b);
    await state.setCurrentWeek(firstWeek);
    if (context.mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已导入 ${items.length} 条课程安排')));
  }
}

class _ImportCard extends StatelessWidget {
  const _ImportCard({required this.onJsonSchedule});
  final VoidCallback onJsonSchedule;
  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        _AvailableImportTile(onPressed: onJsonSchedule),
        const Divider(height: 1),
        const _DisabledImportTile(
          icon: Icons.content_paste_go_outlined,
          title: '粘贴课表文字',
          subtitle: '暂不可用：表格列信息会在复制时丢失',
        ),
        const Divider(height: 1),
        const _DisabledImportTile(
          icon: Icons.picture_as_pdf_outlined,
          title: '导入 PDF 课表',
          subtitle: '暂不可用：PDF 文本布局无法稳定还原星期列',
        ),
        const Divider(height: 1),
        const _DisabledImportTile(
          icon: Icons.document_scanner_outlined,
          title: '图片 OCR 识别',
          subtitle: '暂不可用：OCR 坐标识别结果不稳定',
        ),
        const Divider(height: 1),
        const _DisabledImportTile(
          icon: Icons.web_outlined,
          title: '导入 HTML 课表',
          subtitle: '暂不可用：不同教务系统表格结构差异较大',
        ),
      ],
    ),
  );
}

class _AvailableImportTile extends StatelessWidget {
  const _AvailableImportTile({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      Icons.data_object,
      color: Theme.of(context).colorScheme.primary,
    ),
    title: const Text('识别课表 JSON（class.json 格式）'),
    subtitle: const Text('使用根目录 class.json 结构，保留星期、节次、周次、教师和地点'),
    trailing: FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.upload_file),
      label: const Text('选择 JSON'),
    ),
  );
}

class _DisabledImportTile extends StatelessWidget {
  const _DisabledImportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).disabledColor;
    return ListTile(
      enabled: false,
      leading: Icon(icon, color: muted),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: .16),
          border: Border.all(color: Colors.red.withValues(alpha: .65)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
            SizedBox(width: 4),
            Text(
              '不可用',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JsonCard extends StatelessWidget {
  const _JsonCard({required this.onImport, required this.onExport});
  final VoidCallback onImport;
  final VoidCallback onExport;
  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('导出 JSON'),
          subtitle: const Text('导出全部学期、课程、考试和笔记'),
          trailing: FilledButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download),
            label: const Text('导出'),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: const Text('导入应用备份 JSON（导出格式）'),
          subtitle: const Text('仅用于恢复“导出 JSON”生成的完整应用备份'),
          trailing: OutlinedButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.upload),
            label: const Text('选择文件'),
          ),
        ),
      ],
    ),
  );
}

class _ScheduleTextDialog extends StatefulWidget {
  const _ScheduleTextDialog({required this.initialText, this.initialResult});
  final String initialText;
  final ScheduleImportResult? initialResult;
  @override
  State<_ScheduleTextDialog> createState() => _ScheduleTextDialogState();
}

class _ScheduleTextDialogState extends State<_ScheduleTextDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialText,
  );
  int weekday = 1;
  late ScheduleImportResult? result = widget.initialResult;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void parse() {
    final source = controller.text.trim();
    setState(() {
      if (_looksLikeJson(source)) {
        try {
          final jsonResult = ScheduleImportService.parseJson(source);
          result = ScheduleImportResult(
            items: jsonResult.items,
            warning: jsonResult.termName == null
                ? '未提供学期名称，将导入到当前学期。'
                : '将导入到学期：${jsonResult.termName}',
          );
        } on FormatException {
          result = ScheduleImportResult(items: const [], warning: 'JSON 格式无效');
        } on TypeError {
          result = ScheduleImportResult(items: const [], warning: 'JSON 字段格式不符合课表结构');
        }
      } else {
        result = ScheduleImportService.parseText(
          source,
          defaultWeekday: weekday,
        );
      }
    });
  }

  static bool _looksLikeJson(String source) {
    final s = source.startsWith('\uFEFF') ? source.substring(1) : source;
    final trimmed = s.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('识别课表文字'),
    content: SizedBox(
      width: 650,
      height: 520,
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLines: 9,
            decoration: const InputDecoration(
              labelText: '粘贴课表文字',
              hintText: '把教务系统课表页面中的文字粘贴到这里',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: weekday,
                  decoration: const InputDecoration(labelText: '未检测到星期时默认归入'),
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
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: parse,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('开始识别'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _Preview(
              result: result,
              onWeekdayChanged: (index, value) {
                final current = result!.items[index];
                setState(() {
                  result = ScheduleImportResult(
                    items: [
                      ...result!.items.take(index),
                      current.copyWith(weekday: value),
                      ...result!.items.skip(index + 1),
                    ],
                    warning: result!.warning,
                  );
                });
              },
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: result?.items.isEmpty ?? true
            ? null
            : () => Navigator.pop(context, result!.items),
        child: const Text('导入识别结果'),
      ),
    ],
  );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.result, required this.onWeekdayChanged});
  final ScheduleImportResult? result;
  final void Function(int index, int weekday) onWeekdayChanged;
  @override
  Widget build(BuildContext context) {
    if (result == null)
      return const EmptyState(
        title: '等待识别',
        subtitle: '识别后会在这里显示课程安排预览',
        icon: Icons.manage_search_outlined,
      );
    if (result!.items.isEmpty)
      return const EmptyState(
        title: '没有识别到课程',
        subtitle: '请确认内容包含“课程名 (1-2节)”格式',
        icon: Icons.search_off_outlined,
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result!.warning != null)
          Text(
            result!.warning!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 6),
        Text(
          '识别到 ${result!.items.length} 条安排',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            itemCount: result!.items.length,
            itemBuilder: (_, index) {
              final item = result!.items[index];
              return ListTile(
                dense: true,
                leading: DropdownButton<int>(
                  value: item.weekday,
                  underline: const SizedBox.shrink(),
                  items: List.generate(
                    7,
                    (weekdayIndex) => DropdownMenuItem(
                      value: weekdayIndex + 1,
                      child: Text(weekdays[weekdayIndex]),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) onWeekdayChanged(index, value);
                  },
                ),
                title: Text(
                  '${item.courseName} · 第${item.startPeriod}-${item.endPeriod}节',
                ),
                subtitle: Text(
                  '${item.weekType.label} · ${item.location.isEmpty ? '未识别地点' : item.location} · ${item.teacher.isEmpty ? '未识别教师' : item.teacher}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label),
        ],
      ),
    ],
  );
}
