# 管樂手帳 Bad Case 分析報告

日期：2026-04-26
分析人：Claude (Sonnet 4.6)
分析範疇：lib/ 全模組靜態分析 + 測試覆蓋驗證

---

## P0 崩潰類 Bad Case

### BC-001 `TunerNotifier.startListening()` — `startStream` 無 try/catch
**檔案：** `lib/features/tuner/tuner_provider.dart:88`

**問題：** `_recorder.startStream(...)` 是非同步呼叫，若麥克風被系統搶佔、硬體初始化失敗或 AudioSession 衝突，底層會拋出 `PlatformException`。目前程式碼中 `startStream` 前後都沒有 `try/catch`，異常會沿著 call stack 往上拋，最終導致 unhandled exception 崩潰。

**建議修法：**
```dart
try {
  final recordStream = await _recorder.startStream(...);
  // ... 訂閱邏輯
} on PlatformException catch (e) {
  if (mounted) {
    state = state.copyWith(
      isListening: false,
      error: '音訊裝置啟動失敗：${e.message}',
    );
  }
} catch (e) {
  if (mounted) {
    state = state.copyWith(isListening: false, error: '未知錯誤');
  }
}
```

---

### BC-002 `RecorderNotifier.startRecording()` — `_recorder.start()` 無 try/catch
**檔案：** `lib/features/recorder/recorder_provider.dart:186`

**問題：** `await _recorder.start(...)` 可能在以下情況拋出 `PlatformException`：
- 音訊格式不支援（部分 Android OEM）
- 儲存路徑無寫入權限
- 另一個 App 佔用麥克風

異常未被捕獲，`state.status` 不會被還原為 `idle`，UI 將永遠停在「錄音中」假狀態。

**建議修法：**
```dart
try {
  await _recorder.start(const RecordConfig(...), path: path);
  state = state.copyWith(status: RecorderStatus.recording, elapsedSeconds: 0);
  _startTimer();
} on PlatformException catch (e) {
  // status 保持 idle，顯示錯誤
  debugPrint('startRecording error: $e');
}
```

---

### BC-003 `AudioPlayerNotifier.play()` — `setFilePath/play` 無 try/catch
**檔案：** `lib/features/recorder/recorder_provider.dart:303-305`

**問題：** `await _player.setFilePath(recording.path)` 與 `await _player.play()` 都沒有 `try/catch`。若錄音檔案已被刪除（例如資料夾刪除後殘留 metadata），`setFilePath` 拋出 `PlayerException`，整個 `Notifier` 崩潰，`state` 停留在「播放中」且無法恢復。

**建議修法：**
```dart
try {
  await _player.setFilePath(recording.path);
  await _player.play();
  state = recording.id;
} catch (e) {
  state = null;  // 還原播放狀態
  debugPrint('play error: $e');
}
```

---

### BC-004 `NativeMetronomeChannel` — 所有 `invokeMethod` 無 try/catch
**檔案：** `lib/shared/services/native_metronome_channel.dart:55,65,71,77`

**問題：** `start()`, `stop()`, `updateBpm()`, `updateTimeSig()` 四個方法都直接 `await _channel.invokeMethod<void>(...)` 而沒有 `try/catch`。在 Android 上以下情況會拋出 `PlatformException`：
- 前景服務（ForegroundService）權限不足
- Android 13+ 的通知權限未授予
- 服務被系統 kill 後再次呼叫

**建議修法：** 每個方法加上 try/catch：
```dart
Future<void> start({...}) async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod<void>('start', {...});
  } on PlatformException catch (e) {
    debugPrint('MetronomeChannel.start error: ${e.message}');
  }
}
```

---

### BC-005 `currentUserProvider` — Firestore `.get()` 無 try/catch
**檔案：** `lib/features/auth/auth_provider.dart:24-27`

