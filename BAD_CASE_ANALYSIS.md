# Wind Musician — Bad Case Analysis

> 版本：2026-04-25｜分析範圍：Android + iOS 雙平台上架

嚴重度：**P0** Crash／上架被拒 → **P1** 功能失效 → **P2** UX 明顯劣化 → **P3** 輕微瑕疵

---

## 1. 調音器（Tuner）

### BC-T1｜麥克風永久拒絕未處理 `P1`
- 📍 `tuner_provider.dart:65-71` `startListening()`
- 🐛 只判斷 `isGranted`，`isPermanentlyDenied` 時顯示同樣錯誤文字且無引導。
- 🔄 安裝後拒絕兩次 → 永久拒絕 → 開調音器，錯誤訊息無法解決問題。
- 💥 調音器完全無法使用，用戶無從解決。
- 🔧 `isPermanentlyDenied` 時顯示不同訊息並呼叫 `openAppSettings()`。

### BC-T2｜Audio stream 無 onError handler `P1`
- 📍 `tuner_provider.dart:91` `_audioSubscription = audioSampleBufferedStream.listen(...)`
- 🐛 stream 出錯時 subscription 靜默中斷，UI 仍顯示「聆聽中」。
- 🔄 錄音中接電話，回到 App 後調音器卡住。
- 💥 功能失效，需殺 App 重開。
- 🔧 加入 `onError` handler，設定 `isListening: false` 並顯示錯誤。

### BC-T3｜dispose 用 Future.microtask 有競態風險 `P3`
- 📍 `tuner_page.dart:32-38` `dispose()`
- 🐛 非同步 stop，頁面快速 dispose 又重建時可能雙重啟動 recorder。
- 🔧 改為在 `TunerNotifier.dispose()` 中同步取消 subscription。

### BC-T4｜標準音高預設 442 Hz `P3`
- 📍 `app_constants.dart:73`
- 🐛 業界初始值慣用 440 Hz，442 是進階設定，直接預設讓新手困惑。
- 🔧 改為 440，讓用戶自行調整。

---

## 2. 節拍器（Metronome）

### BC-M1｜長按 +/− 手指滑出 Timer 不停 `P1`
- 📍 `metronome.dart` `_PressButton` GestureDetector
- 🐛 缺少 `onLongPressCancel`，手指滑出按鈕區域時 `_longPressTimer` 永久運行。
- 🔄 長按 + 後把手指滑走，BPM 持續飆升到 320 無法停止。
- 💥 BPM 卡在最大值，UX 嚴重劣化。
- 🔧 加入 `onLongPressCancel: onLongPressEnd`。

### BC-M2｜BPM 手動輸入非數字無提示 `P3`
- 📍 `metronome.dart:157-160`
- 🐛 輸入 "abc" 按確認，`int.tryParse` 返回 null，對話框關閉且無任何提示。
- 🔧 `bpm == null` 時顯示 snackbar 或 errorText。

### BC-M3｜分母允許非音樂拍號值 `P3`
- 📍 `metronome.dart:647`
- 🐛 分母可設 3、5、6、7 等無意義值。
- 🔧 限制為 `[1, 2, 4, 8, 16, 32]`。

### BC-M4｜iOS 背景執行節拍繼續但靜音 `P2`
- 📍 `ios/Runner/Info.plist` 缺少 `UIBackgroundModes: audio`
- 🐛 App 切背景後 Timer 跑但 SoLoud 無聲，回前台時拍點亂。
- 🔧 短期：進入背景時自動暫停節拍器（監聽 AppLifecycleState）。

---

## 3. 音叉（PitchFork）

### BC-PF1｜切換八度有競態條件 `P2`
- 📍 `pitch_fork.dart:108-126` `_changeOctave()`
- 🐛 async 操作無 guard，快速連點多次 `_loadAllNotes()` 同時執行，`_sources` 被並行清除和寫入。
- 🔄 快速連點 + 按鈕 5 次，音符無聲或 SoLoud crash。
- 💥 音符無法播放。
- 🔧 加入 `_isChangingOctave` flag，載入中禁用 +/− 按鈕。

### BC-PF2｜App 背景時音符持續發聲 `P2`
- 📍 `pitch_fork.dart` 缺少 AppLifecycleState 監聽
- 🐛 按下音符後接電話，looping 音符持續播放。
- 🔧 實作 `WidgetsBindingObserver`，`paused` 時停所有 active handles。

