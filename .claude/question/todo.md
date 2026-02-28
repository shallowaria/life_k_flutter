# 代码改进 TODO LIST

> 来源：全项目审查报告 `code-review-2026-02-28.md`
> 进度：10 / 12

---

## 🔴 最高优先级

- [x] **#1** `score_normalizer.dart:3-6` — 修复 `normalizeScore` 逻辑，补充负数下限保护（改用 `.clamp(0.0, 10.0)`）
- [x] **#2** `validators.dart:41-42` — 将 OHLC 校验范围从 `0-100` 改为 `0-10`，与实际分制一致

---

## 🟠 高优先级

- [x] **#3** `utils/` 目录清理 — 将 `app_exit_scope.dart` 和 `exit_tip_overlay.dart` 迁移到 `lib/widgets/`
- [x] **#4** 删除 `destiny_result_bloc.dart` 中暴露的 `apiService` getter，`result_screen.dart` 改用 `RepositoryProvider` 获取 Service
- [x] **#5** 删除 `destiny_api_service.dart` 中重复的 `_getDaYunDirection`，统一使用 `bazi_calculator.dart` 中的公共函数
- [x] **#6** `main.dart` — 将 `StorageService` 和 `DestinyApiService` 实例化从 `build()` 移至 `main()` 函数

---

## 🟡 中优先级

- [x] **#7** `input_screen.dart`（1057行）— 拆分为独立子 Widget：`GenderSelector`、`ShiChenGrid`、`BaziPreview`、`LifeEventsSection`、`AddEventSheet`
- [x] **#8** `app_exit_scope.dart` — 将 `static DateTime? _lastPressedAt` 从静态可变状态改为 `StatefulWidget` 实例变量
- [x] **#9** 核心模型类 (`KLinePoint` / `AnalysisData` / `LifeDestinyResult` / `UserInput`) — 添加 `Equatable` 或实现 `==` / `hashCode`
- [x] **#10** `k_line_painter.dart:663` — 将 `_drawActionAdviceStamps` 循环内的 `maxHigh` 计算提取到循环外

---

## 🔵 低优先级

- [ ] **#11** `destiny_api_service.dart:129` — `catch` 块中使用 `Error.throwWithStackTrace` 保留原始 stack trace
- [ ] **#12** 补充单元测试：`score_normalizer`、`validators`、`BaziCalculator`、`KLineInterpolationService`、`DestinyResultBloc`、`UserInputBloc`