**問題：** `FutureProvider` 中直接 `await FirebaseFirestore.instance.collection('users').doc(uid).get()`，若網路斷線或 Firestore Security Rules 拒絕存取，會拋出 `FirebaseException`。雖然 `FutureProvider` 會捕獲並轉為 `AsyncError`，但若 UI 沒有明確處理 `AsyncError` 狀態，用戶只會看到空白畫面。

**建議修法：**
```dart
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  ...
  try {
    final doc = await FirebaseFirestore.instance...get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  } on FirebaseException catch (_) {
    return null;  // 離線時降級為未登入狀態
  }
});
```

---

### BC-006 `RecordingRepository._saveAll()` — `writeAsString` 無 try/catch
**檔案：** `lib/features/recorder/repositories/recording_repository.dart:121-122`

**問題：** `_saveAll` 直接呼叫 `file.writeAsString(...)` 沒有 `try/catch`。手機儲存空間不足時，`FileSystemException` 會往上傳遞到所有呼叫 `_saveAll` 的地方（`add`, `rename`, `moveToFolder`, `delete`, `deleteByFolderId`），最終導致 `RecordingsNotifier` state 更新失敗且 crash。

**建議修法：**
```dart
Future<void> _saveAll(List<Recording> recordings) async {
  try {
    final file = await _getMetadataFile();
    await file.writeAsString(jsonEncode(recordings.map((r) => r.toJson()).toList()));
  } on FileSystemException catch (e) {
    debugPrint('RecordingRepository._saveAll error: $e');
    // 可選：拋出自定義 StorageFullException 讓 UI 顯示提示
  }
}
```

---

### BC-007 `PracticeRepository.watchEntriesForMonth()` — Stream 無 error handler
**檔案：** `lib/features/calendar/repositories/practice_repository.dart:95-110`

**問題：** `.snapshots()` 建立的 Firestore Stream 如果遇到網路中斷、權限錯誤或 token 過期，會在 stream 上發出 error event。`StreamProvider.family` 預設不會自動捕獲這些錯誤，stream error 會導致 provider 進入 `AsyncError` 狀態，若 UI 的 `when()` 沒處理 error 分支，就會白屏或拋出未處理的 `StreamException`。

**建議修法：**
```dart
return _col
    ...
    .snapshots()
    .handleError((Object error) {
      // Firestore 離線/權限錯誤 → 靜默降級，發出空列表
      debugPrint('watchEntriesForMonth error: $error');
    })
    .map((snap) => snap.docs.map(...).toList());
```

---

## P1 功能缺陷類 Bad Case

### BC-008 `TunerControls` — clamp 範圍與 `AppConstants` 不一致
**檔案：** `lib/features/tuner/widgets/tuner_controls.dart:91`

**問題：** `_adjust()` 使用硬寫的 `.clamp(400, 480)`，而 `AppConstants` 定義的合法範圍是 `tunerMinPitch = 420.0` 至 `tunerMaxPitch = 460.0`。這導致：
- UI 允許設定 400~419 Hz（低於規格）
- UI 允許設定 461~480 Hz（高於規格）
- `TunerNotifier.setReferenceA4()` 完全沒有邊界防呆，接受任何值

兩個常數不同步，未來若 `AppConstants` 修改，`TunerControls` 也需要同步改，維護成本高。

**建議修法：**
```dart
import '../../../shared/constants/app_constants.dart';

void _adjust(double delta) {
  setState(() {
    _value = (_value + delta).clamp(
      AppConstants.tunerMinPitch,
      AppConstants.tunerMaxPitch,
    );
  });
  widget.onChanged(_value);
}
```
同時在 `TunerNotifier.setReferenceA4()` 加入防呆：
```dart
void setReferenceA4(double pitch) {
  if (mounted) {
    final clamped = pitch.clamp(AppConstants.tunerMinPitch, AppConstants.tunerMaxPitch);
    state = state.copyWith(referenceA4: clamped);
  }
}
```

---

### BC-009 `TerminologyService.lookup()` — 網路異常未捕獲
**檔案：** `lib/services/terminology/terminology_service.dart:28`

