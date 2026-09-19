// 课程数据模型。
class Course {
  const Course({
    required this.id,
    required this.name,
    this.teacher = '',
    this.location = '',
    this.colorIndex = 0,
    this.note = '',
  });

  final String id;
  final String name;
  final String teacher;
  final String location;
  final int colorIndex;
  final String note;

  Course copyWith({
    String? name,
    String? teacher,
    String? location,
    int? colorIndex,
    String? note,
  }) => Course(
    id: id,
    name: name ?? this.name,
    teacher: teacher ?? this.teacher,
    location: location ?? this.location,
    colorIndex: colorIndex ?? this.colorIndex,
    note: note ?? this.note,
  );

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'] as String,
    name: json['name'] as String,
    teacher: json['teacher'] as String? ?? '',
    location: json['location'] as String? ?? '',
    colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
    note: json['note'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'teacher': teacher,
    'location': location,
    'colorIndex': colorIndex,
    'note': note,
  };
}
