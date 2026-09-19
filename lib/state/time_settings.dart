// 课表节次模板设置：提供夏季、秋季默认模板，并保存用户自定义时间。
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PeriodSlot {
  const PeriodSlot({required this.start, required this.end});
  final String start;
  final String end;

  Map<String, String> toJson() => {'start': start, 'end': end};
  factory PeriodSlot.fromJson(Map<String, dynamic> json) => PeriodSlot(
    start: json['start'] as String? ?? '08:00',
    end: json['end'] as String? ?? '08:45',
  );
}

class TimeSettings extends ChangeNotifier {
  TimeSettings() {
    _load();
  }

  static const key = 'course_schedule_time_settings';
  static const summer = [
    PeriodSlot(start: '08:10', end: '09:00'),
    PeriodSlot(start: '09:05', end: '09:55'),
    PeriodSlot(start: '10:15', end: '11:05'),
    PeriodSlot(start: '11:10', end: '12:00'),
    PeriodSlot(start: '13:50', end: '14:40'),
    PeriodSlot(start: '14:45', end: '15:35'),
    PeriodSlot(start: '15:55', end: '16:45'),
    PeriodSlot(start: '16:50', end: '17:40'),
  ];
  static const autumn = [
    PeriodSlot(start: '08:00', end: '08:45'),
    PeriodSlot(start: '08:55', end: '09:40'),
    PeriodSlot(start: '10:00', end: '10:45'),
    PeriodSlot(start: '10:55', end: '11:40'),
    PeriodSlot(start: '14:00', end: '14:45'),
    PeriodSlot(start: '14:55', end: '15:40'),
    PeriodSlot(start: '16:00', end: '16:45'),
    PeriodSlot(start: '16:55', end: '17:40'),
    PeriodSlot(start: '19:00', end: '19:45'),
    PeriodSlot(start: '19:55', end: '20:40'),
  ];

  String season = '秋季学期';
  List<PeriodSlot> periods = List<PeriodSlot>.of(autumn);

  Future<void> selectSeason(String value) async {
    season = value;
    periods = List<PeriodSlot>.of(value == '夏季学期' ? summer : autumn);
    await _save();
    notifyListeners();
  }

  Future<void> updatePeriod(int index, PeriodSlot value) async {
    if (index < 0 || index >= periods.length) return;
    periods = [...periods]..[index] = value;
    await _save();
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      season = json['season'] as String? ?? season;
      final rawPeriods = json['periods'] as List<dynamic>?;
      if (rawPeriods != null && rawPeriods.isNotEmpty) {
        periods = rawPeriods
            .map(
              (item) =>
                  PeriodSlot.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      notifyListeners();
    } on FormatException {
      // 损坏的设置使用默认模板。
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'season': season,
        'periods': periods.map((item) => item.toJson()).toList(),
      }),
    );
  }
}
