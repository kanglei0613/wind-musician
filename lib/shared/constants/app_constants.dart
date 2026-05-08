library;

/// App 全域常數
/// 所有寫死的數值、字串都集中在這裡
/// 要換後端網址、調整參數，只需要改這個檔案

class AppConstants {
  AppConstants._();

  // ── 環境設定 ──────────────────────────────────────
  // ⚠️ BC-G2 PRE-RELEASE CHECKLIST: set isDev = false before uploading to
  // Firebase App Distribution / App Store Connect. Leaving true connects
  // all API calls to the local dev server (apiBaseUrlDev).
  /// 切換開發/正式環境，【上線前必須改成 false】
  static const bool isDev = true; // TODO: set false before production build

  // ── 後端 API ──────────────────────────────────────
  /// 本地開發時的後端網址
  /// 10.0.2.2 是 Android 模擬器連到電腦 localhost 的特殊 IP
  static const String apiBaseUrlDev = 'http://10.0.2.2:8000';
  /// 正式環境後端網址（部署到 Render 後填入）
  static const String apiBaseUrlProd = 'https://your-app.onrender.com';

  // ── 官方網站 ──────────────────────────────────────
  /// 官網首頁（App 內顯示「了解更多」時導向這裡）
  static const String websiteUrl = 'https://windmusician.com';
  /// 訂閱頁面（App 內碰到付費功能時導向這裡）
  /// 繞過 Apple/Google 抽成，用戶在網頁付款
  static const String subscriptionUrl = 'https://windmusician.com/pro';
  /// 隱私政策（上架必須提供）
  static const String privacyPolicyUrl = 'https://windmusician.com/privacy';
  /// 服務條款
  static const String termsUrl = 'https://windmusician.com/terms';

  // ── Supabase ──────────────────────────────────────
  /// Supabase 專案網址（建立專案後填入）
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  /// Supabase anon key（公開金鑰，可以放在 App 裡）
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // ── 訂閱 / 金流 ───────────────────────────────────
  /// Stripe 公開金鑰（可以放在 App 裡）
  /// 私密金鑰絕對不能放在 App 裡，只放在後端
  static const String stripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
  /// 免費版每月 AI 分析次數上限
  static const int freeAiAnalysisQuota = 3;
  /// 免費版行程記錄筆數上限
  static const int freeScheduleLimit = 30;

  // ── 支援語言 ──────────────────────────────────────
  /// 目前支援的語系代碼
  /// 新增語言時在這裡加，並新增對應的 .arb 檔案
  static const List<String> supportedLocales = ['zh', 'en', 'ja', 'ko'];

  // ── 目標市場 ──────────────────────────────────────
  /// 各市場的預設貨幣（Stripe 用）
  /// 台灣：TWD，日本：JPY，韓國：KRW，美國：USD
  static const Map<String, String> marketCurrency = {
    'tw': 'TWD',
    'jp': 'JPY',
    'kr': 'KRW',
    'us': 'USD',
  };

  // ── 錄音設定 ──────────────────────────────────────
  /// 最長錄音時間（秒），超過後自動停止並跳出儲存對話框
  static const int maxRecordingSeconds = 900;
  /// 音訊格式
  static const String audioFormat = 'aac';
  /// 免費版錄音只存本地，Pro 版可雲端備份
  /// 雲端備份路徑格式：recordings/{userId}/{recordingId}.aac
  static const String cloudRecordingPath = 'recordings';

  // ── 調音器設定 ────────────────────────────────────
  // Default to 442 Hz (slightly sharp of international standard, common for wind ensembles).
  // Users can adjust from tunerMinPitch (420 Hz) to tunerMaxPitch (460 Hz).
  /// 標準音高基準（Hz），A4 = 442Hz（管樂合奏常用基準）
  static const double standardPitch = 442.0;
  /// 音分誤差容忍範圍，在這範圍內視為準確
  static const double tunerInTuneCents = 10.0;
  /// 支援的調音基準範圍（Hz）
  static const double tunerMinPitch = 420.0;
  static const double tunerMaxPitch = 460.0;

  // ── 節拍器設定 ────────────────────────────────────
  /// 預設 BPM
  static const int metronomeDefaultBpm = 120;
  /// BPM 範圍
  static const int metronomeMinBpm = 20;
  static const int metronomeMaxBpm = 320;

  // ── 樂譜功能（第二版預留）────────────────────────
  /// 支援的樂譜格式
  static const List<String> supportedScoreFormats = ['musicxml', 'mxl'];
  /// 支援的移調樂器清單
  /// Bb 調：單簧管、小號、次中音薩克斯風
  /// Eb 調：中音薩克斯風、上低音薩克斯風
  static const List<String> transposeInstruments = [
    'C', 'Bb', 'Eb', 'F',
  ];

  // ── Score Following（第三版預留）─────────────────
  /// 音訊對齊的取樣率（Hz）
  static const int scoreFollowingSampleRate = 22050;
  /// DTW 視窗大小（影響即時對齊的精確度和延遲）
  static const int dtwWindowSize = 50;

  // ── 社群功能（第三版預留）────────────────────────
  /// 每頁載入的貼文數量
  static const int communityPageSize = 20;
  /// 錄音分享的最長秒數（避免儲存成本過高）
  static const int maxSharedRecordingSeconds = 60;

  // ── 本地儲存 key ──────────────────────────────────
  /// 使用者選擇的語言
  static const String keyLocale = 'locale';
  /// 使用者選擇的音樂家風格
  static const String keySelectedMusician = 'selected_musician';
  /// 調音基準音高
  static const String keyTunerReference = 'tuner_reference';
  /// 節拍器 BPM
  static const String keyMetronomeBpm = 'metronome_bpm';
  /// 色彩主題（AppColorScheme.name）
  static const String keyColorScheme = 'color_scheme';
  /// 亮暗模式（AppBrightness.name）
  static const String keyColorBrightness = 'color_brightness';
  /// 節拍器音色（SINE / WOODBLOCK / STICK_CLICK / SNARE）
  static const String keyMetronomeSoundType = 'metronome_sound_type';
  /// 節拍器音高變體（1~5）
  static const String keyMetronomePitchVariant = 'metronome_pitch_variant';
  /// 側拉選單新手提示是否已顯示過（只顯示一次）
  static const String keyDrawerHintShown = 'drawer_hint_shown';
  /// 是否為 Pro 用戶（從 Supabase 同步過來）
  static const String keyIsPro = 'is_pro';
  /// 本月已使用的 AI 分析次數
  static const String keyAiAnalysisCount = 'ai_analysis_count';
  /// AI 分析次數重置日期
  static const String keyAiAnalysisResetDate = 'ai_analysis_reset_date';

  // ── 分頁設定 ──────────────────────────────────────
  /// 每次載入的行程記錄筆數
  static const int schedulePageSize = 20;
}
