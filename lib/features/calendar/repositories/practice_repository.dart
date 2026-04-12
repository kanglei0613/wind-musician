import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../models/practice_entry.dart';

class PracticeRepository {
  static const _localFileName = 'practice_entries.json';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('practiceEntries');

  // ── Local storage helpers ─────────────────────────────────────────────────

  Future<File> _getLocalFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_localFileName');
  }

  Future<List<PracticeEntry>> _loadLocal() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content);
      return list
          .map((e) => PracticeEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocal(List<PracticeEntry> entries) async {
    final file = await _getLocalFile();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
    await tmp.rename(file.path);
  }

  Future<void> _upsertLocal(PracticeEntry entry) async {
    final all = await _loadLocal();
    final idx = all.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      all[idx] = entry;
    } else {
      all.add(entry);
    }
    await _saveLocal(all);
  }

  Future<void> _deleteLocal(String id) async {
    final all = await _loadLocal();
    all.removeWhere((e) => e.id == id);
    await _saveLocal(all);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// One-shot fetch for a given month.
  Future<List<PracticeEntry>> getEntriesForMonth(
    String userId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    try {
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThan: end.toIso8601String())
          .get();
      return snap.docs
          .map((d) => PracticeEntry.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      // Firestore unavailable — fall back to local
      final all = await _loadLocal();
      return all.where((e) {
        return e.userId == userId &&
            e.date.year == year &&
            e.date.month == month;
      }).toList();
    }
  }

  /// Real-time stream for a given month.
  Stream<List<PracticeEntry>> watchEntriesForMonth(
    String userId,
    int year,
    int month,
  ) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return _col
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PracticeEntry.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  /// Upsert by id (writes to Firestore + local backup).
  Future<void> saveEntry(PracticeEntry entry) async {
    await _col.doc(entry.id).set(entry.toJson());
    await _upsertLocal(entry);
  }

  Future<void> deleteEntry(String id) async {
    await _col.doc(id).delete();
    await _deleteLocal(id);
  }
}
