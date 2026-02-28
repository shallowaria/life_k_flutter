# 全项目代码审查报告

> 审查日期：2026-02-28
> 审查工具：Claude Code — 首席架构师模式
> 静态分析：`flutter analyze` → No issues found
> 格式检查：`dart format` → 0 changed（审查前已格式化 12 个文件）

---

## 全项目健康度总览

```
配置层  ：✅ env.dart 结构清晰，无硬编码凭证，defaultValue 均为空字符串
模型层  ：✅ 纯数据结构，字段全 final，const 构造函数，JSON 解析安全
服务层  ：⚠️ 重试逻辑完备，但存在代码重复(getDaYunDirection)、StorageService 缺 try-catch
状态层  ：✅ BLoC 规范良好，Event/State 使用 Equatable + 完整 props
常量层  ：✅ 提示词安全，明确声明"数据引擎"定位，时辰逻辑正确
工具层  ：⚠️ normalizeScore 逻辑有缺陷，utils/ 放了 UI Widget 违反分层
UI 层   ：⚠️ InputScreen build() 过长(~1057行)，ResultScreen 直接访问 BLoC 的 apiService
入口    ：⚠️ main.dart build() 中每次创建新的 Service 实例
```

> **总体评价**：项目架构清晰、BLoC 分层规范、安全意识良好，主要问题集中在 UI 层过度膨胀、少量分层违规和工具函数边界条件上。

---

## 优点（做得好的地方）

1. **提示词安全设计出色** — `bazi_prompt.dart` 将 AI 定位为"JSON 数据生成引擎"，明确禁止输出非 JSON 内容，有效规避 AI 安全拒绝问题。`_isAiRefusal()` 关键词检测 + 自动重试机制设计周全。

2. **BLoC 状态管理规范** — Event/State 均使用 `Equatable` + 完整 `props` 覆盖，状态字段全部 `final`，`DestinyResultFailure` 包含用户友好的 `suggestion` 字段，状态流转清晰。

3. **图表渲染专业** — `KLinePainter.shouldRepaint` 精确比较 4 个字段而非盲目 `return true`；自然三次样条插值算法实现完整；Knuth hash 保证确定性输出。

---

## 待改进项

### 🔴 最高优先级 — 安全 / 正确性

#### 1. `lib/utils/score_normalizer.dart:3-6` — normalizeScore 逻辑缺陷

**问题**：当 `score` 为 `15` 时返回 `2.0`（`15/10` rounded）；当 `score` 为 `-5` 时直接返回 `-5`，未做下限保护。

**当前代码**：
```dart
double normalizeScore(double score) {
  if (score > 10) {
    return (score / 10).roundToDouble();
  }
  return score;
}
```

**建议修改**：
```dart
double normalizeScore(double score) {
  if (score > 10) return (score / 10).clamp(0.0, 10.0);
  return score.clamp(0.0, 10.0);
}
```

---

#### 2. `lib/utils/validators.dart:41-42` — OHLC 范围校验与实际分制不一致

**问题**：`open` 和 `close` 的校验范围是 `0-100`，但经过 `normalizeScore` 处理后实际分制为 `0-10`，校验形同虚设。

**当前代码**：
```dart
if (open < 0 || open > 100) return 'chartData[$i].open 超出范围';
if (close < 0 || close > 100) return 'chartData[$i].close 超出范围';
```

**建议修改**：
```dart
if (open < 0 || open > 10) return 'chartData[$i].open 超出范围 (0-10)';
if (close < 0 || close > 10) return 'chartData[$i].close 超出范围 (0-10)';
```

---

### 🟠 高优先级 — 分层违规 / 架构问题

#### 3. `lib/utils/` 目录放置了 UI Widget — 违反分层原则

**问题**：`app_exit_scope.dart` 和 `exit_tip_overlay.dart` 依赖 `BuildContext`、`Material`、`OverlayEntry`，是 UI 组件，不应位于 `utils/` 层。

**建议**：迁移到 `lib/widgets/` 目录：
```
lib/widgets/app_exit_scope.dart
lib/widgets/exit_tip_overlay.dart
```

---

#### 4. `lib/screens/result_screen.dart:58` + `lib/blocs/destiny_result/destiny_result_bloc.dart:11` — Screen 直接访问 BLoC 内部 Service

**问题**：
```dart
// result_screen.dart:58
final service = context.read<DestinyResultBloc>().apiService;
```
```dart
// destiny_result_bloc.dart:11
DestinyApiService get apiService => _apiService; // 不应暴露
```

Screen 绕过 BLoC 直接取到 Service 并调用，违反分层原则。

**建议**：通过 `RepositoryProvider` 获取 Service（`main.dart` 已注册）：
```dart
// result_screen.dart
final service = context.read<DestinyApiService>();
```
并删除 `destiny_result_bloc.dart` 中的 `apiService` getter。

---

#### 5. `getDaYunDirection` 函数重复实现

**问题**：完全相同的逻辑在两处实现：
- `lib/services/bazi_calculator.dart:105-115`（顶层公共函数）
- `lib/services/destiny_api_service.dart:186-195`（`_getDaYunDirection` 私有方法）

