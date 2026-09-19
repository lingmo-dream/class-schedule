// 课表中的课程块：支持跨节次、高亮和点击详情操作。
import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';
import '../utils/app_constants.dart';

class CourseBlock extends StatelessWidget {
  const CourseBlock({
    super.key,
    required this.course,
    required this.schedule,
    required this.width,
    required this.onTap,
    this.isCurrentWeek = true,
    this.isPressed = false,
  });
  final Course course;
  final CourseSchedule schedule;
  final double width;
  final VoidCallback onTap;
  final bool isCurrentWeek;
  final bool isPressed;

  String get weekLabel => switch (schedule.weekType) {
    WeekType.all => '全',
    WeekType.odd => '单',
    WeekType.even => '双',
    WeekType.custom => '自',
  };

  @override
  Widget build(BuildContext context) {
    final baseColor = courseColors[course.colorIndex % courseColors.length];
    final color = isCurrentWeek ? baseColor : Colors.blueGrey;
    return AnimatedScale(
      scale: isPressed ? .96 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: width,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isCurrentWeek ? .92 : .48),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (course.location.isNotEmpty)
                        Text(
                          course.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      if (course.teacher.isNotEmpty)
                        Text(
                          course.teacher,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      child: Text(
                        isCurrentWeek ? weekLabel : '非本周',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
