import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ensemble.dart';
import '../models/ensemble_event.dart';

class EnsembleRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ensembles =>
      _db.collection('ensembles');

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('ensembleEvents');

  // ── Invite code generation ─────────────────────────────────────────────

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ── Ensemble CRUD ─────────────────────────────────────────────────────

  Future<Ensemble> createEnsemble(String name, String adminId) async {
    final code = _generateInviteCode();
    final now = DateTime.now();
    final ref = _ensembles.doc();
    final ensemble = Ensemble(
      id: ref.id,
      name: name,
      adminId: adminId,
      memberIds: [adminId],
      inviteCode: code,
      createdAt: now,
    );
    await ref.set(ensemble.toJson());
    return ensemble;
  }

  Future<Ensemble?> getEnsembleByInviteCode(String code) async {
    final snap = await _ensembles
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return Ensemble.fromJson({...d.data(), 'id': d.id});
  }

  Future<void> joinEnsemble(String ensembleId, String userId) async {
    await _ensembles.doc(ensembleId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> updateEnsemble(
    String ensembleId, {
    String? description,
    String? instrumentSection,
  }) async {
    final data = <String, dynamic>{};
    if (description != null) data['description'] = description;
    if (instrumentSection != null) {
      data['instrumentSection'] = instrumentSection;
    }
    if (data.isNotEmpty) {
      await _ensembles.doc(ensembleId).update(data);
    }
  }

  Future<List<Ensemble>> getEnsemblesForUser(String userId) async {
    final snap = await _ensembles
        .where('memberIds', arrayContains: userId)
        .get();
    return snap.docs
        .map((d) => Ensemble.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  // ── Ensemble events ────────────────────────────────────────────────────

  Stream<List<EnsembleEvent>> watchEventsForEnsemble(
    String ensembleId,
    int year,
    int month,
  ) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return _events
        .where('ensembleId', isEqualTo: ensembleId)
        .where('startTime', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('startTime', isLessThan: end.toIso8601String())
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EnsembleEvent.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  Future<void> saveEvent(EnsembleEvent event) async {
    await _events.doc(event.id).set(event.toJson());
  }

  Future<void> markAttendance(
    String eventId,
    String userId,
    bool attending,
  ) async {
    final update = attending
        ? FieldValue.arrayUnion([userId])
        : FieldValue.arrayRemove([userId]);
    await _events.doc(eventId).update({'attendingUserIds': update});
  }
}
