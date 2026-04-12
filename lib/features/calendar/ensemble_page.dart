import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import 'calendar_provider.dart';
import 'models/ensemble.dart';
import 'models/ensemble_event.dart';
import 'widgets/ensemble_event_dialog.dart';

class EnsemblePage extends ConsumerStatefulWidget {
  final String ensembleId;

  const EnsemblePage({super.key, required this.ensembleId});

  @override
  ConsumerState<EnsemblePage> createState() => _EnsemblePageState();
}

class _EnsemblePageState extends ConsumerState<EnsemblePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Ensemble? _findEnsemble(WidgetRef ref) {
    final ensembles = ref.watch(userEnsemblesProvider).valueOrNull ?? [];
    return ensembles.where((e) => e.id == widget.ensembleId).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final ensemble = _findEnsemble(ref);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isAdmin = ensemble?.adminId == uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(ensemble?.name ?? '樂團'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '行事曆'),
            Tab(text: '成員'),
            Tab(text: '資訊'),
          ],
        ),
      ),
      body: ensemble == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _CalendarTab(
                  ensemble: ensemble,
                  isAdmin: isAdmin,
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  onFocusedChanged: (d) => setState(() => _focusedDay = d),
                  onSelectedChanged: (d) => setState(() => _selectedDay = d),
                ),
                _MembersTab(ensemble: ensemble),
                _InfoTab(ensemble: ensemble),
              ],
            ),
    );
  }
}

// ── Calendar tab ──────────────────────────────────────────────────────────

class _CalendarTab extends ConsumerWidget {
  final Ensemble ensemble;
  final bool isAdmin;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onFocusedChanged;
  final ValueChanged<DateTime> onSelectedChanged;

  const _CalendarTab({
    required this.ensemble,
    required this.isAdmin,
    required this.focusedDay,
    required this.selectedDay,
    required this.onFocusedChanged,
    required this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final eventsAsync = ref.watch(
      ensembleEventsStreamProvider((
        ensembleId: ensemble.id,
        year: focusedDay.year,
        month: focusedDay.month,
      )),
    );
    final events = eventsAsync.valueOrNull ?? <EnsembleEvent>[];

    final Map<DateTime, List<EnsembleEvent>> eventMap = {};
    for (final ev in events) {
      final key =
          DateTime(ev.startTime.year, ev.startTime.month, ev.startTime.day);
      eventMap.putIfAbsent(key, () => []).add(ev);
    }

    final selectedKey =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final dayEvents = eventMap[selectedKey] ?? [];

    return Column(
      children: [
        TableCalendar<EnsembleEvent>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: focusedDay,
          selectedDayPredicate: (d) => isSameDay(d, selectedDay),
          calendarFormat: CalendarFormat.month,
          eventLoader: (day) {
            final key = DateTime(day.year, day.month, day.day);
            return eventMap[key] ?? [];
          },
          onDaySelected: (sel, foc) {
            onSelectedChanged(sel);
            onFocusedChanged(foc);
          },
          onPageChanged: onFocusedChanged,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: cs.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => EnsembleEventDialog(
                    ensembleId: ensemble.id,
                    initialDate: selectedDay,
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('新增排練'),
              ),
            ),
          ),
        Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
        Expanded(
          child: dayEvents.isEmpty
              ? Center(
                  child: Text(
                    '這天沒有排練',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dayEvents.length,
                  itemBuilder: (_, i) =>
                      _EventTile(dayEvents[i], ensemble, isAdmin),
                ),
        ),
      ],
    );
  }
}

// ── Event tile ────────────────────────────────────────────────────────────

class _EventTile extends ConsumerWidget {
  final EnsembleEvent event;
  final Ensemble ensemble;
  final bool isAdmin;

  const _EventTile(this.event, this.ensemble, this.isAdmin);

