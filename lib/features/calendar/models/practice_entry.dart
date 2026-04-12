class PracticeEntry {
  final String id;
  final String userId;
  final DateTime date; // just the date, not time
  final int durationMinutes;
  final String content; // free text: what was practiced
  final String? ensembleId; // null = personal practice
  final bool isSharedWithFriends;

  const PracticeEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.durationMinutes,
    required this.content,
    this.ensembleId,
    this.isSharedWithFriends = false,
  });

  PracticeEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? durationMinutes,
    String? content,
    String? ensembleId,
    bool clearEnsemble = false,
    bool? isSharedWithFriends,
  }) {
    return PracticeEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      content: content ?? this.content,
      ensembleId: clearEnsemble ? null : (ensembleId ?? this.ensembleId),
      isSharedWithFriends: isSharedWithFriends ?? this.isSharedWithFriends,
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
      };

  factory PracticeEntry.fromJson(Map<String, dynamic> json) => PracticeEntry(
        id: json['id'] as String,
        userId: json['userId'] as String,
        date: DateTime.parse(json['date'] as String),
        durationMinutes: json['durationMinutes'] as int,
        content: json['content'] as String,
        ensembleId: json['ensembleId'] as String?,
        isSharedWithFriends: (json['isSharedWithFriends'] as bool?) ?? false,
      );
}
