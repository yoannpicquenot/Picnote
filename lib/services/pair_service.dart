import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PairService {
  static final _db = FirebaseFirestore.instance;

  // ── Code-based pairing ────────────────────────────────────────────────────

  static String _generateCode() {
    // Unambiguous chars: no 0/O, 1/I
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Creates a new family space, stores it on the current user, returns the
  /// shareable 6-character code.
  static Future<String> createFamilySpace() async {
    final user = FirebaseAuth.instance.currentUser!;
    final code = _generateCode();

    final pairRef = _db.collection('pairs').doc();
    final batch = _db.batch();
    batch.set(pairRef, {
      'code': code,
      'users': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('users').doc(user.uid), {
      'pairId': pairRef.id,
    });
    await batch.commit();
    return code;
  }

  /// Joins an existing family space by code. Throws a human-readable message
  /// on invalid or full codes.
  static Future<void> joinFamilySpace(String code) async {
    final user = FirebaseAuth.instance.currentUser!;
    final upper = code.trim().toUpperCase();

    final snap = await _db
        .collection('pairs')
        .where('code', isEqualTo: upper)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('Code not found. Double-check and try again.');
    }

    final pairDoc = snap.docs.first;
    final pairId = pairDoc.id;
    final users = List<String>.from(pairDoc.data()['users'] ?? []);

    if (users.contains(user.uid)) {
      throw Exception('You are already in this space.');
    }
    if (users.length >= 2) {
      throw Exception('This space is already full.');
    }

    final creatorUid = users.first;
    final batch = _db.batch();
    batch.update(_db.collection('pairs').doc(pairId), {
      'users': FieldValue.arrayUnion([user.uid]),
    });
    batch.update(_db.collection('users').doc(user.uid), {
      'partnerId': creatorUid,
      'pairId': pairId,
    });
    batch.update(_db.collection('users').doc(creatorUid), {
      'partnerId': user.uid,
    });
    await batch.commit();
  }

  /// Returns true if paired immediately (partner already had an account),
  /// false if an invite email was sent.
  static Future<bool> sendInvite(String toEmail) async {
    final user = FirebaseAuth.instance.currentUser!;

    // Check if partner already has an account in Firestore
    final existing = await _db
        .collection('users')
        .where('email', isEqualTo: toEmail)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Partner already exists — pair immediately, no email needed
      final partnerUid = existing.docs.first.id;
      final pairRef = _db.collection('pairs').doc();

      final batch = _db.batch();
      batch.set(pairRef, {
        'users': [user.uid, partnerUid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_db.collection('users').doc(user.uid), {
        'partnerId': partnerUid,
        'pairId': pairRef.id,
        'inviteEmail': FieldValue.delete(),
      });
      batch.update(_db.collection('users').doc(partnerUid), {
        'partnerId': user.uid,
        'pairId': pairRef.id,
        'inviteEmail': FieldValue.delete(),
      });
      await batch.commit();
      return true; // immediately paired
    }

    // Partner doesn't have an account yet — create the pair doc now
    // so the sender can already add tasks while waiting
    final pairRef = _db.collection('pairs').doc();
    await pairRef.set({
      'users': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Store pairId on sender immediately + mark invite pending
    await _db.collection('users').doc(user.uid).update({
      'inviteEmail': toEmail,
      'pairId': pairRef.id,
    });

    // Create invite doc (carries the pairId so acceptor joins same pair)
    final inviteRef = _db.collection('invites').doc();
    await inviteRef.set({
      'fromUid': user.uid,
      'fromEmail': user.email,
      'toEmail': toEmail,
      'pairId': pairRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final settings = ActionCodeSettings(
      url: 'https://picnote-b8c02.firebaseapp.com/?inviteId=${inviteRef.id}&inviterEmail=${Uri.encodeComponent(user.email ?? '')}',
      handleCodeInApp: true,
      androidPackageName: 'com.example.picnote',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );

    await FirebaseAuth.instance.sendSignInLinkToEmail(
      email: toEmail,
      actionCodeSettings: settings,
    );

    return false; // invite sent
  }

  /// Called when the partner clicks the invite link and signs in.
  static Future<void> acceptInvite(String inviteId, String acceptorUid) async {
    final inviteSnap = await _db.collection('invites').doc(inviteId).get();
    if (!inviteSnap.exists) return;

    final data = inviteSnap.data()!;
    final fromUid = data['fromUid'] as String;
    final pairId = data['pairId'] as String;

    final batch = _db.batch();
    // Add acceptor to the existing pair
    batch.update(_db.collection('pairs').doc(pairId), {
      'users': FieldValue.arrayUnion([acceptorUid]),
    });
    batch.update(_db.collection('users').doc(fromUid), {
      'partnerId': acceptorUid,
      'inviteEmail': FieldValue.delete(),
    });
    batch.update(_db.collection('users').doc(acceptorUid), {
      'partnerId': fromUid,
      'pairId': pairId,
    });
    batch.delete(_db.collection('invites').doc(inviteId));
    await batch.commit();
  }

  static Future<bool> partnerExists(String email) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Pairs the current user with an existing partner while in "waiting" state.
  /// Reuses the pending pair doc so no tasks are lost.
  static Future<void> connectExistingPartner(String partnerEmail) async {
    final user = FirebaseAuth.instance.currentUser!;

    final partnerSnap = await _db
        .collection('users')
        .where('email', isEqualTo: partnerEmail)
        .limit(1)
        .get();
    if (partnerSnap.docs.isEmpty) throw Exception('Partner not found');
    final partnerUid = partnerSnap.docs.first.id;

    final userSnap = await _db.collection('users').doc(user.uid).get();
    final pairId = userSnap.data()?['pairId'] as String?;

    // Delete any pending invite from this user
    final invites = await _db
        .collection('invites')
        .where('fromUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    final batch = _db.batch();
    for (final doc in invites.docs) {
      batch.delete(doc.reference);
    }

    if (pairId != null) {
      batch.update(_db.collection('pairs').doc(pairId), {
        'users': FieldValue.arrayUnion([partnerUid]),
      });
    }
    batch.update(_db.collection('users').doc(user.uid), {
      'partnerId': partnerUid,
      'inviteEmail': FieldValue.delete(),
    });
    batch.update(_db.collection('users').doc(partnerUid), {
      'partnerId': user.uid,
      if (pairId != null) 'pairId': pairId,
    });
    await batch.commit();
  }

  static Future<String?> getPendingInviteEmail(String uid) async {
    final snap = await _db
        .collection('invites')
        .where('fromUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data()['toEmail'] as String?;
  }

  /// Changes the pending invite to a new email address, deletes the old invite
  /// doc, creates a new one, and resends the sign-in link.
  static Future<void> resendInvite(String newEmail) async {
    final user = FirebaseAuth.instance.currentUser!;

    // Find and delete the old invite
    final oldInvites = await _db
        .collection('invites')
        .where('fromUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    final oldPairId = oldInvites.docs.isNotEmpty
        ? oldInvites.docs.first.data()['pairId'] as String?
        : null;
    for (final doc in oldInvites.docs) {
      await doc.reference.delete();
    }

    // Retrieve pairId from user doc if not found in invite
    String pairId;
    if (oldPairId != null) {
      pairId = oldPairId;
    } else {
      final userSnap = await _db.collection('users').doc(user.uid).get();
      pairId = (userSnap.data()?['pairId'] as String?) ?? _db.collection('pairs').doc().id;
    }

    // Update user doc with new email
    await _db.collection('users').doc(user.uid).update({'inviteEmail': newEmail});

    // Create new invite doc
    final inviteRef = _db.collection('invites').doc();
    await inviteRef.set({
      'fromUid': user.uid,
      'fromEmail': user.email,
      'toEmail': newEmail,
      'pairId': pairId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final settings = ActionCodeSettings(
      url: 'https://picnote-b8c02.firebaseapp.com/?inviteId=${inviteRef.id}&inviterEmail=${Uri.encodeComponent(user.email ?? '')}',
      handleCodeInApp: true,
      androidPackageName: 'com.example.picnote',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );

    await FirebaseAuth.instance.sendSignInLinkToEmail(
      email: newEmail,
      actionCodeSettings: settings,
    );
  }
}
