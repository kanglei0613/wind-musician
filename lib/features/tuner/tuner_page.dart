library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_colors.dart';
import 'tuner_provider.dart';
import 'widgets/tuner_display.dart';
import 'widgets/tuner_controls.dart';
import 'widgets/instrument_selector.dart';

/// 調音器頁面
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
        title: const Text('調音器'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── 主顯示區 ──────────────────────────────
            Expanded(
              child: Center(
                child: TunerDisplay(state: tunerState),
              ),
            ),

            // ── 錯誤提示 ──────────────────────────────
            if (tunerState.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
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
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tunerState.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ── 底部控制列（樂器選擇 + 基準音高）────
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 樂器選擇器
                  InstrumentSelector(
                    selectedInstrument: tunerState.selectedInstrument,
                    onSelected: (instrument) {
                      ref
                          .read(tunerProvider.notifier)
                          .setInstrument(instrument);
                    },
                  ),

                  const SizedBox(width: 12),

                  // 基準音高調整
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
    );
  }
}
