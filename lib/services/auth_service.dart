import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
  print('1. Starting Google sign-in');
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    print('2. Google user: ${googleUser?.email}');
    
    if (googleUser == null) {
      print('3. User cancelled sign-in');
      return null;
    }

    final GoogleSignInAuthentication googleAuth = 
        await googleUser.authentication;
    print('4. Got Google auth tokens');

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    print('5. Created Firebase credential');

    UserCredential userCredential = 
        await _auth.signInWithCredential(credential);
    print('6. Firebase sign-in successful: ${userCredential.user?.email}');

    return userCredential.user;
  } catch (e) {
    print('7. Error in Google sign-in: $e');
    return null;
  }
}
}