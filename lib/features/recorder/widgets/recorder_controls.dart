import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../recorder_provider.dart';
import 'save_dialog.dart';
import '../../../l10n/app_localizations.dart';

class RecorderControls extends ConsumerStatefulWidget {
  const RecorderControls({super.key});

  @override
  ConsumerState<RecorderControls> createState() =>
      _RecorderControlsState();
}

class _RecorderControlsState extends ConsumerState<RecorderControls> {
  bool _dialogShowing = false;
  ProviderSubscription? _subscription;

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _subscription =
          ref.listenManual(recorderProvider, (prev, next) async {
        if (!mounted) return;

        // ── 儲存對話框 ──────────────────────────────────────────
        if (!_dialogShowing && prev?.pendingPath == null && next.pendingPath != null) {
          _dialogShowing = true;
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const SaveDialog(),
          );
          _dialogShowing = false;
          if (!mounted) return;

          final notifier = ref.read(recorderProvider.notifier);
          if (result != null) {
            notifier.selectFolder(result['folderId'] as String?);
            await notifier.saveRecording(result['name'] as String);
          } else {
            await notifier.discardRecording();
          }
        }

        // ── 權限錯誤 SnackBar ───────────────────────────────────
        // 當 error 從 null 變為有值時顯示 SnackBar
        if (prev?.error == null && next.error != null) {
          if (!mounted) return;
          final isPermanent = next.micPermPermanentlyDenied;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              duration: const Duration(seconds: 6),
              action: isPermanent
                  ? SnackBarAction(
                      label: '前往設定',
                      onPressed: () => openAppSettings(),
                    )
                  : null,
            ),
          );
          // SnackBar 顯示後清除 state 的 error，避免重複顯示
          ref.read(recorderProvider.notifier).clearError();
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final recorderState = ref.watch(recorderProvider);
    final notifier = ref.read(recorderProvider.notifier);
    final isRecording =
        recorderState.status == RecorderStatus.recording;

    return Column(
      children: [
        Text(
          _formatTime(recorderState.elapsedSeconds),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w200,
            color: isRecording
                ? colorScheme.error
                : colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isRecording ? l.recorderStatusRecording : l.recorderStatusIdle,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () async {
            if (isRecording) {
              await notifier.stopRecording();
            } else {
              await notifier.startRecording();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isRecording ? 72 : 80,
            height: isRecording ? 72 : 80,
            decoration: BoxDecoration(
              color: isRecording
                  ? colorScheme.error
                  : colorScheme.primary,
              shape: isRecording
                  ? BoxShape.rectangle
                  : BoxShape.circle,
              borderRadius:
                  isRecording ? BorderRadius.circular(16) : null,
            ),
            child: Icon(
              isRecording ? Icons.stop : Icons.mic,
              color: isRecording
                  ? colorScheme.onError
                  : colorScheme.onPrimary,
              size: 36,
            ),
          ),
        ),
      ],
    );
  }
}