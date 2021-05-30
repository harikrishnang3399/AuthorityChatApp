import 'package:authority_chat_app/helperfunctions/sharedpref_helper.dart';
import 'package:authority_chat_app/services/database.dart';
import 'package:authority_chat_app/views/chatscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  getCurrentUser() async {
    return auth.currentUser;
  }

  Future saveSharedPrefs(userDetails) async {
    String username =
        "Authority${userDetails.email.replaceAll("@gmail.com", "")}";
    await SharedPreferenceHelper().saveUserEmail(userDetails.email);
    await SharedPreferenceHelper().saveUserId(userDetails.uid);
    await SharedPreferenceHelper().saveUserName(username);
    await SharedPreferenceHelper().saveDisplayName(userDetails.displayName);
    await SharedPreferenceHelper().saveUserProfileUrl(userDetails.photoURL);
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    final GoogleSignInAccount _googleSignInAccount =
        await _googleSignIn.signIn();

    final GoogleSignInAuthentication googleSignInAuthentication =
        await _googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken);
    UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    User userDetails = userCredential.user;

    await saveSharedPrefs(userDetails);

    Map<String, dynamic> userInfoMap = {
      "email": userDetails.email,
      "username": "Authority${userDetails.email.replaceAll("@gmail.com", "")}",
      "name": "Authority",
    };

    DatabaseMethods()
        .addUserInfoToDB(userDetails.uid, userInfoMap)
        .then((value) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ChatScreen()));
    });
  }

  Future signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    await auth.signOut();
  }
}
