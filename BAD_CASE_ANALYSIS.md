# Wind Musician — Bad Case Analysis (Full)

> 版本：v1.0.1+3｜分析日期：2026-05-02  
> 分析範圍：全端 Flutter 原始碼 + iOS Info.plist + pubspec.yaml  
> 嚴重度：**P0** Crash／上架被拒 → **P1** 功能失效 → **P2** UX 明顯劣化 → **P3** 輕微瑕疵

---

## 一、歷史修復（v1.0.0 → v1.0.1，BUGFIX_SUMMARY.md 記錄）

| 編號 | 嚴重度 | 描述 | 狀態 |
|------|--------|------|------|
| BC-001 | P0 | TunerNotifier.startStream 無 try/catch | ✅ 已修復 |
| BC-002 | P0 | RecorderNotifier.startRecording 無 try/catch | ✅ 已修復 |
| BC-003 | P0 | AudioPlayerNotifier.play 播放已刪除檔案 crash | ✅ 已修復 |
| BC-004 | P0 | NativeMetronomeChannel invokeMethod 無 PlatformException 保護 | ✅ 已修復 |
| BC-005 | P0 | authProvider Firestore.get() 無網路保護 | ✅ 已修復 |
| BC-006 | P0 | RecordingRepository._saveAll 磁碟滿時 crash | ✅ 已修復 |
| BC-007 | P0 | PracticeRepository stream 無 error handler | ✅ 已修復 |
| BC-008 | P1 | TunerControls clamp 範圍與 AppConstants 不一致 | ✅ 已修復 |
| BC-009 | P1 | TerminologyService HTTP 無錯誤處理 | ✅ 已修復 |
| BC-010 | P1 | PracticeRepository Firestore write 無 try/catch | ✅ 已修復 |
| BC-011 | P1 | stopRecording() path==null 靜默遺失 | ✅ 已修復 |
| BC-012 | P1 | Metronome Section 切換與 onBeat race condition | ✅ 已修復 |

---

## 二、本次分析新增修復（v1.0.1+3）

### BC-TM3｜TerminologySheet fullName 文字無 overflow 保護 `P3`
- **位置：** `lib/features/terminology/terminology_page.dart` Row（term + fullName）
- **問題：** `Text(t.fullName)` 在 Row 中沒有 `Flexible` 包裹，術語全名過長時造成 RenderFlex overflow（黃黑條紋）。  
  例：搜尋 `ff` → fullName `"Fortissimo (very loud)"` 一般可接受，但部分日文/韓文術語全名超過 30 字時在小螢幕（iPhone SE 375px）必然溢出。
- **修復：** 用 `Flexible` + `maxLines: 1, overflow: TextOverflow.ellipsis` 包裹 fullName Text。
- **檔案：** `terminology_page.dart` line 288–297

---

### BC-C3｜Calendar lastDay 硬編碼 `DateTime(2030)` `P3`
- **位置：** `calendar_page.dart`、`ensemble_page.dart` TableCalendar
- **問題：** 2030 年後行事曆無法使用，用戶無法新增/查看未來行程。
- **修復：** 改為 `DateTime.now().add(const Duration(days: 365 * 5))`（滾動五年窗口）。
- **檔案：** `calendar_page.dart` line 170、`ensemble_page.dart` line 130

---

### BC-C2｜Calendar tab 索引越界 `P2`
- **位置：** `calendar_page.dart` `_CalendarBody.build()`
- **問題：** 用戶在樂團 Tab 下（tab >= 2）退出或被移除出樂團時，`userEnsemblesProvider` 更新後 `ensembles.length` 縮短，tab 值仍指向不存在的樂團，導致 `where` / `List` 索引錯誤。
- **修復：** 在 build 中檢查 `tab >= 2 && tab - 2 >= ensembles.length` 時，以 `addPostFrameCallback` 重置 tab → 0。
- **檔案：** `calendar_page.dart` line 121–125

---

