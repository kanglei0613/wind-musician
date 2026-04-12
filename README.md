# 🎺 Wind Musician

管樂人專屬練習工具 App，支援 Android（iOS 開發中）。

## 功能

### 🎵 調音器
- 即時音高偵測
- 移調模式（Bb / Eb / F / C）
- 基準音高調整（A = 430–450 Hz）
- 節拍器（BPM 20–320，強拍提示）
- Sustain 持續音模式

### 🎙 錄音
- 錄音與播放
- 資料夾分類管理
- 重新命名、刪除、匯出／分享
- 搜尋功能

### 📅 行事曆
- 個人練習紀錄
- 依日期瀏覽練習時長與內容
- 登入後可使用樂團群組功能

### 👥 社群（開發中）
- 好友動態
- 排行榜
- 樂團活動

### 📊 分析（開發中）
- 練習數據分析
- AI 建議

## 多語言

支援 繁體中文 / English / 日本語 / 한국어

## 技術架構

| 類別 | 套件 |
|------|------|
| 框架 | Flutter 3.x |
| 狀態管理 | flutter_riverpod |
| 路由 | go_router |
| 後端 | Firebase（Auth、Firestore、Crashlytics）|
| 登入 | Google Sign-In、Sign in with Apple |
| 音訊 | pitch_detector_dart、record、just_audio、flutter_soloud |
| 圖表 | fl_chart |
| 行事曆 | table_calendar |
| 多語言 | flutter_localizations、intl |

## 開發環境

```bash
flutter pub get
flutter run
```

### Release 打包

```bash
# Android App Bundle（Play Store）
flutter build appbundle --release

# Android APK（側載測試）
flutter build apk --release
```

> Release 打包需要 `android/key.properties` 與 `android/upload-keystore.jks`，不含於版本控制。

## 支援語言

- `lib/l10n/app_zh.arb` — 繁體中文（範本）
- `lib/l10n/app_en.arb` — English
- `lib/l10n/app_ja.arb` — 日本語
- `lib/l10n/app_ko.arb` — 한국어

## 版本

`1.0.0+1` — 開發中 / Internal Beta
