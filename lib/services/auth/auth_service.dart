library;

/// Supabase 認證服務（預留）
/// 目前為骨架，P2 階段整合 Supabase 後實作
///
/// 規劃功能：
/// - 電子郵件註冊 / 登入
/// - Google 登入（第二版）
/// - Apple 登入（iOS 上架前必須支援）
/// - 登出
/// - 取得目前登入用戶
/// - 監聽登入狀態變化
/// - 同步 is_pro 狀態（從 Supabase 用戶表讀取）

class AuthService {
  // TODO: 初始化 Supabase client
  // final _supabase = Supabase.instance.client;

  /// 取得目前登入用戶 ID
  /// 未登入回傳 null
  String? get currentUserId => null; // TODO: 實作

  /// 是否已登入
  bool get isLoggedIn => currentUserId != null;

  /// 電子郵件登入
  Future<void> signInWithEmail(String email, String password) async {
    // TODO: 實作
    throw UnimplementedError();
  }

  /// 電子郵件註冊
  Future<void> signUpWithEmail(String email, String password) async {
    // TODO: 實作
    throw UnimplementedError();
  }

  /// 登出
  Future<void> signOut() async {
    // TODO: 實作
    throw UnimplementedError();
  }

  /// 取得用戶的 Pro 狀態
  /// 從 Supabase users 表的 is_pro 欄位讀取
  Future<bool> getIsProStatus() async {
    // TODO: 實作
    return false;
  }
}