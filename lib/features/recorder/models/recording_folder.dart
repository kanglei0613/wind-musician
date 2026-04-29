class RecordingFolder {
  final String id;
  final String name;
  final DateTime createdAt;

  const RecordingFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  RecordingFolder copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return RecordingFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecordingFolder.fromJson(Map<String, dynamic> json) =>
      RecordingFolder(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
