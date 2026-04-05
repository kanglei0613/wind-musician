import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recording.dart';
import '../recorder_provider.dart';

class RecordingItem extends ConsumerWidget {
  final Recording recording;

  const RecordingItem({super.key, required this.recording});

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDurationFromMs(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final playingId = ref.watch(audioPlayerProvider);
    final isPlaying = playingId == recording.id;
    final playerNotifier = ref.read(audioPlayerProvider.notifier);

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: isPlaying
                  ? colorScheme.primary
                  : colorScheme.onSurface,
              size: 40,
            ),
            onPressed: () => playerNotifier.play(recording),
          ),
          title: Text(
            recording.name,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${_formatDate(recording.createdAt)}  ·  ${_formatDuration(recording.durationSeconds)}',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          trailing: PopupMenuButton<String>(
            color: colorScheme.surface,
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onSelected: (value) async {
              switch (value) {
                case 'rename':
                  await _showRenameDialog(context, ref);
                case 'move':
                  await _showMoveDialog(context, ref);
                case 'share':
                  await ref
                      .read(recorderProvider.notifier)
                      .shareRecording(recording);
                case 'delete':
                  await _showDeleteDialog(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'rename',
                child: _menuRow(
                    Icons.edit, '重新命名', colorScheme.onSurface),
              ),
              PopupMenuItem(
                value: 'move',
                child: _menuRow(Icons.drive_file_move, '移至資料夾',
                    colorScheme.onSurface),
              ),
              PopupMenuItem(
                value: 'share',
                child: _menuRow(
                    Icons.share, '匯出 / 分享', colorScheme.onSurface),
              ),
              PopupMenuItem(
                value: 'delete',
                child: _menuRow(
                    Icons.delete, '刪除', colorScheme.error),
              ),
            ],
          ),
        ),

        // 展開播放進度條
        if (isPlaying)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: StreamBuilder<Duration>(
              stream: playerNotifier.positionStream,
              builder: (context, posSnap) {
                return StreamBuilder<Duration?>(
                  stream: playerNotifier.durationStream,
                  builder: (context, durSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final duration = durSnap.data ??
                        Duration(seconds: recording.durationSeconds);
                    final progress = duration.inMilliseconds > 0
                        ? (position.inMilliseconds /
                                duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape:
                                const RoundSliderOverlayShape(
                                    overlayRadius: 14),
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor: colorScheme.primary
                                .withValues(alpha: 0.2),
                            thumbColor: colorScheme.primary,
                            overlayColor: colorScheme.primary
                                .withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: progress,
                            onChanged: (v) {
                              final target = Duration(
                                milliseconds: (v *
                                        duration.inMilliseconds)
                                    .round(),
                              );
                              playerNotifier.seekTo(target);
                            },
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatDurationFromMs(position),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDurationFromMs(duration),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

        Divider(
          height: 1,
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ],
    );
  }

  Widget _menuRow(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(color: color)),
    ]);
  }

  Future<void> _showRenameDialog(
      BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: recording.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('重新命名',
            style: TextStyle(color: colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colorScheme.primary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(null),
            child: Text('取消',
                style: TextStyle(color: colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true)
                .pop(controller.text.trim()),
            child: Text('確認',
                style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await ref
          .read(recordingsProvider.notifier)
          .rename(recording.id, newName);
    }
  }

  Future<void> _showMoveDialog(
      BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    final folders = ref.read(foldersProvider).valueOrNull ?? [];
    String? selectedId = recording.folderId;

    final result = await showDialog<String?>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('移至資料夾',
              style: TextStyle(color: colorScheme.onSurface)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  selected: selectedId == null,
                  selectedColor: colorScheme.primary,
                  leading: Icon(
                    selectedId == null
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selectedId == null
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  title: Text(
                    '未分類',
                    style: TextStyle(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  onTap: () => setState(() => selectedId = null),
                ),
                ...folders.map(
                  (f) => ListTile(
                    dense: true,
                    selected: selectedId == f.id,
                    selectedColor: colorScheme.primary,
                    leading: Icon(
                      selectedId == f.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selectedId == f.id
                          ? colorScheme.primary
                          : colorScheme.onSurface
                              .withValues(alpha: 0.4),
                      size: 20,
                    ),
                    title: Text(
                      f.name,
                      style:
                          TextStyle(color: colorScheme.onSurface),
                    ),
                    onTap: () => setState(() => selectedId = f.id),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(null),
              child: Text('取消',
                  style: TextStyle(color: colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true)
                  .pop(selectedId ?? ''),
              child: Text('確認',
                  style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await ref.read(recordingsProvider.notifier).moveToFolder(
            recording.id,
            result.isEmpty ? null : result,
          );
    }
  }

  Future<void> _showDeleteDialog(
      BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('刪除錄音',
            style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          '確定要刪除「${recording.name}」？此操作無法復原。',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: Text('取消',
                style: TextStyle(color: colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            child: Text('刪除',
                style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(recordingsProvider.notifier)
          .delete(recording.id);
    }
  }
}
