library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/music_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../tuner_provider.dart';

class TunerDisplay extends StatelessWidget {
  final TunerState state;

  const TunerDisplay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pitchInfo = state.pitchInfo;
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Critical: note name display — use FittedBox to prevent overflow
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            pitchInfo?.noteOctave ?? '--',
            maxLines: 1,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: _noteColor(cs),
              letterSpacing: -2,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          pitchInfo != null
              ? '${pitchInfo.frequency.toStringAsFixed(1)} Hz'
              : '-- Hz',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w300,
          ),
        ),

        const SizedBox(height: 20),

        _TunerNeedle(centsOff: pitchInfo?.centsOff),

        const SizedBox(height: 8),

        Text(
          pitchInfo != null ? pitchInfo.centsDisplay : '0',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            color: _noteColor(cs),
            fontWeight: FontWeight.w500,
          ),
        ),

        if (pitchInfo != null) ...[
          const SizedBox(height: 4),
          Text(
            _statusText(pitchInfo, l),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Color _noteColor(ColorScheme cs) {
    if (state.pitchInfo == null) return cs.onSurfaceVariant;
    if (state.pitchInfo!.isInTune) return AppColors.tunerInTune;
    if (state.pitchInfo!.isSharp) return AppColors.tunerSharp;
    return AppColors.tunerFlat;
  }

  String _statusText(PitchInfo pitchInfo, AppLocalizations l) {
    if (pitchInfo.isInTune) return l.tunerInTune;
    if (pitchInfo.isSharp) return l.tunerSharp;
    return l.tunerFlat;
  }
}

class _TunerNeedle extends StatelessWidget {
  final double? centsOff;

  const _TunerNeedle({this.centsOff});

  @override
  Widget build(BuildContext context) {
    final angle = ((centsOff ?? 0) / 50).clamp(-1.0, 1.0) * (math.pi / 4);
    final cs = Theme.of(context).colorScheme;

    // 根據偏差程度動態調整指針顏色亮度
    Color needleColor;
    if (centsOff == null) {
      needleColor = cs.onSurfaceVariant;
    } else {
      final abs = centsOff!.abs();
      if (abs <= 10) {
        needleColor = AppColors.tunerInTune;
      } else {
        // 偏差越大顏色越深（用 primary 色系）
        final ratio = ((abs - 10) / 40).clamp(0.0, 1.0);
        needleColor = Color.lerp(cs.primary, cs.primary.withAlpha(255), ratio)!;
        // 偏高比偏低深
        if (centsOff! > 10) {
          needleColor = AppColors.tunerSharp;
        } else {
          needleColor = AppColors.tunerFlat;
        }
      }
    }

    return SizedBox(
      width: 220,
      height: 90,
      child: CustomPaint(
        painter: _NeedlePainter(
          angle: angle,
          needleColor: needleColor,
          arcColor: cs.surfaceContainerHighest,
          markerColor: cs.onSurfaceVariant.withAlpha(128),
        ),
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  final double angle;
  final Color needleColor;
  final Color arcColor;
  final Color markerColor;

  _NeedlePainter({
    required this.angle,
    required this.needleColor,
    required this.arcColor,
    required this.markerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);

    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.9,
        height: size.width * 0.9,
      ),
      -math.pi,
      math.pi,
      false,
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawLine(
      Offset(size.width / 2, size.height - size.width * 0.45),
      Offset(size.width / 2, size.height - size.width * 0.38),
      Paint()
        ..color = markerColor
        ..strokeWidth = 1.5,
    );

    final needleLength = size.width * 0.42;
    final endX = center.dx + needleLength * math.sin(angle);
    final endY = center.dy - needleLength * math.cos(angle);

    canvas.drawLine(
      center,
      Offset(endX, endY),
      Paint()
        ..color = needleColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 5, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(_NeedlePainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.needleColor != needleColor;
}