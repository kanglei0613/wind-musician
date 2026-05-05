library;

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/min_touch_target.dart';

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
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _showReferenceSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.surfaceContainerHighest),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 11, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'A4 = ${widget.referenceA4.toStringAsFixed(0)} Hz',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurfaceVariant,
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
      // BC-008：clamp 範圍改用 AppConstants，與調音器設定保持一致
      _value = (_value + delta).clamp(
        AppConstants.tunerMinPitch,
        AppConstants.tunerMaxPitch,
      );
    });
    widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.tunerReference,
            style: TextStyle(
              color: cs.onSurface,
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _value.toStringAsFixed(0),
                      maxLines: 1,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Hz',
                    maxLines: 1,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
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

          Text(
            l.tunerReferenceCommon,
            style: TextStyle(
              color: cs.onSurfaceVariant,
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
                        ? cs.primary.withAlpha(40)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? cs.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '$hz',
                    style: TextStyle(
                      color: isSelected ? cs.primary : cs.onSurface,
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
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                l.tunerDone,
                style: const TextStyle(
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
    final cs = Theme.of(context).colorScheme;
    // Wrap in 48×48 touch target; keep visual circle at 44×44
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: cs.onSurface, size: 20),
          ),
        ),
      ),
    );
  }
}