import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = 
          await googleUser!.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (error) {
      print("Google sign-in error: $error");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  DatabaseReference getUserRef(String userId) {
    return _database.child('users/$userId');
  }

  Future<void> backupData({
    required String userId,
    required String dataType,
    required Map<String, dynamic> data,
    DateTime? lastUpdated,
  }) async {
    final updates = {
      '$dataType/${data['id']}': {
        ...data,
        'lastUpdated': lastUpdated?.millisecondsSinceEpoch ?? 
            ServerValue.timestamp,
      }
    };
    await getUserRef(userId).update(updates);
  }

  Future<Map<String, dynamic>> fetchData(
    String userId, 
    String dataType,
  ) async {
    final snapshot = await getUserRef(userId).child(dataType).once();
    return snapshot.snapshot.value as Map<String, dynamic>? ?? {};
  }

  Stream<DatabaseEvent> getDataChanges(String userId, String dataType) {
    return getUserRef(userId).child(dataType).onValue;
  }
}