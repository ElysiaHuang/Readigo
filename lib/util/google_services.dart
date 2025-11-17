import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_utils.dart';

class GoogleServices{
  static Future<bool> signInWithGoogle() async {
    try {
      final _googleSignIn = GoogleSignIn.instance;
      _googleSignIn.initialize(
          serverClientId: "550818826311-9okroqsll4hhrma17qsfplkcc2er76ek.apps.googleusercontent.com"
      );

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();


      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      // Once signed in, return the UserCredential
      await FirebaseAuth.instance.signInWithCredential(credential);
      FirebaseUtils.adduser(googleUser.displayName, googleUser.email);
       return true;
    } catch (e) {
      print('$e');
      return false;
    }
  }

}

