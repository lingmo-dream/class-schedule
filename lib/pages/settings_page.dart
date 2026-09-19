// 设置页面：管理提醒、主题偏好、节次模板和关于信息。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/time_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final time = context.watch<TimeSettings>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '设置',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('节次模板'),
                subtitle: Text('${time.season} · ${time.periods.length} 节'),
                trailing: DropdownButton<String>(
                  value: time.season,
                  items: const [
                    DropdownMenuItem(value: '夏季学期', child: Text('夏季学期')),
                    DropdownMenuItem(value: '秋季学期', child: Text('秋季学期')),
                  ],
                  onChanged: (value) {
                    if (value != null) time.selectSeason(value);
                  },
                ),
              ),
              const Divider(height: 1),
              ...List.generate(
                time.periods.length,
                (index) => _PeriodEditor(
                  index: index,
                  slot: time.periods[index],
                  onChanged: (slot) => time.updatePeriod(index, slot),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.notifications_none),
                title: Text('上课提醒'),
                subtitle: Text('保存提醒偏好，移动端后续可启用'),
              ),
              const _ReminderSelector(),
              const Divider(height: 1),
              const _PreferenceSwitch(title: '每周从周日开始'),
              const _PreferenceSwitch(title: '显示已结束周'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('主题色'),
            subtitle: Text('蓝色、绿色、紫色'),
            trailing: _ThemeSelector(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.image_outlined),
                title: Text('自定义背景图片'),
                subtitle: Text('背景图片功能预留，后续开放'),
                trailing: Chip(label: Text('即将开放')),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于外事课程表'),
                subtitle: const Text('版本 1.0.0'),
                onTap: () => _showAbout(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  '清空全部数据',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => _reset(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('此操作不可撤销，确定清空全部数据吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted)
      await context.read<AppState>().resetAll();
  }

  void _showAbout(BuildContext context) => showAboutDialog(
    context: context,
    applicationName: '外事课程表',
    applicationVersion: '1.0.0',
    applicationIcon: const Icon(Icons.school_outlined, size: 42),
    children: const [
      Text('面向 Windows 和 Web 的轻量课程表。'),
      SizedBox(height: 12),
      Text(
        '开源组件：Flutter、Provider、shared_preferences、intl、file_picker、Syncfusion PDF、HTML parser、HTTP。',
      ),
    ],
  );
}

class _PeriodEditor extends StatelessWidget {
  const _PeriodEditor({
    required this.index,
    required this.slot,
    required this.onChanged,
  });
  final int index;
  final PeriodSlot slot;
  final ValueChanged<PeriodSlot> onChanged;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: CircleAvatar(radius: 15, child: Text('${index + 1}')),
    title: Text('第 ${index + 1} 节'),
    subtitle: Text('${slot.start} - ${slot.end}'),
    trailing: OutlinedButton(
      onPressed: () async {
        final result = await showDialog<PeriodSlot>(
          context: context,
          builder: (_) => _TimeDialog(slot: slot, title: '编辑第 ${index + 1} 节'),
        );
        if (result != null) onChanged(result);
      },
      child: const Text('修改'),
    ),
  );
}

class _TimeDialog extends StatefulWidget {
  const _TimeDialog({required this.slot, required this.title});
  final PeriodSlot slot;
  final String title;
  @override
  State<_TimeDialog> createState() => _TimeDialogState();
}

class _TimeDialogState extends State<_TimeDialog> {
  late final start = TextEditingController(text: widget.slot.start);
  late final end = TextEditingController(text: widget.slot.end);
  @override
  void dispose() {
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Row(
      children: [
        Expanded(
          child: TextField(
            controller: start,
            decoration: const InputDecoration(labelText: '开始 HH:mm'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: end,
            decoration: const InputDecoration(labelText: '结束 HH:mm'),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          PeriodSlot(start: start.text.trim(), end: end.text.trim()),
        ),
        child: const Text('保存'),
      ),
    ],
  );
}

class _ReminderSelector extends StatefulWidget {
  const _ReminderSelector();
  @override
  State<_ReminderSelector> createState() => _ReminderSelectorState();
}

class _ReminderSelectorState extends State<_ReminderSelector> {
  int value = 15;
  @override
  Widget build(BuildContext context) => ListTile(
    title: const Text('提前提醒分钟数'),
    trailing: DropdownButton<int>(
      value: value,
      items: const [
        DropdownMenuItem(value: 5, child: Text('5 分钟')),
        DropdownMenuItem(value: 15, child: Text('15 分钟')),
        DropdownMenuItem(value: 30, child: Text('30 分钟')),
      ],
      onChanged: (next) => setState(() => value = next ?? value),
    ),
  );
}

class _PreferenceSwitch extends StatefulWidget {
  const _PreferenceSwitch({required this.title});
  final String title;
  @override
  State<_PreferenceSwitch> createState() => _PreferenceSwitchState();
}

class _PreferenceSwitchState extends State<_PreferenceSwitch> {
  bool value = false;
  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(widget.title),
    value: value,
    onChanged: (next) => setState(() => value = next),
  );
}

class _ThemeSelector extends StatefulWidget {
  const _ThemeSelector();
  @override
  State<_ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<_ThemeSelector> {
  int value = 0;
  @override
  Widget build(BuildContext context) => SegmentedButton<int>(
    segments: const [
      ButtonSegment(value: 0, label: Text('蓝')),
      ButtonSegment(value: 1, label: Text('绿')),
      ButtonSegment(value: 2, label: Text('紫')),
    ],
    selected: {value},
    onSelectionChanged: (values) => setState(() => value = values.first),
  );
}
