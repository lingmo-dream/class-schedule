// 响应式应用导航：宽屏使用 NavigationRail，小屏使用 NavigationBar。
import 'package:flutter/material.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const destinations = [
    (
      icon: Icons.calendar_month_outlined,
      selected: Icons.calendar_month,
      label: '周课表',
    ),
    (icon: Icons.menu_book_outlined, selected: Icons.menu_book, label: '课程'),
    (icon: Icons.event_note_outlined, selected: Icons.event_note, label: '学期'),
    (icon: Icons.timer_outlined, selected: Icons.timer, label: '考试'),
    (icon: Icons.notes_outlined, selected: Icons.notes, label: '笔记'),
    (
      icon: Icons.import_export_outlined,
      selected: Icons.import_export,
      label: '数据',
    ),
    (icon: Icons.settings_outlined, selected: Icons.settings, label: '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        destinations: destinations
            .map(
              (item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selected),
                label: Text(item.label),
              ),
            )
            .toList(),
      );
    }
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: destinations
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selected),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
