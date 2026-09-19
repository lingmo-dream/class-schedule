// 应用数据的 JSON 持久化封装。
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/term.dart';

class AppData {
  const AppData({
    this.terms = const [],
    this.courses = const [],
    this.schedules = const [],
    this.currentTermId,
    this.currentWeek = 1,
  });

  final List<Term> terms;
  final List<Course> courses;
  final List<CourseSchedule> schedules;
  final String? currentTermId;
  final int currentWeek;

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
    terms: ((json['terms'] as List<dynamic>?) ?? const [])
        .map((item) => Term.fromJson(item as Map<String, dynamic>))
        .toList(),
    courses: ((json['courses'] as List<dynamic>?) ?? const [])
        .map((item) => Course.fromJson(item as Map<String, dynamic>))
        .toList(),
    schedules: ((json['schedules'] as List<dynamic>?) ?? const [])
        .map((item) => CourseSchedule.fromJson(item as Map<String, dynamic>))
        .toList(),
    currentTermId: json['currentTermId'] as String?,
    currentWeek: (json['currentWeek'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'terms': terms.map((item) => item.toJson()).toList(),
    'courses': courses.map((item) => item.toJson()).toList(),
    'schedules': schedules.map((item) => item.toJson()).toList(),
    'currentTermId': currentTermId,
    'currentWeek': currentWeek,
  };
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
}
