# 外事课表 (IU Schedule App)

面向 Windows 和 Web 的课程安排管理应用，基于 Flutter + Material 3 构建。

> 本项目采用 [GPL-3.0](LICENSE) 协议开源。

---

## 环境要求

- **Flutter** >= 3.11.5
- **Dart** >= 3.11.5
- **平台**：Windows / Web（未配置 Android/iOS）

---

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/lingmo-dream/class-schedule.git
cd class-schedule

# 获取依赖
flutter pub get

# 运行（Windows）
flutter run -d windows

# 运行（Web）
flutter run -d chrome

# 运行测试
flutter test

# 构建 Windows 发布版
flutter build windows --release

# 构建 Web 发布版
flutter build web --release
```

---

## 项目架构

```
lib/
├── main.dart                         # 应用入口，MultiProvider 初始化
│
├── models/                           # 数据模型（不可变 + JSON 序列化）
│   ├── course.dart                   # 课程：id, name, teacher, location, colorIndex
│   ├── course_schedule.dart          # 课程安排：weekday, periods, weekType, customWeeks
│   ├── term.dart                     # 学期：name, startDate, totalWeeks
│   ├── exam.dart                     # 考试：title, time, location
│   └── note.dart                     # 笔记：content, courseId
│
├── state/                            # 状态管理（ChangeNotifier）
│   ├── app_state.dart                # 核心状态：课程/安排/学期/考试/笔记 CRUD + 自动持久化
│   └── time_settings.dart            # 节次时间配置：夏/秋模板 + 自定义编辑
│
├── storage/                          # 持久化层
│   └── storage.dart                  # SharedPreferences 封装，JSON 导出/导入
│
├── services/                         # 业务服务（纯静态方法）
│   ├── schedule_import_service.dart  # 多格式课表解析：Text/JSON/HTML/OCR/PDF
│   └── image_ocr_service.dart        # OCR API 客户端
│
├── pages/                            # 页面
│   ├── home_page.dart                # 应用壳：响应式导航 + IndexedStack
│   ├── timetable_page.dart           # 周课表：WeekGrid + 周次切换
│   ├── course_management_page.dart   # 课程管理：列表 + 展开查看安排
│   ├── term_management_page.dart     # 学期管理
│   ├── exams_page.dart               # 考试倒计时
│   ├── notes_page.dart               # 学习笔记
│   ├── data_page.dart                # 数据中心：JSON 导入 + 备份
│   └── settings_page.dart            # 设置：节次时间 + 主题
│
├── widgets/                          # 可复用组件
│   ├── app_navigation.dart           # 响应式导航栏（Rail/Bar）
│   ├── week_grid.dart                # 周课表网格（Stack + Positioned 渲染）
│   ├── course_block.dart             # 课程色块组件
│   ├── period_column.dart            # 节次时间列
│   ├── add_course_dialog.dart        # 新增/编辑课程表单
│   ├── color_picker.dart             # 8 色选择器
│   ├── detail_bottom_sheet.dart      # 课程详情底部弹窗
│   └── empty_state.dart              # 空状态占位
│
└── utils/                            # 工具
    ├── app_constants.dart            # 常量：节次时间、颜色、星期名
    └── identifiers.dart              # 唯一 ID 生成器
```

### 架构模式

采用 **Provider + ChangeNotifier** 单向数据流架构：

```
用户操作 (UI)
    │
    ▼
Page / Widget ──调用──> AppState (ChangeNotifier)
    │                      │
    │                      ├─ 修改内存数据
    │                      ├─ _changed()
    │                      │    ├─ Storage.save() ──> SharedPreferences (JSON)
    │                      │    └─ notifyListeners()
    │                      │
    │                      ◄── UI 通过 Consumer 自动重建
    │
    └── ScheduleImportService.parse*() ──> ParsedSchedule[]
                                              │
                                              ▼
                                        AppState.addCourse / replaceCurrentTermSchedules
```

**核心设计决策**：

- **无数据库**：所有数据以单个 JSON 字符串存储在 SharedPreferences 中，简单高效
- **自动保存**：每次数据变更自动触发持久化，无需手动保存
- **响应式 UI**：基于 Consumer 的声明式渲染，数据变化自动更新界面
- **Stack 渲染课表**：使用绝对定位实现课程块重叠和时间指针

---

## JSON 导入格式

应用支持从教务系统导出的结构化 JSON 导入课表。格式如下：

```json
{
  "term": "2025-2027学年第1学期",
  "schedule": {
    "星期一": [
      {
        "periods": "1-2",
        "course": "高等数学",
        "weeks": "1-2周,7-19周",
        "location": "场地:xxx",
        "teacher": "教师:xxx"
      }
    ],
    "星期二": [ ... ]
  }
}
```

### weeks 字段支持的格式

| 格式 | 示例 | 说明 |
|---|---|---|
| 范围 | `3-18周` | 第 3 至 18 周 |
| 多范围 | `3-5周,7-19周` | 逗号/分号分隔 |
| 含节次前缀 | `3-5节;6-18周` | 节次部分自动跳过 |
| 单周 | `第6周` | 仅第 6 周 |
| 单双周 | `16-18周(双)` | 仅偶数周 |

---

## 依赖说明

| 包 | 用途 |
|---|---|
| `provider` | 状态管理 |
| `shared_preferences` | 本地持久化 |
| `intl` | 日期格式化 |
| `file_picker` | 文件选择对话框 |
| `syncfusion_flutter_pdf` | PDF 文本提取 |
| `html` | HTML 解析 |
| `http` | HTTP 请求（OCR API） |

---

## 开发

```bash
# 代码分析
flutter analyze

# 运行全部测试
flutter test

# 格式化代码
dart format lib/ test/
```

---

## 构建产物

| 平台 | 命令 | 产物路径 |
|---|---|---|
| Windows | `flutter build windows --release` | `build/windows/x64/runner/Release/` |
| Web | `flutter build web --release` | `build/web/` |

---

## 许可证

本项目采用 [GNU General Public License v3.0](LICENSE) 协议开源。

你可以自由地：
- **使用**：在任何场景下运行本软件
- **研究**：查看和修改源代码
- **分发**：复制和分发原始或修改后的版本
- **改进**：提交修改并分发改进版本

条件是：分发时必须保留原始版权声明，并以相同许可证发布衍生作品。

详见 [LICENSE](LICENSE) 文件。