**建议**：删除 `DestinyApiService` 中的私有版本，直接 import 并调用 `bazi_calculator.dart` 中的公共函数：
```dart
import '../services/bazi_calculator.dart' show getDaYunDirection;
// ...
final direction = getDaYunDirection(input.yearPillar, input.gender);
```

---

#### 6. `lib/main.dart:28-34` — Service 实例在 `build()` 中创建

**问题**：`StorageService()` 和 `DestinyApiService(...)` 在 `LifeKApp.build()` 中实例化，每次 Widget rebuild 都会创建新实例（虽然 `MaterialApp` 不频繁 rebuild，但这是架构反模式）。

**建议**：将实例化移至 `main()` 函数并向下传递，或用 `late final`：
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final storageService = StorageService();
  final apiService = DestinyApiService(...);
  runApp(LifeKApp(storageService: storageService, apiService: apiService));
}
```

---

### 🟡 中优先级 — 性能 / Widget 最佳实践

#### 7. `lib/screens/input_screen.dart` — 单文件过度膨胀（1057 行）

**问题**：`_buildFormView()` 超 280 行，`_showAddEventSheet()` 超 290 行，整个文件包含过多职责。

**建议**：拆分为独立子 Widget 类：
```
lib/widgets/input/gender_selector.dart
lib/widgets/input/shi_chen_grid.dart
lib/widgets/input/bazi_preview.dart
lib/widgets/input/life_events_section.dart
lib/widgets/input/add_event_sheet.dart
```

---

#### 8. `lib/utils/app_exit_scope.dart:10-11` — StatelessWidget 中使用 static 可变状态

**问题**：
```dart
class AppExitScope extends StatelessWidget {
  static DateTime? _lastPressedAt; // 可变静态状态
```

`StatelessWidget` 语义上不应持有可变状态。

**建议**：改为 `StatefulWidget`，将 `_lastPressedAt` 提升为实例变量：
```dart
class AppExitScope extends StatefulWidget { ... }
class _AppExitScopeState extends State<AppExitScope> {
  DateTime? _lastPressedAt;
  ...
}
```

---

#### 9. 模型类缺少 `Equatable` / `==` 实现

**问题**：`KLinePoint`、`AnalysisData`、`LifeDestinyResult`、`UserInput` 等模型类未实现 `Equatable`。`DestinyResultSuccess.props` 包含 `result`，但 `LifeDestinyResult` 无 `==` override，导致状态比较退化为引用相等，可能造成不必要的 UI 刷新。

**建议**：为核心模型类添加 `Equatable` 混入或手动实现 `==` 和 `hashCode`，或引入 `freezed` 代码生成。

---

#### 10. `lib/widgets/k_line_chart/k_line_painter.dart:663` — 循环内重复计算 maxHigh

**问题**：
```dart
void _drawActionAdviceStamps(...) {
  for (var i = 0; i < data.length; i++) {
    // ...
    final maxHigh = data.map((p) => p.high).reduce(max); // 每次循环都重复计算！
    if (d.high == maxHigh) continue;
  }
}
```

O(n²) 复杂度，应提取到循环外：

**建议**：
```dart
final maxHigh = data.map((p) => p.high).reduce(max); // 提取到循环外
for (var i = 0; i < data.length; i++) {
  // ...
}
```

---

### 🔵 低优先级 — 代码规范 / 测试

#### 11. `lib/services/destiny_api_service.dart:129` — Error 被静默包装

**问题**：
```dart
catch (e) {
  if (e is Exception) rethrow; // 4xx: bubble up immediately
  lastError = Exception(e.toString()); // Error 被包装，stack trace 丢失
}
```

`Error`（如 `StackOverflowError`、`OutOfMemoryError`）会被包装为普通 `Exception`，原始 stack trace 丢失，增加调试难度。

**建议**：
```dart
catch (e, stack) {
  if (e is Exception) rethrow;
  Error.throwWithStackTrace(Exception(e.toString()), stack);
}
```

---

#### 12. 测试覆盖严重不足

| 文件 | 当前状态 | 建议 |
|------|---------|------|
| `utils/score_normalizer.dart` | ❌ 无测试 | 添加边界值单元测试（0, 10, 100, -1, 10.5） |
| `utils/validators.dart` | ❌ 无测试 | 添加 OHLC 约束、bazi 格式验证测试 |
| `services/bazi_calculator.dart` | ❌ 无测试 | 添加四柱计算、起运年龄计算测试 |
| `services/kline_interpolation_service.dart` | ❌ 无测试 | 添加样条插值确定性测试、OHLC 约束测试 |
| `blocs/destiny_result/` | ❌ 无测试 | 添加 `bloc_test` 覆盖 Loading→Success / Loading→Failure 流转 |
| `blocs/user_input/` | ❌ 无测试 | 添加 `bloc_test` 覆盖 Loaded / Updated / Cleared |

---

## 全项目安全审计状态

- [x] 未发现 API Key / Token 硬编码
- [x] `env.dart` 的 `defaultValue` 不含真实凭证（均为空字符串或安全默认值）
- [x] `bazi_prompt.dart` 无 Prompt Injection 风险（系统指令明确约束输出格式为纯 JSON，用户输入通过结构化参数传递）
- [x] 无敏感用户数据在日志中泄露（未发现 `print()` 残留）
