// 应用数据的 JSON 持久化和导入导出封装。
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/exam.dart';
import '../models/note.dart';
import '../models/term.dart';

class AppData {
  const AppData({
    this.terms = const [],
    this.courses = const [],
    this.schedules = const [],
    this.exams = const [],
    this.notes = const [],
    this.currentTermId = '',
    this.currentWeek = 1,
  });

  final List<Term> terms;
  final List<Course> courses;
  final List<CourseSchedule> schedules;
  final List<Exam> exams;
  final List<Note> notes;
  final String currentTermId;
  final int currentWeek;

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
    terms: _list(json['terms']).map(Term.fromJson).toList(),
    courses: _list(json['courses']).map(Course.fromJson).toList(),
    schedules: _list(json['schedules']).map(CourseSchedule.fromJson).toList(),
    exams: _list(json['exams']).map(Exam.fromJson).toList(),
    notes: _list(json['notes']).map(Note.fromJson).toList(),
    currentTermId: json['currentTermId'] as String? ?? '',
    currentWeek: (json['currentWeek'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'terms': terms.map((item) => item.toJson()).toList(),
    'courses': courses.map((item) => item.toJson()).toList(),
    'schedules': schedules.map((item) => item.toJson()).toList(),
    'exams': exams.map((item) => item.toJson()).toList(),
    'notes': notes.map((item) => item.toJson()).toList(),
    'currentTermId': currentTermId,
    'currentWeek': currentWeek,
  };

  static List<Map<String, dynamic>> _list(dynamic value) =>
      (value as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
}

class Storage {
  static const String key = 'course_schedule_data';

  Future<AppData?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(AppData data) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(data.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  Future<bool> exportData(AppData data) async {
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(data.toJson()),
    );
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '导出课程表数据',
      fileName: 'course_schedule_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    return path != null;
  }

  Future<AppData?> importData() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '导入课程表数据',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return null;
    try {
      final json = jsonDecode(utf8.decode(result.files.single.bytes!));
      return AppData.fromJson(Map<String, dynamic>.from(json as Map));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
