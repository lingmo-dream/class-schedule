// 课表导入服务：从复制文本或 PDF 提取的文字中解析课程安排。
import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/course_schedule.dart';
import 'image_ocr_service.dart';

class ParsedSchedule {
  const ParsedSchedule({
    required this.courseName,
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    required this.weekType,
    required this.customWeeks,
    required this.weekFrom,
    required this.weekTo,
    this.location = '',
    this.teacher = '',
  });

  final String courseName;
  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final WeekType weekType;
  final List<int> customWeeks;
  final int weekFrom;
  final int weekTo;
  final String location;
  final String teacher;

  ParsedSchedule copyWith({int? weekday}) => ParsedSchedule(
    courseName: courseName,
    weekday: weekday ?? this.weekday,
    startPeriod: startPeriod,
    endPeriod: endPeriod,
    weekType: weekType,
    customWeeks: customWeeks,
    weekFrom: weekFrom,
    weekTo: weekTo,
    location: location,
    teacher: teacher,
  );
}

class ScheduleImportResult {
  const ScheduleImportResult({required this.items, required this.warning});
  final List<ParsedSchedule> items;
  final String? warning;
}

class JsonScheduleImportResult {
  const JsonScheduleImportResult({
    required this.items,
    this.termName,
    this.studentId,
  });

  final List<ParsedSchedule> items;
  final String? termName;
  final String? studentId;
}

class ScheduleImportService {
  static Future<String> extractPdfText(List<int> bytes) async {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }

