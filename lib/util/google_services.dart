import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleServices{
  static Future<bool> signInWithGoogle() async {
    try {
      final _googleSignIn = GoogleSignIn.instance;
      _googleSignIn.initialize(
          serverClientId: "452556427282-eg8gun227afo58d79p4iiq6kfbnobkpu.apps.googleusercontent.com"
      );

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();


      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      // Once signed in, return the UserCredential
      await FirebaseAuth.instance.signInWithCredential(credential);
       return true;
    } catch (e) {
      print('$e');
      return false;
    }
  }
  static Future<void> adduser(String Username,String email)async{
    CollectionReference users= FirebaseFirestore.instance.collection("users");
    users.add({
      "username":Username,
      "email": email,
      "dateCreated":FieldValue.serverTimestamp()

    });
  }
}

