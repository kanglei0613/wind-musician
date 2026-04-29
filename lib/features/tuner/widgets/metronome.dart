library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/services/native_metronome_channel.dart';
import '../../../shared/services/audio_focus_channel.dart';

class _Section {
  int numerator;
  int denominator;
  int measures;

  _Section({
    this.numerator = 4,
    this.denominator = 4,
    this.measures = 4,
  });

  _Section copy() => _Section(
        numerator: numerator,
        denominator: denominator,
        measures: measures,
      );
}

class Metronome extends StatefulWidget {
  const Metronome({super.key});

  @override
  State<Metronome> createState() => _MetronomeState();
}

class _MetronomeState extends State<Metronome>
    with SingleTickerProviderStateMixin {

  int _bpm = AppConstants.metronomeDefaultBpm;
  int _numerator = 4;
  int _denominator = 4;

  bool _sectionMode = false;
  List<_Section> _sections = [
    _Section(numerator: 4, denominator: 4, measures: 4),
    _Section(numerator: 6, denominator: 8, measures: 2),
  ];

  int _currentSectionIndex = 0;
  int _currentMeasure = 0;

  bool _isPlaying = false;
  int _currentBeat = 0;
  Timer? _timer;

  /// 絕對時間補償（iOS / Dart 路徑）：記錄播放起始時間與已排程的拍數
  /// 每拍的實際延遲 = (預定時間 - 目前時間)，避免 Timer 累積漂移
  /// Android 路徑由 MetronomeEngine (Kotlin) 負責，此變數不使用
  DateTime? _playStartTime;
  int _scheduledBeatIndex = 0;

  bool _sectionFlash = false;

  // ── Android Platform Channel ─────────────────────────────────────────────
  /// Android 原生節拍器 Channel（Singleton），iOS 上不會呼叫
  final _nativeChannel = NativeMetronomeChannel();

  /// 訂閱 Native 拍點事件（Android 專用）
  StreamSubscription<void>? _nativeBeatSub;

  /// 訂閱 AudioFocus 變化（Android 專用），用於處理螢幕錄影等搶焦點的情況
  StreamSubscription<AudioFocusState>? _focusSub;

  AudioSource? _strongBeat;
  AudioSource? _weakBeat;

  late AnimationController _animController;
  late Animation<double> _beatAnimation;

  Timer? _longPressTimer;
  int _longPressCount = 0;

  // ── 音色 / 音高變體 ──────────────────────────────────────────────────────
  /// 目前選擇的音色：'SINE' | 'WOODBLOCK' | 'STICK_CLICK' | 'SNARE'
  String _soundType = 'SINE';
  /// 目前選擇的音高變體（1~5，3 為預設）
  int _pitchVariant = 3;

  int get _activeNumerator =>
      _sectionMode ? _sections[_currentSectionIndex].numerator : _numerator;
  int get _activeDenominator =>
      _sectionMode ? _sections[_currentSectionIndex].denominator : _denominator;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _beatAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _initAudio();
    _loadSoundPrefs();

    // Android：訂閱 AudioFocus 變化事件
    // 當螢幕錄影工具等搶走 AudioFocus 時，自動暫停 UI 狀態（音效由 Native 已停止）
    if (Platform.isAndroid) {
      _focusSub = AudioFocusChannel().onFocusChange.listen((state) {
        if (!mounted) return;
        switch (state) {
          case AudioFocusState.lost:
          case AudioFocusState.lostTransient:
            // 焦點被搶走 → 同步更新 Flutter UI 為停止狀態
            if (_isPlaying) {
              setState(() {
                _isPlaying = false;
                _currentBeat = 0;
                _currentSectionIndex = 0;
                _currentMeasure = 0;
                _sectionFlash = false;
              });
              _nativeBeatSub?.cancel();
              _nativeBeatSub = null;
              // 顯示提示（需要在下一幀後取得 context）
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('音訊焦點被其他 App 搶走，節拍器已暫停'),
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
            }
          case AudioFocusState.gained:
            // 焦點恢復（來電結束等），不自動重啟，由用戶手動按播放
            break;
          default:
            break;
        }
      });
    }
  }

  Future<void> _initAudio() async {
    try {
      _strongBeat = await SoLoud.instance.loadWaveform(
        WaveForm.sin, false, 1.0, 0.0,
      );
      SoLoud.instance.setWaveformFreq(_strongBeat!, 880);
      _weakBeat = await SoLoud.instance.loadWaveform(
        WaveForm.sin, false, 1.0, 0.0,
      );
      SoLoud.instance.setWaveformFreq(_weakBeat!, 660);
    } catch (e) {
      debugPrint('Metronome audio init error: $e');
    }
  }

  // ── 音色 / 音高持久化 ────────────────────────────────────────────────────

  /// 從 SharedPreferences 讀取上次選擇的音色與音高，並同步至 Native 引擎。
  Future<void> _loadSoundPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSound   = prefs.getString(AppConstants.keyMetronomeSoundType) ?? 'SINE';
    final savedVariant = prefs.getInt(AppConstants.keyMetronomePitchVariant) ?? 3;
    if (!mounted) return;
    setState(() {
      _soundType    = savedSound;
      _pitchVariant = savedVariant;
    });
    if (Platform.isAndroid || Platform.isIOS) {
      await _nativeChannel.setSoundType(savedSound);
      await _nativeChannel.setPitchVariant(savedVariant);
    }
  }

  /// 切換音色，通知 Native 並存入 SharedPreferences。
  Future<void> _setSoundType(String type) async {
    setState(() => _soundType = type);
    if (Platform.isAndroid || Platform.isIOS) await _nativeChannel.setSoundType(type);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyMetronomeSoundType, type);
  }

  /// 切換音高變體（1~5），通知 Native 並存入 SharedPreferences。
  Future<void> _setPitchVariant(int variant) async {
    setState(() => _pitchVariant = variant);
    if (Platform.isAndroid || Platform.isIOS) await _nativeChannel.setPitchVariant(variant);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyMetronomePitchVariant, variant);
  }

  void _adjustBpm(int delta) {
    setState(() {
      _bpm = (_bpm + delta).clamp(
        AppConstants.metronomeMinBpm,
        AppConstants.metronomeMaxBpm,
      );
      // Bug 4：BPM 改變時重置拍位，確保下一個 onBeat 回呼算出 beat=0（強拍）
      // 等同於 _start() 的初始狀態，_onBeat 內 nextBeat = (-1+1)%n = 0
      if (_isPlaying) _currentBeat = -1;
    });
    if (_isPlaying) {
      if (Platform.isAndroid || Platform.isIOS) {
        // Android / iOS：通知 Native 更新 BPM，引擎內部重置時間基準
        _nativeChannel.updateBpm(_bpm);
      } else {
        // 桌面 / Web Dart 路徑：重置時間基準，重新排程
        _timer?.cancel();
        _playStartTime = DateTime.now();
        _scheduledBeatIndex = 0;
        _scheduleNextBeat();
      }
    }
  }

  void _startLongPress(int delta) {
    _longPressCount = 0;
    _longPressTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        _longPressCount++;
        final speed = _longPressCount < 10 ? 1 : _longPressCount < 20 ? 2 : 5;
        _adjustBpm(delta * speed);
      },
    );
  }

  void _stopLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _longPressCount = 0;
  }

  void _showBpmDialog(BuildContext context) {
    final controller = TextEditingController(text: '$_bpm');
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    // 套用並在必要時夾值，顯示提示
    void applyValue(String raw) {
      if (raw.isEmpty) return; // 空白 → 保留目前 BPM
      final parsed = int.tryParse(raw);
      if (parsed == null) return;
      final clamped = parsed.clamp(
        AppConstants.metronomeMinBpm,
        AppConstants.metronomeMaxBpm,
      );
      _adjustBpm(clamped - _bpm);
      if (parsed != clamped && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.metronomeBpmClamped(clamped)),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text(
          l.metronomeInputBpm,
          style: TextStyle(color: cs.onSurface, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          // 只允許輸入數字，防止非法字元
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '${AppConstants.metronomeMinBpm}–${AppConstants.metronomeMaxBpm}',
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
          ),
          onSubmitted: (value) {
            Navigator.pop(ctx);
            applyValue(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.tunerCancel,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text;
              Navigator.pop(ctx);
              applyValue(value);
            },
            child: Text(
              l.tunerDone,
              style: TextStyle(color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _start() {
    setState(() {
      _isPlaying = true;
      _currentBeat = -1;
      _currentSectionIndex = 0;
      _currentMeasure = 0;
      _sectionFlash = false;
    });

    if (Platform.isAndroid || Platform.isIOS) {
      // Android / iOS 路徑：先訂閱 onBeat Stream，再啟動原生引擎
      // 注意：必須先 listen 再 start，否則可能漏掉 Native 發出的第一拍事件
      _nativeBeatSub?.cancel();
      _nativeBeatSub = _nativeChannel.onBeat.listen((_) {
        if (mounted && _isPlaying) _onBeat();
      });
      _nativeChannel.start(
        bpm: _bpm,
        numerator: _activeNumerator,
        denominator: _activeDenominator,
      );
      // ⚠️ 不在此呼叫 _onBeat()：Native 會透過 stream 發出第一拍事件
    } else {
      // 桌面 / Web Dart 路徑：使用 Dart Timer + SoLoud
      _playStartTime = DateTime.now();
      _scheduledBeatIndex = 0;
      _onBeat();
      _scheduleNextBeat();
    }
  }

  void _stop() {
    if (Platform.isAndroid || Platform.isIOS) {
      // Android / iOS 路徑：通知 Native 停止引擎
      _nativeChannel.stop();
      _nativeBeatSub?.cancel();
      _nativeBeatSub = null;
    } else {
      // 桌面 / Web Dart 路徑：取消 Dart Timer
      _timer?.cancel();
      _playStartTime = null;
      _scheduledBeatIndex = 0;
    }

    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
      _currentSectionIndex = 0;
      _currentMeasure = 0;
      _sectionFlash = false;
    });
  }

  void _toggle() => _isPlaying ? _stop() : _start();

  /// 絕對時間補償排程：計算每拍的「應發時間」，減去實際耗費時間
  /// 解決 Timer 鏈式呼叫導致的累積漂移問題
  void _scheduleNextBeat() {
    if (!_isPlaying || !mounted || _playStartTime == null) return;
    _scheduledBeatIndex++;
    final intervalMs =
        (60000.0 / _bpm) * (4.0 / _activeDenominator);
    final targetMs = (_scheduledBeatIndex * intervalMs).round();
    final elapsedMs =
        DateTime.now().difference(_playStartTime!).inMilliseconds;
    final delayMs = (targetMs - elapsedMs).clamp(0, intervalMs.round() * 2);
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || !_isPlaying) return;
      _onBeat();
      _scheduleNextBeat();
    });
  }

  void _onBeat() {
    // BC-012：section 切換與 onBeat 之間的 race condition 保護。
    // _sections 可能在播放中被用戶修改（段落設定 sheet），需確保索引合法。
    if (_sectionMode) {
      if (_sections.isEmpty) return;
      if (_currentSectionIndex >= _sections.length) {
        _currentSectionIndex = 0;
        _currentMeasure = 0;
      }
      // 確保 _currentBeat 未超出當前 section 的拍數
      if (_currentBeat >= _sections[_currentSectionIndex].numerator) {
        _currentBeat = 0;
      }
    }

    final nextBeat = (_currentBeat + 1) % _activeNumerator;
    final isNewMeasure = nextBeat == 0 && _currentBeat != -1;
    setState(() => _currentBeat = nextBeat);

    if (isNewMeasure && _sectionMode) {
      // 再次確認索引合法（setState 後 _sections 長度可能又變動）
      if (_sections.isEmpty) return;
      if (_currentSectionIndex >= _sections.length) {
        _currentSectionIndex = 0;
        _currentMeasure = 0;
      }
      final section = _sections[_currentSectionIndex];
      final nextMeasure = _currentMeasure + 1;
      if (nextMeasure >= section.measures) {
        final nextSection = (_currentSectionIndex + 1) % _sections.length;
        setState(() {
          _currentSectionIndex = nextSection;
          _currentMeasure = 0;
          _sectionFlash = true;
        });

        if (Platform.isAndroid || Platform.isIOS) {
          // Android / iOS：通知 Native 更新拍號（引擎內部重置時間基準）
          final newSection = _sections[nextSection];
          _nativeChannel.updateTimeSig(newSection.numerator, newSection.denominator);
        } else {
          // 桌面 / Web Dart 路徑：重置時間基準，新拍號的 interval 從這一刻起算
          _playStartTime = DateTime.now();
          _scheduledBeatIndex = 0;
        }

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _sectionFlash = false);
        });
      } else {
        setState(() => _currentMeasure = nextMeasure);
      }
    }

    // 音效播放：
    //   Android → 由 MetronomeEngine (Native) 負責，Flutter 不重複播放
    //   iOS / Dart → SoLoud 播放 + attack/decay envelope
    if (!Platform.isAndroid) {
      try {
        final isDown = _currentBeat == 0;
        final source = isDown ? _strongBeat : _weakBeat;
        if (source != null) {
          // 以音量 0 起播，短暫淡入避免爆音（click）；再快速淡出，模擬打擊聲 envelope
          SoLoud.instance.play(source, volume: 0.0).then((h) {
            try {
              final peak = isDown ? 0.85 : 0.55;
              // Attack: 5ms 淡入到峰值
              SoLoud.instance.fadeVolume(h, peak, const Duration(milliseconds: 5));
              // Decay: 55ms 後開始淡出
              Future.delayed(const Duration(milliseconds: 55), () {
                try {
                  SoLoud.instance.fadeVolume(h, 0, const Duration(milliseconds: 40));
                  Future.delayed(const Duration(milliseconds: 45), () {
                    try { SoLoud.instance.stop(h); } catch (_) {}
                  });
                } catch (_) {}
              });
            } catch (_) {}
          });
        }
      } catch (e) {
        debugPrint('Beat play error: $e');
      }
    }

    _animController.forward().then((_) {
      if (mounted) _animController.reverse();
    });
  }

  void _showSoundSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final cs = Theme.of(ctx).colorScheme;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 拖曳把手
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 音色
                  Text(AppLocalizations.of(ctx)!.metronomeSound, style: TextStyle(
                    color: cs.onSurfaceVariant, fontSize: 12,
                    fontWeight: FontWeight.w500,
                  )),
                  const SizedBox(height: 8),
                  Row(
                    children: _kSoundKeys.map((key) {
                      final l10n = AppLocalizations.of(ctx)!;
                      final label = {
                        'SINE':        l10n.metronomeSoundSine,
                        'WOODBLOCK':   l10n.metronomeSoundWoodblock,
                        'STICK_CLICK': l10n.metronomeSoundStickClick,
                        'SNARE':       l10n.metronomeSoundSnare,
                      }[key] ?? key;
                      final isSelected = key == _soundType;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _setSoundType(key);
                            setLocal(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary.withAlpha(45)
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? cs.primary : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? cs.primary : cs.onSurface,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // 音高
                  Text(AppLocalizations.of(ctx)!.metronomePitch, style: TextStyle(
                    color: cs.onSurfaceVariant, fontSize: 12,
                    fontWeight: FontWeight.w500,
                  )),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final variant = i + 1;
                      final isSelected = variant == _pitchVariant;
                      final freqLabel = _kPitchLabels[variant] ?? '';
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _setPitchVariant(variant);
                            setLocal(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary.withAlpha(45)
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? cs.primary : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$variant',
                                  style: TextStyle(
                                    color: isSelected ? cs.primary : cs.onSurface,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  freqLabel,
                                  style: TextStyle(
                                    color: isSelected
                                        ? cs.primary.withAlpha(200)
                                        : cs.onSurfaceVariant,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SectionSheet(
        sections: _sections.map((s) => s.copy()).toList(),
        sectionMode: _sectionMode,
        onChanged: (sections, mode) {
          setState(() {
            _sections = sections;
            _sectionMode = mode;
            if (_isPlaying) _stop();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _longPressTimer?.cancel();
    _animController.dispose();

    // Android 路徑：取消 Native 訂閱並確保服務停止
    _nativeBeatSub?.cancel();
    _focusSub?.cancel();
    if (Platform.isAndroid && _isPlaying) {
      _nativeChannel.stop();
    }

    // iOS / Dart 路徑：釋放 SoLoud AudioSource
    if (_strongBeat != null) {
      try { SoLoud.instance.disposeSource(_strongBeat!); } catch (_) {}
    }
    if (_weakBeat != null) {
      try { SoLoud.instance.disposeSource(_weakBeat!); } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _BpmControl(
                bpm: _bpm,
                onAdjust: _adjustBpm,
                onLongPressStart: _startLongPress,
                onLongPressEnd: _stopLongPress,
                onTapBpm: () => _showBpmDialog(context),
              ),

              const Spacer(),

              _sectionMode
                  ? _SectionTimeDisplay(
                      section: _sections[_currentSectionIndex],
                      index: _currentSectionIndex,
                      total: _sections.length,
                    )
                  : _TimeSignature(
                      numerator: _numerator,
                      denominator: _denominator,
                      onNumeratorChanged: (v) {
                        setState(() {
                          _numerator = v;
                          // 切換拍號後重置到第一拍，避免畫面與聲音對不上
                          if (_isPlaying) _currentBeat = -1;
                        });
                        if (_isPlaying && (Platform.isAndroid || Platform.isIOS)) {
                          _nativeChannel.updateTimeSig(v, _denominator);
                        }
                      },
                      onDenominatorChanged: (v) {
                        setState(() {
                          _denominator = v;
                          // 切換拍號後重置到第一拍，避免畫面與聲音對不上
                          if (_isPlaying) _currentBeat = -1;
                        });
                        if (_isPlaying) {
                          if (Platform.isAndroid || Platform.isIOS) {
                            // Android / iOS：通知 Native 更新拍號
                            _nativeChannel.updateTimeSig(_numerator, v);
                          } else {
                            // 桌面 / Web Dart：重置時間基準
                            _timer?.cancel();
                            _playStartTime = DateTime.now();
                            _scheduledBeatIndex = 0;
                            _scheduleNextBeat();
                          }
                        }
                      },
                    ),

              const Spacer(),

              GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPlaying
                        ? AppColors.tunerSharp.withAlpha(30)
                        : cs.primary.withAlpha(30),
                    border: Border.all(
                      color: _isPlaying ? AppColors.tunerSharp : cs.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 22,
                    color: _isPlaying ? AppColors.tunerSharp : cs.primary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              GestureDetector(
                onTap: _showSoundSheet,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              GestureDetector(
                onTap: _showSectionSheet,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _sectionMode
                        ? cs.primary.withAlpha(40)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _sectionMode ? cs.primary : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    Icons.segment,
                    size: 16,
                    color: _sectionMode ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          if (_sectionMode && _isPlaying) ...[
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: _sectionFlash
                    ? cs.primary.withAlpha(60)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${l.metronomeSectionLabel} ${_currentSectionIndex + 1}/${_sections.length} · ${_currentMeasure + 1} ${l.metronomeMeasure}',
                style: TextStyle(
                  color: _sectionFlash ? cs.primary : cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: _sectionFlash
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],

          const SizedBox(height: 4),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_activeNumerator, (index) {
                final isActive = _isPlaying && index == _currentBeat;
                final isDownBeat = index == 0;

                return AnimatedBuilder(
                  animation: _beatAnimation,
                  builder: (context, _) {
                    final scale = isActive ? _beatAnimation.value : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isDownBeat ? 14 : 10,
                        height: isDownBeat ? 14 : 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _sectionFlash
                              ? cs.primary
                              : isActive
                                  ? (isDownBeat
                                      ? AppColors.tunerSharp
                                      : cs.primary)
                                  : cs.surfaceContainerHighest,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTimeDisplay extends StatelessWidget {
  final _Section section;
  final int index;
  final int total;

  const _SectionTimeDisplay({
    required this.section,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${section.numerator}/${section.denominator}',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '×${section.measures} ${l.metronomeMeasure}',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _BpmControl extends StatelessWidget {
  final int bpm;
  final ValueChanged<int> onAdjust;
  final ValueChanged<int> onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onTapBpm;

  const _BpmControl({
    required this.bpm,
    required this.onAdjust,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onTapBpm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PressButton(
          label: '−',
          onTap: () => onAdjust(-1),
          onLongPressStart: () => onLongPressStart(-1),
          onLongPressEnd: onLongPressEnd,
        ),
        GestureDetector(
          onTap: onTapBpm,
          child: SizedBox(
            width: 52,
            child: Column(
              children: [
                Text(
                  '$bpm',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'BPM',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
        _PressButton(
          label: '+',
          onTap: () => onAdjust(1),
          onLongPressStart: () => onLongPressStart(1),
          onLongPressEnd: onLongPressEnd,
        ),
      ],
    );
  }
}

class _PressButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _PressButton({
    required this.label,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      // 手指滑出按鈕範圍時手勢被取消，同樣要停止 timer
      onLongPressCancel: onLongPressEnd,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 分母只允許正規的音樂記譜值
const List<int> _kDenominatorValues = [1, 2, 4, 8, 16, 32];

class _TimeSignature extends StatelessWidget {
  final int numerator;
  final int denominator;
  final ValueChanged<int> onNumeratorChanged;
  final ValueChanged<int> onDenominatorChanged;

  const _TimeSignature({
    required this.numerator,
    required this.denominator,
    required this.onNumeratorChanged,
    required this.onDenominatorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScrollPicker(value: numerator, min: 1, max: 32, onChanged: onNumeratorChanged),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '/',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 22,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        // 分母限定為正規音樂值，避免用戶選出無意義的拍號
        _ListScrollPicker(
          value: denominator,
          values: _kDenominatorValues,
          onChanged: onDenominatorChanged,
        ),
      ],
    );
  }
}

class _ScrollPicker extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _ScrollPicker({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_ScrollPicker> createState() => _ScrollPickerState();
}

class _ScrollPickerState extends State<_ScrollPicker> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.value - widget.min);
  }

  @override
  void didUpdateWidget(_ScrollPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.jumpToItem(widget.value - widget.min);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      height: 60,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: 30,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => widget.onChanged(widget.min + index),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.max - widget.min + 1,
          builder: (context, index) {
            final val = widget.min + index;
            final isSelected = val == widget.value;
            return Center(
              child: Text(
                '$val',
                style: TextStyle(
                  color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
                  fontSize: isSelected ? 20 : 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 從固定清單選值的滾輪，用於分母等只有特定合法值的欄位
class _ListScrollPicker extends StatefulWidget {
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;

  const _ListScrollPicker({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  State<_ListScrollPicker> createState() => _ListScrollPickerState();
}

class _ListScrollPickerState extends State<_ListScrollPicker> {
  late FixedExtentScrollController _controller;

  int get _currentIndex {
    final idx = widget.values.indexOf(widget.value);
    return idx >= 0 ? idx : 0;
  }

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _currentIndex);
  }

  @override
  void didUpdateWidget(_ListScrollPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.jumpToItem(_currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      height: 60,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: 30,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => widget.onChanged(widget.values[index]),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.values.length,
          builder: (context, index) {
            final val = widget.values[index];
            final isSelected = val == widget.value;
            return Center(
              child: Text(
                '$val',
                style: TextStyle(
                  color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
                  fontSize: isSelected ? 20 : 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionSheet extends StatefulWidget {
  final List<_Section> sections;
  final bool sectionMode;
  final void Function(List<_Section>, bool) onChanged;

  const _SectionSheet({
    required this.sections,
    required this.sectionMode,
    required this.onChanged,
  });

  @override
  State<_SectionSheet> createState() => _SectionSheetState();
}

class _SectionSheetState extends State<_SectionSheet> {
  late List<_Section> _sections;
  late bool _sectionMode;

  @override
  void initState() {
    super.initState();
    _sections = widget.sections;
    _sectionMode = widget.sectionMode;
  }

  void _save() {
    widget.onChanged(_sections, _sectionMode);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  l.metronomeSection,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _sectionMode,
                  onChanged: (v) => setState(() => _sectionMode = v),
                  thumbColor: WidgetStateProperty.all(cs.primary),
                  trackColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? cs.primary.withAlpha(120)
                        : cs.surfaceContainerHighest,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_sectionMode) ...[
              ..._sections.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${l.metronomeSectionLabel} ${i + 1}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _MiniScrollPicker(
                        value: s.numerator,
                        min: 1,
                        max: 32,
                        onChanged: (v) => setState(() => s.numerator = v),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '/',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _MiniListScrollPicker(
                        value: s.denominator,
                        values: _kDenominatorValues,
                        onChanged: (v) => setState(() => s.denominator = v),
                      ),
                      const SizedBox(width: 12),
                      Text('×',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 14)),
                      const SizedBox(width: 8),
                      _MiniScrollPicker(
                        value: s.measures,
                        min: 1,
                        max: 32,
                        onChanged: (v) => setState(() => s.measures = v),
                      ),
                      const SizedBox(width: 4),
                      Text(l.metronomeMeasure,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12)),
                      const Spacer(),
                      if (_sections.length > 1)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _sections.removeAt(i)),
                          child: Icon(Icons.close,
                              size: 16, color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                );
              }),

              GestureDetector(
                onTap: () => setState(() => _sections.add(_Section())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        l.metronomeSectionAdd,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              Text(
                l.metronomeSectionEnable,
                style:
                    TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _save,
                child: Text(l.tunerDone,
                    style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniScrollPicker extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _MiniScrollPicker({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_MiniScrollPicker> createState() => _MiniScrollPickerState();
}

class _MiniScrollPickerState extends State<_MiniScrollPicker> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
        initialItem: widget.value - widget.min);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 32,
      height: 48,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: 24,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) =>
            widget.onChanged(widget.min + index),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.max - widget.min + 1,
          builder: (context, index) {
            final val = widget.min + index;
            final isSelected = val == widget.value;
            return Center(
              child: Text(
                '$val',
                style: TextStyle(
                  color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
                  fontSize: isSelected ? 16 : 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 段落設定用的固定清單迷你滾輪（分母專用）
class _MiniListScrollPicker extends StatefulWidget {
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;

  const _MiniListScrollPicker({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  State<_MiniListScrollPicker> createState() => _MiniListScrollPickerState();
}

class _MiniListScrollPickerState extends State<_MiniListScrollPicker> {
  late FixedExtentScrollController _controller;

  int get _currentIndex {
    final idx = widget.values.indexOf(widget.value);
    return idx >= 0 ? idx : 0;
  }

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _currentIndex);
  }

  @override
  void didUpdateWidget(_MiniListScrollPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.jumpToItem(_currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 32,
      height: 48,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: 24,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => widget.onChanged(widget.values[index]),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.values.length,
          builder: (context, index) {
            final val = widget.values[index];
            final isSelected = val == widget.value;
            return Center(
              child: Text(
                '$val',
                style: TextStyle(
                  color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
                  fontSize: isSelected ? 16 : 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  音色選擇器（底部 Sheet 使用）
// ═══════════════════════════════════════════════════════════════════════════

/// 音色選項 key 清單
const _kSoundKeys = ['SINE', 'WOODBLOCK', 'STICK_CLICK', 'SNARE'];

/// 各音高變體的強拍頻率標籤（顯示在底部 Sheet 數字下方）
const _kPitchLabels = {
  1: '500Hz',
  2: '700Hz',
  3: '1kHz',
  4: '1.4kHz',
  5: '2kHz',
};
