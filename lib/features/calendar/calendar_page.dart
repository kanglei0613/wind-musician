import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../l10n/app_localizations.dart';
import 'calendar_provider.dart';
import 'models/ensemble.dart';
import 'models/ensemble_event.dart';
import 'models/practice_entry.dart';
import 'widgets/practice_entry_dialog.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isSignedIn = uid != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l.calendarTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: isSignedIn
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.person, size: 16, color: cs.primary),
                  )
                : TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(l.loginSignIn,
                        style: TextStyle(color: cs.primary)),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isSignedIn)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: cs.primaryContainer.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: cs.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.calendarSignInHint,
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Expanded(child: _CalendarBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntry(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.calendarAddEntry),
      ),
    );
  }

  Future<void> _showAddEntry(BuildContext context, WidgetRef ref) async {
    final selected = ref.read(calendarSelectedDayProvider);
    await showDialog<bool>(
      context: context,
      builder: (_) => PracticeEntryDialog(initialDate: selected),
    );
  }
}

class _CalendarBody extends ConsumerWidget {
  const _CalendarBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final focusedDay = ref.watch(calendarFocusedDayProvider);
    final selectedDay = ref.watch(calendarSelectedDayProvider);
    final tab = ref.watch(calendarTabProvider);

    final entriesAsync = ref.watch(
      practiceEntriesStreamProvider(
        (year: focusedDay.year, month: focusedDay.month),
      ),
    );
    final entries = entriesAsync.valueOrNull ?? <PracticeEntry>[];

    final ensemblesAsync = ref.watch(userEnsemblesProvider);
    final ensembles = ensemblesAsync.valueOrNull ?? <Ensemble>[];

    final allEnsembleEvents = <EnsembleEvent>[];
    for (final e in ensembles) {
      final eventsAsync = ref.watch(
        ensembleEventsStreamProvider(
          (ensembleId: e.id, year: focusedDay.year, month: focusedDay.month),
        ),
      );
      allEnsembleEvents.addAll(eventsAsync.valueOrNull ?? []);
    }

    Map<DateTime, List<Object>> eventMap = {};
    for (final entry in entries) {
      final key =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      eventMap.putIfAbsent(key, () => []).add(entry);
    }
    for (final ev in allEnsembleEvents) {
      final key = DateTime(
          ev.startTime.year, ev.startTime.month, ev.startTime.day);
      eventMap.putIfAbsent(key, () => []).add(ev);
    }

    final selectedKey =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final dayItems = eventMap[selectedKey] ?? [];

    final practiceForDay = dayItems.whereType<PracticeEntry>().where((e) {
      if (tab == 0) return e.ensembleId == null;
      if (tab == 1) return true;
      if (tab >= 2 && tab - 2 < ensembles.length) {
        return e.ensembleId == ensembles[tab - 2].id;
      }
      return true;
    }).toList();

    final eventsForDay = dayItems.whereType<EnsembleEvent>().where((ev) {
      if (tab == 0) return false;
      if (tab == 1) return true;
      if (tab >= 2 && tab - 2 < ensembles.length) {
        return ev.ensembleId == ensembles[tab - 2].id;
      }
      return true;
    }).toList();

