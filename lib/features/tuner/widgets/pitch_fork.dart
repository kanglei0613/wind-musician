library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// 音叉 Widget - 六角蜂巢排列
class PitchFork extends StatefulWidget {
  final double referenceA4;

  const PitchFork({super.key, required this.referenceA4});

  @override
  State<PitchFork> createState() => _PitchForkState();
}

class _PitchForkState extends State<PitchFork> {
  /// Android platform channel for audio focus + WakeLock management.
  /// On iOS this is a no-op (AVAudioSession is already configured by the app).
  static const _pitchForkChannel =
      MethodChannel('com.kanglei.muklang/pitch_fork');

  static const _row0 = ['C', 'C#', 'D', 'D#', 'E'];
  static const _row1notes = ['B', 'F'];
  static const _row2 = ['A#', 'A', 'G#', 'G', 'F#'];

  static const _noteIndices = {
    'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5,
    'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11,
  };

  final Map<String, SoundHandle> _activeHandles = {};
  final Map<String, AudioSource> _sources = {};
  int _selectedOctave = 4;
  bool _sustainOn = false;
  // BC-PF1: guard against rapid octave-change race condition
  bool _isChangingOctave = false;

  // ── 滑動手勢支援 ──────────────────────────────────────────────────────────
  /// 每個音名格子的中心座標（在 LayoutBuilder 裡更新，不用 setState）
  final Map<String, Offset> _noteCenters = {};
  /// 當前六角格的邏輯半徑，用於判斷手指是否在格子範圍內
  double _layoutHexR = 0.0;
  /// 目前滑動手勢正在播放的音名（非持續音模式下 panEnd 時停止）
  String? _slideNote;

