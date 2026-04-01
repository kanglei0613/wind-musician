library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/constants/app_constants.dart';

/// 後端 API 溝通層
/// 所有對 FastAPI 後端的請求都透過這個 class
/// 之後要換後端網址、加 token 驗證，只需要改這裡
class ApiClient {
  /// 判斷現在是開發還是正式環境
  /// 之後要切換環境只改這一行
  static const bool _isDev = true;

  static String get _baseUrl =>
      _isDev ? AppConstants.apiBaseUrlDev : AppConstants.apiBaseUrlProd;

  // ── 通用請求方法 ───────────────────────────────────

  /// GET 請求
  /// [path] 路徑，例如 '/health'
  /// 回傳解析後的 JSON Map
  static Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// POST 請求
  /// [path] 路徑，例如 '/analysis'
  /// [body] 要送出的資料
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ── 私有方法 ──────────────────────────────────────

  /// 通用請求標頭
  /// 之後加入 Supabase token 驗證也是在這裡加
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $token', // 之後登入功能完成後取消註解
      };

  /// 統一處理 API 回應
  /// 成功回傳資料，失敗拋出例外讓上層處理
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    // 之後可以在這裡根據狀態碼做更細緻的錯誤處理
    throw Exception('API 錯誤 ${response.statusCode}: ${response.body}');
  }
}