library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// 音叉 Widget - 六角蜂巢排列
class PitchFork extends StatefulWidget {
  final double referenceA4;

  const PitchFork({super.key, required this.referenceA4});

  @override
  State<PitchFork> createState() => _PitchForkState();
}

class _PitchForkState extends State<PitchFork> {
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
      final handle = _activeHandles[note];
      if (handle != null) {
        try { await SoLoud.instance.stop(handle); } catch (_) {}
      }
      setState(() => _activeHandles.remove(note));
      return;
    }
    if (_activeHandles.containsKey(note)) return;
    final source = _sources[note];
    if (source == null) return;
    try {
      final handle = await SoLoud.instance.play(
        source, volume: 0.5, looping: true,
      );
      setState(() => _activeHandles[note] = handle);
    } catch (_) {}
  }

  Future<void> _onNoteUp(String note) async {
    if (_sustainOn) return;
    final handle = _activeHandles[note];
    if (handle == null) return;
    try { await SoLoud.instance.stop(handle); } catch (_) {}
    setState(() => _activeHandles.remove(note));
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
    } else {
      setState(() => _sustainOn = true);
    }
  }

  Future<void> _changeOctave(int delta) async {
    final next = _selectedOctave + delta;
    if (next < 1 || next > 7) return;
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
    setState(() {
      _selectedOctave = next;
      _activeHandles.clear();
    });
    await _loadAllNotes();
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

  @override
  void dispose() {
    for (final h in _activeHandles.values) {
      try { SoLoud.instance.stop(h); } catch (_) {}
    }
    for (final s in _sources.values) {
      try { SoLoud.instance.disposeSource(s); } catch (_) {}
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

        final hexR = (w / 6 / 2) * 0.68;
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

        return Container(
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
                  child: GestureDetector(
                    onTap: _toggleSustain,
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
