# 🎺 管樂手帳（Wind Musician）

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![Version](https://img.shields.io/badge/Version-1.0.1%2B2-blue)]()

> 專為管樂演奏者設計的全方位練習工具，支援 Android 與 iOS。

---

## 簡介

**管樂手帳（Wind Musician）** 是一款針對業餘、半職業管樂手、樂隊成員與音樂學生打造的練習輔助工具。整合調音器、節拍器、音叉、錄音、練習行事曆等核心功能，讓每次練習更有效率、更有記錄。

- **目標用戶**：業餘 / 半職業管樂手、管樂隊成員、音樂學生
- **平台**：Android（Firebase App Distribution 測試中）、iOS（Apple Developer 審核中）
- **語言**：繁體中文 / English / 日本語 / 한국어

---

## 功能概覽

### 已上線功能

**🎵 調音器**
即時音高偵測（麥克風輸入），支援 12 種管樂器移調（Bb / Eb / F / C），基準音高可調整（A4 = 400–480 Hz）。顯示音名、分音差（cents）及準確/偏高/偏低狀態。

**🥁 節拍器**（整合於調音器頁面）
BPM 20–320，多拍型拍號（分子 1–12 / 分母 1–32），強拍提示音，段落練習模式。Android 與 iOS 使用原生 Platform Channel 確保精準節拍：
- Android：`MetronomeService`（前景服務）+ `MetronomeEngine`（AudioTrack 合成）
- iOS：`MetronomeEngine.swift`（AVAudioEngine + mach hostTime 精準排程）

**🎹 音叉（PitchFork）**
六角蜂巢排列 12 音鍵盤，支援 Sustain 持續音模式（長按保持），旋轉手勢切換八度。

**🎙️ 錄音**
高品質錄音與播放，資料夾分類管理，重新命名 / 刪除 / 匯出分享，最長 15 分鐘，支援搜尋。

**📅 行事曆**
個人練習日誌，依日期紀錄練習時長與內容，月曆圓點標記，登入後可存取樂團群組行程。

**📖 音樂術語查詢**
本地離線資料庫，多語系術語解釋，快速標籤一鍵查詢常用術語。

**🐛 問題回報**
App 內一鍵開啟郵件 App，自動帶入版本號與平台資訊，引導使用者描述問題。

**👤 帳號**
Google 登入 / Apple 登入 / Email 帳號，Firebase Auth。

---

### 開發中功能

| 功能 | 狀態 |
|------|------|
| AI 演奏分析 | 架構建立，串接中 |
| 行程規劃 | 頁面架構建立，功能開發中 |
| 社群（好友動態、排行榜） | 規劃中 |
| 樂譜瀏覽 / Score Following | 第二版實作 |

---

## 未來規劃與技術設計

### AI 演奏分析

**功能目標**：用戶錄音後，系統自動分析音準準確率、節拍穩定度、力度曲線，並生成自然語言的練習建議。

**為什麼需要獨立後端**：音訊分析涉及 `librosa`、`numpy` 等 Python 生態的運算，且單次分析可能耗時 10–30 秒，Firebase Cloud Functions 有 9 分鐘 timeout 與 512MB 記憶體限制，且 Python runtime cold start 體驗差，不適合作為分析主體。因此採用獨立的 Python microservice。

**技術選型**：
- `FastAPI`：輕量 async API framework，接收分析請求
- `Celery + Redis`：任務佇列，避免 HTTP request 長時間等待；FastAPI 收到請求後立即回傳 `jobId`，Celery worker 在背景執行分析
- `librosa`：音高偵測統計、onset detection（節拍誤差）、RMS energy（力度曲線）
- `OpenAI API`：將量化數據轉換為自然語言的練習建議
- 部署於 Railway / Fly.io，Firebase Storage 存音檔，分析結果寫回 Firestore

**完整流程**：

```
App 錄音完成
  → 上傳至 Firebase Storage
  → 呼叫 FastAPI（送 storage path）
  → FastAPI 回傳 jobId，Celery worker 非同步處理
    → 下載音檔 → librosa 分析 → 呼叫 OpenAI 生成建議
    → 結果寫回 Firestore（該用戶的 analysisResults collection）
  → App real-time stream 收到更新，顯示分析報告
```

**分析指標說明**：
- 音準準確率：對每幀偵測到的音高與目標音高比對，統計 ±20 cents 內的比例
- 節拍穩定度：onset detection 算出每拍實際時間點，與 BPM 理想值的標準差
- 力度曲線：RMS energy 的時間序列，可視化練習段落的強弱變化

---

### 行程規劃

**功能目標**：個人練習排程設定（含提醒）、樂團成員共用行程（如排練、演出日期）。

**技術設計**：
- 個人行程與樂團行程分別存於 Firestore `schedules` 和 `ensembleEvents` collections，已有資料模型基礎
- 提醒功能透過 Firebase Cloud Messaging（FCM）發送推播，後端觸發點可使用 Cloud Functions scheduled trigger（Firestore 文件到期前 X 小時觸發）
- 不需要自架 server，全部在 Firebase 生態內完成

---

### 社群功能（好友動態、排行榜）

**功能目標**：好友練習動態 feed、每月練習時長排行榜。

**技術設計**：
- 好友關係存於 Firestore `friendships` collection，雙向關係以 `status: pending / accepted` 管理
- 動態 feed 採 Fanout-on-write：用戶新增練習紀錄時，同時寫入所有好友的 `feed` sub-collection，讓每個用戶的 feed 查詢只需讀自己的文件，不需要 join
- 排行榜以 Firestore 聚合查詢（`orderBy('monthlyMinutes').limit(50)`）實作，月初透過 Cloud Functions scheduled trigger 重置計數
- 此功能純 Firebase 即可實現，不需要額外後端

**取捨考量**：Fanout-on-write 在好友數量極大時（1000+）寫入成本高，但管樂社群屬於小圈子產品，預期好友數在數十人以內，此策略合理。

---

### 樂譜瀏覽 / Score Following

**功能目標**：
- 短期：PDF 樂譜上傳、分頁瀏覽、自動翻頁
- 長期：演奏時即時追蹤樂譜位置（Score Following）

**技術設計（短期）**：
- 樂譜 PDF 存於 Firebase Storage，metadata（曲名、樂器、難度）存 Firestore
- App 端使用 `pdfx` 套件渲染，自動翻頁依節拍器 BPM 與小節數計算觸發時機
- 純 Firebase，不需要後端

**技術設計（長期 Score Following）**：
- 真正的 Score Following 需要即時比對演奏音訊與樂譜的時間軸，核心演算法為 DTW（Dynamic Time Warping）或 HMM
- 計算量遠超 on-device 能力，需要後端串流處理（WebSocket 或 chunked HTTP）
- 此功能複雜度高，列為長期研究方向，目前優先實作短期的靜態翻頁版本

---

## 技術架構

### 框架與語言

- **Flutter 3.x / Dart 3.x**
- 狀態管理：`flutter_riverpod ^2.6.1`
- 路由：`go_router ^14.0.0`
- 多語系：`flutter_localizations` + ARB（app_zh / en / ja / ko）

### 後端與服務

| 套件 | 用途 |
|------|------|
| `firebase_core` / `firebase_auth` | 認證 |
| `cloud_firestore` | 雲端資料同步 |
| `firebase_crashlytics` | 崩潰回報 |
| `google_sign_in` / `sign_in_with_apple` | 社交登入 |

### 音訊

| 套件 | 用途 |
|------|------|
| `pitch_detector_dart` | 即時音高偵測 |
| `record` | 錄音 |
| `just_audio` | 錄音播放 |
| `flutter_soloud` | 桌面 / 備援音訊引擎 |

### Android 原生（Platform Channel）

| 元件 | 說明 |
|------|------|
| `MetronomeService` | 前景服務，確保背景持續播放 |
| `MetronomeEngine` | `AudioTrack` 精確音訊合成 |
| `AudioFocusHandler` | 音訊焦點管理 |
| `NotificationHelper` | 前景服務通知 |

### iOS 原生（Platform Channel）

| 元件 | 說明 |
|------|------|
| `MetronomeEngine.swift` | AVAudioEngine + mach hostTime 精準排程 |
| `MetronomePlugin.swift` | Flutter MethodChannel bridge |

---

## 後端架構設計

### 為什麼選擇 Firebase BaaS

本專案刻意選擇 Firebase 作為後端，而非自架 API Server，原因是這個規模的個人工具 App 不需要承擔伺服器維運成本。Firebase 提供的 Auth、Firestore、Storage、Crashlytics 已覆蓋所有現有需求，開發速度更快，且可以讓精力集中在 App 本身的體驗上。

這是一個明確的架構取捨，而非技術能力的限制。當功能擴展到需要自訂運算邏輯（如 AI 分析）時，會在 Firebase 外側追加獨立的後端服務。

### 身份驗證設計

支援三種登入方式：Google、Apple Sign-In、Email/Password。

Apple Sign-In 並非選配功能——App Store 審查規範 4.8 明確要求，只要 App 提供任何第三方社交登入，就必須同時提供 Apple Sign-In。

登入後透過 `AuthService._upsertUser` 在 Firestore `users` collection 管理使用者文件：首次登入建立文件，之後只更新 `lastActiveAt`，避免覆蓋用戶自訂資料。

### 資料存取模式

Firestore 的查詢依使用情境分兩種模式：

**一次性 fetch**（`getEntriesForMonth`）：用於初始載入，取得特定月份資料後不再訂閱，降低 Firestore 讀取計費。

**Real-time stream**（`watchEntriesForMonth`）：用於需要即時反映的 UI（例如行事曆），透過 Riverpod `StreamProvider` 直接驅動畫面更新。

### 離線設計

練習紀錄同時寫入 Firestore 與本機 JSON 檔案（`practice_entries.json`）。Firestore 離線或連線不穩時自動 fallback 到本機資料，用戶不會看到空白畫面或錯誤提示。

Firestore Stream 的 `FirebaseException` 以 `handleError` 靜默攔截，保留最後一次成功的資料繼續顯示，連線恢復後 provider 自動重建重新訂閱。

---

## 本地開發設定

### 前置需求

- Flutter SDK `^3.x`（建議使用 FVM 管理版本）
- Firebase 設定檔（**不含於版本控制**，請自行從 Firebase Console 下載）：
  - Android：`android/app/google-services.json`
  - iOS：`ios/Runner/GoogleService-Info.plist`

### 執行步驟

```bash
# 安裝相依套件
flutter pub get

# 啟動 App（debug 模式）
flutter run -d android
flutter run -d ios
```

### Android Release 打包

Release 打包需要簽名金鑰（**不含於版本控制**）：

- `android/key.properties`
- `android/app/wind_musician.jks`

### 發布測試版（Firebase App Distribution）

```powershell
.\distribute.ps1 -ReleaseNote "更新說明"
```

腳本自動執行：`flutter build apk --release` → 上傳 Firebase → 通知測試人員。

---

## 靜態分析與測試

```bash
# 靜態分析（應無 error）
flutter analyze

# 執行測試
flutter test
```

### 測試涵蓋範圍

| 測試檔案 | 說明 |
|---------|------|
| `test/features/metronome/metronome_boundary_test.dart` | 節拍器邊界條件 |
| `test/features/metronome/metronome_test.dart` | 節拍器核心邏輯 |
| `test/features/recorder/recorder_notifier_test.dart` | 錄音狀態管理 |
| `test/features/tuner/tuner_notifier_test.dart` | 調音器狀態管理 |
| `test/shared/services/native_channel_test.dart` | Platform Channel |

---

## 專案結構

```
lib/
├── features/
│   ├── tuner/          # 調音器（含節拍器、音叉）
│   ├── recorder/       # 錄音
│   ├── calendar/       # 行事曆 / 練習日誌
│   ├── terminology/    # 音樂術語
│   ├── guide/          # 使用說明
│   └── auth/           # 登入 / 認證
├── shared/
│   ├── services/       # 共用服務（Platform Channel 等）
│   ├── theme/          # 主題 / 色彩
│   └── widgets/        # 共用元件（AppDrawer 等）
└── l10n/               # 多語系 ARB
    ├── app_zh.arb      # 繁體中文（範本）
    ├── app_en.arb
    ├── app_ja.arb
    └── app_ko.arb
```

---

## 版本紀錄

### v1.0.1+2（目前版本）
- 問題回報功能（寄信，含版本自動偵測、完整錯誤處理）
- 麥克風權限流程修復（iOS 系統對話框 → 使用者主動前往設定）
- Sustain 按鈕手勢衝突修復
- UI 溢位修復、切換拍號自動回第一拍
- iOS 原生節拍器（AVAudioEngine）

### v1.0.0+1
- 初始版本，核心功能上線

---

## License

本專案採用 [MIT License](LICENSE)。