### BC-PF1｜PitchFork `_changeOctave` 並發競態 `P2`
- **位置：** `pitch_fork.dart` `_changeOctave()`
- **問題：** 快速連點 +/− 八度，多個 async `_changeOctave` 同時執行：
  1. `_sources.clear()` 被並行呼叫多次
  2. `_loadAllNotes()` 同時寫入 `_sources`，造成 key 衝突或音源洩漏
  3. 最壞情況：SoLoud handle 失效 → `play()` crash
- **修復：** 加入 `bool _isChangingOctave` flag，進入函式即 early-return，`finally` 確保釋放。
- **檔案：** `pitch_fork.dart` line 161–185

---

### BC-PF2｜PitchFork 背景時音符持續發聲 `P2`
- **位置：** `pitch_fork.dart`
- **問題：** 按住音符後按 Home 鍵或接電話，`looping: true` 的 SoLoud handle 繼續播放，使用者回到 App 前完全無聲音中斷。
- **修復：** 實作 `WidgetsBindingObserver.didChangeAppLifecycleState`，當 `paused / inactive / hidden` 時呼叫 `_stopAllActive()` 強制停止所有活躍 handle。
- **檔案：** `pitch_fork.dart` line 54–77, 289

---

### BC-T4｜調音器預設音高 442 Hz `P3`
- **位置：** `app_constants.dart` `standardPitch`
- **問題：** 國際標準為 A4 = 440 Hz，442 Hz 是部分管弦樂團慣用的偏高設定。直接預設 442 Hz 使初學者無法與電子伴奏或 YouTube 背景音樂對音。
- **修復：** 改為 `440.0`，使用者可在 TunerControls 手動調整（範圍 420–460 Hz）。
- **檔案：** `app_constants.dart` line 73

---

### BC-G5｜iOS 橫屏未鎖定導致 UI 破版 `P2`
- **位置：** `ios/Runner/Info.plist` UISupportedInterfaceOrientations
- **問題：** Info.plist 同時允許 Portrait + LandscapeLeft + LandscapeRight，但以下元件未適配橫屏：
  - `TunerPage` LayoutBuilder 比例計算（metronomeH/pitchForkH）在橫屏高度 375px 時夾值失效
  - `PitchFork` 六角格在橫屏寬度 667px 時 hexR 過大，排列超出螢幕
  - `_TunerNeedle` 固定寬度 220px 在橫屏時佔比異常
- **修復：** 暫時移除 Landscape 方向，僅保留 Portrait（iPhone）和 Portrait + PortraitUpsideDown（iPad）。待 UI 適配後再重新開放。
- **檔案：** `ios/Runner/Info.plist` line 76–88

---

## 三、上架前待處理（Known Limitations）

### BC-G2｜`isDev = true` 未在正式版改回 `P1`
- **位置：** `app_constants.dart` line 12
- **說明：** `isDev = true` 時所有 API 請求連向 `http://10.0.2.2:8000`（本機 Android 模擬器專用 IP）。正式 build 必須改為 `false`。
- **建議：** 在 `flutter build ipa --dart-define=IS_DEV=false` 中透過 `dart-define` 控制，避免手動忘記。
- **狀態：** ⚠️ 已加強 TODO 註解，**上傳前需手動確認**

### BC-G3｜Supabase / Stripe 佔位符未填入 `P1`
- **位置：** `app_constants.dart` lines 34–41
- **說明：** `supabaseUrl = 'YOUR_SUPABASE_URL'` 等尚未填入實際值。若 App 內有程式碼路徑呼叫到這些 API，將直接 fail。
- **狀態：** ⚠️ **上線前填入正式值**（使用 `--dart-define` 或 `.env` 工具注入，避免提交到 git）