    return Column(
      children: [
        TableCalendar<Object>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          calendarFormat: CalendarFormat.month,
          eventLoader: (day) {
            final key = DateTime(day.year, day.month, day.day);
            return eventMap[key] ?? [];
          },
          onDaySelected: (selected, focused) {
            ref.read(calendarSelectedDayProvider.notifier).state = selected;
            ref.read(calendarFocusedDayProvider.notifier).state = focused;
          },
          onPageChanged: (focused) {
            ref.read(calendarFocusedDayProvider.notifier).state = focused;
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: cs.primary,
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
            leftChevronIcon:
                Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
            rightChevronIcon:
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              final hasPractice = events.any((e) => e is PracticeEntry);
              final hasEnsemble = events.any((e) => e is EnsembleEvent);
              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasPractice)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasEnsemble)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        if (ensembles.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _TabChip(
                  label: l.calendarTabPersonal,
                  selected: tab == 0,
                  onTap: () =>
                      ref.read(calendarTabProvider.notifier).state = 0,
                ),
                _TabChip(
                  label: l.calendarTabAll,
                  selected: tab == 1,
                  onTap: () =>
                      ref.read(calendarTabProvider.notifier).state = 1,
                ),
                ...List.generate(ensembles.length, (i) {
                  return _TabChip(
                    label: ensembles[i].name,
                    selected: tab == i + 2,
                    onTap: () => ref
                        .read(calendarTabProvider.notifier)
                        .state = i + 2,
                  );
                }),
              ],
            ),
          ),

        Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

        Expanded(
          child: (practiceForDay.isEmpty && eventsForDay.isEmpty)
              ? Center(
                  child: Text(
                    l.calendarNoEntries,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    ...eventsForDay.map((ev) => _EnsembleEventTile(ev)),
                    ...practiceForDay.map((e) => _PracticeEntryTile(e)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _EnsembleEventTile extends ConsumerWidget {
  final EnsembleEvent event;
  const _EnsembleEventTile(this.event);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final start = event.startTime;
    final end = event.endTime;
    final timeStr =
        '${_fmt(start.hour)}:${_fmt(start.minute)} – ${_fmt(end.hour)}:${_fmt(end.minute)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.groups_outlined,
              color: Colors.orange, size: 18),
        ),
        title: Text(event.title,
            style: TextStyle(
                color: cs.onSurface, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${event.location != null ? '${event.location}  ' : ''}$timeStr',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        onTap: () {
          final ensembles =
              ref.read(userEnsemblesProvider).valueOrNull ?? [];
          final ensemble = ensembles
              .where((e) => e.id == event.ensembleId)
              .firstOrNull;
          if (ensemble != null) {
            context.push('/ensemble/${ensemble.id}');
          }
        },
      ),
    );
  }

  String _fmt(int v) => v.toString().padLeft(2, '0');
}

class _PracticeEntryTile extends ConsumerWidget {
  final PracticeEntry entry;
  const _PracticeEntryTile(this.entry);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final mins = entry.durationMinutes;
    final dur = mins < 60
        ? '$mins ${l.calendarUnitMin}'
        : '${mins ~/ 60} ${l.calendarUnitHour}${mins % 60 > 0 ? ' ${mins % 60} ${l.calendarUnitMin}' : ''}';

    final isRehearsal = entry.isRehearsal;
    final iconColor = isRehearsal ? Colors.deepPurple : cs.primary;
    final bgColor = isRehearsal
        ? Colors.deepPurple.withValues(alpha: 0.12)
        : cs.primaryContainer;
    final icon = isRehearsal ? Icons.groups_outlined : Icons.music_note_outlined;

    // 副標題：排練行程顯示地點＋時間；個人練習顯示時長
    String subtitleText = dur;
    if (isRehearsal) {
      final parts = <String>[];
      if (entry.startTime != null) {
        final s = '${entry.startTime!.hour.toString().padLeft(2,'0')}:${entry.startTime!.minute.toString().padLeft(2,'0')}';
        final e2 = entry.endTime != null
            ? ' – ${entry.endTime!.hour.toString().padLeft(2,'0')}:${entry.endTime!.minute.toString().padLeft(2,'0')}'
            : '';
        parts.add('$s$e2');
      }
      if (entry.location != null && entry.location!.isNotEmpty) {
        parts.add(entry.location!);
      }
      subtitleText = parts.isNotEmpty ? parts.join('  ') : dur;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(
          entry.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style:
              TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitleText,
            style: TextStyle(
                color: cs.onSurfaceVariant, fontSize: 12)),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert,
              size: 18, color: cs.onSurfaceVariant),
          onSelected: (v) async {
            if (v == 'edit') {
              showDialog<bool>(
                context: context,
                builder: (_) => PracticeEntryDialog(
                  initialDate: entry.date,
                  existing: entry,
                ),
              );
            } else if (v == 'delete') {
              // 加入確認對話框，避免用戶誤刪不可逆的練習紀錄
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l.calendarDelete),
                  content: Text(l.commonUndoWarning),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                      child: Text(l.commonCancel,
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
                      child: Text(l.calendarDelete,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                ref.read(practiceRepositoryProvider).deleteEntry(entry.id);
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(l.calendarEdit)),
            PopupMenuItem(
                value: 'delete',
                child: Text(l.calendarDelete,
                    style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