  // ── 旋轉手勢（八度）─────────────────────────────────────────────────────
  /// Widget 中心座標（LayoutBuilder 裡更新）
  Offset _widgetCenter = Offset.zero;
  /// 上一次 pan 位置（計算角度用）
  Offset? _prevPanPos;
  /// 累計旋轉角度（度）
  double _rotateAccum = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAllNotes();
  }

  List<String> get _allNotes => [..._row0, ..._row1notes, ..._row2];

  Future<void> _loadAllNotes() async {
    for (final note in _allNotes) {
      try {
        final source = await SoLoud.instance.loadWaveform(
          WaveForm.sin, false, 1.0, 0.0,
        );
        SoLoud.instance.setWaveformFreq(
          source,
          _calculateFrequency(note, _selectedOctave),
        );
        _sources[note] = source;
      } catch (e) {
        debugPrint('Load $note error: $e');
      }
    }
  }

  double _calculateFrequency(String note, int octave) {
    final noteIndex = _noteIndices[note] ?? 9;
    final midiNote = (octave + 1) * 12 + noteIndex;
    return widget.referenceA4 * math.pow(2, (midiNote - 69) / 12);
  }

  Future<void> _onNoteDown(String note) async {
    if (_sustainOn && _activeHandles.containsKey(note)) {
      // Sustain 模式下再按同一音 → 淡出後停止
      final handle = _activeHandles[note];
      setState(() => _activeHandles.remove(note));
      // 最後一音停止時釋放音訊焦點（Android）
      if (_activeHandles.isEmpty) {
        _pitchForkChannel.invokeMethod<void>('releaseFocus').ignore();
      }
      if (handle != null) {
        try {
          SoLoud.instance.fadeVolume(handle, 0, const Duration(milliseconds: 30));
          await Future.delayed(const Duration(milliseconds: 35));
          SoLoud.instance.stop(handle);
        } catch (_) {}
      }
      return;
    }
    if (_activeHandles.containsKey(note)) return;
    final source = _sources[note];
    if (source == null) return;
    // 第一個音開始播放時請求音訊焦點 + WakeLock（Android）
    if (_activeHandles.isEmpty) {
      _pitchForkChannel.invokeMethod<void>('requestFocus').ignore();
    }
    try {
      // 以音量 0 開始播放，立即淡入避免咔嗒聲
      final handle = await SoLoud.instance.play(
        source, volume: 0.0, looping: true,
      );
      SoLoud.instance.fadeVolume(handle, 0.9, const Duration(milliseconds: 15));
      setState(() => _activeHandles[note] = handle);
    } catch (_) {}
  }

  Future<void> _onNoteUp(String note) async {
    if (_sustainOn) return;
    final handle = _activeHandles[note];
    if (handle == null) return;
    // 先從 map 移除（UI 立即反應），再淡出停止
    setState(() => _activeHandles.remove(note));
    // 最後一音停止時釋放音訊焦點 + WakeLock（Android）
    if (_activeHandles.isEmpty) {
      _pitchForkChannel.invokeMethod<void>('releaseFocus').ignore();
    }
    try {
      SoLoud.instance.fadeVolume(handle, 0, const Duration(milliseconds: 40));
      await Future.delayed(const Duration(milliseconds: 45));
      SoLoud.instance.stop(handle);
    } catch (_) {}
  }

  Future<void> _toggleSustain() async {
    if (_sustainOn) {
      for (final note in _activeHandles.keys.toList()) {
        final handle = _activeHandles[note];
        if (handle != null) {
          try { await SoLoud.instance.stop(handle); } catch (_) {}
        }
      }
      setState(() {
        _activeHandles.clear();
        _sustainOn = false;
      });
      // Sustain 關閉清除所有音符時釋放音訊焦點（Android）
      _pitchForkChannel.invokeMethod<void>('releaseFocus').ignore();
    } else {
      setState(() => _sustainOn = true);
    }
  }

  Future<void> _changeOctave(int delta) async {
    // BC-PF1: prevent concurrent _changeOctave calls from corrupting _sources
    if (_isChangingOctave) return;
    final next = _selectedOctave + delta;
    if (next < 1 || next > 7) return;
    _isChangingOctave = true;
    try {
      for (final note in _activeHandles.keys.toList()) {
        final handle = _activeHandles[note];
        if (handle != null) {
          try { await SoLoud.instance.stop(handle); } catch (_) {}
        }
      }
      for (final source in _sources.values) {
        try { SoLoud.instance.disposeSource(source); } catch (_) {}
      }
      _sources.clear();
      if (mounted) {
        setState(() {
          _selectedOctave = next;
          _activeHandles.clear();
        });
      }
      await _loadAllNotes();
    } finally {
      _isChangingOctave = false;
    }
  }

  @override
  void didUpdateWidget(PitchFork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.referenceA4 != widget.referenceA4) {
      for (final entry in _sources.entries) {
        try {
          SoLoud.instance.setWaveformFreq(
            entry.value,
            _calculateFrequency(entry.key, _selectedOctave),
          );
        } catch (_) {}
      }
    }
  }

  // ── 滑動手勢處理 ──────────────────────────────────────────────────────────

  /// 根據手指位置找最近的音名格子（距離超過 1.5×hexR 則返回 null）
  String? _findNoteAtPosition(Offset position) {
    if (_noteCenters.isEmpty || _layoutHexR == 0) return null;
    String? nearest;
    double minDist = double.infinity;
    for (final entry in _noteCenters.entries) {
      final dist = (position - entry.value).distance;
      if (dist < minDist) {
        minDist = dist;
        nearest = entry.key;
      }
    }
    return minDist < _layoutHexR * 1.5 ? nearest : null;
  }

  /// 強制停止指定音名（不受 sustain 模式影響，用於滑動中間換格子）
  Future<void> _stopSlideNote(String note) async {
    final handle = _activeHandles[note];
    if (handle == null) return;
    setState(() => _activeHandles.remove(note));
    try {
      SoLoud.instance.fadeVolume(handle, 0, const Duration(milliseconds: 30));
      await Future.delayed(const Duration(milliseconds: 35));
      SoLoud.instance.stop(handle);
    } catch (_) {}
  }

  void _onPanStart(DragStartDetails details) {
    _prevPanPos = details.localPosition;
    _rotateAccum = 0.0;

    // 只記錄起始音名，供滑音追蹤用
    // 音符按下由各 Listener.onPointerDown 負責，此處不重複觸發
    // 避免 sustain 模式下 Listener 移除音符後 pan 又立即重新加回
    _slideNote = _findNoteAtPosition(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final cur = details.localPosition;

    // ── 旋轉角度追蹤 ────────────────────────────────────────────────
    if (_prevPanPos != null && _widgetCenter != Offset.zero) {
      final prev = _prevPanPos! - _widgetCenter;
      final next = cur - _widgetCenter;
      // cross product 符號決定方向，dot product 加 atan2 取角度
      final cross = prev.dx * next.dy - prev.dy * next.dx;
      final dot   = prev.dx * next.dx + prev.dy * next.dy;
      final delta = math.atan2(cross, dot) * 180 / math.pi;
      _rotateAccum += delta;
      if (_rotateAccum >= 360) {
        _rotateAccum -= 360;
        _changeOctave(1);   // 順時針一圈 → oct +1
      } else if (_rotateAccum <= -360) {
        _rotateAccum += 360;
        _changeOctave(-1);  // 逆時針一圈 → oct -1
      }
    }
    _prevPanPos = cur;

    // ── 滑動換音 ────────────────────────────────────────────────────
    final note = _findNoteAtPosition(cur);
    if (note == null || note == _slideNote) return;
    final prev = _slideNote;
    _slideNote = note;
    if (prev != null) _stopSlideNote(prev);
    _onNoteDown(note);
  }

  void _onPanEnd(DragEndDetails details) {
    _prevPanPos = null;
    _rotateAccum = 0.0;
    if (_slideNote != null) _onNoteUp(_slideNote!);
    _slideNote = null;
  }

  void _onPanCancel() {
    _prevPanPos = null;
    _rotateAccum = 0.0;
    if (_slideNote != null && !_sustainOn) _onNoteUp(_slideNote!);
    _slideNote = null;
  }

  @override
  void dispose() {
    for (final h in _activeHandles.values) {
      try { SoLoud.instance.stop(h); } catch (_) {}
    }
    for (final s in _sources.values) {
      try { SoLoud.instance.disposeSource(s); } catch (_) {}
    }
    // Widget 銷毀時確保音訊焦點已釋放（Android），防止 WakeLock 洩漏
    if (_activeHandles.isNotEmpty) {
      _pitchForkChannel.invokeMethod<void>('releaseFocus').ignore();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final hexR = (w / 6 / 2) * 1.05;
        final hexW = hexR * math.sqrt(3);
        final hexH = hexR * 2;
        final colStep = hexW * 1.05;
        final rowStep = hexH * 0.78;

        final totalH = rowStep * 2 + hexH;
        final startY = (h - totalH) / 2 + hexH / 2;
        final y0 = startY;
        final y1 = startY + rowStep;
        final y2 = startY + rowStep * 2;

        final totalW5 = colStep * 4 + hexW;
        final x0Start = (w - totalW5) / 2 + hexW / 2;
        final totalW6 = colStep * 5 + hexW;
        final x1Start = (w - totalW6) / 2 + hexW / 2;

        // 更新格子中心座標與 widget 中心（供手勢 hit-testing 使用；不呼叫 setState）
        _widgetCenter = Offset(w / 2, h / 2);
        _layoutHexR = hexR;
        _noteCenters.clear();
        // 排 0：C C# D D# E
        for (int i = 0; i < _row0.length; i++) {
          _noteCenters[_row0[i]] = Offset(x0Start + i * colStep, y0);
        }
        // 排 1：B ... F
        _noteCenters['B'] = Offset(x1Start, y1);
        _noteCenters['F'] = Offset(x1Start + colStep * 5, y1);
        // 排 2：A# A G# G F#
        for (int i = 0; i < _row2.length; i++) {
          _noteCenters[_row2[i]] = Offset(x0Start + i * colStep, y2);
        }

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // 排0：C C# D D# E
              ..._row0.asMap().entries.map((e) {
                final note = e.value;
                final x = x0Start + e.key * colStep;
                return _HexNote(
                  note: note, x: x, y: y0, hexR: hexR,
                  isPressed: _activeHandles.containsKey(note),
                  onDown: () => _onNoteDown(note),
                  onUp: () => _onNoteUp(note),
                );
              }),

              // B
              _HexNote(
                note: 'B', x: x1Start, y: y1, hexR: hexR,
                isPressed: _activeHandles.containsKey('B'),
                onDown: () => _onNoteDown('B'),
                onUp: () => _onNoteUp('B'),
              ),

              // 減少八度
              Positioned(
                left: x1Start + colStep - hexW / 2,
                top: y1 - hexH / 2,
                child: _HexControl(
                  hexR: hexR, isActive: false,
                  child: Listener(
                    onPointerDown: (_) => _changeOctave(-1),
                    child: Center(
                      child: Text('−', style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 20,
                        fontWeight: FontWeight.w300,
                      )),
                    ),
                  ),
                ),
              ),

              // 八度顯示
              Positioned(
                left: x1Start + colStep * 2 - hexW / 2,
                top: y1 - hexH / 2,
                child: _HexControl(
                  hexR: hexR, isActive: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_selectedOctave', style: TextStyle(
                          color: cs.onSurface, fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )),
                        Text('oct', style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 8,
                        )),
                      ],
                    ),
                  ),
                ),
              ),

              // 增加八度
              Positioned(
                left: x1Start + colStep * 3 - hexW / 2,
                top: y1 - hexH / 2,
                child: _HexControl(
                  hexR: hexR, isActive: false,
                  child: Listener(
                    onPointerDown: (_) => _changeOctave(1),
                    child: Center(
                      child: Text('+', style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 20,
                        fontWeight: FontWeight.w300,
                      )),
                    ),
                  ),
                ),
              ),

              // Sustain
              Positioned(
                left: x1Start + colStep * 4 - hexW / 2,
                top: y1 - hexH / 2,
                child: _HexControl(
                  hexR: hexR, isActive: _sustainOn,
                  // 使用 Listener 繞過手勢 arena，避免與外層 pan GestureDetector 競爭
                  // GestureDetector(onTap) 在外層有 onPan 時容易被搶走手勢所有權
                  child: Listener(
                    onPointerUp: (_) => _toggleSustain(),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sustainOn ? Icons.lock : Icons.lock_open,
                            size: hexR * 0.55,
                            color: _sustainOn ? Colors.white : cs.onSurfaceVariant,
                          ),
                          Text('sustain', style: TextStyle(
                            color: _sustainOn ? Colors.white : cs.onSurfaceVariant,
                            fontSize: 7,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // F
              _HexNote(
                note: 'F', x: x1Start + colStep * 5, y: y1, hexR: hexR,
                isPressed: _activeHandles.containsKey('F'),
                onDown: () => _onNoteDown('F'),
                onUp: () => _onNoteUp('F'),
              ),

              // 排2：A# A G# G F#
              ..._row2.asMap().entries.map((e) {
                final note = e.value;
                final x = x0Start + e.key * colStep;
                return _HexNote(
                  note: note, x: x, y: y2, hexR: hexR,
                  isPressed: _activeHandles.containsKey(note),
                  onDown: () => _onNoteDown(note),
                  onUp: () => _onNoteUp(note),
                );
              }),
            ],
          ),
          ), // GestureDetector
        );
      },
    );
  }
}

