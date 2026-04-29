import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../recorder_provider.dart';
import '../../../l10n/app_localizations.dart';

class SaveDialog extends ConsumerStatefulWidget {
  const SaveDialog({super.key});

  @override
  ConsumerState<SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends ConsumerState<SaveDialog> {
  final _controller = TextEditingController();
  String? _selectedFolderId;
  bool _showNameError = false;

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
    final l = AppLocalizations.of(context)!;
    final folders = ref.watch(foldersProvider).valueOrNull ?? [];

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(l.recorderSaveTitle,
          style: TextStyle(color: colorScheme.onSurface)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(color: colorScheme.onSurface),
            onChanged: (_) {
              // 用戶開始輸入時清除錯誤提示
              if (_showNameError) setState(() => _showNameError = false);
            },
            decoration: InputDecoration(
              hintText: l.recorderSaveHint,
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              errorText: _showNameError ? l.recorderSaveNameRequired : null,
              errorStyle: TextStyle(color: colorScheme.error, fontSize: 12),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: _showNameError ? colorScheme.error : colorScheme.primary,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: _showNameError ? colorScheme.error : colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.recorderSaveFolder,
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
                      l.recorderUncategorized,
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
          child: Text(l.recorderDiscard,
              style: TextStyle(color: colorScheme.error)),
        ),
        TextButton(
          onPressed: () => _submit(context),
          child: Text(l.commonSave,
              style: TextStyle(color: colorScheme.primary)),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      // 顯示錯誤提示，讓用戶知道名稱不能為空
      setState(() => _showNameError = true);
      return;
    }
    Navigator.of(context, rootNavigator: true).pop({
      'name': name,
      'folderId': _selectedFolderId,
    });
  }
}
