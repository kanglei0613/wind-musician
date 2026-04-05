import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../recorder_provider.dart';

class SaveDialog extends ConsumerStatefulWidget {
  const SaveDialog({super.key});

  @override
  ConsumerState<SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends ConsumerState<SaveDialog> {
  final _controller = TextEditingController();
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = ref.read(recorderProvider).selectedFolderId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final folders = ref.watch(foldersProvider).valueOrNull ?? [];

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text('儲存錄音',
          style: TextStyle(color: colorScheme.onSurface)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: '輸入錄音名稱',
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
          const SizedBox(height: 20),
          Text(
            '儲存至資料夾',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedFolderId,
                isExpanded: true,
                dropdownColor: colorScheme.surface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                style: TextStyle(color: colorScheme.onSurface),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      '未分類',
                      style: TextStyle(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  ...folders.map(
                    (f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedFolderId = value);
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(null),
          child: Text('捨棄',
              style: TextStyle(color: colorScheme.error)),
        ),
        TextButton(
          onPressed: () => _submit(context),
          child: Text('儲存',
              style: TextStyle(color: colorScheme.primary)),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context, rootNavigator: true).pop({
      'name': name,
      'folderId': _selectedFolderId,
    });
  }
}
