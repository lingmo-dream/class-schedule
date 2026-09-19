// 学期管理：新增、编辑、删除和切换当前学期。
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/term.dart';
import '../state/app_state.dart';
import '../utils/identifiers.dart';

class TermManagementPage extends StatelessWidget {
  const TermManagementPage({super.key});

  Future<void> _edit(BuildContext context, [Term? term]) async {
    final result = await showDialog<Term>(
      context: context,
      builder: (_) => _TermDialog(term: term),
    );
    if (result == null || !context.mounted) {
      return;
    }
    final state = context.read<AppState>();
    if (term == null) {
      await state.addTerm(result);
    } else {
      await state.updateTerm(result);
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<AppState>(
    builder: (context, state, _) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('学期管理', style: Theme.of(context).textTheme.titleLarge),
                FilledButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.add),
                  label: const Text('新增学期'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: state.terms.length,
                itemBuilder: (context, index) {
                  final term = state.terms[index];
                  final selected = term.id == state.currentTermId;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(term.name),
                      subtitle: Text(
                        '${DateFormat('yyyy-MM-dd').format(term.startDate)} · ${term.totalWeeks} 周',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (!selected)
                            IconButton(
                              tooltip: '设为当前学期',
                              onPressed: () => state.setCurrentTerm(term.id),
                              icon: const Icon(Icons.check_circle_outline),
                            ),
                          IconButton(
                            tooltip: '编辑',
                            onPressed: () => _edit(context, term),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: '删除',
                            onPressed: state.terms.length == 1
                                ? null
                                : () => state.deleteTerm(term.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _TermDialog extends StatefulWidget {
  const _TermDialog({this.term});
  final Term? term;
  @override
  State<_TermDialog> createState() => _TermDialogState();
}

class _TermDialogState extends State<_TermDialog> {
  late final TextEditingController name;
  late final TextEditingController weeks;
  late DateTime startDate;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.term?.name ?? '');
    weeks = TextEditingController(text: '${widget.term?.totalWeeks ?? 20}');
    startDate = widget.term?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    name.dispose();
    weeks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.term == null ? '新增学期' : '编辑学期'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: '学期名称'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '请输入学期名称' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '开始日期：${DateFormat('yyyy-MM-dd').format(startDate)}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final value = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: startDate,
                    );
                    if (value != null) setState(() => startDate = value);
                  },
                  child: const Text('选择'),
                ),
              ],
            ),
            TextFormField(
              controller: weeks,
              decoration: const InputDecoration(labelText: '总周数'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                return parsed == null || parsed < 1 ? '请输入有效周数' : null;
              },
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
        onPressed: () {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            Term(
              id: widget.term?.id ?? createId(),
              name: name.text.trim(),
              startDate: startDate,
              totalWeeks: int.parse(weeks.text),
            ),
          );
        },
        child: const Text('保存'),
      ),
    ],
  );
}