### BC-PF3｜多點觸控同音符兩指不對稱 `P3`
- 📍 `pitch_fork.dart:347`
- 🐛 兩根手指按同音符，任一根離開即停音。
- 🔧 追蹤 pointer ID，全部離開才停音。

---

## 4. 術語查詢（Terminology）

### BC-TM1｜搜尋語言寫死 `'en'` `P1`
- 📍 `terminology_page.dart:91`
- 🐛 無論 App 設定何種語言，永遠查英文術語資料庫。
- 🔧 改為 `Localizations.localeOf(context).languageCode`。

### BC-TM2｜快速連點搜尋可重複觸發 `P3`
- 📍 `terminology_page.dart:181-199`
- 🐛 `_isLoading` 時 GestureDetector 未禁用，可觸發多次搜尋。
- 🔧 `_isLoading` 時 `onTap: null`。

### BC-TM3｜搜尋結果 fullName 無 overflow 處理 `P3`
- 📍 `terminology_page.dart:279`
- 🐛 fullName 過長時 Row overflow RenderFlex。
- 🔧 用 `Flexible` + `overflow: TextOverflow.ellipsis` 包裹。

---

## 5. 錄音（Recorder）

### BC-R1｜startRecording 無麥克風權限檢查 `P1`
- 📍 `recorder_provider.dart:161`
- 🐛 直接 `_recorder.start()`，Android 13+ 未授權 → PlatformException crash。
- 🔄 首次安裝 → 拒絕權限 → 點錄音 → crash 或無響應。
- 💥 Crash。
- 🔧 仿照 TunerNotifier 加入 `Permission.microphone.request()` 檢查。

### BC-R2｜RecorderNotifier & AudioPlayerNotifier dispose 未被 Riverpod 呼叫 `P0`
- 📍 `recorder_provider.dart:243, 291`
- 🐛 `void dispose()` 不是 `@override`，Riverpod 永遠不呼叫，AudioRecorder / AudioPlayer 永遠不釋放。
- 💥 記憶體洩漏，長時間使用後 iOS 可能被系統終止。
- 🔧 改用 `ref.onDispose(() { ... })` 在 `build()` 中註冊清理。

### BC-R3｜playerStateStream listener 累積洩漏 `P0`
- 📍 `recorder_provider.dart:272-276`
- 🐛 每次 `play()` 都新增 listener 但未儲存、未取消，播放 N 次有 N 個 listener 同時觸發。
- 💥 記憶體洩漏，最終多次 `state = null` 競態。
- 🔧 用 `StreamSubscription? _stateSubscription` 儲存，每次 `play()` 先 `cancel()`。

### BC-R4｜RecordingRepository.delete firstWhere 會 throw `P0`
- 📍 `recording_repository.dart:97`
- 🐛 `all.firstWhere((r) => r.id == id)` 若 id 不存在拋出 `StateError`。
- 🔄 metadata 與實際檔案不同步時（外部刪檔）即觸發。
- 💥 Crash，整個錄音清單失效。
- 🔧 改用 `firstWhereOrNull` + null guard。

### BC-R5｜錄音中可播放，iOS AVAudioSession 衝突 `P2`
- 📍 `recorder_controls.dart` + `recording_item.dart`
- 🐛 錄音進行中仍可點播放，iOS AVAudioSession category 衝突。
- 🔧 `recorderProvider.status == recording` 時禁用播放按鈕。

### BC-R6｜SaveDialog 空名稱靜默失敗 `P2`
- 📍 `save_dialog.dart:128-135`
- 🐛 名稱為空按「儲存」，直接 return，對話框不關也不報錯。
- 💥 UX 差，用戶不知道為何無反應。
- 🔧 加入 `_showError` 狀態，顯示 TextField errorText。

### BC-R7｜錄音未強制 300 秒停止 `P2`
- 📍 `app_constants.dart:64` + `recorder_provider.dart`
- 🐛 `maxRecordingSeconds = 300` 但 `_tick()` 超過後不自動停止，可產生超大檔案。
- 🔧 在 `_tick()` 加入 `>= maxRecordingSeconds` 判斷自動停止。

