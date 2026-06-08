import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PairService {
  static final _db = FirebaseFirestore.instance;

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

  static Future<String?> getPendingInviteEmail(String uid) async {
    final snap = await _db
        .collection('invites')
        .where('fromUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data()['toEmail'] as String?;
  }
}
