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
