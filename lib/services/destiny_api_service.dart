import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/user_input.dart';
import '../models/life_destiny_result.dart';
import '../models/k_line_point.dart';
import '../models/analysis_data.dart';
import '../constants/bazi_prompt.dart';
import '../utils/score_normalizer.dart';
import 'bazi_calculator.dart' show getDaYunDirection;

/// Thrown when the AI returns a refusal instead of JSON.
class _AiRefusalException implements Exception {
  final String message;
  const _AiRefusalException(this.message);
  @override
  String toString() => message;
}

class DestinyApiService {
  final Dio _dio;
  final String baseUrl;
  final String authToken;
  final String model;

  DestinyApiService({
    required this.baseUrl,
    required this.authToken,
    required this.model,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 60),
               receiveTimeout: const Duration(seconds: 300),
             ),
           );

  // ---------------------------------------------------------------------------
  // Shared retry helper
  // ---------------------------------------------------------------------------

  /// Posts to [baseUrl]/v1/messages with [body], retrying up to [maxRetries]
  /// times.  Handles:
  ///   - 5xx HTTP errors  → exponential back-off, retry
  ///   - 4xx HTTP errors  → immediate rethrow (client bug, no point retrying)
  ///   - AI refusal text  → detected via [_isAiRefusal], retry with short delay
  ///
  /// Returns the raw response `data` on success.
  Future<Map<String, dynamic>> _retryPost({
    required Map<String, dynamic> body,
    int maxRetries = 5,
  }) async {
    Exception? lastError;

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.post(
          '$baseUrl/v1/messages',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'anthropic-version': '2023-06-01',
              'x-api-key': authToken,
            },
            validateStatus: (status) => status != null,
          ),
          data: body,
        );

        final status = response.statusCode ?? 0;

        // 4xx: client-side error, don't retry
        if (status >= 400 && status < 500) {
          throw Exception('API 错误 ($status): ${response.data}');
        }

        // 5xx: server error, retry with back-off
        if (status != 200) {
          lastError = Exception('API 服务端错误 ($status): ${response.data}');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: 5 * attempt));
          }
          continue;
        }

        // 200: validate response structure and check for AI refusal
        final rawData = response.data;
        if (rawData is! Map<String, dynamic>) {
          lastError = Exception('API 响应格式异常：期望 Map，实际为 ${rawData.runtimeType}');
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
          }
          continue;
        }

        final rawContent = rawData['content'];
        if (rawContent is! List || rawContent.isEmpty) {
          lastError = Exception('AI 返回格式错误：content 为空或格式异常');
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
          }
          continue;
        }

        final textBlock = rawContent.firstWhere(
          (b) => b['type'] == 'text',
          orElse: () => null,
        );
        if (textBlock == null) {
          lastError = Exception('AI 返回格式错误：未找到文本内容');
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
          }
          continue;
        }

        final rawText = textBlock['text'];
        if (rawText is! String) {
          lastError = Exception('AI 返回格式错误：text 字段非字符串');
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
          }
          continue;
        }

        final text = rawText.trim();
        if (_isAiRefusal(text)) {
          lastError = _AiRefusalException('AI 拒绝生成（第 $attempt 次），正在重试...');
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: 3));
          }
          continue;
        }

        return rawData;
      } on _AiRefusalException catch (e) {
        lastError = e;
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 3));
        }
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          lastError = Exception('网络超时：${e.message ?? e.type.name}');
        } else {
          lastError = Exception('网络错误：${e.message ?? e.type.name}');
        }
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 5 * attempt));
        }
      } catch (e, st) {
        if (e is Exception) rethrow; // Exception（含 4xx 客户端错误）立即重抛，不再重试
        Error.throwWithStackTrace(Exception(e.toString()), st);
      }
    }

    throw lastError ?? Exception('所有重试均失败');
  }

  /// Returns true when the AI has responded with a refusal instead of JSON.
  bool _isAiRefusal(String text) {
    // Starts with JSON → definitely not a refusal
    if (text.startsWith('{') || text.startsWith('[')) return false;

    const patterns = [
      'i appreciate',
      'i need to be direct',
      "i'm not able",
      "i can't",
      'i cannot',
      "i'm unable",
      'i must clarify',
      'i must decline',
      'sorry,',
      'i apologize',
      'unfortunately',
      'as an ai',
    ];
    final lower = text.toLowerCase();
    return patterns.any(lower.contains);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  String _generateUserPrompt(UserInput input) {
    final direction = getDaYunDirection(input.yearPillar, input.gender);
    final genderText = input.gender == Gender.male ? '乾造（男）' : '坤造（女）';

    return '''**输入参数（干支数据）:**
- 性别参数: $genderText
- 出生年份: ${input.birthYear}
- 四柱干支: ${input.yearPillar}年 ${input.monthPillar}月 ${input.dayPillar}日 ${input.hourPillar}时
- 起运年龄: ${input.startAge}岁（虚岁）
- 大运方向: ${direction.text}
${_buildLifeEventsSection(input)}
请直接输出纯JSON数据，不要添加任何额外文字。''';
  }

  String _buildLifeEventsSection(UserInput input) {
    if (input.lifeEvents == null || input.lifeEvents!.isEmpty) return '';
    final lines = input.lifeEvents!
        .map((e) => '- ${e.toPromptString()}')
        .join('\n');
    return '\n## 用户过往人生大事（请据此校准运势模型）\n$lines\n';
  }

  /// Generate 30-year destiny data for [input].
  Future<LifeDestinyResult> generateDestiny(UserInput input) async {
    final prompt = _generateUserPrompt(input);
    final responseData = await _retryPost(
      body: {
        'model': model,
        'max_tokens': 16000,
        'temperature': 0.5,
        'system': baziSystemInstruction,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      },
    );
    return _parseResponse(responseData);
  }

  /// Fetch action advice for all year-view points that currently lack it.
  /// Returns a map keyed by year (int).
  Future<Map<int, ActionAdvice>> generateYearlyAdvice({
    required UserInput input,
    required List<KLinePoint> allPoints,
  }) async {
    final missing = allPoints.where((p) => p.actionAdvice == null).toList();
    if (missing.isEmpty) return {};

    final userMsg = buildYearlyAdviceUserMessage(input, missing);
    final responseData = await _retryPost(
      body: {
        'model': model,
        'max_tokens': 6000,
        'temperature': 0.5,
        'system': yearlyAdviceSystemInstruction,
        'messages': [
          {'role': 'user', 'content': userMsg},
        ],
      },
    );

    try {
      if (responseData['content'] is! List) {
        throw Exception('AI 响应格式异常：content 字段非列表');
      }
      final content = (responseData['content'] as List).firstWhere(
        (b) => b['type'] == 'text',
        orElse: () => throw Exception('AI 返回格式错误：未找到文本内容'),
      );
      final rawText = content['text'];
      if (rawText is! String) throw Exception('AI 返回格式错误：text 字段非字符串');
      var aiText = rawText.trim();
      aiText = aiText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final json = jsonDecode(aiText) as Map<String, dynamic>;
      final list = json['yearAdvice'] as List;
      return {
        for (final item in list)
          item['year'] as int: ActionAdvice.fromJson(
            item as Map<String, dynamic>,
          ),
      };
    } catch (e) {
      throw Exception('年度建议数据解析失败: $e');
    }
  }

  /// Fetch per-day action advice for a list of interpolated KLinePoints.
  /// Returns a map keyed by "yyyy-M-d".
  Future<Map<String, ActionAdvice>> generateDailyAdvice({
    required UserInput input,
    required List<KLinePoint> points,
  }) async {
    if (points.isEmpty) return {};

    final userMsg = buildDailyAdviceUserMessage(input, points);
    final responseData = await _retryPost(
      body: {
        'model': model,
        'max_tokens': 4000,
        'temperature': 0.6,
        'system': dailyAdviceSystemInstruction,
        'messages': [
          {'role': 'user', 'content': userMsg},
        ],
      },
    );

    try {
      if (responseData['content'] is! List) {
        throw Exception('AI 响应格式异常：content 字段非列表');
      }
      final content = (responseData['content'] as List).firstWhere(
        (b) => b['type'] == 'text',
        orElse: () => throw Exception('AI 返回格式错误：未找到文本内容'),
      );
      final rawText = content['text'];
      if (rawText is! String) throw Exception('AI 返回格式错误：text 字段非字符串');
      var aiText = rawText.trim();
      aiText = aiText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final json = jsonDecode(aiText) as Map<String, dynamic>;
      final list = json['dailyAdvice'] as List;
      return {
        for (final item in list)
          item['date'] as String: ActionAdvice.fromJson(
            item as Map<String, dynamic>,
          ),
      };
    } catch (e) {
      throw Exception('每日建议数据解析失败: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  LifeDestinyResult _parseResponse(Map<String, dynamic> responseData) {
    if (responseData['content'] is! List) {
      throw Exception('AI 返回格式错误：content 字段非列表');
    }
    final content = responseData['content'] as List;
    final textBlock = content.firstWhere(
      (block) => block['type'] == 'text',
      orElse: () => throw Exception('AI 返回格式错误：未找到文本内容'),
    );

    final rawText = textBlock['text'];
    if (rawText is! String) throw Exception('AI 返回格式错误：text 字段非字符串');
    var aiText = rawText.trim();
    aiText = aiText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final Map<String, dynamic> rawData;
    try {
      rawData = jsonDecode(aiText) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('AI 返回的数据无法解析为 JSON: $e');
    }

    try {
      return _transformToLifeDestinyResult(rawData);
    } catch (e) {
      throw Exception('命运数据结构转换失败: $e');
    }
  }

  LifeDestinyResult _transformToLifeDestinyResult(Map<String, dynamic> data) {
    if (data.containsKey('chartData') &&
        data.containsKey('analysis') &&
        data['analysis'] is Map) {
      final chartData = (data['chartData'] as List)
          .map((e) => _normalizeKLinePoint(e as Map<String, dynamic>))
          .toList();
      final analysis = _normalizeAnalysis(
        data['analysis'] as Map<String, dynamic>,
      );
      return LifeDestinyResult(chartData: chartData, analysis: analysis);
    }

    final rawChartData =
        (data['chartPoints'] as List?) ?? (data['chartData'] as List?) ?? [];
    final chartData = rawChartData
        .map((e) => _normalizeKLinePoint(e as Map<String, dynamic>))
        .toList();

    final analysis = _normalizeAnalysis(data);
    return LifeDestinyResult(chartData: chartData, analysis: analysis);
  }

  KLinePoint _normalizeKLinePoint(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['score'] = normalizeScore((json['score'] as num).toDouble());
    return KLinePoint.fromJson(normalized);
  }

  AnalysisData _normalizeAnalysis(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    for (final key in [
      'summaryScore',
      'personalityScore',
      'industryScore',
      'fengShuiScore',
      'wealthScore',
      'marriageScore',
      'healthScore',
      'familyScore',
      'cryptoScore',
    ]) {
      if (normalized[key] != null) {
        normalized[key] = normalizeScore((normalized[key] as num).toDouble());
      }
    }

    normalized['bazi'] ??= <String>[];

    for (final key in [
      'summary',
      'personality',
      'industry',
      'fengShui',
      'wealth',
      'marriage',
      'health',
      'family',
      'crypto',
      'cryptoYear',
      'cryptoStyle',
    ]) {
      normalized[key] ??= '';
    }

    return AnalysisData.fromJson(normalized);
  }
}
