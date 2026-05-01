library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tuner_provider.dart';
import 'widgets/tuner_display.dart';
import 'widgets/tuner_controls.dart';
import 'widgets/instrument_selector.dart';
import 'widgets/metronome.dart';
import 'widgets/pitch_fork.dart';
import '../../features/terminology/terminology_page.dart';
import '../../shared/theme/app_colors.dart';

class TunerPage extends ConsumerStatefulWidget {
  const TunerPage({super.key});

  @override
  ConsumerState<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends ConsumerState<TunerPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(tunerProvider.notifier).startListening();
    });
  }

  /// App 生命週期變化：切到背景停止麥克風，回到前景重啟
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        Future.microtask(() {
          if (mounted) ref.read(tunerProvider.notifier).startListening();
        });
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        Future.microtask(() {
          try { ref.read(tunerProvider.notifier).stopListening(); } catch (_) {}
        });
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const TerminologySheet(),
          );
        },
        backgroundColor: cs.primary,
        mini: true,
        child: const Icon(
          Icons.menu_book_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              const SizedBox(
                height: 110,
                child: Metronome(),
              ),

              const SizedBox(height: 6),

              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: TunerDisplay(state: tunerState),
                      ),
                    ),

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
                            Expanded(
                              child: Text(
                                tunerState.error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            // 只有在 iOS 不再顯示系統對話框時才顯示「前往設定」按鈕
                            if (tunerState.micPermPermanentlyDenied) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => openAppSettings(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '前往設定',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

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

              SizedBox(
                height: 150,
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