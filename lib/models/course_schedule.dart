// 课程时间安排模型。
enum WeekType { all, odd, even, custom }

extension WeekTypeText on WeekType {
  String get label => switch (this) {
    WeekType.all => '全部周',
    WeekType.odd => '单周',
    WeekType.even => '双周',
    WeekType.custom => '自定义周',
  };

  String get value => name;

  static WeekType fromValue(String? value) => WeekType.values.firstWhere(
    (item) => item.name == value,
    orElse: () => WeekType.all,
  );
}

class CourseSchedule {
  const CourseSchedule({
    required this.id,
    required this.termId,
    required this.courseId,
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    this.weekType = WeekType.all,
    this.customWeeks = const [],
  });

  final String id;
  final String termId;
  final String courseId;
  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final WeekType weekType;
  final List<int> customWeeks;

  bool isVisibleInWeek(int week) => switch (weekType) {
    WeekType.all => true,
    WeekType.odd => week.isOdd,
    WeekType.even => week.isEven,
    WeekType.custom => customWeeks.contains(week),
  };

  factory CourseSchedule.fromJson(Map<String, dynamic> json) => CourseSchedule(
    id: json['id'] as String,
    termId: json['termId'] as String,
    courseId: json['courseId'] as String,
    weekday: (json['weekday'] as num).toInt(),
    startPeriod: (json['startPeriod'] as num).toInt(),
    endPeriod: (json['endPeriod'] as num).toInt(),
    weekType: WeekTypeText.fromValue(json['weekType'] as String?),
    customWeeks: [
      ...((json['customWeeks'] as List<dynamic>?) ?? const []).map(
        (item) => (item as num).toInt(),
      ),
    ],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'termId': termId,
    'courseId': courseId,
    'weekday': weekday,
    'startPeriod': startPeriod,
    'endPeriod': endPeriod,
    'weekType': weekType.value,
    'customWeeks': customWeeks,
  };
}
