class EnsembleEvent {
  final String id;
  final String ensembleId;
  final String title; // e.g. "合奏排練", "音樂會前總彩排"
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? notes; // practice content, what to prepare
  final List<String> attendingUserIds; // who confirmed attendance

  const EnsembleEvent({
    required this.id,
    required this.ensembleId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
    this.notes,
    this.attendingUserIds = const [],
  });

  EnsembleEvent copyWith({
    String? id,
    String? ensembleId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? notes,
    List<String>? attendingUserIds,
  }) {
    return EnsembleEvent(
      id: id ?? this.id,
      ensembleId: ensembleId ?? this.ensembleId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      attendingUserIds: attendingUserIds ?? this.attendingUserIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ensembleId': ensembleId,
        'title': title,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'location': location,
        'notes': notes,
        'attendingUserIds': attendingUserIds,
      };

  factory EnsembleEvent.fromJson(Map<String, dynamic> json) => EnsembleEvent(
        id: json['id'] as String,
        ensembleId: json['ensembleId'] as String,
        title: json['title'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        location: json['location'] as String?,
        notes: json['notes'] as String?,
        attendingUserIds: List<String>.from(
          (json['attendingUserIds'] as List?) ?? [],
        ),
      );
}
