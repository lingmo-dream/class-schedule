import 'dart:math';

int _idSeq = 0;

// 生成跨平台使用的唯一标识。
// Windows 时钟精度约 15.6ms，仅靠时间戳会重复，所以加入随机数和自增序号。
String createId() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  final rand = Random.secure().nextInt(0x7FFFFFFF);
  _idSeq++;
  return '$ts-$rand-$_idSeq';
}
