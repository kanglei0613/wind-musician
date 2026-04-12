import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../calendar_provider.dart';
import '../models/ensemble.dart';
import '../models/practice_entry.dart';

class PracticeEntryDialog extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final PracticeEntry? existing; // null = create, non-null = edit

  const PracticeEntryDialog({
    super.key,
    required this.initialDate,
    this.existing,
  });

  @override
  ConsumerState<PracticeEntryDialog> createState() =>
      _PracticeEntryDialogState();
}

class _PracticeEntryDialogState extends ConsumerState<PracticeEntryDialog> {
  late DateTime _date;
  late int _durationMinutes;
  late TextEditingController _contentController;
  String? _selectedEnsembleId; // null = 個人
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? widget.initialDate;
    _durationMinutes = e?.durationMinutes ?? 30;
    _contentController = TextEditingController(text: e?.content ?? '');
    _selectedEnsembleId = e?.ensembleId;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入')),
      );
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫練習內容')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final entry = PracticeEntry(
      id: widget.existing?.id ?? const Uuid().v4(),
      userId: uid,
      date: DateTime(_date.year, _date.month, _date.day),
      durationMinutes: _durationMinutes,
      content: _contentController.text.trim(),
      ensembleId: _selectedEnsembleId,
    );
    try {
      await ref.read(practiceRepositoryProvider).saveEntry(entry);
      if (mounted) Navigator.of(context).pop(true);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗：$err')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ensemblesAsync = ref.watch(userEnsemblesProvider);
    final ensembles = ensemblesAsync.valueOrNull ?? <Ensemble>[];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? '新增練習紀錄' : '編輯練習紀錄',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Date
            _Label('日期', cs),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}',
                      style: TextStyle(color: cs.onSurface, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            _Label('練習時間', cs),
            Row(
              children: [
                IconButton(
                  onPressed: _durationMinutes > 5
                      ? () =>
                          setState(() => _durationMinutes -= 5)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: cs.primary,
                ),
                Text(
                  _formatDuration(_durationMinutes),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  onPressed: _durationMinutes < 300
                      ? () =>
                          setState(() => _durationMinutes += 5)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: cs.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            _Label('練習內容', cs),
            TextField(
              controller: _contentController,
              maxLines: 4,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: '今天練了什麼？',
                hintStyle:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.primary),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // Ensemble selector
            if (ensembles.isNotEmpty) ...[
              _Label('歸屬', cs),
              DropdownButtonFormField<String?>(
                initialValue: _selectedEnsembleId,
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                dropdownColor: cs.surface,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('個人練習',
                        style: TextStyle(color: cs.onSurface)),
                  ),
                  ...ensembles.map(
                    (e) => DropdownMenuItem<String?>(
                      value: e.id,
                      child: Text(e.name,
                          style: TextStyle(color: cs.onSurface)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedEnsembleId = v),
              ),
              const SizedBox(height: 16),
            ],

            // Share toggle (disabled — future feature)
            Row(
              children: [
                Switch(value: false, onChanged: null),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('分享給朋友',
                        style:
                            TextStyle(color: cs.onSurface, fontSize: 14)),
                    Text(
                      // TODO: enable when friend feature ships
                      '功能開發中',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('取消',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('儲存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes 分鐘';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h 小時' : '$h 小時 $m 分鐘';
  }
}

class _Label extends StatelessWidget {
  final String text;
  final ColorScheme cs;

  const _Label(this.text, this.cs);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
