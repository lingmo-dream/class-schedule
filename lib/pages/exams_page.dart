// 考试倒计时页面：按考试时间排序并高亮临近考试。
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/exam.dart';
import '../state/app_state.dart';
import '../utils/identifiers.dart';
import '../widgets/empty_state.dart';

class ExamsPage extends StatelessWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final exams = [...state.exams]
      ..sort((a, b) => a.examTime.compareTo(b.examTime));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '考试倒计时',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _ExamDialog(),
                ),
                icon: const Icon(Icons.add),
                label: const Text('新增考试'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: exams.isEmpty
                ? const EmptyState(
                    title: '还没有考试安排',
                    subtitle: '把重要考试加入这里，提前做好准备',
                    icon: Icons.timer_outlined,
                  )
                : ListView.separated(
                    itemCount: exams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _ExamCard(exam: exams[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});
  final Exam exam;
  @override
  Widget build(BuildContext context) {
    final days = exam.examTime.difference(DateTime.now()).inDays;
    final past = days < 0;
    final color = past
        ? Colors.grey
        : days <= 7
        ? Colors.deepOrange
        : Theme.of(context).colorScheme.primary;
    final state = context.read<AppState>();
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(Icons.timer_outlined, color: color),
        ),
        title: Text(
          exam.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: past ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          '${DateFormat('yyyy-MM-dd HH:mm').format(exam.examTime)}${exam.location.isEmpty ? '' : ' · ${exam.location}'}',
        ),
        trailing: Wrap(
          children: [
            Text(
              past ? '已结束' : '还有 ${days + 1} 天',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            IconButton(
              tooltip: '删除',
              onPressed: () => state.deleteExam(exam.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamDialog extends StatefulWidget {
  const _ExamDialog();
  @override
  State<_ExamDialog> createState() => _ExamDialogState();
}

class _ExamDialogState extends State<_ExamDialog> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final location = TextEditingController();
  final remark = TextEditingController();
  DateTime examTime = DateTime.now().add(const Duration(days: 7));
  String? courseId;
  @override
  void dispose() {
    title.dispose();
    location.dispose();
    remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return AlertDialog(
      title: const Text('新增考试'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: '考试标题 *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入考试标题' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: courseId,
                decoration: const InputDecoration(labelText: '关联课程（可选）'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('不关联课程')),
                  ...state.courses.map(
                    (course) => DropdownMenuItem(
                      value: course.id,
                      child: Text(course.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => courseId = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(examTime),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        initialDate: examTime,
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(examTime),
                      );
                      if (time != null)
                        setState(
                          () => examTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                    },
                    child: const Text('选择时间'),
                  ),
                ],
              ),
              TextFormField(
                controller: location,
                decoration: const InputDecoration(labelText: '地点'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: remark,
                decoration: const InputDecoration(labelText: '备注'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await state.addExam(
              Exam(
                id: createId(),
                title: title.text.trim(),
                courseId: courseId,
                examTime: examTime,
                location: location.text.trim(),
                remark: remark.text.trim(),
              ),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
