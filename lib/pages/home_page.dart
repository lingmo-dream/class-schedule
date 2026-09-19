// 应用主壳：统一标题栏、响应式导航和页面切换。
import 'package:flutter/material.dart';

import '../widgets/app_navigation.dart';
import 'course_management_page.dart';
import 'data_page.dart';
import 'exams_page.dart';
import 'notes_page.dart';
import 'settings_page.dart';
import 'term_management_page.dart';
import 'timetable_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  static const pages = [
    TimetablePage(),
    CourseManagementPage(),
    TermManagementPage(),
    ExamsPage(),
    NotesPage(),
    DataPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '外事课程表',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.school_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                AppNavigation(
                  selectedIndex: selectedIndex,
                  onSelected: (value) => setState(() => selectedIndex = value),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(index: selectedIndex, children: pages),
                ),
              ],
            )
          : IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: wide
          ? null
          : AppNavigation(
              selectedIndex: selectedIndex,
              onSelected: (value) => setState(() => selectedIndex = value),
            ),
    );
  }
}
