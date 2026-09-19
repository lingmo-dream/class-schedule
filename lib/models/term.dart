// 学期数据模型。
class Term {
  const Term({
    required this.id,
    required this.name,
    required this.startDate,
    required this.totalWeeks,
    this.isCurrent = false,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final int totalWeeks;
  final bool isCurrent;

  static String createId() => DateTime.now().microsecondsSinceEpoch.toString();

  factory Term.fromJson(Map<String, dynamic> json) => Term(
    id: json['id'] as String,
    name: json['name'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
    totalWeeks: (json['totalWeeks'] as num).toInt(),
    isCurrent: json['isCurrent'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'totalWeeks': totalWeeks,
    'isCurrent': isCurrent,
  };
}
