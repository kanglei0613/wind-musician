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
    // BC-007：Firestore stream 離線時會發出 FirebaseException error event，
    // 使用 handleError 攔截，避免 StreamProvider 進入 error state 而白屏。
    // stream 會停止接收新事件，但已顯示的資料不受影響；
    // 連線恢復後 provider 自動重建時會重新訂閱。
    return _col
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PracticeEntry.fromJson({...d.data(), 'id': d.id}))
            .toList())
        .handleError(
          (Object error, StackTrace stack) {
            // 靜默處理：保留最後一次成功的資料，不向 UI 拋出 error event
          },
          test: (e) => e is FirebaseException,
        );
  }

  /// Upsert by id (writes to Firestore + local backup).
  Future<void> saveEntry(PracticeEntry entry) async {
    // BC-010：Firestore write 離線或驗證失敗時拋出 FirebaseException
    try {
      await _col.doc(entry.id).set(entry.toJson());
    } on FirebaseException catch (e) {
      throw Exception('儲存練習紀錄失敗（Firebase 異常）：${e.message}');
    }
    await _upsertLocal(entry);
  }

  Future<void> deleteEntry(String id) async {
    // BC-010：Firestore delete 離線或權限不足時拋出 FirebaseException
    try {
      await _col.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('刪除練習紀錄失敗（Firebase 異常）：${e.message}');
    }
    await _deleteLocal(id);
  }
}