  static ScheduleImportResult parseText(
    String source, {
    int defaultWeekday = 1,
  }) {
    final text = _normalize(source);
    final items = <ParsedSchedule>[];
    final marker = RegExp(
      r'([\u4e00-\u9fffA-Za-z0-9（）()·、\- ]{2,60}?)\s*[★☆◆※〇●■]?\s*(?:第\s*)?[（(【\[]?\s*(\d{1,2})\s*[-－—~～]\s*(\d{1,2})\s*节\s*[）)】\]]?',
    );
    final matches = marker.allMatches(text).toList();
    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      final nextStart = index + 1 < matches.length
          ? matches[index + 1].start
          : text.length;
      final title = _cleanTitle(match.group(1)!);
      if (title.length < 2 || title.contains('星期')) continue;
      final detail = text.substring(match.end, nextStart);
      final weeks = _parseWeeks(detail);
      final teacherAndLocation = _parseLocationTeacher(detail);
      items.add(
        ParsedSchedule(
          courseName: title,
          weekday:
              _detectWeekday(text.substring(0, match.start)) ?? defaultWeekday,
          startPeriod: int.parse(match.group(2)!),
          endPeriod: int.parse(match.group(3)!),
          weekType: weeks.type,
          customWeeks: weeks.weeks,
          weekFrom: weeks.from,
          weekTo: weeks.to,
          location: teacherAndLocation.location,
          teacher: teacherAndLocation.teacher,
        ),
      );
    }
    return ScheduleImportResult(
      items: _deduplicate(items),
      warning: _hasReliableWeekdayMarkers(text)
          ? null
          : '复制文本中的星期列已被压缩，无法可靠判断每门课的星期；本次先默认归入${_weekdayName(defaultWeekday)}，导入后请在课程管理中调整。',
    );
  }

  static JsonScheduleImportResult parseJson(String source) {
    final normalized = source.startsWith('\uFEFF')
        ? source.substring(1)
        : source;
    final root = jsonDecode(normalized) as Map<String, dynamic>;
    final schedule = Map<String, dynamic>.from(
      root['schedule'] as Map? ?? const {},
    );
    final items = <ParsedSchedule>[];
    for (final entry in schedule.entries) {
      final weekday = _weekdayFromText(entry.key);
      if (weekday == null || entry.value is! List) continue;
      for (final raw in entry.value as List<dynamic>) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final periods = _parsePeriodRange(item['periods']?.toString() ?? '');
        if (periods == null) continue;
        final weeks = _parseWeeks(item['weeks']?.toString() ?? '');
        items.add(
          ParsedSchedule(
            courseName: (item['course'] as String? ?? '').trim(),
            weekday: weekday,
            startPeriod: periods.$1,
            endPeriod: periods.$2,
            weekType: weeks.type,
            customWeeks: weeks.weeks,
            weekFrom: weeks.from,
            weekTo: weeks.to,
            location: _stripPrefix(item['location'] as String?, '场地:'),
            teacher: _stripPrefix(item['teacher'] as String?, '教师:'),
          ),
        );
      }
    }
    return JsonScheduleImportResult(
      items: _deduplicate(items),
      termName: root['term'] as String?,
      studentId: root['student_id'] as String?,
    );
  }

  static ScheduleImportResult parseOcrLines(
    List<OcrLine> lines, {
    int defaultWeekday = 1,
  }) {
    final headers = <int, double>{};
    for (final line in lines) {
      final weekday = _weekdayFromText(line.text);
      if (weekday != null) headers[weekday] = line.centerX;
    }
    if (headers.length < 2) {
      return parseText(
        lines.map((line) => line.text).join('\n'),
        defaultWeekday: defaultWeekday,
      );
    }

    final grouped = <int, List<String>>{};
    for (final line in lines) {
      if (_weekdayFromText(line.text) != null) continue;
      final weekday = headers.entries
          .reduce(
            (a, b) =>
                (line.centerX - a.value).abs() < (line.centerX - b.value).abs()
                ? a
                : b,
          )
          .key;
      grouped.putIfAbsent(weekday, () => []).add(line.text);
    }
    final items = <ParsedSchedule>[];
    for (final entry in grouped.entries) {
      final parsed = parseText(
        entry.value.join(' '),
        defaultWeekday: entry.key,
      );
      items.addAll(
        parsed.items.map((item) => item.copyWith(weekday: entry.key)),
      );
    }
    return ScheduleImportResult(
      items: _deduplicate(items),
      warning: items.isEmpty ? 'OCR 已识别到表头，但课程文字未包含可识别的节次格式。' : null,
    );
  }

  static ScheduleImportResult parseHtml(
    String source, {
    int defaultWeekday = 1,
  }) {
    final document = html_parser.parse(source);
    final rows = document.querySelectorAll('tr');
    final weekdayByColumn = <int, int>{};
    for (final row in rows) {
      final cells = row.querySelectorAll('th,td');
      for (var index = 0; index < cells.length; index++) {
        final weekday = _weekdayFromText(cells[index].text);
        if (weekday != null) weekdayByColumn[index] = weekday;
      }
    }

    final items = <ParsedSchedule>[];
    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      for (var index = 0; index < cells.length; index++) {
        final cellText = cells[index].text.trim();
        if (!_courseMarker.hasMatch(cellText)) continue;
        final weekday = weekdayByColumn[index] ?? defaultWeekday;
        final parsed = parseText(cellText, defaultWeekday: weekday).items;
        items.addAll(parsed.map((item) => item.copyWith(weekday: weekday)));
      }
    }

    if (items.isEmpty) {
      final fallback = parseText(
        document.body?.text ?? source,
        defaultWeekday: defaultWeekday,
      );
      return ScheduleImportResult(
        items: fallback.items,
        warning: 'HTML 中没有识别到标准课表表格，已按普通文字解析：${fallback.warning ?? ''}',
      );
    }
    return ScheduleImportResult(
      items: _deduplicate(items),
      warning: weekdayByColumn.isEmpty
          ? 'HTML 保留了课程表格，但没有识别到星期表头；未识别的课程暂归入${_weekdayName(defaultWeekday)}。'
          : null,
    );
  }

  static final _courseMarker = RegExp(
    r'(?:第\s*)?[（(【\[]?\s*\d{1,2}\s*[-－—~～]\s*\d{1,2}\s*节\s*[）)】\]]?',
  );

  static (int, int)? _parsePeriodRange(String value) {
    final match = RegExp(r'(\d{1,2})\s*[-－—~～]\s*(\d{1,2})').firstMatch(value);
    if (match == null) return null;
    return (int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  static String _stripPrefix(String? value, String prefix) {
    if (value == null) return '';
    final normalized = value.trim();
    final prefixIndex = normalized.lastIndexOf(prefix);
    return prefixIndex >= 0
        ? normalized.substring(prefixIndex + prefix.length).trim()
        : normalized;
  }

  static String _normalize(String value) => value
      .replaceAll('\u3000', ' ')
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static int? _weekdayFromText(String value) {
    final match = RegExp(r'星期([一二三四五六日天])').firstMatch(value);
    if (match == null) return null;
    return '一二三四五六日天'.indexOf(match.group(1)!) + 1;
  }

  static String _cleanTitle(String value) => value
      .replaceAll(RegExp(r'^(上午|下午|晚上)\s*\d*'), '')
      .replaceAll(RegExp(r'^\d+'), '')
      .replaceAll(RegExp(r'[★☆◆※〇●■]'), '')
      .trim();

  static ({WeekType type, List<int> weeks, int from, int to}) _parseWeeks(
    String detail,
  ) {
    final rangeMatches = RegExp(
      r'(?:第)?(\d{1,2})(?:-(\d{1,2}))?周(?:\s*[（(](单|双)[）)])?',
    ).allMatches(detail).toList();
    if (rangeMatches.isEmpty)
      return (type: WeekType.all, weeks: const [], from: 1, to: 20);
    final first = rangeMatches.first;
    final from = int.parse(first.group(1)!);
    final to = int.parse(first.group(2) ?? first.group(1)!);
    final parity = first.group(3);
    if (parity == '单')
      return (type: WeekType.odd, weeks: const [], from: from, to: to);
    if (parity == '双')
      return (type: WeekType.even, weeks: const [], from: from, to: to);
    final weeks = <int>{};
    for (final match in rangeMatches) {
      final start = int.parse(match.group(1)!);
      final end = int.parse(match.group(2) ?? match.group(1)!);
      for (var week = start; week <= end; week++) weeks.add(week);
    }
    return (
      type: WeekType.custom,
      weeks: weeks.toList()..sort(),
      from: weeks.reduce((a, b) => a < b ? a : b),
      to: weeks.reduce((a, b) => a > b ? a : b),
    );
  }

  static ({String location, String teacher}) _parseLocationTeacher(
    String detail,
  ) {
    final match = RegExp(
      r'南校区\s+(.+?)\s+([\u4e00-\u9fff]{2,4}(?:、[\u4e00-\u9fff]{2,4})*)\s+[\u4e00-\u9fffA-Za-z]+-\d{4}',
    ).firstMatch(detail);
    if (match == null) return (location: '', teacher: '');
    return (location: match.group(1)!.trim(), teacher: match.group(2)!.trim());
  }

  static int? _detectWeekday(String before) {
    final markers = RegExp(r'星期([一二三四五六日天])').allMatches(before).toList();
    if (markers.length != 1) return null;
    final match = markers.last;
    return '一二三四五六日天'.indexOf(match.group(1)!) + 1;
  }

  static bool _hasReliableWeekdayMarkers(String text) =>
      RegExp(r'星期([一二三四五六日天])').allMatches(text).length == 1;

  static String _weekdayName(int weekday) =>
      const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][weekday - 1];

  static List<ParsedSchedule> _deduplicate(List<ParsedSchedule> items) {
    final seen = <String>{};
    return items.where((item) {
      final key = jsonEncode([
        item.courseName,
        item.weekday,
        item.startPeriod,
        item.endPeriod,
        item.weekType.name,
        item.customWeeks,
      ]);
      return seen.add(key);
    }).toList();
  }
}
