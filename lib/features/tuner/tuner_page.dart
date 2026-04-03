library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_colors.dart';
import 'tuner_provider.dart';
import 'widgets/tuner_display.dart';
import 'widgets/tuner_controls.dart';
import 'widgets/instrument_selector.dart';
import 'widgets/metronome.dart';
import 'widgets/pitch_fork.dart';

/// 調音器頁面
/// 節拍器（固定高度）、調音器（剩餘空間）、音叉（固定高度）
class TunerPage extends ConsumerStatefulWidget {
  const TunerPage({super.key});

  @override
  ConsumerState<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends ConsumerState<TunerPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tunerProvider.notifier).startListening();
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      try {
        ref.read(tunerProvider.notifier).stopListening();
      } catch (_) {}
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tunerState = ref.watch(tunerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              // ── 節拍器（固定高度）────────────────
              const SizedBox(
                height: 110,
                child: Metronome(),
              ),

              const SizedBox(height: 6),

              // ── 調音器（剩餘空間）────────────────
              Expanded(
                child: Column(
                  children: [
                    // 主顯示區
                    Expanded(
                      child: Center(
                        child: TunerDisplay(state: tunerState),
                      ),
                    ),

                    // 錯誤提示
                    if (tunerState.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withAlpha(100),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tunerState.error!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 樂器選擇（左）+ 基準音高（右）
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InstrumentSelector(
                            selectedInstrument: tunerState.selectedInstrument,
                            onSelected: (instrument) {
                              ref
                                  .read(tunerProvider.notifier)
                                  .setInstrument(instrument);
                            },
                          ),
                          TunerControls(
                            referenceA4: tunerState.referenceA4,
                            onReferenceChanged: (value) {
                              ref
                                  .read(tunerProvider.notifier)
                                  .setReferenceA4(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // ── 音叉（固定高度）──────────────────
              SizedBox(
                height: 160,
                child: PitchFork(referenceA4: tunerState.referenceA4),
              ),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}