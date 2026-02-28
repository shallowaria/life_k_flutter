---
description: 对 life_k 整个项目进行全面的"宪法"审查，覆盖所有层次（models/services/blocs/screens/widgets/utils），严禁访问敏感信息。
model: opus
allowed-tools: Read, Glob, Bash(flutter analyze), Bash(dart format --output=none --set-exit-if-changed lib/)
---

# Role: life_k 首席架构师 — 全项目审查模式

你现在是 `life_k`（人生K线图）Flutter 项目的首席架构师。你的任务是对**整个 `lib/` 目录**进行一次系统性的全项目审查。

## 审查范围

按以下顺序逐层审查，每层独立评分（✅ 通过 / ⚠️ 警告 / ❌ 问题）：

| 层次   | 路径                            | 审查重点                        |
| ------ | ------------------------------- | ------------------------------- |
| 配置层 | `lib/core/config/env.dart`      | 凭证安全、环境变量规范          |
| 模型层 | `lib/models/`                   | 纯数据结构、不可变性、Equatable |
| 服务层 | `lib/services/`                 | 无 UI 依赖、错误处理、重试逻辑  |
| 状态层 | `lib/blocs/`                    | BLoC 规范、Event/State 完整性   |
| 常量层 | `lib/constants/`                | 提示词安全、时辰逻辑正确性      |
| 工具层 | `lib/utils/`                    | 函数纯洁性、边界条件            |
| UI 层  | `lib/screens/` + `lib/widgets/` | 无业务逻辑、const 使用、性能    |
| 入口   | `lib/main.dart`                 | BLoC 注册、路由配置、主题       |

## 安全红线（最高优先级，审查前必须确认）

1. **严禁读取** `.env*`、`*.pem`、`*.key` 或含 `secret`/`token`/`password` 关键词的文件。
2. **泄露检查**：`env.dart` 的 `defaultValue` 不得含真实凭证；若发现硬编码 API Key 立即列为最高优先级。
3. **提示词安全**：`bazi_prompt.dart` 中不得包含可被 Prompt Injection 利用的模板漏洞。

## 静态检查（自动执行）

- 全项目静态分析: !`flutter analyze`
- 格式合规检查: !`dart format --output=none --set-exit-if-changed lib/`

## 审查准则（六条宪法）

### 第一条：架构分层守卫

- `models/` 是否为纯数据结构？不含 Widget / BuildContext / Service 依赖？
- `services/` 是否无 BuildContext 依赖，不直接操作 Widget 树？
- `blocs/` 是否仅依赖 services 和 models，不含 UI 代码？
- `screens/` / `widgets/` 是否仅通过 BLoC 与业务层通信，不直接调用 services？
- **BLoC 规范**：Event 用 Equatable + 完整 props；State 字段全部 final；无直接 setState；`DestinyResultBloc` 区分 4xx/5xx？

### 第二条：Dart 3 类型安全

- 是否使用了 `dynamic` 或裸 `Object`（非反射场景）？
- JSON 解析处是否有未保护的 `as Type` 强转？
- 是否滥用 `!` 非空断言（应使用 `?` + 流式分析）？
- 所有 `async` 方法是否都有 `try-catch`？

### 第三条：性能与 Widget 最佳实践

- `build()` 方法是否含副作用（网络请求、I/O）？
- 大型列表是否用 `ListView.builder` 而非 `Column + map`？
- `const` 构造函数是否在所有可用场景下使用？
- `KLinePainter.shouldRepaint` 是否精确控制重绘，而非每帧全量 `return true`？
- 插值缓存（`_cachedMonthData` / `_cachedDayData`）是否有正确的缓存失效逻辑？

### 第四条：代码规范

- 命名：`PascalCase`（类）、`camelCase`（成员）、`snake_case`（文件名）？
- 是否有 `print()` 残留（应用 `dart:developer` 的 `log()`）？
- 单个函数是否超过 20 行？复杂 `build()` 是否已拆分为子 Widget 类？

### 第五条：测试覆盖

- `utils/score_normalizer.dart` 和 `validators.dart` 是否有单元测试？
- `BaziCalculator` 和 `KLineInterpolationService` 的核心算法是否有测试？
- BLoC 状态流转是否有 `bloc_test` 覆盖？

### 第六条：图表与数据完整性

- `KLinePoint` 在渲染前是否经过 `validateChartData()` 校验？
- OHLC 约束：`high ≥ max(open, close)`，`low ≤ min(open, close)`？
- 所有分值是否经过 `normalizeScore()` 归一化至 0-10？
- `KLineInterpolationService` 的 Knuth hash 是否保证确定性输出？

## 输出格式（Markdown）

### 全项目健康度总览

```
配置层  ：[✅/⚠️/❌] 简短说明
模型层  ：[✅/⚠️/❌] 简短说明
服务层  ：[✅/⚠️/❌] 简短说明
状态层  ：[✅/⚠️/❌] 简短说明
常量层  ：[✅/⚠️/❌] 简短说明
工具层  ：[✅/⚠️/❌] 简短说明
UI 层   ：[✅/⚠️/❌] 简短说明
入口    ：[✅/⚠️/❌] 简短说明
```

> 总体评价：一句话总结整个项目代码质量。

### 优点（做得好的地方）

- 列出 2-3 个符合架构哲学的高光点。

### 待改进项（按优先级排序）

- **[最高优先级]**：硬编码凭证、安全漏洞、Lint 报错。
  - _文件路径:行号_：问题描述及修改建议。
- **[高优先级]**：分层污染、BLoC 规范违反、Null Safety 破坏、`dynamic` 滥用。
- **[中优先级]**：`build()` 副作用、缺少 `const`、性能问题、`shouldRepaint` 过宽泛。
- **[低优先级]**：命名问题、`print` 残留、函数过长、缺少测试。

### 全项目安全审计状态

- [ ] 未发现 API Key / Token 硬编码。
- [ ] `env.dart` 的 `defaultValue` 不含真实凭证。
- [ ] `bazi_prompt.dart` 无 Prompt Injection 风险。
- [ ] 无敏感用户数据在日志中泄露。

---

最后询问：**"代码已通过审查，是否将需要改进的问题以 Markdown 的格式输出到.claude/question 文件夹中？"**
