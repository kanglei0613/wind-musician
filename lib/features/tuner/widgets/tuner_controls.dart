library;

import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

/// 調音器底部控制區
class TunerControls extends StatefulWidget {
  final double referenceA4;
  final ValueChanged<double> onReferenceChanged;

  const TunerControls({
    super.key,
    required this.referenceA4,
    required this.onReferenceChanged,
  });

  @override
  State<TunerControls> createState() => _TunerControlsState();
}

class _TunerControlsState extends State<TunerControls> {
  void _showReferenceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _ReferenceSheetContent(
        referenceA4: widget.referenceA4,
        onChanged: widget.onReferenceChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showReferenceSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune, size: 11, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'A4 = ${widget.referenceA4.toStringAsFixed(0)} Hz',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceSheetContent extends StatefulWidget {
  final double referenceA4;
  final ValueChanged<double> onChanged;

  const _ReferenceSheetContent({
    required this.referenceA4,
    required this.onChanged,
  });

  @override
  State<_ReferenceSheetContent> createState() => _ReferenceSheetContentState();
}

class _ReferenceSheetContentState extends State<_ReferenceSheetContent> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.referenceA4;
  }

  void _adjust(double delta) {
    setState(() {
      _value = (_value + delta).clamp(400, 480);
    });
    widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '設定基準音高',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdjustButton(
                icon: Icons.remove,
                onTap: () => _adjust(-1),
                onLongPress: () => _adjust(-5),
              ),

              const SizedBox(width: 32),

              Column(
                children: [
                  Text(
                    _value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Hz',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 32),

              _AdjustButton(
                icon: Icons.add,
                onTap: () => _adjust(1),
                onLongPress: () => _adjust(5),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            '常用設定',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [440, 441, 442, 443, 444].map((hz) {
              final isSelected = _value == hz.toDouble();
              return GestureDetector(
                onTap: () {
                  setState(() => _value = hz.toDouble());
                  widget.onChanged(_value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent1.withAlpha(40)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent1
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '$hz',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.accent1
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent1,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '完成',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AdjustButton({
    required this.icon,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}
