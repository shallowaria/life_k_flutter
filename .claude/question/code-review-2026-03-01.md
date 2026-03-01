# 全项目代码审查报告 — 2026-03-01

> `flutter analyze`: No issues found | `dart format`: 0 changed

## 全项目健康度总览

```
配置层  ：✅ env.dart 无硬编码凭证，defaultValue 使用空字符串安全回退
模型层  ：✅ 全部 6 个模型类纯数据结构、Equatable 完整、final 不可变
服务层  ：⚠️ destiny_api_service.dart 存在 dynamic 返回类型和未保护类型转换
状态层  ：⚠️ DestinyResultBloc 未区分 4xx/5xx 错误类型，错误提示过于笼统
常量层  ：✅ 提示词无严重注入风险，时辰逻辑基本正确（有小边界歧义）
工具层  ：✅ 纯函数、边界条件完备、normalizeScore 实现正确
UI 层   ：✅ 无业务逻辑泄漏、const 全面、shouldRepaint 精确、缓存失效正确
入口    ：✅ 服务注入正确、BLoC 注册完整、路由/主题配置规范
```

**总体评价：** 项目整体架构质量优秀，分层清晰、BLoC 模式执行严格。主要问题集中在 `destiny_api_service.dart` 的类型安全和 `destiny_result_bloc.dart` 的错误分类，属于可控的中优先级改进项。

---

## 安全审计状态

- [x] 未发现 API Key / Token 硬编码
- [x] `env.dart` 的 `defaultValue` 不含真实凭证（均为空字符串或公开模型名）
- [x] `bazi_prompt.dart` 无严重 Prompt Injection 风险（用户输入为四柱干支，格式受 `validateBaziInput()` 约束）
- [x] 无敏感用户数据在日志中泄露（全项目无 `print()` 残留）

---

## 待改进项

### 高优先级 — 类型安全与错误处理

#### H1: `_retryPost` 返回类型为 `dynamic`

- **文件：** `lib/services/destiny_api_service.dart:50`
- **问题：** `Future<dynamic> _retryPost(...)` 返回值为 `dynamic`，下游第 88、227、272、300 行均对其做无保护的 `as List` / `as Map` 强转，API 返回异常结构时将抛出难以诊断的 `TypeError`。
- **建议：** 将返回类型改为 `Future<Map<String, dynamic>>`，并在函数内部完成结构验证。

```dart
// 修改前
Future<dynamic> _retryPost({...}) async { ... }

// 修改后
Future<Map<String, dynamic>> _retryPost({...}) async {
  // ...
  final data = response.data;
  if (data is! Map<String, dynamic>) {
    throw Exception('API 响应格式异常：期望 Map，实际为 ${data.runtimeType}');
  }
  return data;
}
```

#### H2: 未保护的 `as` 类型转换

- **文件：** `lib/services/destiny_api_service.dart:88,109,227,272,300`
- **问题：** `response.data['content'] as List?`、`textBlock['text'] as String` 等直接强转，若 Claude API 返回非预期结构（如限流响应 `{"error":"rate_limit"}`）将崩溃。
- **建议：** 在转换前添加 `is` 类型检查：

```dart
// 修改前
final content = response.data['content'] as List?;

// 修改后
final rawContent = response.data['content'];
if (rawContent is! List) {
  throw Exception('AI 响应 content 字段格式异常：${rawContent.runtimeType}');
}
final content = rawContent;
```

#### H3: `DestinyResultBloc` 未区分错误类型

- **文件：** `lib/blocs/destiny_result/destiny_result_bloc.dart:35-39`
- **问题：** `catch (e)` 笼统捕获所有异常，所有错误统一显示 `'请检查网络连接，或稍后重试'`，用户无法判断是输入有误（4xx）、服务器故障（5xx）还是超时。
- **建议：** 按异常类型分发不同 suggestion：

```dart
} catch (e) {
  String suggestion;
  if (e is DioException) {
    final statusCode = e.response?.statusCode;
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      suggestion = '请求参数有误，请检查出生信息是否完整';
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout) {
      suggestion = '网络请求超时，请检查网络连接后重试';
    } else {
      suggestion = 'API 服务暂时不可用，请稍后重试';
    }
  } else if (e is FormatException) {
    suggestion = '数据解析失败，请重新生成';
  } else {
    suggestion = '发生未知错误，请重试';
  }
  emit(DestinyResultFailure(error: e.toString(), suggestion: suggestion));
}
```

