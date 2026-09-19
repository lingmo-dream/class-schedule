// 考试信息数据模型。
class Exam {
  const Exam({
    required this.id,
    required this.title,
    required this.examTime,
    this.courseId,
    this.location = '',
    this.remark = '',
  });

  final String id;
  final String title;
  final String? courseId;
  final DateTime examTime;
  final String location;
  final String remark;

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
    id: json['id'] as String,
    title: json['title'] as String,
    courseId: json['courseId'] as String?,
    examTime: DateTime.parse(json['examTime'] as String),
    location: json['location'] as String? ?? '',
    remark: json['remark'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'courseId': courseId,
    'examTime': examTime.toIso8601String(),
    'location': location,
    'remark': remark,
  };
}
