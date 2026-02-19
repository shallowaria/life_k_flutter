import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/user_input.dart';
import '../models/life_destiny_result.dart';
import '../models/k_line_point.dart';
import '../models/analysis_data.dart';
import '../constants/bazi_prompt.dart';
import '../utils/score_normalizer.dart';

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
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 120),
            ));

  /// Generate user prompt from input
  String _generateUserPrompt(UserInput input) {
    final direction = _getDaYunDirection(input.yearPillar, input.gender);
    final genderText =
        input.gender == Gender.male ? '乾造（男）' : '坤造（女）';

    return '''$baziSystemInstruction

---

**用户八字信息:**
- 性别: $genderText
- 出生年份: ${input.birthYear}
- 四柱: ${input.yearPillar}年 ${input.monthPillar}月 ${input.dayPillar}日 ${input.hourPillar}时
- 起运年龄: ${input.startAge}岁（虚岁）
- 大运方向: ${direction.text}

请严格按照JSON格式输出，不要添加任何额外的文字说明。''';
  }

  ({bool isForward, String text}) _getDaYunDirection(
      String yearPillar, Gender gender) {
    final firstChar =
        yearPillar.trim().isNotEmpty ? yearPillar.trim()[0] : '';
    const yangStems = ['甲', '丙', '戊', '庚', '壬'];
    final isYangYear = yangStems.contains(firstChar);
    final isForward = gender == Gender.male ? isYangYear : !isYangYear;
    return (isForward: isForward, text: isForward ? '顺行' : '逆行');
  }

  /// Call AI API to generate destiny data
  Future<LifeDestinyResult> generateDestiny(UserInput input) async {
    final prompt = _generateUserPrompt(input);

    const maxRetries = 3;
    const initialRetryDelay = Duration(seconds: 1);

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
              'Authorization': 'Bearer $authToken',
            },
          ),
          data: {
            'model': model,
            'max_tokens': 16000,
            'temperature': 0.5,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
          },
        );

        if (response.statusCode == 200) {
          return _parseResponse(response.data);
        }

        // 4xx errors: don't retry
        if (response.statusCode != null &&
            response.statusCode! >= 400 &&
            response.statusCode! < 500) {
          throw Exception(
              'API 错误 (${response.statusCode}): ${response.data}');
        }
      } on DioException catch (e) {
        lastError = e;
        if (attempt < maxRetries) {
          final delay = initialRetryDelay * (1 << (attempt - 1));
          await Future.delayed(delay);
          continue;
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt < maxRetries) {
          final delay = initialRetryDelay * (1 << (attempt - 1));
          await Future.delayed(delay);
          continue;
        }
      }
    }

    throw lastError ?? Exception('所有重试均失败');
  }

  /// Parse API response and transform to LifeDestinyResult
  LifeDestinyResult _parseResponse(dynamic responseData) {
    // Extract text content from Anthropic response
    final content = responseData['content'] as List;
    final textBlock = content.firstWhere(
      (block) => block['type'] == 'text',
      orElse: () => throw Exception('AI 返回格式错误：未找到文本内容'),
    );

    var aiText = (textBlock['text'] as String).trim();

    // Clean markdown wrappers
    aiText = aiText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Parse JSON
    final Map<String, dynamic> rawData;
    try {
      rawData = jsonDecode(aiText) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('AI 返回的数据无法解析为 JSON: $e');
    }

    return _transformToLifeDestinyResult(rawData);
  }

  /// Transform raw AI response (flat or nested) to LifeDestinyResult
  LifeDestinyResult _transformToLifeDestinyResult(
      Map<String, dynamic> data) {
    // Check if already nested format
    if (data.containsKey('chartData') &&
        data.containsKey('analysis') &&
        data['analysis'] is Map) {
      final chartData = (data['chartData'] as List)
          .map((e) => _normalizeKLinePoint(e as Map<String, dynamic>))
          .toList();
      final analysis =
          _normalizeAnalysis(data['analysis'] as Map<String, dynamic>);
      return LifeDestinyResult(chartData: chartData, analysis: analysis);
    }

    // Flat format: extract chartPoints/chartData and analysis fields
    final rawChartData = (data['chartPoints'] as List?) ??
        (data['chartData'] as List?) ??
        [];
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

    // Normalize all score fields
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
        normalized[key] =
            normalizeScore((normalized[key] as num).toDouble());
      }
    }

    // Ensure bazi is present
    normalized['bazi'] ??= <String>[];

    // Ensure string fields have defaults
    for (final key in [
      'summary', 'personality', 'industry', 'fengShui',
      'wealth', 'marriage', 'health', 'family', 'crypto',
      'cryptoYear', 'cryptoStyle',
    ]) {
      normalized[key] ??= '';
    }

    return AnalysisData.fromJson(normalized);
  }
}
