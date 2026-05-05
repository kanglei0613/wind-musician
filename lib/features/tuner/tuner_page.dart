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
import '../../l10n/app_localizations.dart';
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive heights clamped to safe ranges so the layout
            // works on small (SE) and large (tablet) screens alike.
            final metronomeH = (constraints.maxHeight * 0.175).clamp(110.0, 160.0);
            final pitchForkH = ((constraints.maxWidth - 24) * 0.45 + 16).clamp(170.0, 340.0);

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  SizedBox(
                    height: metronomeH,
                    child: const Metronome(),
                  ),

                  const SizedBox(height: 6),

                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: const Alignment(0, -0.25),
                            child: TunerDisplay(state: tunerState),
                          ),
                        ),

                        // 非永久拒絕時顯示簡單錯誤提示（永久拒絕時 provider 已直接開啟設定）
                        if (tunerState.error != null && !tunerState.micPermPermanentlyDenied)
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Terminology button — sits above the Hz controls row
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const TerminologySheet(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: cs.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: cs.primary.withAlpha(80)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.menu_book_rounded,
                                      size: 11, color: cs.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)?.terminologyButton ?? 'Terminology',
                                    style: TextStyle(
                                        color: cs.primary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

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
                    height: pitchForkH,
                    child: PitchFork(referenceA4: tunerState.referenceA4),
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}