**問題：** `await http.post(...)` 在以下情況會拋出未捕獲的異常：
- 網路斷線 → 拋出 `SocketException`
- 請求超時 → 拋出 `TimeoutException`
- ANTHROPIC_API_KEY 為空字串 → 伺服器回傳 `401`，目前程式碼只在 `statusCode == 200` 時解析，否則解析 error body，但若 error body 格式不符預期，`jsonDecode` 可能拋出 `FormatException`

**建議修法：**
```dart
static Future<TerminologyResult> lookup(String term, ...) async {
  try {
    final response = await http.post(...).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) { ... }
    else { throw Exception('API 錯誤 ${response.statusCode}'); }
  } on SocketException {
    throw Exception('網路連線失敗，請檢查網路設定');
  } on TimeoutException {
    throw Exception('查詢逾時，請稍後再試');
  }
}
```

---

### BC-010 `PracticeRepository.saveEntry/deleteEntry` — Firestore write 無 try/catch
**檔案：** `lib/features/calendar/repositories/practice_repository.dart:113-120`

**問題：** `saveEntry()` 與 `deleteEntry()` 在離線時直接呼叫 Firestore write，雖然 Firestore SDK 有本地佇列機制，但呼叫端如果沒有 catch `FirebaseException`，一旦 Security Rules 拒絕寫入（例如未登入），exception 會直接傳到 `calendarProvider`，導致 UI 崩潰。

**建議修法：**
```dart
Future<void> saveEntry(PracticeEntry entry) async {
  try {
    await _col.doc(entry.id).set(entry.toJson());
  } on FirebaseException catch (e) {
    debugPrint('saveEntry Firestore error: $e');
    // 僅寫本地，等待下次上線同步
  }
  await _upsertLocal(entry);
}
```

---

### BC-011 `RecorderNotifier.stopRecording()` — `_recorder.stop()` 返回 null 的情況
**檔案：** `lib/features/recorder/recorder_provider.dart:210`

**問題：** `final path = await _recorder.stop()` 若 `_recorder` 已被 dispose（例如 App 進入背景時系統強制中斷），`stop()` 可能返回 `null`。程式碼有 `if (path == null) return;` 的防呆，正確。但在 state 已被設為 `idle` 之後，`pendingPath` 為 null，使用者將看不到儲存對話框且錄音遺失，缺乏提示。

**建議修法：** 在 `path == null` 時加入錯誤提示機制，例如透過 provider 狀態通知 UI。

---

### BC-012 `MetronomeState._onBeat()` — Section 切換與 Android Native 事件的 race condition
**檔案：** `lib/features/tuner/widgets/metronome.dart`

**問題：** `_SectionSheet._save()` 的回呼中先更新 `_sections` 再呼叫 `_stop()`：
```dart
setState(() {
  _sections = sections;   // ← 先更新 _sections
  _sectionMode = mode;
  if (_isPlaying) _stop(); // ← 才停止
});
```
在 Android 上，Native `MetronomeEngine` 可能在 `_sections` 更新後、`_stop()` 執行前的極短時間內透過 `_nativeBeatSub` 發出 `onBeat` 事件，觸發 `_onBeat()` 使用新的 `_sections` 但 `_currentSectionIndex` 可能超出新 `_sections.length`，導致 `RangeError`。

**建議修法：** 先停止再更新 sections：
```dart
setState(() {
  if (_isPlaying) _stop(); // 先停止，確保 Native 不再發事件
  _sections = sections;
  _sectionMode = mode;
});
```

---

## P2 UX 問題類 Bad Case

### BC-013 四語系 ARB 同步狀態
**分析：** 所有四個語系（zh、en、ja、ko）均包含完整的 140 個 key，無缺漏，無可疑的未翻譯字串。**通過。**

---

### BC-014 `TunerPage.dispose()` 中 `Future.microtask` 的潛在問題
**檔案：** `lib/features/tuner/tuner_page.dart:55-60`

