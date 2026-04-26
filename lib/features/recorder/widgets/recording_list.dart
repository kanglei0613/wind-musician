import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../recorder_provider.dart';
import 'folder_item.dart';
import 'recording_item.dart';
import '../../../l10n/app_localizations.dart';

class RecordingList extends ConsumerWidget {
  const RecordingList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final recordingsAsync = ref.watch(recordingsProvider);
    final foldersAsync = ref.watch(foldersProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

    final recordings = recordingsAsync.valueOrNull ?? [];
    final folders = foldersAsync.valueOrNull ?? [];

    // 有效資料夾 id 集合（資料夾刪除後過濾孤兒錄音）
    final validFolderIds = folders.map((f) => f.id).toSet();

    // 只顯示有效的錄音（未分類 or 屬於現有資料夾）
    final validRecordings = recordings
        .where((r) =>
            r.folderId == null || validFolderIds.contains(r.folderId))
        .toList();

    // 搜尋過濾
    final filteredFolders = searchQuery.isEmpty
        ? folders
        : folders
            .where((f) => f.name.toLowerCase().contains(searchQuery))
            .toList();

    final filteredRecordings = searchQuery.isEmpty
        ? validRecordings
        : validRecordings
            .where((r) => r.name.toLowerCase().contains(searchQuery))
            .toList();

    // 未分類錄音
    final unclassified = filteredRecordings
        .where((r) => r.folderId == null)
        .toList();


    final isLoading =
        recordingsAsync.isLoading || foldersAsync.isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isEmpty =
        filteredFolders.isEmpty && filteredRecordings.isEmpty;

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searchQuery.isEmpty
                  ? Icons.mic_none
                  : Icons.search_off,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty ? l.recorderNoRecordings : l.recorderNoResults,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        // 資料夾區塊
        ...filteredFolders.map((folder) {
          final folderRecordings = validRecordings
              .where((r) => r.folderId == folder.id)
              .toList();
          return FolderItem(
            folder: folder,
            recordings: folderRecordings,
          );
        }),

        // 未分類錄音
        if (unclassified.isNotEmpty) ...[
          if (filteredFolders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l.recorderUncategorized,
                style: TextStyle(
                  color:
                      colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ...unclassified
              .map((r) => RecordingItem(recording: r)),
        ],
      ],
    );
  }
}
