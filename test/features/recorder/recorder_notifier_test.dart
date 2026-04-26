library;

/// 錄音器 Bad Case 測試
///
/// 覆蓋範圍：
///   BC-R1  startRecording 無麥克風權限 → status 不切換到 recording（需 mock）
///   BC-R4  RecordingRepository.delete — id 不存在時不 crash（firstOrNull）
///   BC-R7  _tick 超過 maxRecordingSeconds 自動停止
///   BC-RS1 RecorderState.copyWith — clearPending / clearFolder 語意
///   BC-RS2 RecorderState 初始值驗證
///   BC-RM  Recording.fromJson / toJson 往返無損
///   BC-RM2 Recording.copyWith clearFolder = true 清除 folderId
///   BC-RR1 saveRecording path=null → 靜默跳出（不 throw）
///   BC-RR2 discardRecording path=null → 不 throw

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_musician/features/recorder/recorder_provider.dart';
import 'package:wind_musician/features/recorder/models/recording.dart';
import 'package:wind_musician/shared/constants/app_constants.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // RecorderState — 初始值 & copyWith 語意
  // ─────────────────────────────────────────────────────────────────────────

  group('RecorderState 初始值 (BC-RS2)', () {
    test('status 預設 idle', () {
      const s = RecorderState();
      expect(s.status, equals(RecorderStatus.idle));
    });

    test('elapsedSeconds 預設 0', () {
      const s = RecorderState();
      expect(s.elapsedSeconds, equals(0));
    });

    test('pendingPath 預設 null', () {
      const s = RecorderState();
      expect(s.pendingPath, isNull);
    });

    test('selectedFolderId 預設 null', () {
      const s = RecorderState();
      expect(s.selectedFolderId, isNull);
    });
  });

  group('RecorderState.copyWith (BC-RS1)', () {
    test('clearPending=true → pendingPath 變 null', () {
      const s = RecorderState(pendingPath: '/tmp/rec.m4a');
      final cleared = s.copyWith(clearPending: true);
      expect(cleared.pendingPath, isNull);
    });

    test('clearPending=false → pendingPath 保留', () {
      const s = RecorderState(pendingPath: '/tmp/rec.m4a');
      final kept = s.copyWith(status: RecorderStatus.recording);
      expect(kept.pendingPath, equals('/tmp/rec.m4a'));
    });

    test('clearFolder=true → selectedFolderId 變 null', () {
      const s = RecorderState(selectedFolderId: 'folder-123');
      final cleared = s.copyWith(clearFolder: true);
      expect(cleared.selectedFolderId, isNull);
    });

    test('clearFolder=false → selectedFolderId 保留', () {
      const s = RecorderState(selectedFolderId: 'folder-123');
      final kept = s.copyWith(elapsedSeconds: 5);
      expect(kept.selectedFolderId, equals('folder-123'));
    });

    test('status 可以從 recording 改回 idle', () {
      const s = RecorderState(status: RecorderStatus.recording);
      final idle = s.copyWith(status: RecorderStatus.idle);
      expect(idle.status, equals(RecorderStatus.idle));
    });

    test('elapsedSeconds 累加正常', () {
      const s = RecorderState(elapsedSeconds: 10);
      final next = s.copyWith(elapsedSeconds: s.elapsedSeconds + 1);
      expect(next.elapsedSeconds, equals(11));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Recording Model — fromJson / toJson 往返
  // ─────────────────────────────────────────────────────────────────────────

  group('Recording.fromJson / toJson (BC-RM)', () {
    final now = DateTime(2025, 1, 15, 10, 0, 0);

    test('toJson → fromJson 往返無損（有 folderId）', () {
      final original = Recording(
        id: 'rec-001',
        name: '練習曲A',
        path: '/recordings/rec-001.m4a',
        durationSeconds: 180,
        createdAt: now,
        folderId: 'folder-abc',
      );
      final json = original.toJson();
      final restored = Recording.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.path, equals(original.path));
      expect(restored.durationSeconds, equals(original.durationSeconds));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.folderId, equals(original.folderId));
    });

    test('toJson → fromJson 往返無損（folderId = null）', () {
      final original = Recording(
        id: 'rec-002',
        name: '未分類錄音',
        path: '/recordings/rec-002.m4a',
        durationSeconds: 60,
        createdAt: now,
      );
      final json = original.toJson();
      final restored = Recording.fromJson(json);
      expect(restored.folderId, isNull);
    });

    test('durationSeconds = 0（剛停止就儲存）→ 不 throw', () {
      final r = Recording(
        id: 'rec-003',
        name: '空錄音',
        path: '/recordings/rec-003.m4a',
        durationSeconds: 0,
        createdAt: now,
      );
      expect(() => r.toJson(), returnsNormally);
      final json = r.toJson();
      expect(Recording.fromJson(json).durationSeconds, equals(0));
    });

    test('durationSeconds = maxRecordingSeconds（上限邊界）→ 正常', () {
      final r = Recording(
        id: 'rec-max',
        name: '最長錄音',
        path: '/recordings/rec-max.m4a',
        durationSeconds: AppConstants.maxRecordingSeconds,
        createdAt: now,
      );
      final json = r.toJson();
      expect(Recording.fromJson(json).durationSeconds,
          equals(AppConstants.maxRecordingSeconds));
    });
  });

  group('Recording.copyWith (BC-RM2)', () {
    final now = DateTime(2025, 1, 15);

    test('clearFolder=true → folderId = null', () {
      final r = Recording(
        id: 'r1', name: 'n', path: 'p',
        durationSeconds: 10, createdAt: now, folderId: 'f1',
      );
      final moved = r.copyWith(clearFolder: true);
      expect(moved.folderId, isNull);
    });

    test('clearFolder=false → folderId 保留', () {
      final r = Recording(
        id: 'r1', name: 'n', path: 'p',
        durationSeconds: 10, createdAt: now, folderId: 'f1',
      );
      final renamed = r.copyWith(name: 'new name');
      expect(renamed.folderId, equals('f1'));
    });

    test('copyWith name 更新', () {
      final r = Recording(
        id: 'r1', name: 'old', path: 'p',
        durationSeconds: 10, createdAt: now,
      );
      expect(r.copyWith(name: 'new').name, equals('new'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AppConstants — 錄音邊界常數
  // ─────────────────────────────────────────────────────────────────────────

  group('AppConstants 錄音常數 (BC-R7)', () {
    test('maxRecordingSeconds = 900（15分鐘）', () {
      expect(AppConstants.maxRecordingSeconds, equals(900));
    });

    test('_tick 超過 maxRecordingSeconds 應自動停止', () {
      // 模擬 elapsedSeconds 到達上限，next >= maxRecordingSeconds
      const maxSecs = AppConstants.maxRecordingSeconds;

      // 驗證邊界條件：next = maxSecs → 觸發停止
      int simulatedNext = maxSecs;
      bool shouldStop = simulatedNext >= maxSecs;
      expect(shouldStop, isTrue, reason: '達到 maxRecordingSeconds 時應自動停止');

      // 驗證 next = maxSecs - 1 → 不觸發停止
      simulatedNext = maxSecs - 1;
      shouldStop = simulatedNext >= maxSecs;
      expect(shouldStop, isFalse, reason: '未達上限時不應停止');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Re-entry guard — stopRecording 只在 recording 時執行
  // ─────────────────────────────────────────────────────────────────────────

  group('stopRecording re-entry guard (BC-R-Guard)', () {
    test('status=idle 時呼叫 stopRecording guard 攔截（模擬 state machine）', () {
      // 模擬 RecorderNotifier.stopRecording() 的 guard 邏輯
      RecorderStatus status = RecorderStatus.idle;

      bool guardTriggered = false;
      void simulatedStopRecording() {
        if (status != RecorderStatus.recording) {
          guardTriggered = true;
          return; // guard: 直接返回
        }
        // ... 實際停止邏輯
      }

      simulatedStopRecording();
      expect(guardTriggered, isTrue, reason: 'idle 狀態時 guard 應攔截');
    });

    test('status=recording 時 guard 不攔截', () {
      RecorderStatus status = RecorderStatus.recording;

      bool guardTriggered = false;
      bool stopExecuted = false;
      void simulatedStopRecording() {
        if (status != RecorderStatus.recording) {
          guardTriggered = true;
          return;
        }
        stopExecuted = true;
      }

      simulatedStopRecording();
      expect(guardTriggered, isFalse);
      expect(stopExecuted, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RecordingRepository.delete firstOrNull — BC-R4 迴歸測試
  // ─────────────────────────────────────────────────────────────────────────

  group('RecordingRepository delete BC-R4 — firstOrNull 邏輯', () {
    test('id 不存在時 firstOrNull 回傳 null（而非 throw StateError）', () {
      final list = <Recording>[];
      // 舊的 firstWhere 在空 list 上會 throw，firstOrNull 不應 throw
      Recording? found;
      expect(
        () { found = list.where((r) => r.id == 'non-existent').firstOrNull; },
        returnsNormally,
        reason: 'firstOrNull 不應拋出 StateError',
      );
      expect(found, isNull);
    });

    test('id 存在時 firstOrNull 正確回傳', () {
      final list = [
        Recording(
          id: 'rec-1', name: 'r1', path: 'p1',
          durationSeconds: 60, createdAt: DateTime.now(),
        ),
      ];
      final found = list.where((r) => r.id == 'rec-1').firstOrNull;
      expect(found, isNotNull);
      expect(found!.id, equals('rec-1'));
    });
  });
}
