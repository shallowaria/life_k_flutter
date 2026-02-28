# life_k 项目架构文档

> 生成日期：2026-02-23
> Flutter 版本：Dart SDK `^3.10.7`

---

## 目录结构

```
life_k/
├── .claude/
│   ├── CLAUDE.md              # 项目总览与开发指南
│   ├── ARCHITECTURE.md        # 本文件：详细架构参考
│   └── rules_4k.md            # AI 编码规范
├── lib/
│   ├── main.dart              # 应用入口：BLoC 注册、路由、主题
│   ├── core/
│   │   └── config/
│   │       └── env.dart       # 环境配置（API URL / Token / Model）
│   ├── models/                # 数据模型层
│   │   ├── user_input.dart
│   │   ├── k_line_point.dart
│   │   ├── analysis_data.dart
│   │   ├── life_destiny_result.dart
│   │   └── life_event.dart
│   ├── services/              # 业务逻辑层
│   │   ├── bazi_calculator.dart
│   │   ├── destiny_api_service.dart
│   │   ├── storage_service.dart
│   │   └── kline_interpolation_service.dart
│   ├── blocs/                 # 状态管理层（BLoC）
│   │   ├── user_input/
│   │   │   ├── user_input_bloc.dart
│   │   │   ├── user_input_event.dart
│   │   │   └── user_input_state.dart
│   │   └── destiny_result/
│   │       ├── destiny_result_bloc.dart
│   │       ├── destiny_result_event.dart
│   │       └── destiny_result_state.dart
│   ├── screens/               # UI 页面层
│   │   ├── input_screen.dart
│   │   └── result_screen.dart
│   ├── widgets/               # 可复用组件层
│   │   └── k_line_chart/
│   │       ├── k_line_chart.dart
│   │       ├── k_line_painter.dart
│   │       ├── k_line_tooltip.dart
│   │       └── chart_view_mode.dart
│   ├── constants/             # 常量与提示词
│   │   ├── shi_chen.dart
│   │   └── bazi_prompt.dart
│   └── utils/                 # 工具函数
│       ├── score_normalizer.dart
│       └── validators.dart
├── assets/
│   └── images/                # App 图标
├── android/                   # Android 构建配置
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 数据流

```
用户填写生辰信息
        ↓
InputScreen
  → BaziCalculator.calculate(birthDate, shiChen, gender)
  → 得到四柱干支 + 大运起步年龄
        ↓
UserInputBloc.add(UserInputUpdated)
  → StorageService.saveUserInput()        // 持久化到 SharedPreferences
        ↓
DestinyResultBloc.add(DestinyResultGenerate)
  → DestinyApiService.generateDestiny(userInput)
      → POST /v1/messages (Anthropic API)
          系统提示：bazi_prompt.dart (baziSystemInstruction)
          用户提示：四柱 + 性别 + 起运年龄 + 可选人生事件
          max_tokens: 16000, temperature: 0.5
          超时：60s connect / 300s receive
          重试：最多5次，_retryPost 统一处理
            - 4xx → 立即失败，不重试
            - 5xx → 指数退避（5s × attempt）
            - AI拒绝文本 → _isAiRefusal() 检测，3s 后重试
          解析：每步均有 try-catch，解析失败抛 Exception 而非崩溃
      → 解析 JSON → normalizeScore() 归一化 0-10
      → 构造 LifeDestinyResult (30 KLinePoints + AnalysisData)
  → StorageService.saveDestinyResult()    // 缓存结果
        ↓
DestinyResultBloc 发出 DestinyResultSuccess
        ↓
GoRouter 导航到 /result
        ↓
ResultScreen
  → KLineChart 渲染 30 根年蜡烛（年视图）
  → 用户切换月/日视图 → KLineInterpolationService 插值生成细粒度数据
  → 用户点击月/日标签 → 懒加载 generateDailyAdvice() 获取每日建议
  → 用户点击蜡烛 → KLineTooltip 弹层显示详情
