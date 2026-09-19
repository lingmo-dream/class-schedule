// 应用使用的默认节次、颜色和显示文本。
import 'package:flutter/material.dart';

const List<({String start, String end})> periodTimes = [
  (start: '08:00', end: '08:45'),
  (start: '08:55', end: '09:40'),
  (start: '10:00', end: '10:45'),
  (start: '10:55', end: '11:40'),
  (start: '14:00', end: '14:45'),
  (start: '14:55', end: '15:40'),
  (start: '16:00', end: '16:45'),
  (start: '16:55', end: '17:40'),
  (start: '19:00', end: '19:45'),
  (start: '19:55', end: '20:40'),
];

const List<Color> courseColors = [
  Color(0xff2563eb),
  Color(0xff059669),
  Color(0xffd97706),
  Color(0xffdc2626),
  Color(0xff7c3aed),
  Color(0xff0891b2),
  Color(0xffdb2777),
  Color(0xff4f46e5),
];

const List<String> weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
