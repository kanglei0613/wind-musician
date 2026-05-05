# Wind Musician — 內部測試發布指南（Firebase App Distribution）

> 版本：v1.0.1+3｜適用平台：iOS  
> Bundle ID：`com.kanglei.wind-musician`  
> 聯絡：kla7522@gmail.com

---

## 一、Build 前置準備

### 1-1. 確認上架檢查清單

在打包之前，逐一確認以下事項：

```
[ ] app_constants.dart 第 12 行：isDev = false
[ ] app_constants.dart 第 34–41 行：填入正式 Supabase URL / Stripe key（或確認未呼叫）
[ ] pubspec.yaml：version = 1.0.1+3（版本號已正確）
[ ] Xcode Signing：選擇正確的 Development Team 與 Provisioning Profile
[ ] Firebase App Distribution：確認 App 已建立於 Firebase Console
```

### 1-2. 切換至正式環境

打開 `lib/shared/constants/app_constants.dart`，將：

```dart
static const bool isDev = true; // TODO: set false before production build
```

改為：

```dart
static const bool isDev = false;
```

> ⚠️ 重要：測試完成後若需繼續開發，記得改回 `true`。

---

## 二、建置 iOS IPA（Firebase App Distribution 用）

### 方式 A：使用 Flutter CLI（推薦）

開啟終端機，進入專案目錄：

```bash
cd ~/Desktop/wind-musician

# 清理舊建置快取
flutter clean

# 取得套件
flutter pub get

# 建置 iOS Archive（無模擬器、使用 release 設定）
flutter build ipa --release \
  --export-method ad-hoc

# IPA 輸出位置：
# build/ios/ipa/wind_musician.ipa
```

> **`--export-method ad-hoc`** 代表要發給 Firebase App Distribution 測試人員使用。  
> 若要上傳至 App Store Connect，改用 `--export-method app-store`。

### 方式 B：使用 Xcode Archive（備用）

1. 在 Xcode 開啟 `ios/Runner.xcworkspace`
2. 確認 Scheme 為 **Runner**，目標裝置為 **Any iOS Device (arm64)**
3. 選單 → **Product → Archive**
4. Archive 完成後在 Organizer 視窗點選 **Distribute App**
5. 選擇 **Ad Hoc** → 下一步 → 選擇 Signing → 匯出 IPA

---

## 三、上傳至 Firebase App Distribution

### 方式 A：使用 Firebase CLI（推薦，可自動化）

```bash
# 安裝 Firebase CLI（如尚未安裝）
npm install -g firebase-tools

# 登入
firebase login

# 上傳 IPA
firebase appdistribution:distribute \
  build/ios/ipa/wind_musician.ipa \
  --app "1:YOUR_FIREBASE_APP_ID:ios:XXXXXXXXXXXXXXXX" \
  --groups "internal-testers" \
  --release-notes "v1.0.1+3 修復項目：
  - 音叉背景繼續發聲問題修復
  - 音叉快速切換八度崩潰保護
  - 術語全名文字截斷顯示
  - 行事曆 Tab 越界保護
  - 調音器預設音高改為標準 440 Hz
  - 螢幕方向鎖定為直向（避免橫屏版型破版）"
```