### BC-R8｜metadata 讀寫競態 `P2`
- 📍 `recording_repository.dart` loadAll → modify → saveAll 非原子操作
- 🐛 同時發起 add + moveToFolder，後者 loadAll 讀到未含前者的舊資料並覆蓋。
- 🔧 加入 `package:synchronized` Mutex 序列化所有 write 操作。

---

## 6. 行事曆（Calendar）

### BC-C1｜練習紀錄刪除無確認 `P2`
- 📍 `calendar_page.dart:397`
- 🐛 選「刪除」直接執行 `deleteEntry()`，無確認對話框，操作不可逆。
- 🔧 加入 AlertDialog 確認步驟。

### BC-C2｜tab int 索引越界 `P2`
- 📍 `calendar_page.dart:140-151`
- 🐛 選了樂團 tab 後退出樂團，`ensembles.length` 縮短，tab 值指向不存在的樂團。
- 🔧 `userEnsemblesProvider` 更新時若 tab >= 2 重置為 0。

### BC-C3｜Calendar lastDay 硬編碼到 2030 `P3`
- 📍 `calendar_page.dart:158-159`
- 🐛 2030 年後無法使用行事曆。
- 🔧 `lastDay: DateTime.now().add(const Duration(days: 365 * 5))`。

---

## 7. 全域 / 平台

### BC-G1｜iOS NSMicrophoneUsageDescription 缺失 `P0`
- 📍 `ios/Runner/Info.plist`
- 🐛 iOS App Store 審核強制要求，缺失直接**上架被拒**。
- 🔧 加入各語言版本的麥克風使用說明。

### BC-G2｜AppConstants.isDev = true `P1`
- 📍 `app_constants.dart:14`
- 🐛 上架若忘記改成 false，所有 API 請求連到開發環境。
- 🔧 加入上架 checklist；或用 dart-define 在 CI 控制。

### BC-G3｜Supabase / Stripe 佔位符未填入 `P1`
- 📍 `app_constants.dart:35, 41`
- 🐛 `'YOUR_SUPABASE_URL'` 若被呼叫直接失敗。
- 🔧 上架前填入正式值，或在呼叫端加 guard。

### BC-G4｜語言設定不持久化 `P2`
- 📍 `app.dart:12` `localeProvider`
- 🐛 冷啟動後語言重置為中文。
- 🔧 初始化時讀 SharedPreferences，切換時同步寫入。

### BC-G5｜橫屏支援但 UI 未適配 `P2`
- 📍 `ios/Runner/Info.plist` 支援 Landscape
- 🐛 調音器、PitchFork 在橫屏下嚴重壓縮甚至無法點擊。
- 🔧 短期：鎖定 Portrait（移除 Info.plist Landscape 選項）。

### BC-G6｜播放中切到調音器 AVAudioSession 衝突 `P2`
- 📍 `recorder_provider.dart` + `tuner_provider.dart`
- 🐛 播放錄音後切到調音器，兩者同時搶 AVAudioSession。
- 🔧 `TunerNotifier.startListening()` 前先呼叫 `audioPlayerProvider.notifier.stop()`。

---

## 修復優先序總表

| 編號 | 嚴重度 | 狀態 |
|------|--------|------|
| BC-G1 — NSMicrophoneUsageDescription | P0 | ✅ 已修復 |
| BC-R4 — firstWhere crash | P0 | ✅ 已修復 |
| BC-R2 — Notifier dispose 洩漏 | P0 | ✅ 已修復 |
| BC-R3 — playerStateStream 洩漏 | P0 | ✅ 已修復 |
| BC-T1 — permanentlyDenied | P1 | ✅ 已修復 |
| BC-T2 — stream onError | P1 | ✅ 已修復 |
| BC-R1 — startRecording 無權限 | P1 | ✅ 已修復 |
| BC-TM1 — 術語語言寫死 | P1 | ✅ 已修復 |
| BC-M1 — 長按 timer 不停 | P1 | ✅ 已修復 |
| BC-R6 — SaveDialog 靜默失敗 | P2 | ✅ 已修復 |
| BC-C1 — 刪除無確認 | P2 | ✅ 已修復 |
| BC-G2 — isDev=true | P1 | ⚠️ 上架前手動確認 |
| BC-R7 — 錄音超時未停 | P2 | ⚠️ 待實作 |
| BC-R8 — metadata 競態 | P2 | ⚠️ 待實作 |
| BC-G4 — 語言不持久化 | P2 | ⚠️ 待實作 |
