// 全局应用状态：管理课程表数据并在每次变更后自动保存。
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/exam.dart';
import '../models/note.dart';
import '../models/term.dart';
import '../storage/storage.dart';

class AppState extends ChangeNotifier {
  AppState(this._storage) {
    unawaited(loadData());
  }

  final Storage _storage;
  List<Term> terms = [];
  List<Course> courses = [];
  List<CourseSchedule> schedules = [];
  List<Exam> exams = [];
  List<Note> notes = [];
  String currentTermId = '';
  int currentWeek = 1;
  bool isLoading = true;

  Term? get currentTerm =>
      terms.where((item) => item.id == currentTermId).firstOrNull;

  Future<void> loadData() async {
    final data = await _storage.load();
    if (data == null || data.terms.isEmpty) {
      final today = DateTime.now();
      final defaultTerm = Term(
        id: Term.createId(),
        name: '2026-2027学年第一学期',
        startDate: DateTime(today.year, today.month, today.day),
        totalWeeks: 20,
        isCurrent: true,
      );
      terms = [defaultTerm];
      courses = [];
      schedules = [];
      exams = [];
      notes = [];
      currentTermId = defaultTerm.id;
      currentWeek = 1;
      await save();
    } else {
      terms = [...data.terms];
      courses = [...data.courses];
      schedules = [...data.schedules];
      exams = [...data.exams];
      notes = [...data.notes];
      currentTermId = data.currentTermId.isNotEmpty
          ? data.currentTermId
          : data.terms.first.id;
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
      exams: exams,
      notes: notes,
      currentTermId: currentTermId,
      currentWeek: currentWeek,
    ),
  );

  Future<void> _changed() async {
    await save();
    notifyListeners();
  }

  Future<void> addTerm(Term term) async {
    final makeCurrent = terms.isEmpty || term.isCurrent;
    terms = [
      ...terms.map((item) => makeCurrent ? _withCurrent(item, false) : item),
      _withCurrent(term, makeCurrent),
    ];
    if (makeCurrent) currentTermId = term.id;
    await _changed();
  }

  Future<void> editTerm(Term term) async {
    terms = terms.map((item) => item.id == term.id ? term : item).toList();
    await _changed();
  }

  Future<void> updateTerm(Term term) => editTerm(term);

  Future<void> deleteTerm(String id) async {
    terms = terms.where((item) => item.id != id).toList();
    schedules = schedules.where((item) => item.termId != id).toList();
    if (currentTermId == id && terms.isNotEmpty) {
      await setCurrentTerm(terms.first.id);
    }
    await _changed();
  }

  Future<void> setCurrentTerm(String termId) async {
    currentTermId = termId;
    terms = terms.map((item) => _withCurrent(item, item.id == termId)).toList();
    currentWeek = 1;
    await _changed();
  }

  Future<void> setCurrentWeek(int week) async {
    currentWeek = week.clamp(1, currentTerm?.totalWeeks ?? 20);
    await _changed();
  }

  Future<void> addCourse(Course course) async {
    courses = [...courses, course];
    await _changed();
  }

  Future<void> editCourse(Course course) async {
    courses = courses
        .map((item) => item.id == course.id ? course : item)
        .toList();
    await _changed();
  }

  Future<void> updateCourse(Course course) => editCourse(course);

  Future<void> deleteCourse(String id) async {
    courses = courses.where((item) => item.id != id).toList();
    schedules = schedules.where((item) => item.courseId != id).toList();
    exams = exams.where((item) => item.courseId != id).toList();
    notes = notes.where((item) => item.courseId != id).toList();
    await _changed();
  }

  Future<void> addSchedule(CourseSchedule schedule) async {
    schedules = [...schedules, schedule];
    await _changed();
  }

  Future<void> replaceCurrentTermSchedules(
    List<CourseSchedule> replacement,
  ) async {
    schedules = [
      ...schedules.where((item) => item.termId != currentTermId),
      ...replacement,
    ];
    await _changed();
  }

  Future<void> editSchedule(CourseSchedule schedule) async {
    schedules = schedules
        .map((item) => item.id == schedule.id ? schedule : item)
        .toList();
    await _changed();
  }

  Future<void> updateSchedule(CourseSchedule schedule) =>
      editSchedule(schedule);
  Future<void> deleteSchedule(String id) async {
    schedules = schedules.where((item) => item.id != id).toList();
    await _changed();
  }

  Future<void> addExam(Exam exam) async {
    exams = [...exams, exam];
    await _changed();
  }

  Future<void> editExam(Exam exam) async {
    exams = exams.map((item) => item.id == exam.id ? exam : item).toList();
    await _changed();
  }

  Future<void> deleteExam(String id) async {
    exams = exams.where((item) => item.id != id).toList();
    await _changed();
  }

  Future<void> addNote(Note note) async {
    notes = [...notes, note];
    await _changed();
  }

  Future<void> editNote(Note note) async {
    notes = notes.map((item) => item.id == note.id ? note : item).toList();
    await _changed();
  }

  Future<void> deleteNote(String id) async {
    notes = notes.where((item) => item.id != id).toList();
    await _changed();
  }

  List<CourseSchedule> getCoursesForDay(
    String termId,
    int weekday,
    int weekNumber,
  ) =>
      schedules
          .where(
            (item) =>
                item.termId == termId &&
                item.weekday == weekday &&
                item.isVisibleInWeek(weekNumber),
          )
          .toList()
        ..sort((a, b) => a.startPeriod.compareTo(b.startPeriod));

  List<CourseSchedule> schedulesForDay(int weekday) =>
      getCoursesForDay(currentTermId, weekday, currentWeek);

  Course? courseById(String id) =>
      courses.where((item) => item.id == id).firstOrNull;

  Future<bool> exportData() => _storage.exportData(
    AppData(
      terms: terms,
      courses: courses,
      schedules: schedules,
      exams: exams,
      notes: notes,
      currentTermId: currentTermId,
      currentWeek: currentWeek,
    ),
  );

  Future<bool> importData() async {
    final data = await _storage.importData();
    if (data == null || data.terms.isEmpty) return false;
    terms = [...data.terms];
    courses = [...data.courses];
    schedules = [...data.schedules];
    exams = [...data.exams];
    notes = [...data.notes];
    currentTermId = data.currentTermId.isNotEmpty
        ? data.currentTermId
        : terms.first.id;
    currentWeek = data.currentWeek.clamp(1, currentTerm?.totalWeeks ?? 20);
    await _changed();
    return true;
  }

  Future<void> resetAll() async {
    terms = [];
    courses = [];
    schedules = [];
    exams = [];
    notes = [];
    currentTermId = '';
    currentWeek = 1;
    await _storage.clear();
    isLoading = false;
    notifyListeners();
  }

  Term _withCurrent(Term term, bool isCurrent) => Term(
    id: term.id,
    name: term.name,
    startDate: term.startDate,
    totalWeeks: term.totalWeeks,
    isCurrent: isCurrent,
  );
}