  String _fmt(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isAttending =
        uid != null && event.attendingUserIds.contains(uid);

    final s = event.startTime;
    final e = event.endTime;
    final timeStr =
        '${_fmt(s.hour)}:${_fmt(s.minute)} – ${_fmt(e.hour)}:${_fmt(e.minute)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => showDialog<bool>(
                      context: context,
                      builder: (_) => EnsembleEventDialog(
                        ensembleId: ensemble.id,
                        initialDate: event.startTime,
                        existing: event,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style:
                  TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            if (event.location != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  event.location!,
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ),
            if (event.notes != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  event.notes!,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontSize: 12),
                ),
              ),
            if (uid != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${event.attendingUserIds.length} 人確認出席',
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 28),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: isAttending
                          ? Colors.green.withValues(alpha: 0.2)
                          : null,
                    ),
                    onPressed: () => ref
                        .read(ensembleRepositoryProvider)
                        .markAttendance(event.id, uid, !isAttending),
                    child: Text(
                      isAttending ? '已確認' : '確認出席',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isAttending ? Colors.green : cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Members tab ───────────────────────────────────────────────────────────

class _MembersTab extends StatelessWidget {
  final Ensemble ensemble;
  const _MembersTab({required this.ensemble});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final members = ensemble.memberIds;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (_, i) {
        final memberId = members[i];
        final isAdmin = memberId == ensemble.adminId;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: cs.primaryContainer,
            child:
                Icon(Icons.person_outline, color: cs.primary, size: 18),
          ),
          title: Text(
            memberId.length > 12
                ? '${memberId.substring(0, 8)}…'
                : memberId,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
          ),
          trailing: isAdmin
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '管理員',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

// ── Info tab ──────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final Ensemble ensemble;
  const _InfoTab({required this.ensemble});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String pad(int v) => v.toString().padLeft(2, '0');
    final created = ensemble.createdAt;
    final createdStr =
        '${created.year}/${pad(created.month)}/${pad(created.day)}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow('樂團名稱', ensemble.name, cs),
        if (ensemble.description != null)
          _InfoRow('簡介', ensemble.description!, cs),
        if (ensemble.instrumentSection != null)
          _InfoRow('類型', ensemble.instrumentSection!, cs),
        _InfoRow('成立日期', createdStr, cs),
        const SizedBox(height: 16),
        Text(
          '邀請碼',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                ensemble.inviteCode,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.copy_outlined,
                    color: cs.primary, size: 20),
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: ensemble.inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('邀請碼已複製')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '分享邀請碼給朋友，讓他們加入樂團',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _InfoRow(this.label, this.value, this.cs);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(color: cs.onSurface, fontSize: 15)),
        ],
      ),
    );
  }
}

// ── Create / Join bottom sheet ────────────────────────────────────────────

Future<void> showCreateJoinEnsembleSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CreateJoinSheet(),
  );
}

class _CreateJoinSheet extends ConsumerStatefulWidget {
  const _CreateJoinSheet();

  @override
  ConsumerState<_CreateJoinSheet> createState() => _CreateJoinSheetState();
}

class _CreateJoinSheetState extends ConsumerState<_CreateJoinSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String? _instrumentSection;
  bool _isSaving = false;

  static const _sections = [
    '管樂團',
    '弦樂四重奏',
    '管弦樂團',
    '室內樂',
    '爵士樂團',
    '其他',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請先登入')));
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請輸入樂團名稱')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(ensembleRepositoryProvider);
      final ensemble =
          await repo.createEnsemble(_nameCtrl.text.trim(), uid);
      await repo.updateEnsemble(
        ensemble.id,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        instrumentSection: _instrumentSection,
      );
      ref.invalidate(userEnsemblesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('建立失敗：$e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _join() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請先登入')));
      return;
    }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('邀請碼為 6 碼')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(ensembleRepositoryProvider);
      final ensemble = await repo.getEnsembleByInviteCode(code);
      if (ensemble == null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('找不到此邀請碼')));
        }
        return;
      }
      await repo.joinEnsemble(ensemble.id, uid);
      ref.invalidate(userEnsemblesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('加入失敗：$e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TabBar(
            controller: _tab,
            tabs: const [Tab(text: '建立樂團'), Tab(text: '加入樂團')],
          ),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tab,
              children: [
                // Create
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field('樂團名稱', _nameCtrl, hint: '我的管樂團'),
                      const SizedBox(height: 12),
                      _field('簡介（選填）', _descCtrl, hint: '一些介紹文字'),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: _instrumentSection,
                        decoration: InputDecoration(
                          labelText: '類型（選填）',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('不指定'),
                          ),
                          ..._sections.map(
                            (s) => DropdownMenuItem<String?>(
                              value: s,
                              child: Text(s),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _instrumentSection = v),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _create,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('建立'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Join
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '輸入朋友給你的 6 碼邀請碼',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeCtrl,
                        maxLength: 6,
                        textCapitalization:
                            TextCapitalization.characters,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 24,
                          letterSpacing: 8,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'AB12CD',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _join,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('加入'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }
}
