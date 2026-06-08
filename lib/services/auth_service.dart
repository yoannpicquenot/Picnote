import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn(
      serverClientId: '1055647633275-o9cf4k3731hma4pm5o44bfajmvqj1d2d.apps.googleusercontent.com',
    ).signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    await ensureUserDoc(userCred.user!);
    return userCred;
  }

  static Future<void> ensureUserDoc(User user) async {
    try {
      final ref = _db.collection('users').doc(user.uid);
      final snap = await ref.get().timeout(const Duration(seconds: 10));
      if (!snap.exists) {
        await ref.set({
          'email': user.email,
          'displayName': user.displayName ?? user.email,
          'partnerId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  // Returns: 'paired' | 'waiting' | 'onboarding'
  static Future<String> getRoute(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get()
          .timeout(const Duration(seconds: 10));
      if (!snap.exists) return 'onboarding';
      final data = snap.data()!;
      if (data['partnerId'] != null) return 'paired';
      if (data['inviteEmail'] != null) return 'waiting';
      return 'onboarding';
    } catch (_) {
      return 'onboarding';
    }
  }

  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data();
  }
}
