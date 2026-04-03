library;

/// Stripe 金流服務（預留）
/// 目前為骨架，第二版實作
///
/// 規劃功能：
/// - 建立訂閱 Checkout Session（導向網頁付款）
/// - 驗證訂閱狀態
/// - 取消訂閱
/// - Webhook 處理（後端接收 Stripe 通知）
///
/// 收費策略：
/// - 繞過 Apple/Google 抽成，用戶在官網付款
/// - 官網用 Stripe 處理金流（手續費約 2.9%）
/// - 付款完成後 Stripe Webhook 通知後端
/// - 後端更新 Supabase 用戶的 is_pro = true
/// - App 登入後自動同步 Pro 狀態
///
/// 定價：
/// - 台灣：NT$99/月，NT$799/年
/// - 日本：¥480/月，¥3,800/年
/// - 韓國：₩4,500/月，₩36,000/年
/// - 美國：$3.99/月，$29.99/年

class PaymentService {
  /// 開啟官網訂閱頁面
  /// App 內不放價格和付款按鈕，避免違反 Apple 規定
  Future<void> openSubscriptionPage() async {
    // TODO: 用 url_launcher 開啟 AppConstants.subscriptionUrl
    throw UnimplementedError();
  }

  /// 從 Supabase 同步最新的 Pro 狀態
  /// 用戶在網頁完成付款後，打開 App 呼叫這個方法更新狀態
  Future<bool> syncProStatus() async {
    // TODO: 呼叫後端 API 確認訂閱狀態
    return false;
  }
}
