// 课程笔记数据模型。
class Note {
  const Note({
    required this.id,
    required this.content,
    required this.createdAt,
    this.courseId,
  });

  final String id;
  final String? courseId;
  final String content;
  final DateTime createdAt;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    courseId: json['courseId'] as String?,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}
