import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recording.dart';
import '../models/recording_folder.dart';
import '../recorder_provider.dart';
import 'recording_item.dart';
import '../../../l10n/app_localizations.dart';

class FolderItem extends ConsumerStatefulWidget {
  final RecordingFolder folder;
  final List<Recording> recordings;

  const FolderItem({
    super.key,
    required this.folder,
    required this.recordings,
  });

  @override
  ConsumerState<FolderItem> createState() => _FolderItemState();
}

class _FolderItemState extends ConsumerState<FolderItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final count = widget.recordings.length;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.folder_open : Icons.folder,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  l.recorderFolderCount(count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  color: colorScheme.surface,
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.6),
                    size: 20,
                  ),
                  onSelected: (value) async {
                    switch (value) {
                      case 'rename':
                        if (mounted) await _showRenameDialog(context);
                      case 'delete':
                        if (mounted) await _showDeleteDialog(context);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(children: [
                        Icon(Icons.edit,
                            color: colorScheme.onSurface, size: 18),
                        const SizedBox(width: 12),
                        Text(l.commonRename,
                            style: TextStyle(
                                color: colorScheme.onSurface)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete,
                            color: colorScheme.error, size: 18),
                        const SizedBox(width: 12),
                        Text(l.recorderFolderDeleteTitle,
                            style:
                                TextStyle(color: colorScheme.error)),
                      ]),
                    ),
                  ],
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color:
                      colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        if (_expanded)
          Container(
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            child: count == 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      l.recorderFolderEmpty,
                      style: TextStyle(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    children: widget.recordings
                        .map((r) => RecordingItem(recording: r))
                        .toList(),
                  ),
          ),

        Divider(
          height: 1,
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ],
    );
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final controller =
        TextEditingController(text: widget.folder.name);
    final notifier = ref.read(foldersProvider.notifier);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(l.recorderFolderRenameTitle,
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
            child: Text(l.commonCancel,
                style: TextStyle(color: colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true)
                .pop(controller.text.trim()),
            child: Text(l.commonConfirm,
                style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );

    controller.dispose();
    if (newName != null && newName.isNotEmpty && mounted) {
      await notifier.rename(widget.folder.id, newName);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final notifier = ref.read(foldersProvider.notifier);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(l.recorderFolderDeleteTitle,
            style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          l.recorderFolderDeleteBody(widget.folder.name),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: Text(l.commonCancel,
                style: TextStyle(color: colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            child: Text(l.commonDelete,
                style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await notifier.delete(widget.folder.id);
    }
  }
}
