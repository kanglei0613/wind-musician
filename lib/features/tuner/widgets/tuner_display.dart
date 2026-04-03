library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/music_utils.dart';
import '../tuner_provider.dart';

/// 調音器主顯示區
class TunerDisplay extends StatelessWidget {
  final TunerState state;

  const TunerDisplay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pitchInfo = state.pitchInfo;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 音名 + 八度
        Text(
          pitchInfo?.noteOctave ?? '--',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: _noteColor,
            letterSpacing: -2,
          ),
        ),

        const SizedBox(height: 8),

        // 頻率
        Text(
          pitchInfo != null
              ? '${pitchInfo.frequency.toStringAsFixed(1)} Hz'
              : '-- Hz',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w300,
          ),
        ),

        const SizedBox(height: 48),

        // 半圓指針
        _TunerNeedle(centsOff: pitchInfo?.centsOff),

        const SizedBox(height: 16),

        // 音分偏差數值
        Text(
          pitchInfo != null ? pitchInfo.centsDisplay : '0',
          style: TextStyle(
            fontSize: 16,
            color: _noteColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        // 音準狀態文字（只有偵測到聲音才顯示）
        if (pitchInfo != null) ...[
          const SizedBox(height: 4),
          Text(
            _statusText(pitchInfo),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Color get _noteColor {
    if (state.pitchInfo == null) return AppColors.textSecondary;
    if (state.pitchInfo!.isInTune) return AppColors.tunerInTune;
    if (state.pitchInfo!.isSharp) return AppColors.tunerSharp;
    return AppColors.tunerFlat;
  }

  String _statusText(PitchInfo pitchInfo) {
    if (pitchInfo.isInTune) return '準確';
    if (pitchInfo.isSharp) return '偏高';
    return '偏低';
  }
}

/// 半圓指針元件
class _TunerNeedle extends StatelessWidget {
  final double? centsOff;

  const _TunerNeedle({this.centsOff});

  @override
  Widget build(BuildContext context) {
    final angle = ((centsOff ?? 0) / 50).clamp(-1.0, 1.0) * (math.pi / 4);

    return SizedBox(
      width: 220,
      height: 90,
      child: CustomPaint(
        painter: _NeedlePainter(
          angle: angle,
          centsOff: centsOff,
        ),
      ),
    );
  }
}

/// 指針 CustomPainter
class _NeedlePainter extends CustomPainter {
  final double angle;
  final double? centsOff;

  _NeedlePainter({required this.angle, this.centsOff});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);

    // 刻度弧線
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
        ..color = AppColors.surfaceLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 中心標記線
    canvas.drawLine(
      Offset(size.width / 2, size.height - size.width * 0.45),
      Offset(size.width / 2, size.height - size.width * 0.38),
      Paint()
        ..color = AppColors.textSecondary.withAlpha(128)
        ..strokeWidth = 1.5,
    );

    // 指針顏色
    Color needleColor = AppColors.textSecondary;
    if (centsOff != null) {
      if (centsOff!.abs() <= 10) {
        needleColor = AppColors.tunerInTune;
      } else if (centsOff! > 10) {
        needleColor = AppColors.tunerSharp;
      } else {
        needleColor = AppColors.tunerFlat;
      }
    }

    // 指針
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

    // 中心圓點
    canvas.drawCircle(
      center,
      5,
      Paint()..color = needleColor,
    );
  }

  @override
  bool shouldRepaint(_NeedlePainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.centsOff != centsOff;
}
