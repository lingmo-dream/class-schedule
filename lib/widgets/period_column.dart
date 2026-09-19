// 节次列：显示节次编号和对应时间。
import 'package:flutter/material.dart';

import '../state/time_settings.dart';

class PeriodColumn extends StatelessWidget {
  const PeriodColumn({
    super.key,
    required this.period,
    required this.slot,
    this.height = 76,
  });
  final int period;
  final PeriodSlot slot;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 76,
    height: height,
    child: Center(
      child: Text(
        '$period\n${slot.start}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(height: 1.35),
      ),
    ),
  );
}
