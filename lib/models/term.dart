// 学期数据模型。
class Term {
  const Term({
    required this.id,
    required this.name,
    required this.startDate,
    required this.totalWeeks,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final int totalWeeks;

  factory Term.fromJson(Map<String, dynamic> json) => Term(
    id: json['id'] as String,
    name: json['name'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
    totalWeeks: (json['totalWeeks'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'totalWeeks': totalWeeks,
  };
}
