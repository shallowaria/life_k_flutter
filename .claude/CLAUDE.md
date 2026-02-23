# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**life_k** (人生K线图) — A Flutter app that visualizes BaZi (八字) fortune analysis as interactive candlestick (K-line) charts. Users enter birth date/time/gender, the app calculates Four Pillars (四柱) using the Chinese lunar calendar, sends data to the Anthropic Claude API for AI-generated 30-year fortune analysis, and renders results as a stock-market-style chart with 9-dimensional life analysis.

## Common Commands

```bash
# Get dependencies
flutter pub get

# Run the app (debug)
flutter run

# Static analysis
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path_to_test.dart

# Build APK
flutter build apk
```

## Architecture

### State Management: BLoC Pattern

Two BLoCs manage all app state, provided via `MultiBlocProvider` in `main.dart`:

- **UserInputBloc** — Persists/loads user birth info. Events: `UserInputUpdated`, `UserInputLoaded`, `UserInputCleared`.
- **DestinyResultBloc** — Triggers API generation, caches results. Events: `DestinyResultGenerate`, `DestinyResultLoaded`, `DestinyResultCleared`. States include `Loading`, `Success`, and `Failure` with user-friendly error messages.

### Data Flow

```
InputScreen → BaziCalculator.calculate() → UserInput model
           → UserInputBloc (save to SharedPreferences)
           → DestinyResultBloc → DestinyApiService.generateDestiny()
                                  → Claude API (with system prompt from bazi_prompt.dart)
                                  → Parse JSON + normalizeScore()
                                  → LifeDestinyResult (30 KLinePoints + AnalysisData)
                                  → Cache via StorageService
                                  → Navigate to ResultScreen
```

### Key Layers

| Layer     | Location                    | Purpose                                                                                                                                                                                                                                 |
| --------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Models    | `lib/models/`               | `KLinePoint` (OHLC + score + TenGod + energy + advice), `AnalysisData` (9 dimensions), `UserInput` (birth info + 4 pillars), `LifeDestinyResult` (wrapper)                                                                              |
| Services  | `lib/services/`             | `BaziCalculator` — static Four Pillars computation via `lunar` library; `DestinyApiService` — Anthropic API with 3 retries + exponential backoff (30s connect / 120s receive timeout); `StorageService` — SharedPreferences persistence |
| BLoCs     | `lib/blocs/`                | `user_input/` and `destiny_result/` each with event/state/bloc files                                                                                                                                                                    |
| Screens   | `lib/screens/`              | `InputScreen` (birth form + ShiChen grid + live pillar preview), `ResultScreen` (chart + 9D analysis cards + action advice)                                                                                                             |
| Widgets   | `lib/widgets/k_line_chart/` | `KLineChart` (interactive tap + tooltip overlay), `KLinePainter` (CustomPainter with diamond candles, MK10 line, support/pressure levels, Da Yun separators), `KLineTooltip` (detailed popup)                                           |
| Constants | `lib/constants/`            | `shi_chen.dart` (12 traditional double-hour periods with conversion functions), `bazi_prompt.dart` (AI system prompt defining analysis rules)                                                                                           |
| Utils     | `lib/utils/`                | `score_normalizer.dart` (clamp 0-10), `validators.dart` (chart data + BaZi input validation)                                                                                                                                            |

### Routing

GoRouter with two routes: `/input` (initial) and `/result`.

### API Integration

`DestinyApiService` calls the Anthropic Messages API. The system prompt in `bazi_prompt.dart` defines strict rules for generating 30-year fortune data including OHLC scoring, 9-dimensional analysis, support/pressure levels, and action advice. The auth token in `main.dart` is currently empty and needs configuration.

### Chart Rendering

`KLinePainter` uses `CustomPainter` with a Chinese painting aesthetic (cinnabar red for 吉/bullish, indigo for 凶/bearish). Features: diamond-shaped candles, MK10 moving average line, support/pressure reference lines, Da Yun (大运) 10-year cycle separators, current year marker, peak seal stamp, and action advice stamps (启/变).

## Dependencies

- **flutter_bloc** / **bloc** — State management
- **dio** — HTTP client for API calls
- **go_router** — Declarative routing
- **lunar** — Chinese calendar / BaZi calculation
- **shared_preferences** — Local key-value storage
- **equatable** — Value equality for BLoC states/events

##SDK

Dart SDK `^3.10.7`. Linting via `package:flutter_lints/flutter.yaml`.

## Project Rules

@.claude/rules_4k.md
@.claude/ARCHITECTURE.md
