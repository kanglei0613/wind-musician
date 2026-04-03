library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/constants/app_constants.dart';

/// 節拍器 Widget
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

  bool _isPlaying = false;
  int _currentBeat = 0;
  Timer? _timer;

  AudioSource? _strongBeat;
  AudioSource? _weakBeat;

  late AnimationController _animController;
  late Animation<double> _beatAnimation;

  Timer? _longPressTimer;
  int _longPressCount = 0;

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
  }

  Future<void> _initAudio() async {
    try {
      // 強拍：高頻短促音
      _strongBeat = await SoLoud.instance.loadWaveform(
        WaveForm.sin, false, 1.0, 0.0,
      );
      SoLoud.instance.setWaveformFreq(_strongBeat!, 880);

      // 弱拍：低頻短促音
      _weakBeat = await SoLoud.instance.loadWaveform(
        WaveForm.sin, false, 1.0, 0.0,
      );
      SoLoud.instance.setWaveformFreq(_weakBeat!, 660);
    } catch (e) {
      debugPrint('Metronome audio init error: $e');
    }
  }

  void _adjustBpm(int delta) {
    setState(() {
      _bpm = (_bpm + delta).clamp(
        AppConstants.metronomeMinBpm,
        AppConstants.metronomeMaxBpm,
      );
    });
    if (_isPlaying) {
      _timer?.cancel();
      _scheduleBeat();
    }
  }

  void _startLongPress(int delta) {
    _longPressCount = 0;
    _longPressTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        _longPressCount++;
        final speed = _longPressCount < 10
            ? 1
            : _longPressCount < 20
                ? 2
                : 5;
        _adjustBpm(delta * speed);
      },
    );
  }

  void _stopLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _longPressCount = 0;
  }

  void _start() {
    setState(() {
      _isPlaying = true;
      _currentBeat = 0;
    });
    _onBeat();
    _scheduleBeat();
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
    });
  }

  void _toggle() {
    if (_isPlaying) {
      _stop();
    } else {
      _start();
    }
  }

  void _scheduleBeat() {
    // BPM 以四分音符為基準，分母不同時換算實際間隔
    // 例如分母=8 → 間隔是四分音符的一半
    final interval = Duration(
      milliseconds: ((60000 / _bpm) * (4 / _denominator)).round(),
    );
    _timer = Timer(interval, () {
      if (!mounted || !_isPlaying) return;
      _onBeat();
      _scheduleBeat();
    });
  }

  void _onBeat() {
    setState(() {
      _currentBeat = (_currentBeat + 1) % _numerator;
    });

    try {
      if (_currentBeat == 0) {
        if (_strongBeat != null) {
          // 播放短促音：設定音量淡出讓聲音短促
          final handle = SoLoud.instance.play(
            _strongBeat!,
            volume: 0.8,
          );
          // 80ms 後淡出停止，產生短促效果
          handle.then((h) {
            Future.delayed(const Duration(milliseconds: 60), () {
              try {
                SoLoud.instance.fadeVolume(
                  h,
                  0,
                  const Duration(milliseconds: 40),
                );
                Future.delayed(const Duration(milliseconds: 50), () {
                  try { SoLoud.instance.stop(h); } catch (_) {}
                });
              } catch (_) {}
            });
          });
        }
      } else {
        if (_weakBeat != null) {
          final handle = SoLoud.instance.play(
            _weakBeat!,
            volume: 0.5,
          );
          handle.then((h) {
            Future.delayed(const Duration(milliseconds: 60), () {
              try {
                SoLoud.instance.fadeVolume(
                  h,
                  0,
                  const Duration(milliseconds: 40),
                );
                Future.delayed(const Duration(milliseconds: 50), () {
                  try { SoLoud.instance.stop(h); } catch (_) {}
                });
              } catch (_) {}
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Beat play error: $e');
    }

    _animController.forward().then((_) {
      if (mounted) _animController.reverse();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _longPressTimer?.cancel();
    _animController.dispose();
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 第一行：速度 + 拍號 + 開始按鈕 ──────
          Row(
            children: [
              _BpmControl(
                bpm: _bpm,
                onAdjust: _adjustBpm,
                onLongPressStart: _startLongPress,
                onLongPressEnd: _stopLongPress,
              ),

              const Spacer(),

              _TimeSignature(
                numerator: _numerator,
                denominator: _denominator,
                onNumeratorChanged: (v) {
                  setState(() {
                    _numerator = v;
                    _currentBeat = 0;
                  });
                },
                onDenominatorChanged: (v) {
                  setState(() {
                    _denominator = v;
                    // 分母改變時重啟計時器套用新速度
                    if (_isPlaying) {
                      _timer?.cancel();
                      _scheduleBeat();
                    }
                  });
                },
              ),

              const Spacer(),

              // 開始/停止按鈕
              GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPlaying
                        ? AppColors.tunerSharp.withAlpha(30)
                        : AppColors.accent1.withAlpha(30),
                    border: Border.all(
                      color: _isPlaying
                          ? AppColors.tunerSharp
                          : AppColors.accent1,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isPlaying
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    size: 24,
                    color: _isPlaying
                        ? AppColors.tunerSharp
                        : AppColors.accent1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── 第二行：節拍指示燈 ────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_numerator, (index) {
                final isActive = _isPlaying && index == _currentBeat;
                final isDownBeat = index == 0;

                return AnimatedBuilder(
                  animation: _beatAnimation,
                  builder: (context, _) {
                    final scale = isActive ? _beatAnimation.value : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isDownBeat ? 14 : 10,
                        height: isDownBeat ? 14 : 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? (isDownBeat
                                  ? AppColors.tunerSharp
                                  : AppColors.accent1)
                              : AppColors.surfaceLight,
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

/// BPM 控制區塊
class _BpmControl extends StatelessWidget {
  final int bpm;
  final ValueChanged<int> onAdjust;
  final ValueChanged<int> onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _BpmControl({
    required this.bpm,
    required this.onAdjust,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PressButton(
          label: '−',
          onTap: () => onAdjust(-1),
          onLongPressStart: () => onLongPressStart(-1),
          onLongPressEnd: onLongPressEnd,
        ),

        SizedBox(
          width: 52,
          child: Column(
            children: [
              Text(
                '$bpm',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'BPM',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
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

/// 長按加速按鈕
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
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 拍號選擇
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScrollPicker(
          value: numerator,
          min: 1,
          max: 32,
          onChanged: onNumeratorChanged,
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '/',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 22,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),

        _ScrollPicker(
          value: denominator,
          min: 1,
          max: 32,
          onChanged: onDenominatorChanged,
        ),
      ],
    );
  }
}

/// 數字上下滑動選擇器
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
    _controller = FixedExtentScrollController(
      initialItem: widget.value - widget.min,
    );
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
    return SizedBox(
      width: 36,
      height: 60,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: 30,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          widget.onChanged(widget.min + index);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.max - widget.min + 1,
          builder: (context, index) {
            final val = widget.min + index;
            final isSelected = val == widget.value;
            return Center(
              child: Text(
                '$val',
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: isSelected ? 20 : 14,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
