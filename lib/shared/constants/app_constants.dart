library;
/// App 全域常數
/// 所有寫死的數值、字串都集中在這裡
/// 要換後端網址或調整參數，只需要改這個檔案，不用到處找

class AppConstants {
  // 禁止直接實例化這個 class
  AppConstants._();

  // ── 後端 API ──────────────────────────────────────
  /// 本地開發時的後端網址（FastAPI）
  static const String apiBaseUrlDev = 'http://10.0.2.2:8000';
  /// 正式環境的後端網址（之後部署到 Render 後填入）
  static const String apiBaseUrlProd = 'https://your-app.onrender.com';

  // ── 錄音設定 ──────────────────────────────────────
  /// 最長錄音時間（秒）
  static const int maxRecordingSeconds = 300; // 5 分鐘
  /// 支援的音訊格式
  static const String audioFormat = 'aac';

  // ── 調音器設定 ────────────────────────────────────
  /// 標準音高基準（Hz），A4 = 440Hz
  static const double standardPitch = 440.0;
  /// 音分誤差容忍範圍，在這範圍內視為準確
  static const double tunerInTuneCents = 10.0;

  // ── 本地儲存 key ──────────────────────────────────
  /// 使用者選擇的音樂家風格
  static const String keySelectedMusician = 'selected_musician';
  /// 使用者偏好的調音基準音高
  static const String keyTunerReference = 'tuner_reference';

  // ── 分頁設定 ──────────────────────────────────────
  /// 每次載入的行程記錄筆數
  static const int schedulePageSize = 20;
}
