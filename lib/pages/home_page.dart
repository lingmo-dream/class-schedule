// 响应式应用外壳：宽屏使用 NavigationRail，小屏使用 NavigationBar。
import 'package:flutter/material.dart';

import 'course_management_page.dart';
import 'term_management_page.dart';
import 'timetable_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  final pages = const [
    TimetablePage(),
    TermManagementPage(),
    CourseManagementPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final content = IndexedStack(index: selectedIndex, children: pages);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '外事课程表',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) =>
                      setState(() => selectedIndex = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_view_week),
                      label: Text('周课表'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.event_note),
                      label: Text('学期管理'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book),
                      label: Text('课程管理'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) =>
                  setState(() => selectedIndex = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.calendar_view_week),
                  label: '周课表',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_note),
                  label: '学期管理',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book),
                  label: '课程管理',
                ),
              ],
            ),
    );
  }
}
