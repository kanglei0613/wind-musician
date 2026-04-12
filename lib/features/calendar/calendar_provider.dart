import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/ensemble.dart';
import 'models/ensemble_event.dart';
import 'models/practice_entry.dart';
import 'repositories/ensemble_repository.dart';
import 'repositories/practice_repository.dart';

// ── Repositories ──────────────────────────────────────────────────────────

final practiceRepositoryProvider = Provider((ref) => PracticeRepository());
final ensembleRepositoryProvider = Provider((ref) => EnsembleRepository());

// ── Calendar state ────────────────────────────────────────────────────────

final calendarFocusedDayProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final calendarSelectedDayProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// ── Practice entries ──────────────────────────────────────────────────────

final practiceEntriesStreamProvider =
    StreamProvider.family<List<PracticeEntry>, ({int year, int month})>(
  (ref, params) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    final repo = ref.watch(practiceRepositoryProvider);
    return repo.watchEntriesForMonth(uid, params.year, params.month);
  },
);

// ── Ensembles ─────────────────────────────────────────────────────────────

final userEnsemblesProvider = FutureProvider<List<Ensemble>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];
  final repo = ref.watch(ensembleRepositoryProvider);
  return repo.getEnsemblesForUser(uid);
});

// ── Ensemble events ────────────────────────────────────────────────────────

final ensembleEventsStreamProvider = StreamProvider.family<
    List<EnsembleEvent>, ({String ensembleId, int year, int month})>(
  (ref, params) {
    final repo = ref.watch(ensembleRepositoryProvider);
    return repo.watchEventsForEnsemble(
      params.ensembleId,
      params.year,
      params.month,
    );
  },
);

// ── Selected tab (0 = 個人, 1 = 全部樂團, 2+ = per-ensemble) ──────────────

final calendarTabProvider = StateProvider<int>((ref) => 0);
