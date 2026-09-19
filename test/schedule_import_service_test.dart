// 课表文字解析回归测试。
import 'package:flutter_test/flutter_test.dart';

import 'package:iu_schedule_app/services/schedule_import_service.dart';
import 'package:iu_schedule_app/services/image_ocr_service.dart';

void main() {
  test('可以识别课程名、节次和周次', () {
    const text = '高等数学1★ (1-2节)3-5周,7-19周 南校区 学术苑105 安东 高等数学1-0014 2026';
    final result = ScheduleImportService.parseText(text);

    expect(result.items, isNotEmpty);
    expect(result.items.first.courseName, '高等数学1');
    expect(result.items.first.startPeriod, 1);
    expect(result.items.first.endPeriod, 2);
    expect(result.items.first.customWeeks, containsAll([3, 4, 5, 7, 19]));
  });

  test('可以识别双周安排', () {
    const text = '大学物理1★ (5-6节)6-18周(双) 南校区 3#412 毕升 大学物理1-0002';
    final result = ScheduleImportService.parseText(text);

    expect(result.items.single.weekType.name, 'even');
    expect(result.items.single.weekFrom, 6);
    expect(result.items.single.weekTo, 18);
  });

  test('可以识别 OCR 常见的中文括号和节次空格', () {
    const text = '高等数学1★（1 - 2 节）3-5周 南校区 学术苑105 安东';
    final result = ScheduleImportService.parseText(text);

    expect(result.items, hasLength(1));
    expect(result.items.single.courseName, '高等数学1');
    expect(result.items.single.startPeriod, 1);
    expect(result.items.single.endPeriod, 2);
  });

  test('可以识别 OCR 漏掉括号的节次', () {
    const text = '网页与网站基础☆ 第1-2节 3-5周 南校区 3#115 张志强';
    final result = ScheduleImportService.parseText(text);

    expect(result.items, hasLength(1));
    expect(result.items.single.courseName, '网页与网站基础');
    expect(result.items.single.startPeriod, 1);
    expect(result.items.single.endPeriod, 2);
  });

  test('可以从 HTML 表格列识别星期', () {
    const html = '''
      <table>
        <tr><th>节次</th><th>星期一</th><th>星期二</th></tr>
        <tr>
          <td>1</td>
          <td>高等数学1★ (1-2节)3-5周 南校区 学术苑105 安东 高等数学1-0014</td>
          <td>网页与网站基础☆ (1-2节)3-5周 南校区 3#115 张志强 网页与网站基础-0002</td>
        </tr>
      </table>
    ''';
    final result = ScheduleImportService.parseHtml(html);

    expect(result.items, hasLength(2));
    expect(result.items[0].weekday, 1);
    expect(result.items[1].weekday, 2);
  });

  test('可以根据 OCR 坐标识别课程所在星期列', () {
    final result = ScheduleImportService.parseOcrLines([
      const OcrLine(text: '星期一', left: 100, top: 20, width: 40, height: 20),
      const OcrLine(text: '星期二', left: 300, top: 20, width: 40, height: 20),
      const OcrLine(
        text: '高等数学1★（1-2节）3-5周',
        left: 80,
        top: 100,
        width: 100,
        height: 30,
      ),
      const OcrLine(
        text: '网页与网站基础☆（1-2节）3-5周',
        left: 280,
        top: 100,
        width: 100,
        height: 30,
      ),
    ]);

    expect(result.items, hasLength(2));
    expect(result.items[0].weekday, 1);
    expect(result.items[1].weekday, 2);
  });

  test('可以识别结构化课表 JSON', () {
    const source = '''
    {
      "term": "2025-2027学年第1学期",
      "schedule": {
        "星期一": [{
          "periods": "1-2",
          "course": "高等数学1",
          "weeks": "3-5周,7-19周",
          "location": "校区-南校区/场地:学术苑105",
          "teacher": "教师:安东"
        }],
        "星期二": [{
          "periods": "5-6",
          "course": "线性代数",
          "weeks": "16-18周(双)",
          "location": "校区-南校区/场地:3B411",
          "teacher": "教师:赵微"
        }]
      }
    }
    ''';
    final result = ScheduleImportService.parseJson(source);

    expect(result.termName, '2025-2027学年第1学期');
    expect(result.items, hasLength(2));
    expect(result.items[0].weekday, 1);
    expect(result.items[0].location, '学术苑105');
    expect(result.items[1].weekday, 2);
    expect(result.items[1].weekType.name, 'even');
  });
}