/// 六角形音名按鍵
class _HexNote extends StatelessWidget {
  final String note;
  final double x;
  final double y;
  final double hexR;
  final bool isPressed;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _HexNote({
    required this.note, required this.x, required this.y,
    required this.hexR, required this.isPressed,
    required this.onDown, required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hexW = hexR * math.sqrt(3);
    final hexH = hexR * 2;
    final isSharp = note.contains('#');

    return Positioned(
      left: x - hexW / 2,
      top: y - hexH / 2,
      child: Listener(
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: hexW,
          height: hexH,
          child: CustomPaint(
            painter: _HexPainter(
              isPressed: isPressed,
              isSharp: isSharp,
              pressedColor: cs.primary,
              sharpColor: cs.surfaceContainerHighest,
              normalColor: cs.surface,
              borderColor: isPressed ? cs.primary : cs.surfaceContainerHighest,
            ),
            child: Center(
              child: Text(
                note,
                style: TextStyle(
                  color: isPressed
                      ? Colors.white
                      : isSharp
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                  fontSize: hexR * 0.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 六角形控制格
class _HexControl extends StatelessWidget {
  final double hexR;
  final bool isActive;
  final Widget child;

  const _HexControl({
    required this.hexR, required this.isActive, required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hexW = hexR * math.sqrt(3);
    final hexH = hexR * 2;

    return SizedBox(
      width: hexW,
      height: hexH,
      child: CustomPaint(
        painter: _HexPainter(
          isPressed: isActive,
          isSharp: !isActive,
          pressedColor: cs.primary,
          sharpColor: cs.surfaceContainerHighest,
          normalColor: cs.surface,
          borderColor: isActive ? cs.primary : cs.surfaceContainerHighest,
        ),
        child: child,
      ),
    );
  }
}

/// 六角形繪製
class _HexPainter extends CustomPainter {
  final bool isPressed;
  final bool isSharp;
  final Color pressedColor;
  final Color sharpColor;
  final Color normalColor;
  final Color borderColor;

  _HexPainter({
    required this.isPressed,
    required this.isSharp,
    required this.pressedColor,
    required this.sharpColor,
    required this.normalColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.height / 2 * 0.95;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = isPressed ? pressedColor : isSharp ? sharpColor : normalColor,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isPressed ? 2 : 1,
    );
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.isPressed != isPressed || old.isSharp != isSharp;
}
