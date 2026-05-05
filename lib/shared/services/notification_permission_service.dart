import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android 13+（API 33+）POST_NOTIFICATIONS 執行期授權請求。
///
/// Android 13 起，App 必須在執行期主動請求 POST_NOTIFICATIONS 權限，
/// 否則前景服務通知（如節拍器）會在裝置上被靜默忽略。
///
/// 使用 permission_handler v12+：
///   - Android 12 以下：[Permission.notification.status] 直接回傳 granted，不彈出對話框。
///   - Android 13+：若尚未授予，彈出系統權限對話框。
///   - 若使用者選擇「永不詢問」：靜默跳過，不強制導向設定頁。
///
/// 呼叫時機：在 [main()] 初始化流程完成後、[runApp] 之前呼叫一次即可。
Future<void> requestNotificationPermissionIfNeeded() async {
  if (!Platform.isAndroid) return;
  final status = await Permission.notification.status;
  if (status.isDenied) {
    await Permission.notification.request();
  }
}

/// 在使用者嘗試啟動節拍器時，確認通知權限已授予。
///
/// - [PermissionStatus.granted]：直接回傳 true，允許啟動。
/// - [PermissionStatus.denied]：再次顯示系統授權對話框。
/// - [PermissionStatus.permanentlyDenied]：顯示多語言說明對話框，引導使用者前往系統設定。
/// - 非 Android 平台（iOS / 桌面）：直接回傳 true，不做任何檢查。
///
/// 回傳 true 表示可繼續啟動節拍器；false 表示使用者未授予，應中止啟動。
Future<bool> checkAndRequestNotificationForMetronome(BuildContext context) async {
  if (!Platform.isAndroid) return true;

  final status = await Permission.notification.status;
  if (status.isGranted) return true;

  if (status.isDenied) {
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  if (status.isPermanentlyDenied) {
    if (!context.mounted) return false;

    // Determine dialog text from system locale
    final locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final isZh = locale == 'zh';
    final isJa = locale == 'ja';
    final isKo = locale == 'ko';

    final title = isZh ? '需要通知權限' : isJa ? '通知の許可が必要' : isKo ? '알림 권한 필요' : 'Notification Permission';
    final body = isZh
        ? '節拍器在背景執行時需要顯示通知。請在設定中開啟通知權限。'
        : isJa
            ? 'メトロノームがバックグラウンドで動作するには通知の表示が必要です。設定で通知を許可してください。'
            : isKo
                ? '메트로놈이 백그라운드에서 실행될 때 알림을 표시해야 합니다. 설정에서 알림 권한을 활성화해 주세요.'
                : 'The metronome needs to show a notification when running in the background. Please enable notification permission in Settings.';
    final openSettings = isZh ? '前往設定' : isJa ? '設定を開く' : isKo ? '설정 열기' : 'Open Settings';
    final cancel = isZh ? '取消' : isJa ? 'キャンセル' : isKo ? '취소' : 'Cancel';

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(openSettings),
          ),
        ],
      ),
    );
    if (shouldOpen == true) await openAppSettings();
    return false;
  }

  return true;
}
