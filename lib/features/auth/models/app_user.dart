library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an authenticated app user stored in Firestore.
/// Mirrors the Firestore document at users/{uid}.
class AppUser {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  // User preferences — synced across devices via Firestore.
  final String? language;       // 'zh' | 'en' | 'ja' | 'ko'
  final String? colorScheme;    // AppColorScheme.name
  final String? colorBrightness; // AppBrightness.name

  const AppUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.createdAt,
    required this.lastActiveAt,
    this.language,
    this.colorScheme,
    this.colorBrightness,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastActiveAt': Timestamp.fromDate(lastActiveAt),
        if (language != null) 'language': language,
        if (colorScheme != null) 'colorScheme': colorScheme,
        if (colorBrightness != null) 'colorBrightness': colorBrightness,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String?,
        photoUrl: json['photoUrl'] as String?,
        createdAt: (json['createdAt'] as Timestamp).toDate(),
        lastActiveAt: (json['lastActiveAt'] as Timestamp).toDate(),
        language: json['language'] as String?,
        colorScheme: json['colorScheme'] as String?,
        colorBrightness: json['colorBrightness'] as String?,
      );

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    String? language,
    String? colorScheme,
    String? colorBrightness,
  }) =>
      AppUser(
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt ?? this.createdAt,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        language: language ?? this.language,
        colorScheme: colorScheme ?? this.colorScheme,
        colorBrightness: colorBrightness ?? this.colorBrightness,
      );
}