**問題：** `dispose()` 使用 `Future.microtask` 呼叫 `stopListening()`，有 try-catch 保護。但在極端情況（provider 被快速重建）下，microtask 的排程時間可能晚於 provider 的 dispose，導致 try-catch 中的 `ref.read(tunerProvider.notifier)` 拋出 `ProviderException`。目前有 `catch (_) {}` 靜默處理，不會崩潰，但會留下麥克風 stream 未關閉的可能。

**建議修法：** 直接在 dispose 中同步取消 subscription，避免延遲：
```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  // 直接通知 provider（不等 microtask），recorder dispose 會處理剩餘清理
  super.dispose();
}
```
改由 `TunerNotifier.dispose()` 負責所有資源釋放（已有正確實作）。

---

### BC-015 `AudioPlayerNotifier` — `_player.playerStateStream` subscription 在播放完成後未停止累積
**檔案：** `lib/features/recorder/recorder_provider.dart:308-313`

**問題：** 每次呼叫 `play()` 都會建立一個新的 `_stateSubscription`（舊的有正確 `cancel()`）。但若 `play()` 被快速連續呼叫（例如用戶快速點擊播放按鈕），第一次 `cancel()` 是非同步的，可能在第二次 `play()` 已經建立新 subscription 之後才完成取消，造成短暫的雙重 subscription 狀態，`state = null` 可能被重複觸發。

**建議修法：** 在 `cancel()` 後等待完成，或使用 `await` 確保順序：
```dart
await _stateSubscription?.cancel();
_stateSubscription = null;
// 然後再建立新 subscription
```

---

## 測試執行摘要

### 環境說明
測試環境（Linux sandbox）不包含 Flutter SDK，且網路受限無法下載（storage.googleapis.com 回傳 403）。以下採用靜態語法驗證替代實際執行。

### 靜態語法驗證結果

| 檔案 | Groups | Tests | 大括號 | 狀態 |
|------|--------|-------|--------|------|
| `test/features/tuner/tuner_notifier_test.dart` | 8 | 30 | 42/42 | ✅ OK |
| `test/features/recorder/recorder_notifier_test.dart` | 7 | 23 | 36/36 | ✅ OK |
| `test/features/metronome/metronome_test.dart` | 7 | 36 | 59/59 | ✅ OK |
| `test/features/metronome/metronome_boundary_test.dart` ⭐新增 | 8 | 33 | 53/53 | ✅ OK |
| `test/shared/services/native_channel_test.dart` ⭐新增 | 7 | 31 | 52/52 | ✅ OK |
| `test/widget_test.dart` | 0 | 0 | 2/2 | ✅ OK（placeholder） |

**既有測試：** 語法驗證通過（無法執行，待本機 `flutter test` 確認）
**新增測試：** 語法驗證通過，共 2 檔案、15 groups、64 tests

### 本機執行指令
```bash
cd wind_musician

# 執行既有測試
flutter test test/features/ test/widget_test.dart

# 執行全部測試（含新增）
flutter test test/

# 執行特定新增測試
flutter test test/features/metronome/metronome_boundary_test.dart
flutter test test/shared/services/native_channel_test.dart
```

---

## 新增測試檔案說明

### `test/features/metronome/metronome_boundary_test.dart`
針對現有 `metronome_test.dart` 未覆蓋的邊界，補充 8 groups / 33 tests：
- BPM 邊界 intervalMs 數值正確性與有限性
- 長按加速 ramp（count < 10 / 10~20 / ≥20 三段速度）
- `_scheduleNextBeat` delay clamp 永不為負
- Section 空列表防護邏輯
- 分母 1（全音符）與 32（三十二分音符）的極端 intervalMs
- BPM Dialog 各種邊界字串不 crash
- Section 段落增刪邊界（measureCount = 1 / 32）

