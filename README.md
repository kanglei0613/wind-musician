# 🎺 管樂手帳（Wind Musician）

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-159%20passing-brightgreen)]()

> 針對管樂演奏者設計的全方位練習工具 App，支援 Android 與 iOS。

---

## 簡介

**管樂手帳（Wind Musician）** 是一款專為業餘、半職業管樂手、樂隊成員與音樂學生打造的練習輔助工具。整合調音器、節拍器、錄音、練習日誌等核心功能，讓每次練習更有效率、更有記錄。

- **目標用戶**：業餘 / 半職業管樂手、管樂隊成員、音樂學生
- **平台**：Android（已上線）、iOS（開發中）
- **語言**：繁體中文 / English / 日本語 / 한국어

---

## 功能列表

### ✅ 已完成功能

| 功能 | 說明 |
|------|------|
| 🎵 **調音器** | 即時音高偵測、移調模式（Bb / Eb / F / C）、基準音高調整（A = 420–460 Hz）、Sustain 持續音模式 |
| 🥁 **節拍器** | BPM 20–320、強拍提示音、多拍型、Android 前景服務背景持續播放（MetronomeService） |
| 🔔 **音叉** | 標準音高參考，支援多種調音基準 |
| 🎙 **錄音** | 高品質錄音與播放、資料夾分類管理、重新命名 / 刪除 / 匯出分享、搜尋功能 |
| 📅 **練習日誌 / 行程** | 個人練習紀錄、依日期瀏覽練習時長與內容、樂團群組行事曆（登入後） |
| 📖 **音樂術語查詢** | 本地離線資料庫、多語系術語解釋 |
| 🎼 **音樂家風格** | 演奏風格與技法參考 |
| 📗 **使用說明** | 內建 App 操作指南 |
| 🌐 **多語系** | 繁體中文 / English / 日本語 / 한국어（flutter_gen-l10n ARB） |

### 🚧 開發中功能

- **AI 演奏分析**：練習數據分析與 AI 建議
- **社群**：好友動態、排行榜、樂團活動
- **樂譜顯示**：內建樂譜瀏覽器
- **Score Following**：自動跟譜系統

---

## 技術架構

### 框架與語言

- **Flutter 3.x / Dart 3.x**（SDK constraint: `^3.11.4`）

### 主要套件

| 類別 | 套件 / 版本 |
|------|------------|
| 狀態管理 | `flutter_riverpod ^2.6.1` |
| 路由 | `go_router ^14.0.0` |
| 後端 | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_crashlytics` |
| 登入 | `google_sign_in`, `sign_in_with_apple` |
| 音訊 | `pitch_detector_dart`, `record`, `just_audio`, `flutter_soloud` |
| 圖表 | `fl_chart` |
| 行事曆 | `table_calendar` |
| 多語系 | `flutter_localizations`, `intl ^0.20.2` |

### Android 原生（Platform Channel）

| 元件 | 說明 |
|------|------|
| `MetronomeService` | 前景服務，確保背景持續播放節拍 |
| `MetronomeEngine` | 使用 `AudioTrack` 精確音訊合成 |
| `AudioFocusHandler` | 音訊焦點管理，避免與其他 App 衝突 |
| `NotificationHelper` | 前景服務通知管理 |

---

## 本地開發設定

### 前置需求

- Flutter SDK `^3.11.4`（建議使用 FVM 管理版本）
- Dart SDK `^3.11.4`
- Firebase 設定檔：
  - Android：`android/app/google-services.json`
  - iOS：`ios/Runner/GoogleService-Info.plist`

> ⚠️ Firebase 設定檔不含於版本控制，請自行從 Firebase Console 下載。

### 執行步驟

```bash
# 1. 安裝相依套件
flutter pub get

# 2. 啟動 App（debug 模式）
flutter run

# 3. 指定平台
flutter run -d android
flutter run -d ios
```

### 簽名設定（Release 打包）

Release 打包需要簽名金鑰，相關檔案不含於版本控制：

- `android/key.properties`：簽名設定
- `android/app/*.jks`：Keystore 檔案

請參考 `setup_keystore.py` 進行本地設定。

---

## 測試

```bash
# 靜態分析（應無 error）
flutter analyze

# 執行所有測試（159 個，全數通過）
flutter test
```

### 測試涵蓋範圍

| 測試檔案 | 說明 | 數量 |
|---------|------|------|
| `test/features/metronome/metronome_boundary_test.dart` | 節拍器邊界條件 | 33 |
| `test/features/metronome/metronome_test.dart` | 節拍器核心邏輯 | — |
| `test/features/recorder/recorder_notifier_test.dart` | 錄音狀態管理 | — |
| `test/features/tuner/tuner_notifier_test.dart` | 調音器狀態管理 | — |
| `test/shared/services/native_channel_test.dart` | Platform Channel | 31 |

---

## 發布（測試版分發）

使用 Firebase App Distribution 進行測試版分發：

```powershell
.\distribute.ps1 -ReleaseNote "更新說明"
```

此腳本會自動執行：
1. `flutter build apk --release`（簽名打包）
2. 上傳至 Firebase App Distribution
3. 通知測試人員

> 詳細安裝步驟請參考 [測試版安裝指南](測試版安裝指南.md)。

---

## 專案結構

```
lib/
├── features/
│   ├── tuner/          # 調音器
│   ├── metronome/      # 節拍器
│   ├── recorder/       # 錄音
│   ├── practice/       # 練習日誌
│   ├── terminology/    # 音樂術語
│   └── auth/           # 登入 / 認證
├── shared/
│   ├── services/       # 共用服務（native channel 等）
│   └── widgets/        # 共用元件
└── l10n/               # 多語系 ARB 檔案
    ├── app_zh.arb      # 繁體中文（範本）
    ├── app_en.arb      # English
    ├── app_ja.arb      # 日本語
    └── app_ko.arb      # 한국어
```

---

## 版本紀錄

- **1.0.0+1** — Internal Beta（開發中）

---

## License

本專案採用 [MIT License](LICENSE)。
