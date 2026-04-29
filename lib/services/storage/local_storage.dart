library;

import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/constants/app_constants.dart';

/// 本地儲存服務
/// 使用 shared_preferences 儲存用戶偏好設定
/// 所有本地儲存的讀寫都透過這個 class，不直接呼叫 shared_preferences
///
/// 儲存的資料：
/// - 語言設定
/// - 調音基準音高
/// - 節拍器 BPM
/// - 音樂家風格選擇
/// - Pro 狀態快取
/// - AI 分析使用次數
class LocalStorage {
  static SharedPreferences? _prefs;

  /// 初始化，在 main.dart 啟動時呼叫一次
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── 語言設定 ──────────────────────────────────────

  /// 取得儲存的語言代碼，預設中文
  static String getLocale() {
    return _prefs?.getString(AppConstants.keyLocale) ?? 'zh';
  }

  /// 儲存語言代碼
  static Future<void> setLocale(String locale) async {
    await _prefs?.setString(AppConstants.keyLocale, locale);
  }

  // ── 調音器設定 ────────────────────────────────────

  /// 取得調音基準音高，預設 440Hz
  static double getTunerReference() {
    return _prefs?.getDouble(AppConstants.keyTunerReference)
        ?? AppConstants.standardPitch;
  }

  /// 儲存調音基準音高
  static Future<void> setTunerReference(double pitch) async {
    await _prefs?.setDouble(AppConstants.keyTunerReference, pitch);
  }

  // ── 節拍器設定 ────────────────────────────────────

  /// 取得節拍器 BPM，預設 100
  static int getMetronomeBpm() {
    return _prefs?.getInt(AppConstants.keyMetronomeBpm)
        ?? AppConstants.metronomeDefaultBpm;
  }

  /// 儲存節拍器 BPM
  static Future<void> setMetronomeBpm(int bpm) async {
    await _prefs?.setInt(AppConstants.keyMetronomeBpm, bpm);
  }

  // ── 音樂家風格 ────────────────────────────────────

  /// 取得選擇的音樂家風格
  static String? getSelectedMusician() {
    return _prefs?.getString(AppConstants.keySelectedMusician);
  }

  /// 儲存選擇的音樂家風格
  static Future<void> setSelectedMusician(String musician) async {
    await _prefs?.setString(AppConstants.keySelectedMusician, musician);
  }

  // ── Pro 狀態 ──────────────────────────────────────

  /// 取得 Pro 狀態快取
  /// 真實狀態以 Supabase 為準，這裡只是快取避免每次都要請求
  static bool getIsPro() {
    return _prefs?.getBool(AppConstants.keyIsPro) ?? false;
  }

  /// 儲存 Pro 狀態
  static Future<void> setIsPro(bool isPro) async {
    await _prefs?.setBool(AppConstants.keyIsPro, isPro);
  }

  // ── AI 分析次數 ───────────────────────────────────

  /// 取得本月已使用的 AI 分析次數
  static int getAiAnalysisCount() {
    // 檢查是否需要重置（每月 1 日重置）
    final resetDate = _prefs?.getString(AppConstants.keyAiAnalysisResetDate);
    final now = DateTime.now();
    final thisMonth = '${now.year}-${now.month}';

    if (resetDate != thisMonth) {
      // 新的一個月，重置次數
      _prefs?.setInt(AppConstants.keyAiAnalysisCount, 0);
      _prefs?.setString(AppConstants.keyAiAnalysisResetDate, thisMonth);
      return 0;
    }

    return _prefs?.getInt(AppConstants.keyAiAnalysisCount) ?? 0;
  }

  /// 增加 AI 分析使用次數
  static Future<void> incrementAiAnalysisCount() async {
    final count = getAiAnalysisCount();
    await _prefs?.setInt(AppConstants.keyAiAnalysisCount, count + 1);
  }

  /// 檢查免費用戶是否還有 AI 分析額度
  static bool hasAiAnalysisQuota() {
    if (getIsPro()) return true; // Pro 用戶無限制
    return getAiAnalysisCount() < AppConstants.freeAiAnalysisQuota;
  }
}