```

---

## 状态管理（BLoC）

### UserInputBloc

| 事件                          | 触发时机     | 处理逻辑                            |
| ----------------------------- | ------------ | ----------------------------------- |
| `UserInputLoaded`             | App 启动     | 从 SharedPreferences 读取已保存信息 |
| `UserInputUpdated(UserInput)` | 用户提交表单 | 保存到 SharedPreferences            |
| `UserInputCleared`            | 用户清除数据 | 删除本地数据                        |

| 状态                        | 含义     |
| --------------------------- | -------- |
| `UserInputInitial`          | 未加载   |
| `UserInputReady(UserInput)` | 数据就绪 |

### DestinyResultBloc

| 事件                               | 触发时机     | 处理逻辑           |
| ---------------------------------- | ------------ | ------------------ |
| `DestinyResultLoaded`              | App 启动     | 从缓存恢复上次结果 |
| `DestinyResultGenerate(UserInput)` | 用户提交表单 | 调用 API，重试3次  |
| `DestinyResultCleared`             | 用户清除     | 删除缓存           |

| 状态                                      | 含义                   |
| ----------------------------------------- | ---------------------- |
| `DestinyResultInitial`                    | 初始                   |
| `DestinyResultLoading`                    | API 请求中             |
| `DestinyResultSuccess(result, userName)`  | 分析完成               |
| `DestinyResultFailure(error, suggestion)` | 失败（含用户友好提示） |

---

## 数据模型

### UserInput

```dart
class UserInput {
  String? name;
  Gender gender;            // male / female
  String birthDate;         // "YYYY-MM-DD"
  String yearPillar;        // 年柱干支
  String monthPillar;       // 月柱干支
  String dayPillar;         // 日柱干支
  String hourPillar;        // 时柱干支
  int startAge;             // 大运起步虚岁 (0-10)
  List<LifeEvent>? lifeEvents;  // 可选：人生事件校准
}
```

### KLinePoint（30年蜡烛数据）

```dart
class KLinePoint {
  int age;                  // 虚岁 (1-30)
  int year;                 // 公历年份
  String ganZhi;            // 年干支
  String daYun;             // 当前大运
  double open, close, high, low;  // K线 OHLC (0-10)
  double score;             // 综合分 (0-10)
  String reason;            // 10-15字说明
  String tenGod;            // 十神
  EnergyScore energyScore;  // 能量细分
  ActionAdvice? actionAdvice;  // 关键年：3建议+2警示
  bool get isUp => close >= open;
}
```

### AnalysisData（九维分析）

```dart
class AnalysisData {
  List<String> bazi;         // 四柱数组
  DimensionData summary;     // 综合运势
  DimensionData personality; // 性格
  DimensionData industry;    // 行业方向
  DimensionData fengShui;    // 风水
  DimensionData wealth;      // 财运
  DimensionData marriage;    // 婚姻
  DimensionData health;      // 健康
  DimensionData family;      // 家庭
  CryptoDimension crypto;    // 数字资产（含年份/风格）
  List<SupportPressureLevel> supportPressureLevels;  // 3-5个支撑/压力位
}
```

### LifeDestinyResult（顶层包装）

```dart
class LifeDestinyResult {
  List<KLinePoint> chartData;   // 30个年度K线点
  AnalysisData analysis;        // 九维分析
}
```

### LifeEvent（人生事件，用于 AI 校准）

```dart
class LifeEvent {
  int age;         // 发生时虚岁
  String event;    // 事件描述
}
```

---

## 服务层

### BaziCalculator（静态方法）

- 依赖 `lunar` 包：公历 → 农历 → 八字
- 入参：`birthDate`（DateTime）、`shiChenName`（时辰名）、`gender`
- 出参：四柱干支 + 大运起步年龄（虚岁，钳制 0-10）
- 校验：出生年份 1900-2100，时辰名有效

### DestinyApiService

- 调用 Anthropic Messages API（`/v1/messages`）
- **`_retryPost()`**：私有统一重试方法，两个公开方法均委托于此
  - 最多 5 次重试
  - 4xx → 立即抛出（客户端错误）
  - 5xx → 指数退避（5s × attempt）
  - AI 拒绝文本 → `_isAiRefusal()` 关键词检测，3s 后重试
- **`generateDestiny()`**：生成30年运势 JSON，解析后包 try-catch
- **`generateDailyAdvice()`**：
  - 先调用 `KLineInterpolationService` 插值至日级
  - 再请求每日行动建议
  - 返回 `Map<String, ActionAdvice>`（键："yyyy-M-d"）
  - 解析段包 try-catch，失败抛带描述的 Exception
- 响应解析：提取文本块 → 清理 Markdown → 解析 JSON → 归一化分数
- System prompt 将任务框架定义为"JSON 数据生成引擎"以规避 AI 安全拒绝

### StorageService

- SharedPreferences 封装
- 存储键：用户信息 / 运势结果 / 用户姓名
- 方法：save / load / clearAll（各实体独立）

### KLineInterpolationService

- 算法：自然三次样条 + 确定性伪随机 OHLC
- 确定性：Knuth hash 保证相同日期始终产生相同蜡烛
- 元数据继承：daYun / tenGod / reason 来自最近年锚点
- 输出：分值钳制 0-10，保留2位小数

---

## 路由

```
GoRouter
  /input  →  InputScreen   （初始页）
  /result →  ResultScreen  （结果页）
