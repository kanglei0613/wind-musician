library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../tuner_provider.dart';

/// 調音器主顯示區
/// 顯示音名、頻率、音分偏差指針
class TunerDisplay extends StatelessWidget {
  final TunerState state;

  const TunerDisplay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pitchInfo = state.pitchInfo;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 音名 + 八度顯示（例如 A4、C5）
        // 顏色根據音準狀態變化
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

        // 頻率顯示（保留一位小數）
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

        // 半圓指針，角度對應音分偏差
        _TunerNeedle(centsOff: pitchInfo?.centsOff),

        const SizedBox(height: 16),

        // 音分偏差數值（例如 +5、-12）
        Text(
          pitchInfo != null ? pitchInfo.centsDisplay : '0',
          style: TextStyle(
            fontSize: 16,
            color: _noteColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        // 狀態文字（準確 / 偏高 / 偏低 / 請演奏）
        Text(
          _statusText,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 根據音準狀態決定顯示顏色
  /// 準確 → 綠色，偏高 → 紅色，偏低 → 橙色，無聲音 → 灰色
  Color get _noteColor {
    if (state.pitchInfo == null) return AppColors.textSecondary;
    if (state.pitchInfo!.isInTune) return AppColors.tunerInTune;
    if (state.pitchInfo!.isSharp) return AppColors.tunerSharp;
    return AppColors.tunerFlat;
  }

  /// 音準狀態文字
  String get _statusText {
    if (state.pitchInfo == null) return '請演奏...';
    if (state.pitchInfo!.isInTune) return '準確';
    if (state.pitchInfo!.isSharp) return '偏高';
    return '偏低';
  }
}

/// 半圓指針元件
/// 把音分偏差（-50 到 +50）對應到指針角度（-45 到 +45 度）
class _TunerNeedle extends StatelessWidget {
  /// 音分偏差，null 表示沒有偵測到聲音
  final double? centsOff;

  const _TunerNeedle({this.centsOff});

  @override
  Widget build(BuildContext context) {
    // 把音分偏差轉換成弧度
    // clamp 確保不超出 -1.0 到 1.0 的範圍
    // * π/4（45度）= 最大偏轉角度
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
/// 繪製半圓刻度弧線、中心標記線、旋轉指針、中心圓點
class _NeedlePainter extends CustomPainter {
  /// 指針角度（弧度），0 = 正中間，正數 = 偏右（偏高），負數 = 偏左（偏低）
  final double angle;

  /// 音分偏差，用來決定指針顏色
  final double? centsOff;

  _NeedlePainter({required this.angle, this.centsOff});

  @override
  void paint(Canvas canvas, Size size) {
    // 指針的旋轉中心在底部中央
    final center = Offset(size.width / 2, size.height);

    // ── 刻度弧線 ──────────────────────────────────────
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.9,
        height: size.width * 0.9,
      ),
      // 從左邊（π）畫到右邊（0），順時針半圓
      -math.pi,
      math.pi,
      false,
      Paint()
        ..color = AppColors.surfaceLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── 中心標記線（12點鐘方向的短刻度）────────────────
    canvas.drawLine(
      Offset(size.width / 2, size.height - size.width * 0.45),
      Offset(size.width / 2, size.height - size.width * 0.38),
      Paint()
        ..color = AppColors.textSecondary.withAlpha(128)
        ..strokeWidth = 1.5,
    );

    // ── 指針顏色（根據音準狀態）──────────────────────
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

    // ── 指針 ──────────────────────────────────────────
    // 用三角函數計算旋轉後的終點座標
    // sin(angle) = 水平偏移，cos(angle) = 垂直偏移
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

    // ── 中心圓點 ──────────────────────────────────────
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
