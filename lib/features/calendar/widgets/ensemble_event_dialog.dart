import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../calendar_provider.dart';
import '../models/ensemble_event.dart';

class EnsembleEventDialog extends ConsumerStatefulWidget {
  final String ensembleId;
  final DateTime initialDate;
  final EnsembleEvent? existing;

  const EnsembleEventDialog({
    super.key,
    required this.ensembleId,
    required this.initialDate,
    this.existing,
  });

  @override
  ConsumerState<EnsembleEventDialog> createState() =>
      _EnsembleEventDialogState();
}

class _EnsembleEventDialogState extends ConsumerState<EnsembleEventDialog> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.startTime ?? widget.initialDate;
    _startTime = e != null
        ? TimeOfDay.fromDateTime(e.startTime)
        : const TimeOfDay(hour: 14, minute: 0);
    _endTime = e != null
        ? TimeOfDay.fromDateTime(e.endTime)
        : const TimeOfDay(hour: 17, minute: 0);
    _titleController = TextEditingController(text: e?.title ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫排練標題')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final startDt = DateTime(
      _date.year, _date.month, _date.day,
      _startTime.hour, _startTime.minute,
    );
    final endDt = DateTime(
      _date.year, _date.month, _date.day,
      _endTime.hour, _endTime.minute,
    );
    final event = EnsembleEvent(
      id: widget.existing?.id ?? const Uuid().v4(),
      ensembleId: widget.ensembleId,
      title: _titleController.text.trim(),
      startTime: startDt,
      endTime: endDt,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      attendingUserIds: widget.existing?.attendingUserIds ?? [],
    );
    try {
      await ref.read(ensembleRepositoryProvider).saveEvent(event);
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

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? '新增排練' : '編輯排練',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            _buildField('標題', _titleController, cs, hint: '合奏排練'),
            const SizedBox(height: 14),

            // Date
            _label('日期', cs),
            GestureDetector(
              onTap: _pickDate,
              child: _dateBox(
                '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}',
                cs,
              ),
            ),
            const SizedBox(height: 14),

            // Time
            _label('時間', cs),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStart,
                    child: _dateBox('開始  ${_fmtTime(_startTime)}', cs),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('–'),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickEnd,
                    child: _dateBox('結束  ${_fmtTime(_endTime)}', cs),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Location
            _buildField('地點（選填）', _locationController, cs,
                hint: '學校音樂廳'),
            const SizedBox(height: 14),

            // Notes
            _buildField('備注／練習內容（選填）', _notesController, cs,
                hint: '請攜帶第三樂章分譜', maxLines: 3),
            const SizedBox(height: 24),

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

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    ColorScheme cs, {
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, cs),
        TextField(
          controller: ctrl,
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
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _label(String text, ColorScheme cs) => Padding(
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

  Widget _dateBox(String text, ColorScheme cs) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border:
              Border.all(color: cs.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: TextStyle(color: cs.onSurface, fontSize: 14)),
      );
}