```

---

## 图表渲染

### KLineChart（Widget 层）

- 管理视图模式：年 / 月 / 日
- 维护插值缓存：`_cachedMonthData` / `_cachedDayData`
- 管理 OverlayEntry tooltip 生命周期
- 切换视图时触发 `onViewModeChanged` 回调，传递插值后的数据

### KLinePainter（CustomPainter）

绘制顺序：

1. 网格线 + Y轴标签
2. 支撑/压力水平线（强/中/弱）
3. 大运分隔竖线（仅年视图）
4. 当前年份标记竖线
5. MA10 移动均线（10周期，绿色）
6. 蜡烛主体（菱形）+ 影线
7. 最高点封印印章
8. 关键年行动印章（启/变，仅年视图）
9. 图例

颜色体系：
| 含义 | 颜色 | Hex |
|------|------|-----|
| 吉/阳线 | 朱砂红 | `#B22D1B` |
| 凶/阴线 | 藏青 | `#2F4F4F` |
| 金色装饰 | 金 | `#C5A367` |
| MA10均线 | 翠绿 | `#479977` |

### ChartViewMode（Enum）

```dart
enum ChartViewMode { year, month, day }
```

- `label`：年视图 / 月视图 / 日视图
- `dateRange(today)`：
  - year：全部30年数据
  - month：today ± 15天
  - day：today ± 7天

### KLineTooltip（弹层）

- 触发：点击蜡烛
- 内容：日期+干支+年龄 / 大运 / 十神 / 吉凶徽章 / OHLC / 能量分 / 行动建议

---

## 常量

### shi_chen.dart（十二时辰）

- 12个时辰（子丑寅卯…）及对应2小时区间
- `getHourFromShiChen(name)` → 代表小时
- `getShiChenFromHour(hour)` → 时辰名称

### bazi_prompt.dart（AI 提示词）

- `baziSystemInstruction`：30年运势生成规则 + JSON Schema（chartPoints + analysis + 支撑压力位）
- `dailyAdviceSystemInstruction`：每日行动建议规则 + JSON Schema

---

## 工具函数

### score_normalizer.dart

```dart
double normalizeScore(double score) {
  // 若分数 > 10，视为0-100制，除以10取整
  if (score > 10) return (score / 10).roundToDouble();
  return score;
}
```

### validators.dart

- `validateChartData(List<KLinePoint>)`：验证30个点、OHLC约束（high ≥ max(O,C)，low ≤ min(O,C)）、分值0-10
- `validateBaziInput(UserInput)`：四柱汉字校验、起运年龄0-10

---

## 环境配置

```dart
// lib/core/config/env.dart — 运行时从 .env 文件读取
class Env {
  static String get baseUrl   => dotenv.env['API_BASE_URL']   ?? '';
  static String get authToken => dotenv.env['API_AUTH_TOKEN'] ?? '';
  static String get model     => dotenv.env['API_MODEL']      ?? 'claude-haiku-4-5-20251001';
  static String get flavor    => dotenv.env['FLAVOR']         ?? 'dev';
}
```

- 依赖 `flutter_dotenv`，在 `main()` 中 `await dotenv.load(fileName: '.env')` 加载
- `.env` 文件放在项目根目录，已在 `pubspec.yaml` 的 `flutter.assets` 中注册
- `.env` 已加入 `.gitignore`，不提交至版本库

---

## 依赖一览

| 包                       | 版本    | 用途              |
| ------------------------ | ------- | ----------------- |
| `flutter_bloc`           | ^9.1.0  | BLoC 状态管理     |
| `bloc`                   | ^9.0.0  | BLoC 核心         |
| `dio`                    | ^5.8.0  | HTTP 客户端       |
| `go_router`              | ^15.1.2 | 声明式路由        |
| `lunar`                  | ^1.3.20 | 农历/八字计算     |
| `shared_preferences`     | ^2.5.3  | 本地 KV 存储      |
| `equatable`              | ^2.0.7  | BLoC 值相等       |
| `intl`                   | ^0.20.2 | 国际化            |
| `flutter_dotenv`         | ^6.0.0  | .env 环境变量加载 |
| `url_launcher`           | ^6.3.1  | 外部链接跳转      |
| `flutter_launcher_icons` | ^0.14.4 | 图标生成（dev）   |
| `flutter_lints`          | ^6.0.0  | 代码规范（dev）   |

---

## 关键设计决策

1. **离线优先**：结果缓存于 SharedPreferences，无网络时可查看历史分析。
2. **懒加载日建议**：月/日视图的行动建议仅在用户切换时才请求，避免首屏 API 开销。
3. **确定性插值**：Knuth hash 保证同一日期在多次进入结果页时渲染结果一致。
4. **严格 JSON 校验**：`validateChartData` 在渲染前校验 OHLC 约束，防止 API 返回异常数据导致图表崩溃。
5. **中国美学渲染**：朱砂红/藏青色系 + 菱形蜡烛 + 篆印风格印章，强化文化调性。
6. **多语言支持**：flutter_localizations 注册 zh_CN + en_US，当前界面以中文为主。
