// 课程颜色选择器：提供八种柔和且易区分的色板。
import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

class CourseColorPicker extends StatelessWidget {
  const CourseColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 8,
    children: List.generate(courseColors.length, (index) {
      final selected = index == value;
      return Semantics(
        label: '课程颜色 ${index + 1}',
        button: true,
        child: InkWell(
          onTap: () => onChanged(index),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: courseColors[index],
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: courseColors[index].withValues(alpha: .35),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, size: 17, color: Colors.white)
                : null,
          ),
        ),
      );
    }),
  );
}
