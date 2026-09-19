// 生成跨平台使用的简单唯一标识。
String createId() => DateTime.now().microsecondsSinceEpoch.toString();
