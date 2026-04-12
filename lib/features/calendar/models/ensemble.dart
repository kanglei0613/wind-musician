class Ensemble {
  final String id;
  final String name;
  final String adminId; // userId of creator
  final List<String> memberIds;
  final String inviteCode; // 6-char alphanumeric, e.g. "AB12CD"
  final DateTime createdAt;
  final String? description;
  final String? instrumentSection; // e.g. "管樂團", "弦樂四重奏"

  const Ensemble({
    required this.id,
    required this.name,
    required this.adminId,
    required this.memberIds,
    required this.inviteCode,
    required this.createdAt,
    this.description,
    this.instrumentSection,
  });

  Ensemble copyWith({
    String? id,
    String? name,
    String? adminId,
    List<String>? memberIds,
    String? inviteCode,
    DateTime? createdAt,
    String? description,
    String? instrumentSection,
  }) {
    return Ensemble(
      id: id ?? this.id,
      name: name ?? this.name,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      instrumentSection: instrumentSection ?? this.instrumentSection,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'adminId': adminId,
        'memberIds': memberIds,
        'inviteCode': inviteCode,
        'createdAt': createdAt.toIso8601String(),
        'description': description,
        'instrumentSection': instrumentSection,
      };

  factory Ensemble.fromJson(Map<String, dynamic> json) => Ensemble(
        id: json['id'] as String,
        name: json['name'] as String,
        adminId: json['adminId'] as String,
        memberIds: List<String>.from(json['memberIds'] as List),
        inviteCode: json['inviteCode'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        description: json['description'] as String?,
        instrumentSection: json['instrumentSection'] as String?,
      );
}