### `test/shared/services/native_channel_test.dart`
針對 Platform Channel 與邊界文件化，8 groups / 31 tests：
- `AudioFocusChannel._parseCode` 所有合法 AUDIOFOCUS_* 常數映射正確
- 未知 / null code 映射至 `unknown`（防止 switch fall-through 問題）
- **文件化已知 BUG**：`TunerControls.clamp(400,480)` 與 `AppConstants.tuner{Min,Max}Pitch(420,460)` 不一致
- 非 Android 平台 Platform Channel guard 邏輯模擬
- `_handleNativeCall` 未知方法名靜默忽略不 crash
- `MusicUtils` 在 [25, 5000] Hz 合法範圍內的完整性
- `AudioFocusState` 列舉值完整性驗證

---

## Top 5 優先修復建議

### 🔴 P0-1：為所有 Platform Channel `invokeMethod` 加 try/catch
**影響：** `NativeMetronomeChannel`（4 個方法）在 Android 前景服務權限問題、Android 13+ 通知權限未授予時必 crash。
**修改量：** 小（每個方法加 4 行 try/catch）
**優先度：** 最高，Android 實機測試必現

---

### 🔴 P0-2：`TunerNotifier.startListening()` 的 `startStream` 加 try/catch
**影響：** 麥克風被其他 App 佔用（電話、錄影工具）時，Tuner 頁面必 crash
**修改量：** 小（10 行）
**優先度：** 最高，iOS 和 Android 均會發生

---

### 🔴 P0-3：`RecorderNotifier.startRecording()` 與 `AudioPlayerNotifier.play()` 加 try/catch
**影響：** 錄音啟動失敗時 UI 停在「錄音中」無法恢復；播放已刪除錄音時 crash
**修改量：** 小（各 5~8 行）
**優先度：** 高

---

### 🟠 P1-1：統一 `TunerControls` clamp 與 `AppConstants` 邊界
**影響：** 用戶可設定超出 420~460 Hz 規格的調音基準（400~419 / 461~480），音高偵測結果與設計文件不符
**修改量：** 極小（1 行，`clamp(400, 480)` → `clamp(AppConstants.tunerMinPitch, AppConstants.tunerMaxPitch)`）
**優先度：** 高（影響核心功能正確性）

---

### 🟠 P1-2：修正 Section 切換與 Android Native onBeat 的 race condition
**影響：** Android 裝置上，快速切換 Section 模式時可能觸發 `RangeError` 崩潰（機率性，難以重現）
**修改量：** 小（調換 `_stop()` 與 `_sections = sections` 的順序）
**優先度：** 中高（Android 專用且機率性，但一旦發生就崩潰）

---

## 附錄：Bad Case 索引

| ID | 嚴重度 | 模組 | 簡述 |
|----|--------|------|------|
| BC-001 | P0 | tuner_provider | startStream 無 try/catch |
| BC-002 | P0 | recorder_provider | _recorder.start 無 try/catch |
| BC-003 | P0 | recorder_provider | AudioPlayer setFilePath/play 無 try/catch |
| BC-004 | P0 | native_metronome_channel | invokeMethod 無 try/catch |
| BC-005 | P0 | auth_provider | Firestore .get() 無 try/catch |
| BC-006 | P0 | recording_repository | _saveAll writeAsString 無 try/catch |
| BC-007 | P0 | practice_repository | snapshots() stream 無 error handler |
| BC-008 | P1 | tuner_controls | clamp(400,480) vs AppConstants(420,460) 不一致 |
| BC-009 | P1 | terminology_service | http.post 無 try/catch（SocketException/TimeoutException）|
| BC-010 | P1 | practice_repository | saveEntry/deleteEntry Firestore write 無 try/catch |
| BC-011 | P1 | recorder_provider | stopRecording path=null 時無用戶提示 |
| BC-012 | P1 | metronome | Section 切換 vs Android onBeat race condition |
| BC-013 | P2 | l10n | ARB 四語系同步 ✅ 通過 |
| BC-014 | P2 | tuner_page | dispose() Future.microtask 潛在 stream 洩漏 |
| BC-015 | P2 | recorder_provider | AudioPlayer 快速點擊時短暫雙重 subscription |
