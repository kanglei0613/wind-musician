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
  late TextEditingController _ensembleNameController;
  late TextEditingController _locationController;
  String? _selectedEnsembleId;
  late PracticeEntryType _type;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? widget.initialDate;
    _durationMinutes = e?.durationMinutes ?? 60;
    _contentController = TextEditingController(text: e?.content ?? '');
    _ensembleNameController =
        TextEditingController(text: e?.rehearsalEnsembleName ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _selectedEnsembleId = e?.ensembleId;
    _type = e?.type ?? PracticeEntryType.personal;
    _startTime = e?.startTime;
    _endTime = e?.endTime;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _ensembleNameController.dispose();
    _locationController.dispose();
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

  Future<void> _pickTime(bool isStart) async {
    final initial = (isStart ? _startTime : _endTime) ?? TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請先登入')));
      return;
    }
    // 驗證
    if (_type == PracticeEntryType.personal &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請填寫練習內容')));
      return;
    }
    if (_type == PracticeEntryType.rehearsal &&
        _ensembleNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請填寫排練樂團名稱')));
      return;
    }

    setState(() => _isSaving = true);

    final entry = PracticeEntry(
      id: widget.existing?.id ?? const Uuid().v4(),
      userId: uid,
      date: DateTime(_date.year, _date.month, _date.day),
      durationMinutes: _durationMinutes,
      content: _type == PracticeEntryType.personal
          ? _contentController.text.trim()
          : _ensembleNameController.text.trim(),
      ensembleId: _selectedEnsembleId,
      type: _type,
      rehearsalEnsembleName: _type == PracticeEntryType.rehearsal
          ? _ensembleNameController.text.trim()
          : null,
      location: _type == PracticeEntryType.rehearsal &&
              _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      startTime: _type == PracticeEntryType.rehearsal ? _startTime : null,
      endTime: _type == PracticeEntryType.rehearsal ? _endTime : null,
    );

    try {
      await ref.read(practiceRepositoryProvider).saveEntry(entry);
      if (mounted) Navigator.of(context).pop(true);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('儲存失敗：$err')));
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
    final isEdit = widget.existing != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              isEdit ? '編輯紀錄' : '新增紀錄',
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // ── 類型切換 ─────────────────────────────
            _Label('類型', cs),
            Row(
              children: [
                _TypeChip(
                  label: '今日練習',
                  icon: Icons.music_note_outlined,
                  selected: _type == PracticeEntryType.personal,
                  cs: cs,
                  onTap: () =>
                      setState(() => _type = PracticeEntryType.personal),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: '排練行程',
                  icon: Icons.groups_outlined,
                  selected: _type == PracticeEntryType.rehearsal,
                  cs: cs,
                  onTap: () =>
                      setState(() => _type = PracticeEntryType.rehearsal),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 日期 ──────────────────────────────────
            _Label('日期', cs),
            _TapField(
              leading: Icon(Icons.calendar_today_outlined,
                  size: 16, color: cs.primary),
              label:
                  '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}',
              cs: cs,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // ── 個人練習欄位 ─────────────────────────
            if (_type == PracticeEntryType.personal) ...[
              _Label('練習時間', cs),
              _DurationPicker(
                  value: _durationMinutes,
                  cs: cs,
                  onChanged: (v) => setState(() => _durationMinutes = v)),
              const SizedBox(height: 16),
              _Label('練習內容', cs),
              _MultilineField(
                controller: _contentController,
                hint: '今天練了什麼？',
                cs: cs,
              ),
              const SizedBox(height: 16),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                        value: null,
                        child: Text('個人練習',
                            style: TextStyle(color: cs.onSurface))),
                    ...ensembles.map((e) => DropdownMenuItem<String?>(
                        value: e.id,
                        child: Text(e.name,
                            style: TextStyle(color: cs.onSurface)))),
                  ],
                  onChanged: (v) => setState(() => _selectedEnsembleId = v),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // ── 排練行程欄位 ─────────────────────────
            if (_type == PracticeEntryType.rehearsal) ...[
              _Label('排練樂團 *', cs),
              _SinglelineField(
                controller: _ensembleNameController,
                hint: '樂團名稱',
                cs: cs,
              ),
              const SizedBox(height: 16),
              _Label('地點（選填）', cs),
              _SinglelineField(
                controller: _locationController,
                hint: '排練場地',
                cs: cs,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _Label('時間（選填）', cs),
              Row(
                children: [
                  Expanded(
                    child: _TapField(
                      leading: Icon(Icons.schedule_outlined,
                          size: 16, color: cs.primary),
                      label: _startTime != null
                          ? _formatTime(_startTime!)
                          : '開始時間',
                      cs: cs,
                      onTap: () => _pickTime(true),
                      faded: _startTime == null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('－',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                  Expanded(
                    child: _TapField(
                      leading: Icon(Icons.schedule_outlined,
                          size: 16, color: cs.primary),
                      label: _endTime != null
                          ? _formatTime(_endTime!)
                          : '結束時間',
                      cs: cs,
                      onTap: () => _pickTime(false),
                      faded: _endTime == null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Label('備註（選填）', cs),
              _MultilineField(
                controller: _contentController,
                hint: '排練曲目、注意事項…',
                cs: cs,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],

            // ── Actions ───────────────────────────────
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
                              strokeWidth: 2, color: Colors.white))
                      : const Text('儲存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 共用小元件 ────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? cs.onPrimary : cs.onSurface,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  final Widget leading;
  final String label;
  final ColorScheme cs;
  final VoidCallback onTap;
  final bool faded;

  const _TapField({
    required this.leading,
    required this.label,
    required this.cs,
    required this.onTap,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border:
              Border.all(color: cs.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: faded
                    ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                    : cs.onSurface,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final int value;
  final ColorScheme cs;
  final ValueChanged<int> onChanged;

  const _DurationPicker(
      {required this.value, required this.cs, required this.onChanged});

  String _fmt(int minutes) {
    if (minutes < 60) return '$minutes 分鐘';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h 小時' : '$h 小時 $m 分鐘';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed:
              value > 5 ? () => onChanged(value - 5) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: cs.primary,
        ),
        Text(_fmt(value),
            style: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
        IconButton(
          onPressed:
              value < 480 ? () => onChanged(value + 5) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: cs.primary,
        ),
      ],
    );
  }
}

class _MultilineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ColorScheme cs;
  final int maxLines;

  const _MultilineField({
    required this.controller,
    required this.hint,
    required this.cs,
    this.maxLines = 4,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }
}

class _SinglelineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ColorScheme cs;
  final IconData? icon;

  const _SinglelineField({
    required this.controller,
    required this.hint,
    required this.cs,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: cs.onSurfaceVariant)
            : null,
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
        isDense: true,
        contentPadding: const EdgeInsets.all(12),
      ),
    );
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
