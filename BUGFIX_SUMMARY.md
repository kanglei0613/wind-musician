# Wind Musician — Bug Fix Summary

修復日期：2026-04-26  
修復範圍：BC-001 ～ BC-012（P0 崩潰 × 7、P1 功能缺陷 × 5）

---

## P0 崩潰類

### BC-001 — TunerNotifier.startListening() startStream 無保護
**檔案：** `lib/features/tuner/tuner_provider.dart`  
**修改：** 在 `_recorder.startStream()` 外層加 `try/catch`。  
捕獲後設定 `state.isListening = false, error = '無法啟動麥克風...'`，避免硬體故障或麥克風被搶占時 unhandled exception。

---

### BC-002 — RecorderNotifier.startRecording() 無 try/catch
**檔案：** `lib/features/recorder/recorder_provider.dart`  
**修改：** 將 `_recorder.start()` 包入 `try/catch`。  
捕獲後 reset `status → idle` 並設定 `error` 訊息，避免 UI 卡在「錄音中」。

---

### BC-003 — AudioPlayerNotifier.play() 播放已刪除檔案 crash
**檔案：** `lib/features/recorder/recorder_provider.dart`  
**修改：** 將 `_player.setFilePath()` + `_player.play()` 包入 `try/catch`。  
捕獲後 `state = null`（停止播放），再 `rethrow` 讓 UI 層顯示 SnackBar。

---

### BC-004 — NativeMetronomeChannel 四個 invokeMethod 無 PlatformException 保護
**檔案：** `lib/shared/services/native_metronome_channel.dart`  
**修改：** `start`、`stop`、`updateBpm`、`updateTimeSig` 各自加 `on PlatformException catch`。  
捕獲後包裝成 `Exception` rethrow，攜帶中文訊息供上層處理。

---

### BC-005 — currentUserProvider Firestore .get() 無網路保護
**檔案：** `lib/features/auth/auth_provider.dart`  
**修改：** 新增 `import 'dart:io'`，在 Firestore `.get()` 外層加 `try/catch FirebaseException + SocketException`。  
捕獲後 rethrow，讓 `FutureProvider` 正確進入 error state，UI 可顯示重試提示。

---

### BC-006 — RecordingRepository._saveAll 磁碟滿時 crash
**檔案：** `lib/features/recorder/repositories/recording_repository.dart`  
**修改：** 在 `file.writeAsString()` 外層加 `on IOException catch`。  
捕獲後拋出帶說明的 `Exception`，供呼叫端顯示錯誤。

---

### BC-007 — PracticeRepository.watchEntriesForMonth stream 無 error handler
**檔案：** `lib/features/calendar/repositories/practice_repository.dart`  
**修改：** 在 stream pipeline 末端加 `.handleError((error, stack) {...}, test: (e) => e is FirebaseException)`。  
離線時 FirebaseException 被攔截，stream 靜默結束（保留最後資料），避免白屏。

---

## P1 功能缺陷

### BC-008 — TunerControls clamp 範圍硬寫 400/480 與 AppConstants 不一致
**檔案：** `lib/features/tuner/widgets/tuner_controls.dart`  
**修改：** 新增 `import app_constants.dart`；將 `clamp(400, 480)` 改為  
`clamp(AppConstants.tunerMinPitch, AppConstants.tunerMaxPitch)`（目前為 420/460）。

---

### BC-009 — TerminologyService HTTP 無錯誤處理
**檔案：** `lib/services/terminology/terminology_service.dart`  
**修改：** 新增 `import 'dart:async'` + `import 'dart:io'`；在 `http.post()` 外加  
`on SocketException`、`on TimeoutException`、`on http.ClientException`，  
各自拋出中文錯誤訊息供 UI 顯示。HTTP 呼叫加 `.timeout(Duration(seconds: 15))`。

---

### BC-010 — PracticeRepository.saveEntry/deleteEntry Firestore write 無 try/catch
**檔案：** `lib/features/calendar/repositories/practice_repository.dart`  
**修改：** `saveEntry` 與 `deleteEntry` 各自在 Firestore write 外層加  
`on FirebaseException catch`，捕獲後 rethrow 帶說明訊息。

---

### BC-011 — stopRecording() path==null 靜默遺失
**檔案：** `lib/features/recorder/recorder_provider.dart`  
**修改：**  
1. `RecorderState` 新增 `error` 欄位（`String?`）及 `copyWith` 的 `clearError` 旗標。  
2. `stopRecording()` 在 `path == null` 時設定 `error = '錄音儲存失敗，請重試。'` 再 return，讓 UI 透過監聽 `state.error` 顯示提示。

---

### BC-012 — Metronome Section 切換與 onBeat race condition
**檔案：** `lib/features/tuner/widgets/metronome.dart`  
**修改：** 在 `_onBeat()` 開頭加邊界保護：
- 若 `_sections` 為空則直接 return
- 若 `_currentSectionIndex >= _sections.length` 則重置為 0
- 若 `_currentBeat >= sections[_currentSectionIndex].numerator` 則重置拍數為 0

`isNewMeasure` 判斷進入後再次做同樣的保護（雙重確認），防止 `_sections` 在 `setState` 過程中被並發修改。

---

## 修改檔案清單

| 檔案 | Bug |
|------|-----|
| `lib/features/tuner/tuner_provider.dart` | BC-001 |
| `lib/features/recorder/recorder_provider.dart` | BC-002, BC-003, BC-011 |
| `lib/shared/services/native_metronome_channel.dart` | BC-004 |
| `lib/features/auth/auth_provider.dart` | BC-005 |
| `lib/features/recorder/repositories/recording_repository.dart` | BC-006 |
| `lib/features/calendar/repositories/practice_repository.dart` | BC-007, BC-010 |
| `lib/features/tuner/widgets/tuner_controls.dart` | BC-008 |
| `lib/services/terminology/terminology_service.dart` | BC-009 |
| `lib/features/tuner/widgets/metronome.dart` | BC-012 |
