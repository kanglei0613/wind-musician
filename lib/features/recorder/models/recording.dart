class Recording {
  final String id;
  final String name;
  final String path;
  final int durationSeconds;
  final DateTime createdAt;
  final String? folderId; // null = 未分類

  const Recording({
    required this.id,
    required this.name,
    required this.path,
    required this.durationSeconds,
    required this.createdAt,
    this.folderId,
  });

  Recording copyWith({
    String? id,
    String? name,
    String? path,
    int? durationSeconds,
    DateTime? createdAt,
    String? folderId,
    bool clearFolder = false,
  }) {
    return Recording(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'durationSeconds': durationSeconds,
        'createdAt': createdAt.toIso8601String(),
        'folderId': folderId,
      };

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
        durationSeconds: json['durationSeconds'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        folderId: json['folderId'] as String?,
      );
}
