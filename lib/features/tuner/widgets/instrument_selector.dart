library;

import 'package:flutter/material.dart';
import '../../../shared/utils/music_utils.dart';
import '../../../l10n/app_localizations.dart';

class InstrumentSelector extends StatelessWidget {
  final Instrument selectedInstrument;
  final ValueChanged<Instrument> onSelected;

  const InstrumentSelector({
    super.key,
    required this.selectedInstrument,
    required this.onSelected,
  });

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final localizedName = _localizedName(l, selectedInstrument);

    return GestureDetector(
      onTap: () => _showSheet(context),
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
            Icon(Icons.music_note, size: 11, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              localizedName,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
            if (selectedInstrument.key != 'C') ...[
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  selectedInstrument.key,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 根據 localizationKey 取得對應語言的樂器名稱
String _localizedName(AppLocalizations l, Instrument instrument) {
  switch (instrument.localizationKey) {
    case 'instrumentConcertPitch': return l.instrumentConcertPitch;
    case 'instrumentFlute': return l.instrumentFlute;
    case 'instrumentOboe': return l.instrumentOboe;
    case 'instrumentBassoon': return l.instrumentBassoon;
    case 'instrumentTrombone': return l.instrumentTrombone;
    case 'instrumentTuba': return l.instrumentTuba;
    case 'instrumentTrumpet': return l.instrumentTrumpet;
    case 'instrumentClarinet': return l.instrumentClarinet;
    case 'instrumentTenorSax': return l.instrumentTenorSax;
    case 'instrumentEuphonium': return l.instrumentEuphonium;
    case 'instrumentBassClarinet': return l.instrumentBassClarinet;
    case 'instrumentAltoSax': return l.instrumentAltoSax;
    case 'instrumentBaritoneSax': return l.instrumentBaritoneSax;
    case 'instrumentEbClarinet': return l.instrumentEbClarinet;
    case 'instrumentFrenchHorn': return l.instrumentFrenchHorn;
    case 'instrumentEnglishHorn': return l.instrumentEnglishHorn;
    default: return instrument.name;
  }
}

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
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l.tunerSelectInstrument,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ...entry.value.map((instrument) {
                      final isSelected =
                          instrument.localizationKey == selectedInstrument.localizationKey;
                      final name = _localizedName(l, instrument);

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
                                ? cs.primary.withAlpha(30)
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? cs.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? cs.primary
                                        : cs.onSurface,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              Text(
                                instrument.nameEn,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: cs.primary,
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
