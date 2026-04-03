library;

import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/music_utils.dart';

/// 樂器選擇器
/// 點擊後從底部滑出，依調性分組顯示所有樂器
class InstrumentSelector extends StatelessWidget {
  /// 目前選擇的樂器
  final Instrument selectedInstrument;

  /// 選擇樂器後的回呼
  final ValueChanged<Instrument> onSelected;

  const InstrumentSelector({
    super.key,
    required this.selectedInstrument,
    required this.onSelected,
  });

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _InstrumentSheetContent(
        selectedInstrument: selectedInstrument,
        onSelected: (instrument) {
          onSelected(instrument);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.music_note,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              selectedInstrument.name,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            // 顯示調性標籤（例如 Bb、Eb）
            if (selectedInstrument.key != 'C')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent1.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  selectedInstrument.key,
                  style: const TextStyle(
                    color: AppColors.accent1,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// BottomSheet 內容
class _InstrumentSheetContent extends StatelessWidget {
  final Instrument selectedInstrument;
  final ValueChanged<Instrument> onSelected;

  const _InstrumentSheetContent({
    required this.selectedInstrument,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = Instruments.grouped;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // 拖曳指示條
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 標題
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '選擇樂器',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 樂器列表
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 調性分組標題
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // 該調性的樂器列表
                    ...entry.value.map((instrument) {
                      final isSelected =
                          instrument.name == selectedInstrument.name;

                      return GestureDetector(
                        onTap: () => onSelected(instrument),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent1.withAlpha(30)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent1
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              // 樂器名稱（中文）
                              Expanded(
                                child: Text(
                                  instrument.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.accent1
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),

                              // 英文名稱
                              Text(
                                instrument.nameEn,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(width: 8),

                              // 選中圖示
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.accent1,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
