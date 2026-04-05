import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/recording_folder.dart';

class FolderRepository {
  static const _metadataFileName = 'folders_metadata.json';

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

  Future<List<RecordingFolder>> loadAll() async {
    final file = await _getMetadataFile();
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final folders = jsonList
          .map((e) => RecordingFolder.fromJson(e as Map<String, dynamic>))
          .toList();
      folders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return folders;
    } catch (_) {
      return [];
    }
  }

  Future<void> add(RecordingFolder folder) async {
    final all = await loadAll();
    all.add(folder);
    await _saveAll(all);
  }

  Future<void> rename(String id, String newName) async {
    final all = await loadAll();
    final index = all.indexWhere((f) => f.id == id);
    if (index == -1) return;
    all[index] = all[index].copyWith(name: newName);
    await _saveAll(all);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((f) => f.id == id);
    await _saveAll(all);
  }

  // 取得資料夾的實體目錄路徑
  Future<String> getFolderDirPath(String folderId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/recordings/$folderId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<void> _saveAll(List<RecordingFolder> folders) async {
    final file = await _getMetadataFile();
    await file.writeAsString(jsonEncode(folders.map((f) => f.toJson()).toList()));
  }
}
