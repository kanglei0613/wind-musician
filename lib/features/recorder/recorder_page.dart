import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recorder_provider.dart';
import 'widgets/recorder_controls.dart';
import 'widgets/recording_list.dart';

class RecorderPage extends ConsumerStatefulWidget {
  const RecorderPage({super.key});

  @override
  ConsumerState<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends ConsumerState<RecorderPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // 錄音控制區
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.onSurface.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const RecorderControls(),
          ),

          // 搜尋欄 + 新增資料夾
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: '搜尋資料夾',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.5),
                        size: 20,
                      ),
                      suffixIcon: Consumer(
                        builder: (_, ref, _) {
                          final query = ref.watch(searchQueryProvider);
                          return query.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(searchQueryProvider
                                            .notifier)
                                        .state = '';
                                  },
                                );
                        },
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    onChanged: (v) {
                      ref.read(searchQueryProvider.notifier).state = v;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () =>
                      _showAddFolderDialog(context),
                  icon: Icon(
                    Icons.create_new_folder_outlined,
                    color: colorScheme.primary,
                  ),
                  tooltip: '新增資料夾',
                ),
              ],
            ),
          ),

          // 錄音列表
          const Expanded(child: RecordingList()),
        ],
      ),
    );
  }

  Future<void> _showAddFolderDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('新增資料夾',
            style: TextStyle(color: colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: '資料夾名稱',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
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
            child: Text('建立',
                style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref.read(foldersProvider.notifier).add(name);
    }
  }
}
