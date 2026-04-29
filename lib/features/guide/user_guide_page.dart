library;

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class UserGuidePage extends StatelessWidget {
  const UserGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final sections = _buildSections(context, l);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l.drawerUserGuide),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: sections.length,
        itemBuilder: (context, i) => sections[i],
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;

    return [
      _GuideSection(
        icon: Icons.tune_rounded,
        title: _str(l, 'tuner'),
        color: Colors.blue,
        children: [
          _GuideItem(
            title: _str(l, 'guide_tuner_start_title'),
            body: _str(l, 'guide_tuner_start_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_tuner_instrument_title'),
            body: _str(l, 'guide_tuner_instrument_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_tuner_reference_title'),
            body: _str(l, 'guide_tuner_reference_body'),
          ),
        ],
        cs: cs,
      ),

      _GuideSection(
        icon: Icons.music_note_rounded,
        title: _str(l, 'metronome'),
        color: Colors.green,
        children: [
          _GuideItem(
            title: _str(l, 'guide_metro_play_title'),
            body: _str(l, 'guide_metro_play_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_metro_bpm_title'),
            body: _str(l, 'guide_metro_bpm_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_metro_timesig_title'),
            body: _str(l, 'guide_metro_timesig_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_metro_section_title'),
            body: _str(l, 'guide_metro_section_body'),
          ),
        ],
        cs: cs,
      ),

      _GuideSection(
        icon: Icons.menu_book_rounded,
        title: _str(l, 'guide_terminology_title'),
        color: Colors.orange,
        children: [
          _GuideItem(
            title: _str(l, 'guide_terminology_how_title'),
            body: _str(l, 'guide_terminology_how_body'),
          ),
        ],
        cs: cs,
      ),

      _GuideSection(
        icon: Icons.mic_rounded,
        title: _str(l, 'recorderTitle'),
        color: Colors.red,
        children: [
          _GuideItem(
            title: _str(l, 'guide_rec_start_title'),
            body: _str(l, 'guide_rec_start_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_rec_save_title'),
            body: _str(l, 'guide_rec_save_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_rec_folder_title'),
            body: _str(l, 'guide_rec_folder_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_rec_actions_title'),
            body: _str(l, 'guide_rec_actions_body'),
          ),
        ],
        cs: cs,
      ),

      _GuideSection(
        icon: Icons.calendar_month_rounded,
        title: _str(l, 'calendarTitle'),
        color: Colors.purple,
        children: [
          _GuideItem(
            title: _str(l, 'guide_cal_add_title'),
            body: _str(l, 'guide_cal_add_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_cal_edit_title'),
            body: _str(l, 'guide_cal_edit_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_cal_ensemble_title'),
            body: _str(l, 'guide_cal_ensemble_body'),
          ),
        ],
        cs: cs,
      ),

      _GuideSection(
        icon: Icons.person_rounded,
        title: _str(l, 'drawerSignIn'),
        color: Colors.teal,
        children: [
          _GuideItem(
            title: _str(l, 'guide_auth_how_title'),
            body: _str(l, 'guide_auth_how_body'),
          ),
          _GuideItem(
            title: _str(l, 'guide_auth_benefit_title'),
            body: _str(l, 'guide_auth_benefit_body'),
          ),
        ],
        cs: cs,
      ),

      _GuideSection(
        icon: Icons.palette_rounded,
        title: _str(l, 'drawerAppearance'),
        color: Colors.indigo,
        children: [
          _GuideItem(
            title: _str(l, 'settingsLanguage'),
            body: _str(l, 'guide_lang_body'),
          ),
          _GuideItem(
            title: _str(l, 'drawerColorMode'),
            body: _str(l, 'guide_color_body'),
          ),
        ],
        cs: cs,
      ),

      // 開發中
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          _str(l, 'guide_coming_soon_header'),
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),

      _ComingSoonCard(
        icon: Icons.auto_awesome_rounded,
        title: _str(l, 'analysisTitle'),
        body: _str(l, 'guide_analysis_coming'),
        cs: cs,
      ),
      _ComingSoonCard(
        icon: Icons.schedule_rounded,
        title: _str(l, 'scheduleTitle'),
        body: _str(l, 'guide_schedule_coming'),
        cs: cs,
      ),
      _ComingSoonCard(
        icon: Icons.people_rounded,
        title: _str(l, 'communityTitle'),
        body: _str(l, 'guide_community_coming'),
        cs: cs,
      ),
    ];
  }

  /// 從 AppLocalizations 取得字串；若尚未加入 l10n 則直接 fallback 到多語靜態表
  String _str(AppLocalizations l, String key) {
    // 直接映射已有的 l10n key
    switch (key) {
      case 'tuner': return l.navTuner;
      case 'metronome': return l.metronomeSection.split(' ').first; // 取「節拍器」
      case 'recorderTitle': return l.recorderTitle;
      case 'calendarTitle': return l.calendarTitle;
      case 'drawerSignIn': return l.drawerSignIn;
      case 'drawerAppearance': return l.drawerAppearance;
      case 'settingsLanguage': return l.settingsLanguage;
      case 'drawerColorMode': return l.drawerColorMode;
      case 'analysisTitle': return l.analysisTitle;
      case 'scheduleTitle': return l.scheduleTitle;
      case 'communityTitle': return l.communityTitle;
      default: return _fallback(l, key);
    }
  }

  String _fallback(AppLocalizations l, String key) {
    // 未入 ARB 的指南專用字串，依當前語系回傳
    // 判斷語系：透過已知翻譯值反推
    final isZh = l.recorderTitle == '錄音';
    final isJa = l.recorderTitle == '録音' && l.tunerInTune == '正確';
    final isKo = l.recorderTitle == '녹음';
    // final isEn = !isZh && !isJa && !isKo;

    if (isZh) return _zhStrings[key] ?? key;
    if (isJa) return _jaStrings[key] ?? _enStrings[key] ?? key;
    if (isKo) return _koStrings[key] ?? _enStrings[key] ?? key;
    return _enStrings[key] ?? key;
  }

  // ── 中文字串 ──────────────────────────────────────
  static const _zhStrings = <String, String>{
    'metronome': '節拍器',
    'guide_tuner_start_title': '自動偵測音高',
    'guide_tuner_start_body': '切換至「調音器」分頁後自動啟動，即時偵測麥克風輸入。\n•  中央顯示目前最接近的音名\n•  ±數值（cents）顯示偏高或偏低程度\n•  誤差在 ±10 分貝以內即顯示「準確」',
    'guide_tuner_instrument_title': '選擇樂器（移調）',
    'guide_tuner_instrument_body': '點擊左下角樂器按鈕，從清單選擇：\n•  Concert Pitch：長笛、雙簧管、長號、大號\n•  B♭ 調：小號、單簧管、次中音薩克斯風\n•  E♭ 調：中音薩克斯風、上低音薩克斯風\n•  F 調：法國號\nApp 會自動換算對應音高。',
    'guide_tuner_reference_title': '調整基準音高',
    'guide_tuner_reference_body': '點擊右下角「A4 = ___ Hz」按鈕開啟調整面板。\n•  ＋ / － 每次 ±1 Hz，長按加速\n•  快選：440 / 441 / 442 / 443 / 444 Hz\n•  範圍：400 – 480 Hz',
    'guide_metro_play_title': '播放 / 停止',
    'guide_metro_play_body': '點擊節拍器中央播放鍵（▶）啟動，再次點擊停止。\n強拍音調較高，弱拍音調較低。',
    'guide_metro_bpm_title': '調整 BPM',
    'guide_metro_bpm_body': '方法一：點擊左右 ＋ / － 按鈕每次 ±1，長按可持續增減。\n方法二：直接點擊 BPM 數字，輸入數值後按確認（範圍 20 – 320）。\n若輸入超出範圍，App 會自動夾值並顯示提示。',
    'guide_metro_timesig_title': '調整拍號',
    'guide_metro_timesig_body': '點擊節拍器左側拍號（如 4/4）後滾動選擇：\n•  分子（上方）：每小節拍數，1 – 12\n•  分母（下方）：音符時值，可選 1 / 2 / 4 / 8 / 16 / 32',
    'guide_metro_section_title': '段落練習模式',
    'guide_metro_section_body': '切換「段落練習」開關後，可為每個段落分別設定拍號與小節數，節拍器會依序循環播放。\n適合拍號交替變化的曲目（如 4/4 接 3/4）。',
    'guide_terminology_title': '音樂術語查詢',
    'guide_terminology_how_title': '如何查詢',
    'guide_terminology_how_body': '在調音器頁面右下角點擊書本圖示（📖）。\n•  輸入縮寫或術語，例如 ff、rit.、D.C.\n•  點擊下方快速標籤一鍵查詢常用術語\n•  結果顯示全稱與當前語言的解釋\n術語庫會跟隨 App 語言自動切換。',
    'guide_rec_start_title': '開始錄音',
    'guide_rec_start_body': '切換至「錄音」分頁，點擊大圓圈按鈕開始錄音，計時器同步啟動。\n再次點擊停止。\n⚠️ 最長 15 分鐘（900 秒），到達上限後自動停止。',
    'guide_rec_save_title': '儲存錄音',
    'guide_rec_save_body': '停止後彈出儲存對話框：\n•  輸入錄音名稱（必填）\n•  選擇要存入的資料夾\n點擊「儲存」完成，「捨棄」則丟棄此次錄音。',
    'guide_rec_folder_title': '管理資料夾',
    'guide_rec_folder_body': '•  新增：點擊搜尋列右側資料夾圖示（🗂️）\n•  搜尋：搜尋欄即時篩選資料夾\n•  重新命名 / 刪除：點擊資料夾右側 ⋮ 選單\n⚠️ 刪除資料夾會同時刪除其中所有錄音，無法復原。',
    'guide_rec_actions_title': '錄音操作',
    'guide_rec_actions_body': '點擊錄音右側 ⋮ 選單：\n•  重新命名\n•  移至資料夾\n•  匯出 / 分享（傳送至其他 App）\n•  刪除（會顯示確認對話框）',
    'guide_cal_add_title': '新增紀錄',
    'guide_cal_add_body': '點擊右下角「新增紀錄」，填寫練習內容與時長後儲存。\n有紀錄的日期在月曆上以圓點標記。',
    'guide_cal_edit_title': '編輯 / 刪除紀錄',
    'guide_cal_edit_body': '點擊日期後，在下方紀錄列表點擊 ⋮ 選單，可選擇「編輯」或「刪除」。\n刪除前會顯示確認對話框。',
    'guide_cal_ensemble_title': '樂團群組（需登入）',
    'guide_cal_ensemble_body': '登入後可加入樂團群組，查看合奏活動（橘色圓點）與他人練習紀錄。\n上方標籤可切換「個人」/ 「全部樂團」/ 個別樂團。',
    'guide_auth_how_title': '登入方式',
    'guide_auth_how_body': '打開右上角選單（☰），點擊帳號區域的「登入」。\n支援：Google 登入、Apple 登入（iOS）、Email 帳號。\n未登入也可使用調音器、錄音、音樂術語查詢及個人行事曆。',
    'guide_auth_benefit_title': '登入後的功能',
    'guide_auth_benefit_body': '•  設定與紀錄跨裝置同步\n•  加入樂團群組\n•  AI 分析額度（Pro 版更高）',
    'guide_lang_body': '打開右上角選單（☰）→ 語言，選擇後立即生效，重新啟動 App 後也會記住。\n支援：繁體中文、English、日本語、한국어',
    'guide_color_body': '打開右上角選單（☰）→ Color Mode，可選擇主題顏色與明暗模式。',
    'guide_coming_soon_header': '開發中功能',
    'guide_analysis_coming': 'AI 分析錄音的音準、節奏穩定度與音色表現。\n免費版每月 3 次；Pro 版無限次。（功能串接中）',
    'guide_schedule_coming': '事前規劃練習行程，設定日期、時間與練習項目。（功能開發中）',
    'guide_community_coming': '查看好友練習動態、本週練習時數排行榜、互相督促分享進度。（規劃中）',
  };

  // ── English strings ───────────────────────────────
  static const _enStrings = <String, String>{
    'metronome': 'Metronome',
    'guide_tuner_start_title': 'Real-time Pitch Detection',
    'guide_tuner_start_body': 'Opens automatically on the Tuner tab.\n•  Center: current detected note name\n•  Cents value: positive = sharp, negative = flat\n•  "In Tune" shown when within ±10 cents',
    'guide_tuner_instrument_title': 'Instrument / Transposition',
    'guide_tuner_instrument_body': 'Tap the instrument button (bottom-left) to switch:\n•  Concert Pitch: Flute, Oboe, Trombone, Tuba\n•  B♭: Trumpet, Clarinet, Tenor Sax\n•  E♭: Alto Sax, Baritone Sax, Eb Clarinet\n•  F: French Horn\nThe tuner auto-converts the pitch.',
    'guide_tuner_reference_title': 'Reference Pitch',
    'guide_tuner_reference_body': 'Tap the "A4 = ___ Hz" button (bottom-right).\n•  +/− buttons: ±1 Hz; long-press to speed up\n•  Quick select: 440 / 441 / 442 / 443 / 444 Hz\n•  Range: 400 – 480 Hz',
    'guide_metro_play_title': 'Play / Stop',
    'guide_metro_play_body': 'Tap the play button (▶) in the metronome area at the top of the Tuner page to start; tap again to stop.\nStrong beat is higher-pitched.',
    'guide_metro_bpm_title': 'Adjust BPM',
    'guide_metro_bpm_body': 'Method 1: Tap the +/− buttons on either side of the BPM number (long-press to accelerate).\nMethod 2: Tap the BPM number directly to type a value (range 20–320).\nValues outside range are automatically clamped.',
    'guide_metro_timesig_title': 'Time Signature',
    'guide_metro_timesig_body': 'Tap the time signature (e.g. 4/4) on the left side of the metronome:\n•  Numerator: beats per bar, 1–12\n•  Denominator: note value — 1 / 2 / 4 / 8 / 16 / 32',
    'guide_metro_section_title': 'Section Practice Mode',
    'guide_metro_section_body': 'Toggle "Section Practice" to define multiple sections, each with its own time signature and bar count. The metronome loops through them in order.\nIdeal for pieces with changing meters.',
    'guide_terminology_title': 'Music Terminology',
    'guide_terminology_how_title': 'How to Search',
    'guide_terminology_how_body': 'Tap the book icon (📖) at the bottom-right of the Tuner page.\n•  Type an abbreviation or term (e.g. ff, rit., D.C.)\n•  Tap quick-access chips for common terms\n•  Results show full name and explanation\nThe database switches language with the app.',
    'guide_rec_start_title': 'Start Recording',
    'guide_rec_start_body': 'Go to the Recorder tab and tap the large circle button. Tap again to stop.\n⚠️ Max 15 minutes (900 s) — auto-stops at the limit.',
    'guide_rec_save_title': 'Save a Recording',
    'guide_rec_save_body': 'After stopping, a dialog appears:\n•  Enter a recording name (required)\n•  Choose a folder\nTap Save to keep it, Discard to delete.',
    'guide_rec_folder_title': 'Manage Folders',
    'guide_rec_folder_body': '•  New folder: tap the folder icon next to the search bar\n•  Search: type in the search bar to filter\n•  Rename / Delete: tap ⋮ on a folder\n⚠️ Deleting a folder removes all recordings inside it.',
    'guide_rec_actions_title': 'Recording Actions',
    'guide_rec_actions_body': 'Tap ⋮ on a recording:\n•  Rename\n•  Move to Folder\n•  Export / Share\n•  Delete (with confirmation)',
    'guide_cal_add_title': 'Add a Practice Record',
    'guide_cal_add_body': 'Tap the "Add Practice Record" FAB, fill in the content and duration, then save.\nDays with entries are marked with dots on the calendar.',
    'guide_cal_edit_title': 'Edit / Delete',
    'guide_cal_edit_body': 'Tap a date, then tap ⋮ on an entry to Edit or Delete.\nA confirmation dialog appears before deleting.',
    'guide_cal_ensemble_title': 'Ensemble Groups (Sign-in required)',
    'guide_cal_ensemble_body': 'After signing in, join ensemble groups to see rehearsal events (orange dots) and member practice.\nSwitch tabs: Personal / All Ensembles / individual groups.',
    'guide_auth_how_title': 'How to Sign In',
    'guide_auth_how_body': 'Open the menu (☰) and tap Sign In.\nSupports: Google, Apple (iOS), and Email.\nTuner, Recorder, Terminology, and personal Calendar work without signing in.',
    'guide_auth_benefit_title': 'Benefits of Signing In',
    'guide_auth_benefit_body': '•  Sync settings and records across devices\n•  Join ensemble groups\n•  AI analysis quota (higher for Pro)',
    'guide_lang_body': 'Open menu (☰) → Language. Takes effect immediately and persists across app restarts.\nSupported: 中文, English, 日本語, 한국어',
    'guide_color_body': 'Open menu (☰) → Color Mode to pick a theme color and light/dark mode.',
    'guide_coming_soon_header': 'COMING SOON',
    'guide_analysis_coming': 'AI-powered analysis of your recording — pitch accuracy, rhythm stability, and tone. Free: 3 analyses/month; Pro: unlimited. (In development)',
    'guide_schedule_coming': 'Plan practice sessions in advance with date, time, and content. (In development)',
    'guide_community_coming': 'See what friends practiced, weekly leaderboard, and progress sharing. (Planned)',
  };

  // ── 日本語 ────────────────────────────────────────
  static const _jaStrings = <String, String>{
    'metronome': 'メトロノーム',
    'guide_tuner_start_title': 'リアルタイム音程検出',
    'guide_tuner_start_body': 'チューナータブを開くと自動的に起動します。\n•  中央：検出された音名\n•  セント値：正=シャープ、負=フラット\n•  ±10セント以内で「正確」と表示',
    'guide_tuner_instrument_title': '楽器／移調',
    'guide_tuner_instrument_body': '左下の楽器ボタンをタップして選択：\n•  Concert Pitch：フルート、オーボエ、トロンボーン\n•  B♭：トランペット、クラリネット、テナーサックス\n•  E♭：アルトサックス、バリトンサックス\n•  F：フレンチホルン',
    'guide_tuner_reference_title': '基準音高の調整',
    'guide_tuner_reference_body': '右下の「A4 = ___ Hz」ボタンをタップ。\n•  ＋/－で±1Hz、長押しで加速\n•  クイック選択：440〜444 Hz\n•  範囲：400〜480 Hz',
    'guide_metro_play_title': '再生 / 停止',
    'guide_metro_play_body': '調音器ページ上部の再生ボタン（▶）をタップ。\n強拍は音が高く、弱拍は低くなります。',
    'guide_metro_bpm_title': 'BPM調整',
    'guide_metro_bpm_body': '方法①：BPM両側の＋/－ボタン（長押しで加速）\n方法②：BPM数字をタップして直接入力（範囲：20〜320）\n範囲外の値は自動でクランプされます。',
    'guide_metro_timesig_title': '拍子記号',
    'guide_metro_timesig_body': '拍子記号（例：4/4）をタップしてスクロール：\n•  分子：1拍あたりの拍数（1〜12）\n•  分母：音符の種類（1/2/4/8/16/32）',
    'guide_metro_section_title': 'セクション練習モード',
    'guide_metro_section_body': '「セクション練習」をオンにすると、異なる拍子の複数セクションを設定してループ再生できます。',
    'guide_terminology_title': '音楽用語検索',
    'guide_terminology_how_title': '検索方法',
    'guide_terminology_how_body': 'チューナーページ右下の本アイコン（📖）をタップ。\n•  略語や用語を入力（例：ff、rit.）\n•  クイックタグで一発検索\n•  現在の言語で意味を表示',
    'guide_rec_start_title': '録音開始',
    'guide_rec_start_body': '「録音」タブで大きな丸ボタンをタップして開始。再度タップで停止。\n⚠️ 最長15分（900秒）で自動停止。',
    'guide_rec_save_title': '録音を保存',
    'guide_rec_save_body': '停止後にダイアログが表示されます：\n•  録音名を入力（必須）\n•  フォルダを選択\n「保存」または「破棄」をタップ。',
    'guide_rec_folder_title': 'フォルダ管理',
    'guide_rec_folder_body': '•  新規：検索欄右のフォルダアイコン\n•  検索：検索欄で絞り込み\n•  名前変更/削除：フォルダの ⋮ メニュー\n⚠️ フォルダを削除すると中の録音も削除されます。',
    'guide_rec_actions_title': '録音の操作',
    'guide_rec_actions_body': '録音の ⋮ メニューをタップ：\n•  名前変更\n•  フォルダに移動\n•  エクスポート / 共有\n•  削除（確認ダイアログあり）',
    'guide_cal_add_title': '練習記録を追加',
    'guide_cal_add_body': '右下の「練習記録を追加」ボタンをタップ。内容と時間を入力して保存。',
    'guide_cal_edit_title': '編集 / 削除',
    'guide_cal_edit_body': '日付をタップして記録を選択し、⋮ メニューから「編集」か「削除」。',
    'guide_cal_ensemble_title': 'アンサンブルグループ（要サインイン）',
    'guide_cal_ensemble_body': 'サインイン後にアンサンブルグループに参加すると、合奏イベントや他メンバーの練習を確認できます。',
    'guide_auth_how_title': 'サインイン方法',
    'guide_auth_how_body': 'メニュー（☰）を開いて「サインイン」。\nGoogle・Apple（iOS）・Emailに対応。\nサインインなしでも調音器、録音、用語検索、個人カレンダーは使えます。',
    'guide_auth_benefit_title': 'サインインのメリット',
    'guide_auth_benefit_body': '•  設定と記録のクロスデバイス同期\n•  アンサンブルグループ参加\n•  AI分析クォータ（Pro版はより高い）',
    'guide_lang_body': 'メニュー（☰）→ 言語で選択。即時反映・起動後も維持。\n対応言語：中文、English、日本語、한국어',
    'guide_color_body': 'メニュー（☰）→ Color Mode でテーマカラーと明暗モードを選択。',
    'guide_coming_soon_header': '開発中',
    'guide_analysis_coming': '録音のAI分析（音程・リズム・音色）。無料版：月3回、Pro版：無制限。（開発中）',
    'guide_schedule_coming': '練習スケジュールを事前に計画。（開発中）',
    'guide_community_coming': '友達の練習動態・週間ランキング・進捗シェア。（企画中）',
  };

  // ── 한국어 ────────────────────────────────────────
  static const _koStrings = <String, String>{
    'metronome': '메트로놈',
    'guide_tuner_start_title': '실시간 음정 감지',
    'guide_tuner_start_body': '튜너 탭을 열면 자동으로 시작됩니다.\n•  중앙: 감지된 음이름\n•  센트 값: 양수=샤프, 음수=플랫\n•  ±10센트 이내 시 "정확" 표시',
    'guide_tuner_instrument_title': '악기 / 이조',
    'guide_tuner_instrument_body': '왼쪽 하단 악기 버튼을 탭하여 선택:\n•  Concert Pitch: 플루트, 오보에, 트롬본\n•  B♭: 트럼펫, 클라리넷, 테너 색소폰\n•  E♭: 알토/바리톤 색소폰\n•  F: 프렌치 호른',
    'guide_tuner_reference_title': '기준 음높이 조정',
    'guide_tuner_reference_body': '오른쪽 하단 "A4 = ___ Hz" 버튼을 탭.\n•  +/− 버튼: ±1Hz, 길게 누르면 가속\n•  빠른 선택: 440〜444 Hz\n•  범위: 400〜480 Hz',
    'guide_metro_play_title': '재생 / 정지',
    'guide_metro_play_body': '튜너 페이지 상단의 재생 버튼(▶)을 탭.\n강박은 높은 음, 약박은 낮은 음이 납니다.',
    'guide_metro_bpm_title': 'BPM 조정',
    'guide_metro_bpm_body': '방법①: BPM 양쪽 +/− 버튼 (길게 누르면 가속)\n방법②: BPM 숫자를 직접 탭하여 입력 (범위: 20〜320)\n범위 초과 시 자동으로 클램핑됩니다.',
    'guide_metro_timesig_title': '박자표',
    'guide_metro_timesig_body': '박자표(예: 4/4)를 탭하여 스크롤:\n•  분자: 마디당 박수 (1〜12)\n•  분모: 음표 단위 (1/2/4/8/16/32)',
    'guide_metro_section_title': '섹션 연습 모드',
    'guide_metro_section_body': '"섹션 연습"을 켜면 각각 다른 박자의 여러 섹션을 설정하여 순환 재생할 수 있습니다.',
    'guide_terminology_title': '음악 용어 검색',
    'guide_terminology_how_title': '검색 방법',
    'guide_terminology_how_body': '튜너 페이지 오른쪽 하단 책 아이콘(📖)을 탭.\n•  약어나 용어 입력 (예: ff, rit.)\n•  빠른 태그로 바로 검색\n•  현재 언어로 의미 표시',
    'guide_rec_start_title': '녹음 시작',
    'guide_rec_start_body': '녹음 탭에서 큰 원형 버튼을 탭하여 시작, 다시 탭하면 정지.\n⚠️ 최대 15분(900초) — 한도 도달 시 자동 정지.',
    'guide_rec_save_title': '녹음 저장',
    'guide_rec_save_body': '정지 후 대화상자 표시:\n•  녹음 이름 입력 (필수)\n•  폴더 선택\n저장 또는 폐기를 탭.',
    'guide_rec_folder_title': '폴더 관리',
    'guide_rec_folder_body': '•  새 폴더: 검색창 옆 폴더 아이콘\n•  검색: 검색창에 입력하여 필터링\n•  이름 변경/삭제: 폴더의 ⋮ 메뉴\n⚠️ 폴더 삭제 시 내부 모든 녹음도 삭제됩니다.',
    'guide_rec_actions_title': '녹음 작업',
    'guide_rec_actions_body': '녹음의 ⋮ 메뉴를 탭:\n•  이름 변경\n•  폴더로 이동\n•  내보내기 / 공유\n•  삭제 (확인 대화상자)',
    'guide_cal_add_title': '연습 기록 추가',
    'guide_cal_add_body': '오른쪽 하단 "연습 기록 추가" 버튼을 탭하여 내용과 시간을 입력하고 저장.',
    'guide_cal_edit_title': '편집 / 삭제',
    'guide_cal_edit_body': '날짜를 탭한 후 기록의 ⋮ 메뉴에서 편집 또는 삭제 선택.',
    'guide_cal_ensemble_title': '앙상블 그룹 (로그인 필요)',
    'guide_cal_ensemble_body': '로그인 후 앙상블 그룹에 참여하면 합주 이벤트와 멤버 연습을 확인할 수 있습니다.',
    'guide_auth_how_title': '로그인 방법',
    'guide_auth_how_body': '메뉴(☰)를 열고 로그인 탭.\nGoogle, Apple(iOS), 이메일 지원.\n로그인 없이도 튜너, 녹음, 용어 검색, 개인 캘린더 사용 가능.',
    'guide_auth_benefit_title': '로그인의 이점',
    'guide_auth_benefit_body': '•  기기 간 설정 및 기록 동기화\n•  앙상블 그룹 참여\n•  AI 분석 할당량 (Pro는 더 높음)',
    'guide_lang_body': '메뉴(☰) → 언어에서 선택. 즉시 반영되고 재시작 후에도 유지.\n지원: 中文, English, 日本語, 한국어',
    'guide_color_body': '메뉴(☰) → Color Mode에서 테마 색상과 밝기 모드 선택.',
    'guide_coming_soon_header': '개발 중',
    'guide_analysis_coming': 'AI 녹음 분석 (음정·리듬·음색). 무료: 월 3회, Pro: 무제한. (개발 중)',
    'guide_schedule_coming': '연습 일정 사전 계획. (개발 중)',
    'guide_community_coming': '친구 연습 현황, 주간 리더보드, 진도 공유. (기획 중)',
  };
}

// ── 섹션 위젯 ──────────────────────────────────────────
class _GuideSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<_GuideItem> children;
  final ColorScheme cs;

  const _GuideSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outline.withAlpha(40)),
      ),
      color: cs.surface,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((item) => _itemWidget(item, cs)).toList(),
      ),
    );
  }

  Widget _itemWidget(_GuideItem item, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Text(
              item.body,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideItem {
  final String title;
  final String body;
  const _GuideItem({required this.title, required this.body});
}

// ── 開發中卡片 ─────────────────────────────────────────
class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final ColorScheme cs;

  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
