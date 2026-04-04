library;

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// 音樂術語查詢 Service
/// 使用 Claude Haiku 3.5 解釋音樂術語
class TerminologyService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';

  static String get _apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  /// 查詢音樂術語
  /// [term] 術語或縮寫（例如 ff、rit.、D.C.、pizz.）
  /// [languageCode] 使用者語言（zh、en、ja、ko）
  static Future<TerminologyResult> lookup(
    String term, {
    String languageCode = 'zh',
  }) async {
    if (term.trim().isEmpty) {
      throw ArgumentError('術語不能為空');
    }

    final languageInstruction = _languageInstruction(languageCode);

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 300,
        'system': '''你是一位專業的音樂術語解說員。
使用者會輸入樂譜上的術語、縮寫或記號。
請提供：
1. 完整名稱（原文）
2. $languageInstruction 的解釋

格式要求：
- 直接回答，不要有多餘的前言
- 解釋要簡潔清楚，適合演奏者在練習時快速理解
- 如果是縮寫，先給出完整名稱
- 如果輸入不是音樂術語，請回覆「找不到這個術語」''',
        'messages': [
          {
            'role': 'user',
            'content': term.trim(),
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['content'][0]['text'] as String;
      return TerminologyResult(
        term: term.trim(),
        explanation: text.trim(),
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? '查詢失敗');
    }
  }

  static String _languageInstruction(String code) {
    switch (code) {
      case 'zh': return '繁體中文';
      case 'en': return '英文';
      case 'ja': return '日文';
      case 'ko': return '韓文';
      default: return '繁體中文';
    }
  }
}

/// 術語查詢結果
class TerminologyResult {
  final String term;
  final String explanation;

  const TerminologyResult({
    required this.term,
    required this.explanation,
  });
}