---

### 中优先级 — 边界逻辑与一致性

#### M1: 子时/丑时午夜边界歧义

- **文件：** `lib/constants/shi_chen.dart:129-138`
- **问题：** `getShiChenFromHour()` 对 hour=23 和 hour=0 做特殊处理后，hour=1（01:00）理论上属于丑时（startHour:1），但当前逻辑可能被子时特殊分支覆盖，边界语义不明确。
- **建议：** 增加注释明确 hour=1 的归属，或补充单元测试固定此行为：

```dart
// 建议在 getShiChenFromHour 顶部注释：
// 子时跨越午夜：23:00-00:59 归子时，01:00-02:59 归丑时
// hour=0 → 子时，hour=1 → 丑时
```

#### M2: 两个时辰函数错误处理策略不一致

- **文件：** `lib/constants/shi_chen.dart:121-135`
- **问题：** `getHourFromShiChen()` 对无效输入抛出 `ArgumentError`；`getShiChenFromHour()` 对无效 hour 静默回退 `shiChenList[0]`（子时），两者策略不一致，调用方难以区分合法的子时与无效输入。
- **建议：** 统一策略，`getShiChenFromHour` 也对 hour < 0 || hour > 23 抛出 `ArgumentError`。

#### M3: 误导性注释

- **文件：** `lib/services/destiny_api_service.dart:130`
- **问题：** catch-all 块注释 `// 4xx: bubble up immediately` 与实际逻辑不符（4xx 在第 74 行已提前抛出，不会到达此处）。
- **建议：** 修改注释为实际描述：`// 非 Exception 错误（如 Error 子类），保留原始堆栈重新抛出`。

---

### 低优先级 — 测试覆盖缺口

#### L1: `DestinyApiService` 无直接单元测试（高风险）

- **文件：** `test/services/` — 缺失 `destiny_api_service_test.dart`
- **问题：** retry 逻辑（5 次重试、指数退避）、AI refusal 检测关键词、JSON 解析、4xx 立即抛出行为均无覆盖。
- **建议：** 使用 `mocktail` mock `Dio`，测试以下场景：
  - 5xx → 重试 + 指数退避后成功
  - 4xx → 立即抛出，不重试
  - AI refusal 关键词 → 检测并重试
  - 响应 JSON 格式错误 → 抛出 FormatException

#### L2: `StorageService` 无直接单元测试

- **文件：** `test/services/` — 缺失 `storage_service_test.dart`
- **问题：** JSON 序列化/反序列化正确性仅依赖 BLoC 测试中的 mock，SharedPreferences 实际读写未验证。
- **建议：** 使用 `shared_preferences` 的 `setMockInitialValues` 测试 save/load/clear 完整流程。

#### L3: `BaziCalculator.calculate()` 核心算法未测试

- **文件：** `test/services/bazi_calculator_test.dart`
- **问题：** 仅 `validateInput()` 和 `getDaYunDirection()` 有覆盖，四柱干支计算本身（依赖 `lunar` 库）无任何测试。
- **建议：** 选取已知出生日期（如黄历典籍中的已知案例）编写回归测试，固定四柱输出防止库升级引发静默错误。

#### L4: 归档文件应删除

- **文件：** `lib/screens/temp.dart`
- **问题：** 631 行全注释代码，为旧版 InputScreen 存档，增加代码库体积和阅读噪音。
- **建议：** 直接删除（版本历史已保留此文件内容）。

---

## 优点汇总

1. **架构分层严格** — screens/widgets 通过 BLoC 通信，无直接 service 调用；服务层无 BuildContext 依赖；models 全部纯数据+Equatable。
2. **图表渲染性能优秀** — `KLinePainter.shouldRepaint()` 对比 5 个关键属性；月/日数据缓存+精确失效逻辑（`didUpdateWidget` 中 `_cachedMonthData = null`）；const 构造函数全面使用。
3. **测试基础扎实** — 76 个测试覆盖 utils（29）、services（22）、BLoC（14）、widgets（11），`bloc_test` + `mocktail` 使用规范。