> 在 [Firebase Console](https://console.firebase.google.com/) → 你的專案 → App Distribution → 點選 App → 「App 設定」可找到 **App ID**。

### 方式 B：Firebase Console 手動上傳

1. 前往 [https://console.firebase.google.com](https://console.firebase.google.com)
2. 選擇專案 → 左側選單 **App Distribution**
3. 點選 iOS App
4. 點選 **「上傳」** 按鈕，拖拉或選取 `wind_musician.ipa`
5. 在 **Release notes** 填入本版更新說明
6. 在 **Testers & Groups** 欄位加入測試人員 Email 或群組
7. 點選 **「Distribute」** 完成發布

---

## 四、測試人員安裝步驟

測試人員在 iPhone 上需依照以下步驟進行安裝：

### 步驟 1：接受邀請

1. 收到 Firebase 寄出的測試邀請 Email
2. 點選 Email 中的 **「Get started」** 連結
3. 若為首次使用，依指示安裝 **Firebase App Tester** App（從 App Store 下載）

### 步驟 2：信任開發者憑證

> 若顯示「未受信任的企業開發者」錯誤，請執行此步驟

1. 開啟 iPhone **設定** App
2. 前往 **一般 → VPN 與裝置管理**
3. 找到開發者名稱（如 `Kanglei...`），點選後選擇 **信任**
4. 確認信任後重新嘗試開啟 App

### 步驟 3：下載並安裝

1. 開啟 **Firebase App Tester** App
2. 找到 **Wind Musician v1.0.1+3**
3. 點選 **「下載」**
4. 下載完成後點選 **「安裝」**
5. 若系統詢問是否信任此 App，選擇 **「信任」**

> 若裝置未加入 Ad Hoc Provisioning Profile 的 UDID 白名單，將無法安裝。請將裝置 UDID 提供給開發者加入 Apple Developer Portal。

---

## 五、結構化測試計畫

請測試人員依照以下項目逐一測試，並在每項測試後記錄是否正常（✅ / ❌ / ⚠️）。

---

### 5-1. 調音器（Tuner）

| # | 測試項目 | 預期結果 | 結果 |
|---|----------|----------|------|
| T1 | 首次啟動拒絕麥克風權限 | 顯示「需要麥克風權限」提示，不崩潰 | |
| T2 | 永久拒絕後再進調音器 | 彈出系統設定頁，引導開啟權限 | |
| T3 | 授權後吹奏任意音 | 音名（如 A4）、Hz 值、音分顯示正確 | |
| T4 | 切換樂器（Bb 單簧管等） | 顯示移調後音名，Hz 值不變 | |
| T5 | 調整 A4 基準（預設 440 Hz） | 預設應為 440 Hz（本版修改），滑桿可調整 | |
| T6 | 切到背景再回到前景 | 調音器自動重啟，無卡頓 | |
| T7 | 吹奏低頻（E2 / 大提琴 C 音等）| 正確辨識，不閃爍 | |

---

### 5-2. 節拍器（Metronome）

| # | 測試項目 | 預期結果 | 結果 |
|---|----------|----------|------|
| M1 | 點播放，觀察拍點燈號 | 強拍（橙色大圓）、弱拍（藍色小圓）正確閃爍 | |
| M2 | 長按 + 鍵後手指滑出 | BPM 停止增加（不再飆升），滑出即停 | |
| M3 | 點 BPM 數字輸入 240 | 正確設定為 240 | |
| M4 | 輸入非數字（如 "abc"）| 顯示提示或保留目前值，不崩潰 | |
| M5 | 播放中切換拍號（如 3/4 → 6/8）| 立即生效，拍點重新同步 | |
| M6 | 開啟段落模式，設定 2 個段落 | 播放自動切換段落，UI 顯示正確 | |
| M7 | 播放中切到背景再回來 | 節拍器已暫停（iOS 背景限制），UI 顯示停止狀態 | |
| M8 | 點選音色（木魚、棒打）| 聲音正確切換 | |

---

### 5-3. 音叉（PitchFork）

| # | 測試項目 | 預期結果 | 結果 |
|---|----------|----------|------|
| P1 | 點按任意音名格 | 發出對應音高，格子顯示高亮 | |
| P2 | 快速連點 + 八度鍵 5 次 | 不崩潰，最終正確停在某個八度 | |
| P3 | 按住 A 後按 Home 鍵 | 音符立即停止（不繼續發聲）（本版修復） | |
| P4 | 從 A 滑到 C | 順暢滑音，A 停止、C 開始 | |
| P5 | 開 Sustain，按多個音 | 所有音持續發聲，再按一次才停 | |
| P6 | 旋轉手勢順時針一圈 | 八度 +1 | |

---

### 5-4. 錄音（Recorder）

| # | 測試項目 | 預期結果 | 結果 |
|---|----------|----------|------|
| R1 | 首次錄音拒絕麥克風 | 顯示提示，不崩潰 | |
| R2 | 授權後點錄音鍵 | 計時器開始，UI 變為停止按鈕 | |
| R3 | 停止錄音 | 彈出儲存對話框，輸入名稱後儲存 | |
| R4 | 儲存對話框留空點儲存 | 顯示錯誤提示（「名稱不能為空」），不關閉 | |
| R5 | 播放已儲存錄音 | 播放進度條正常，時間顯示正確 | |
| R6 | 刪除錄音 | 先顯示確認對話框，確認後刪除 | |
| R7 | 建立資料夾，移動錄音 | 錄音移動到指定資料夾 | |
| R8 | 搜尋錄音名稱 | 即時過濾顯示符合項目 | |

---

### 5-5. 行事曆（Calendar）

| # | 測試項目 | 預期結果 | 結果 |
|---|----------|----------|------|
| C1 | 未登入檢視行事曆 | 顯示「請登入以記錄練習」提示橫幅 | |
| C2 | 登入後新增練習紀錄 | 選擇日期、輸入內容、儲存後出現在行事曆 | |
| C3 | 點選有紀錄的日期 | 底部列出當天練習紀錄 | |
| C4 | 刪除練習紀錄 | 顯示確認對話框，確認後刪除 | |
| C5 | 切換月份至 2027 年 | 正常切換，不報錯 | |

---

### 5-6. 術語查詢（Terminology）

| # | 測試項目 | 預期結果 | 結果 |
|---|----------|----------|------|
| TM1 | 點右下角書本按鈕 | 底部 Sheet 彈出 | |
| TM2 | 搜尋 "ff" | 顯示 Fortissimo 說明 | |
| TM3 | 搜尋長全名術語（如日文） | fullName 顯示省略號，不超出框 | |
| TM4 | 切換 App 語言後搜尋 | 術語說明切換為對應語言 | |
| TM5 | 點選快速鍵（如 `rit.`） | 直接搜尋並顯示結果 | |

---

### 5-7. 登入/登出

| # | 測試項目 | 預期結果 | 結果 |
|---|----------|----------|------|
| L1 | Google 登入 | 成功導向調音器頁面 | |
| L2 | Apple 登入（iOS）| 成功導向調音器頁面 | |
| L3 | Email 登入 | 成功 | |
| L4 | Email 格式錯誤 | 顯示驗證錯誤 | |
| L5 | 忘記密碼 | 重設信件寄出提示 | |
| L6 | 從側拉選單登出 | 回到未登入狀態 | |

---

### 5-8. 全域 UX 測試

| # | 測試項目 | 預期結果 | 結果 |
|---|----------|----------|------|
| G1 | 橫置 iPhone | App 保持直向（本版已鎖定，橫轉不旋轉） | |
| G2 | 在底部導覽切換頁面 5 次 | 無記憶體異常，切換流暢 | |
| G3 | 切換主題顏色（側拉→外觀）| 整個 App 顏色即時更新 | |
| G4 | 切換語言（中→英→日）| UI 文字更新，重啟後保留 | |
| G5 | 斷網後開 App | 不崩潰，Firebase 相關功能顯示適當提示 | |
| G6 | 在 iPhone SE（最小測試）| 所有頁面不出現黃黑條紋溢出 | |

---

## 六、回報問題

測試發現問題時，請透過以下方式回報：

1. **截圖** 或 **螢幕錄影**（設定 → 控制中心 → 螢幕錄製）
2. **描述** 觸發步驟（例：「在行事曆頁點擊某日期後 App 關閉」）
3. **裝置型號** 與 **iOS 版本**（設定 → 一般 → 關於本機）
4. 發送至 **kla7522@gmail.com**，主旨格式：`[Wind Musician Beta] 問題描述`

---

## 七、版本記錄

| 版本 | 日期 | 主要變更 |
|------|------|----------|
| 1.0.1+3 | 2026-05-02 | BC-PF1/PF2 音叉修復、BC-TM3 術語溢出、BC-C2/C3 行事曆修復、BC-T4 預設音高 440Hz、BC-G5 鎖定直向 |
| 1.0.1+2 | 2026-04-26 | BC-001~012 P0/P1 修復（崩潰保護、權限處理、錄音修復） |
| 1.0.0+1 | 初版 | 內部開發版 |
