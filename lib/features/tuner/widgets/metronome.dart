library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

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

  bool _sectionFlash = false;

  AudioSource? _strongBeat;
  AudioSource? _weakBeat;

  late AnimationController _animController;
  late Animation<double> _beatAnimation;

  Timer? _longPressTimer;
  int _longPressCount = 0;

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
          autofocus: true,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '20-320',
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
          ),
          onSubmitted: (value) {
            final bpm = int.tryParse(value);
            if (bpm != null) _adjustBpm(bpm - _bpm);
            Navigator.pop(ctx);
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
              final bpm = int.tryParse(controller.text);
              if (bpm != null) _adjustBpm(bpm - _bpm);
              Navigator.pop(ctx);
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
    _onBeat();
    _scheduleBeat();
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
      _currentSectionIndex = 0;
      _currentMeasure = 0;
      _sectionFlash = false;
    });
  }

  void _toggle() => _isPlaying ? _stop() : _start();

  void _scheduleBeat() {
    final interval = Duration(
      milliseconds: ((60000 / _bpm) * (4 / _activeDenominator)).round(),
    );
    _timer = Timer(interval, () {
      if (!mounted || !_isPlaying) return;
      _onBeat();
      _scheduleBeat();
    });
  }

  void _onBeat() {
    final nextBeat = (_currentBeat + 1) % _activeNumerator;
    final isNewMeasure = nextBeat == 0 && _currentBeat != -1;
    setState(() => _currentBeat = nextBeat);

    if (isNewMeasure && _sectionMode) {
      final section = _sections[_currentSectionIndex];
      final nextMeasure = _currentMeasure + 1;
      if (nextMeasure >= section.measures) {
        final nextSection = (_currentSectionIndex + 1) % _sections.length;
        setState(() {
          _currentSectionIndex = nextSection;
          _currentMeasure = 0;
          _sectionFlash = true;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _sectionFlash = false);
        });
      } else {
        setState(() => _currentMeasure = nextMeasure);
      }
    }

    try {
      final isDown = _currentBeat == 0;
      final source = isDown ? _strongBeat : _weakBeat;
      if (source != null) {
        SoLoud.instance.play(source, volume: isDown ? 0.8 : 0.5).then((h) {
          Future.delayed(const Duration(milliseconds: 60), () {
            try {
              SoLoud.instance.fadeVolume(h, 0, const Duration(milliseconds: 40));
              Future.delayed(const Duration(milliseconds: 50), () {
                try { SoLoud.instance.stop(h); } catch (_) {}
              });
            } catch (_) {}
          });
        });
      }
    } catch (e) {
      debugPrint('Beat play error: $e');
    }

    _animController.forward().then((_) {
      if (mounted) _animController.reverse();
    });
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
                      onNumeratorChanged: (v) => setState(() => _numerator = v),
                      onDenominatorChanged: (v) {
                        setState(() {
                          _denominator = v;
                          if (_isPlaying) {
                            _timer?.cancel();
                            _scheduleBeat();
                          }
                        });
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
        _ScrollPicker(value: denominator, min: 1, max: 32, onChanged: onDenominatorChanged),
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
                      _MiniScrollPicker(
                        value: s.denominator,
                        min: 1,
                        max: 32,
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
