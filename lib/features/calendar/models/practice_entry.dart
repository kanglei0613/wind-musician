import 'package:flutter/material.dart' show TimeOfDay;

/// 練習紀錄類型
enum PracticeEntryType {
  personal,  // 個人練習
  rehearsal, // 排練行程
}

class PracticeEntry {
  final String id;
  final String userId;
  final DateTime date; // just the date, not time
  final int durationMinutes;
  final String content; // free text: what was practiced
  final String? ensembleId; // null = personal practice
  final bool isSharedWithFriends;

  // ── 排練行程專屬欄位 ──────────────────
  final PracticeEntryType type;
  final String? rehearsalEnsembleName; // 排練的樂團名稱（自由輸入）
  final String? location;             // 排練地點（選填）
  final TimeOfDay? startTime;         // 排練開始時間（選填）
  final TimeOfDay? endTime;           // 排練結束時間（選填）

  const PracticeEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.durationMinutes,
    required this.content,
    this.ensembleId,
    this.isSharedWithFriends = false,
    this.type = PracticeEntryType.personal,
    this.rehearsalEnsembleName,
    this.location,
    this.startTime,
    this.endTime,
  });

  bool get isRehearsal => type == PracticeEntryType.rehearsal;

  PracticeEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? durationMinutes,
    String? content,
    String? ensembleId,
    bool clearEnsemble = false,
    bool? isSharedWithFriends,
    PracticeEntryType? type,
    String? rehearsalEnsembleName,
    String? location,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool clearRehearsal = false,
  }) {
    return PracticeEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      content: content ?? this.content,
      ensembleId: clearEnsemble ? null : (ensembleId ?? this.ensembleId),
      isSharedWithFriends: isSharedWithFriends ?? this.isSharedWithFriends,
      type: type ?? this.type,
      rehearsalEnsembleName: clearRehearsal ? null : (rehearsalEnsembleName ?? this.rehearsalEnsembleName),
      location: clearRehearsal ? null : (location ?? this.location),
      startTime: clearRehearsal ? null : (startTime ?? this.startTime),
      endTime: clearRehearsal ? null : (endTime ?? this.endTime),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date.toIso8601String(),
        'durationMinutes': durationMinutes,
        'content': content,
        'ensembleId': ensembleId,
        'isSharedWithFriends': isSharedWithFriends,
        'type': type.name,
        'rehearsalEnsembleName': rehearsalEnsembleName,
        'location': location,
        'startTimeHour': startTime?.hour,
        'startTimeMinute': startTime?.minute,
        'endTimeHour': endTime?.hour,
        'endTimeMinute': endTime?.minute,
      };

  factory PracticeEntry.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(dynamic h, dynamic m) {
      if (h == null || m == null) return null;
      return TimeOfDay(hour: h as int, minute: m as int);
    }

    return PracticeEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      durationMinutes: json['durationMinutes'] as int,
      content: json['content'] as String,
      ensembleId: json['ensembleId'] as String?,
      isSharedWithFriends: (json['isSharedWithFriends'] as bool?) ?? false,
      type: PracticeEntryType.values.firstWhere(
        (e) => e.name == (json['type'] as String?),
        orElse: () => PracticeEntryType.personal,
      ),
      rehearsalEnsembleName: json['rehearsalEnsembleName'] as String?,
      location: json['location'] as String?,
      startTime: parseTime(json['startTimeHour'], json['startTimeMinute']),
      endTime: parseTime(json['endTimeHour'], json['endTimeMinute']),
    );
  }
}
