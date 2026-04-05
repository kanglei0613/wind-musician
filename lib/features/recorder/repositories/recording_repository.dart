import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/recording.dart';

class RecordingRepository {
  static const _metadataFileName = 'recordings_metadata.json';

  Future<Directory> _getRecordingsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/recordings');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _getMetadataFile() async {
    final dir = await _getRecordingsDir();
    return File('${dir.path}/$_metadataFileName');
  }

  // 產生錄音檔路徑：有資料夾就放進去，沒有就放根目錄
  Future<String> generateRecordingPath(String id, {String? folderId}) async {
    final appDir = await getApplicationDocumentsDirectory();
    if (folderId != null) {
      final folderDir =
          Directory('${appDir.path}/recordings/$folderId');
      if (!await folderDir.exists()) {
        await folderDir.create(recursive: true);
      }
      return '${folderDir.path}/$id.m4a';
    }
    final dir = await _getRecordingsDir();
    return '${dir.path}/$id.m4a';
  }

  Future<List<Recording>> loadAll() async {
    final file = await _getMetadataFile();
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final recordings = jsonList
          .map((e) => Recording.fromJson(e as Map<String, dynamic>))
          .toList();
      recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return recordings;
    } catch (_) {
      return [];
    }
  }

  Future<void> add(Recording recording) async {
    final all = await loadAll();
    all.insert(0, recording);
    await _saveAll(all);
  }

  Future<void> rename(String id, String newName) async {
    final all = await loadAll();
    final index = all.indexWhere((r) => r.id == id);
    if (index == -1) return;
    all[index] = all[index].copyWith(name: newName);
    await _saveAll(all);
  }

  // 搬移錄音到資料夾（實體檔案也搬）
  Future<Recording?> moveToFolder(String id, String? folderId) async {
    final all = await loadAll();
    final index = all.indexWhere((r) => r.id == id);
    if (index == -1) return null;

    final recording = all[index];
    final oldFile = File(recording.path);
    if (!await oldFile.exists()) return null;

    // 產生新路徑
    final newPath =
        await generateRecordingPath(recording.id, folderId: folderId);

    // 搬移實體檔案
    await oldFile.rename(newPath);

    // 更新 metadata
    final updated = recording.copyWith(
      path: newPath,
      folderId: folderId,
      clearFolder: folderId == null,
    );
    all[index] = updated;
    await _saveAll(all);
    return updated;
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    final recording = all.firstWhere((r) => r.id == id);
    final file = File(recording.path);
    if (await file.exists()) await file.delete();
    all.removeWhere((r) => r.id == id);
    await _saveAll(all);
  }

  // 刪除資料夾內所有錄音
  Future<void> deleteByFolderId(String folderId) async {
    final all = await loadAll();
    final toDelete = all.where((r) => r.folderId == folderId).toList();
    for (final r in toDelete) {
      final file = File(r.path);
      if (await file.exists()) await file.delete();
    }
    all.removeWhere((r) => r.folderId == folderId);
    await _saveAll(all);
  }

  Future<void> _saveAll(List<Recording> recordings) async {
    final file = await _getMetadataFile();
    await file.writeAsString(
        jsonEncode(recordings.map((r) => r.toJson()).toList()));
  }
}
