library;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Possible feedback topics – keep in sync with [_topicLabel].
enum _Topic { bug, feature, question, other }

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  _Topic _topic = _Topic.bug;
  final _descCtrl = TextEditingController();

  // Device / app info (loaded in initState)
  String _appVersion = '';
  String _buildNumber = '';
  String _deviceModel = '';
  String _osVersion = '';

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    String model = '';
    String os = '';

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      model = iosInfo.utsname.machine; // e.g. iPhone16,1
      os = 'iOS ${iosInfo.systemVersion}';
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      model = '${androidInfo.manufacturer} ${androidInfo.model}';
      os = 'Android ${androidInfo.version.release}';
    }

    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _deviceModel = model;
        _osVersion = os;
      });
    }
  }

  String _topicLabel(_Topic t) {
    switch (t) {
      case _Topic.bug:
        return '🐛 Bug 回報';
      case _Topic.feature:
        return '💡 功能建議';
      case _Topic.question:
        return '❓ 問題/疑惑';
      case _Topic.other:
        return '📝 其他';
    }
  }

  String _topicLabelEn(_Topic t) {
    switch (t) {
      case _Topic.bug:
        return 'Bug';
      case _Topic.feature:
        return 'Feature';
      case _Topic.question:
        return 'Question';
      case _Topic.other:
        return 'Other';
    }
  }

  Future<void> _send() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請描述你遇到的問題或建議')),
      );
      return;
    }

    setState(() => _sending = true);

    final subject =
        '[MuKlang][${_topicLabelEn(_topic)}] v$_appVersion($_buildNumber) - $_deviceModel $_osVersion';

    final body = '''
【問題類型】${_topicLabel(_topic)}
【App 版本】MuKlang v$_appVersion (Build $_buildNumber)
【裝置】$_deviceModel
【系統】$_osVersion

【詳細描述】
$desc
''';

    final uri = Uri(
      scheme: 'mailto',
      path: 'kla7522@gmail.com',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法開啟郵件 App，請確認裝置有設定郵件帳號')),
        );
      }
    }

    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.drawerBugReport),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Topic picker ────────────────────────────────────────────────
            _SectionLabel('問題類型'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _Topic.values.map((t) {
                  return RadioListTile<_Topic>(
                    dense: true,
                    title: Text(_topicLabel(t)),
                    value: t,
                    groupValue: _topic,
                    onChanged: (v) => setState(() => _topic = v!),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Description ─────────────────────────────────────────────────
            _SectionLabel('詳細描述（必填）'),
            const SizedBox(height: 4),
            Text(
              '請盡量說明：你按了什麼按鈕？發生了什麼事？有無錯誤訊息？',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 7,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: '例如：點了節拍器的開始按鈕後，App 突然關閉，重開後節拍器設定消失了。',
                filled: true,
                fillColor: cs.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Device info (read-only) ──────────────────────────────────────
            _SectionLabel('裝置資訊（自動填入）'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _appVersion.isEmpty
                  ? const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Column(
                      children: [
                        _InfoRow('App 版本', 'MuKlang v$_appVersion (Build $_buildNumber)'),
                        const Divider(height: 16),
                        _InfoRow('裝置', _deviceModel),
                        const Divider(height: 16),
                        _InfoRow('系統', _osVersion),
                      ],
                    ),
            ),

            const SizedBox(height: 32),

            // ── Submit ───────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('開啟郵件 App 傳送'),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                '點擊後會開啟你的郵件 App，確認後送出即可',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
