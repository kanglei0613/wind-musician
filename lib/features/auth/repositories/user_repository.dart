library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('users');

  Future<AppUser?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<void> createUser(AppUser user) async {
    await _col.doc(user.uid).set(user.toJson());
  }

  Future<void> updateLastActive(String uid) async {
    await _col.doc(uid).update({
      'lastActiveAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateDisplayName(String uid, String displayName) async {
    await _col.doc(uid).update({'displayName': displayName});
  }

  /// Persist user preference settings to Firestore so they sync across devices.
  Future<void> updateSettings(
    String uid, {
    String? language,
    String? colorScheme,
    String? colorBrightness,
  }) async {
    final data = <String, dynamic>{};
    if (language != null) data['language'] = language;
    if (colorScheme != null) data['colorScheme'] = colorScheme;
    if (colorBrightness != null) data['colorBrightness'] = colorBrightness;
    if (data.isEmpty) return;
    await _col.doc(uid).update(data);
  }
}