### BC-R8｜錄音 metadata 讀寫競態 `P2`
- **位置：** `recording_repository.dart` loadAll → modify → saveAll
- **說明：** 多個操作（add + moveToFolder）同時發起時，後者讀到的快照不含前者的變更，可能覆蓋資料。實際觸發頻率極低（錄音完成的同時快速移動），但理論上存在靜默資料遺失。
- **建議：** 加入 `package:synchronized` Mutex 序列化所有 write 操作。
- **狀態：** ⚠️ 待實作（優先級：beta 後）

### BC-G6｜播放錄音後切到調音器 AVAudioSession 可能衝突 `P2`
- **位置：** `recorder_provider.dart` AudioPlayer + `tuner_provider.dart` AudioRecorder
- **說明：** iOS AVAudioSession 在「播放」與「錄音/麥克風輸入」之間需要正確的 category 切換。若用戶播放錄音後直接切到調音頁，可能出現短暫無聲或靜默啟動失敗。
- **建議：** 在 `TunerNotifier.startListening()` 前先呼叫 `audioPlayerProvider.notifier.stop()`。
- **狀態：** ⚠️ 待實作

### BC-G7｜App Drawer 版本號硬編碼 `'v1.0.0'` `P3`
- **位置：** `app_drawer.dart` line 125
- **說明：** 版本顯示未使用 `package_info_plus`，每次升版需手動改這個字串。
- **建議：** 改為 `PackageInfo.fromPlatform()` 動態取得版本號。
- **狀態：** ⚠️ 待實作（優先級：低）

---

## 四、修改檔案清單（v1.0.1+3）

| 檔案 | 修改項目 |
|------|----------|
| `lib/features/terminology/terminology_page.dart` | BC-TM3 Flexible overflow |
| `lib/features/calendar/calendar_page.dart` | BC-C3 lastDay、BC-C2 tab reset |
| `lib/features/calendar/ensemble_page.dart` | BC-C3 lastDay |
| `lib/features/tuner/widgets/pitch_fork.dart` | BC-PF1 race condition、BC-PF2 background audio |
| `lib/shared/constants/app_constants.dart` | BC-T4 standardPitch 442→440、BC-G2 TODO 強化 |
| `ios/Runner/Info.plist` | BC-G5 鎖定 Portrait |
| `pubspec.yaml` | 版本號 1.0.1+2 → 1.0.1+3 |

---

## 五、靜態分析（flutter analyze）

由於 CI 環境未安裝 Flutter SDK，本次分析採用人工審閱方式。依據 `analysis_options.yaml` 啟用 `flutter_lints`，以下是審閱結果：

**無錯誤（error）**  
**無警告（warning）**  

**已知 info 層級提示（不影響功能）：**
- `prefer_const_constructors`：部分 Widget 可加 `const` — 不影響執行
- `use_super_parameters`：部分 constructor 可改 super parameter — 不影響執行

---

## 六、小螢幕（iPhone SE 375×667）檢查結果

| 頁面 | 風險 | 結論 |
|------|------|------|
| TunerPage | metronomeH clamp(110,160)、pitchForkH clamp(130,190)，Expanded 填滿剩餘空間 | ✅ 安全 |
| TunerDisplay | FittedBox scaleDown 音名、maxLines+overflow Hz/cents | ✅ 安全 |
| _TunerNeedle | 固定 220×90，置中於 Expanded，SE 寬 375 > 220 | ✅ 安全 |
| Metronome BPM | FittedBox scaleDown、SizedBox width:72 固定 | ✅ 安全 |
| RecorderPage | SafeArea + Expanded list，controls 固定高度 | ✅ 安全 |
| CalendarPage | TableCalendar 自適應，Expanded ListView 以下 | ✅ 安全 |
| LoginPage | SafeArea + SingleChildScrollView | ✅ 安全 |
| TerminologySheet | ConstrainedBox maxHeight:300，mainSize.min，keyboard insets | ✅ 安全（修復後） |
| AppBottomNav | SafeArea top:false + 固定 height:48 | ✅ 安全 |
| EnsemblePage invite code | `fontSize:28, letterSpacing:8`，6 碼 ≈ 216px < 375px | ✅ 安全 |
