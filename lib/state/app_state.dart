// 应用状态：集中管理课程表数据并负责持久化。
import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/term.dart';
import '../storage/storage.dart';

class AppState extends ChangeNotifier {
  AppState(this._storage) {
    load();
  }

  final Storage _storage;
  List<Term> terms = [];
  List<Course> courses = [];
  List<CourseSchedule> schedules = [];
  String? currentTermId;
  int currentWeek = 1;
  bool isLoading = true;

  Term? get currentTerm =>
      terms.where((item) => item.id == currentTermId).firstOrNull;

  Future<void> load() async {
    final data = await _storage.load();
    if (data == null || data.terms.isEmpty) {
      final today = DateTime.now();
      final defaultTerm = Term(
        id: _newId(),
        name: '2026-2027学年第一学期',
        startDate: DateTime(today.year, today.month, today.day),
        totalWeeks: 20,
      );
      terms = [defaultTerm];
      courses = [];
      schedules = [];
      currentTermId = defaultTerm.id;
      currentWeek = 1;
      await save();
    } else {
      terms = [...data.terms];
      courses = [...data.courses];
      schedules = [...data.schedules];
      currentTermId = data.currentTermId ?? data.terms.first.id;
      currentWeek = data.currentWeek.clamp(1, currentTerm?.totalWeeks ?? 20);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> save() => _storage.save(
    AppData(
      terms: terms,
      courses: courses,
      schedules: schedules,
      currentTermId: currentTermId,
      currentWeek: currentWeek,
    ),
  );

  Future<void> addTerm(Term term) async {
    terms = [...terms, term];
    currentTermId ??= term.id;
    await save();
    notifyListeners();
  }

  Future<void> updateTerm(Term term) async {
    terms = terms.map((item) => item.id == term.id ? term : item).toList();
    await save();
    notifyListeners();
  }

  Future<void> deleteTerm(String id) async {
    terms = terms.where((item) => item.id != id).toList();
    schedules = schedules.where((item) => item.termId != id).toList();
    if (currentTermId == id) currentTermId = terms.firstOrNull?.id;
    currentWeek = 1;
    await save();
    notifyListeners();
  }

  Future<void> setCurrentTerm(String id) async {
    currentTermId = id;
    currentWeek = 1;
    await save();
    notifyListeners();
  }

  Future<void> setCurrentWeek(int week) async {
    currentWeek = week.clamp(1, currentTerm?.totalWeeks ?? 20);
    await save();
    notifyListeners();
  }

  Future<void> addCourse(Course course) async {
    courses = [...courses, course];
    await save();
    notifyListeners();
  }

  Future<void> updateCourse(Course course) async {
    courses = courses
        .map((item) => item.id == course.id ? course : item)
        .toList();
    await save();
    notifyListeners();
  }

  Future<void> deleteCourse(String id) async {
    courses = courses.where((item) => item.id != id).toList();
    schedules = schedules.where((item) => item.courseId != id).toList();
    await save();
    notifyListeners();
  }

  Future<void> addSchedule(CourseSchedule schedule) async {
    schedules = [...schedules, schedule];
    await save();
    notifyListeners();
  }

  Future<void> updateSchedule(CourseSchedule schedule) async {
    schedules = schedules
        .map((item) => item.id == schedule.id ? schedule : item)
        .toList();
    await save();
    notifyListeners();
  }

  Future<void> deleteSchedule(String id) async {
    schedules = schedules.where((item) => item.id != id).toList();
    await save();
    notifyListeners();
  }

  List<CourseSchedule> schedulesForDay(int weekday) =>
      schedules
          .where(
            (item) =>
                item.termId == currentTermId &&
                item.weekday == weekday &&
                item.isVisibleInWeek(currentWeek),
          )
          .toList()
        ..sort((a, b) => a.startPeriod.compareTo(b.startPeriod));

  Course? courseById(String id) =>
      courses.where((item) => item.id == id).firstOrNull;

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
