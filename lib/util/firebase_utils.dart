import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUtils {
  static Future<bool> adduser(String? username,String email)async{
    CollectionReference users= FirebaseFirestore.instance.collection("users");
    try {
      String? friendCode = await getCurrentUserFriendCode();

      if(friendCode == null){
        friendCode = await generateUniqueFriendCode();
        DocumentSnapshot docRef=await users.doc(friendCode).get();
        if(!docRef.exists) {
          users.doc(friendCode).set({
            "username": username,
            "username_lower": username?.toLowerCase(),
            "email": email,
            "dateCreated": FieldValue.serverTimestamp(),
            "books": [],
            "level": 1,
            "xp": 0,
            "next_level_xp": 100,
            "friends": [],
            "bio": "Welcome to my profile!",
            "friendCode": friendCode,
            "profilePic": "https://imgcdn.stablediffusionweb.com/2024/4/15/437c2a91-01ea-4d6b-b7c4-d489155207f7.jpg",
          });
        }
      }

      return true;
    } catch (e) {
      throw Exception("Error adding new user to Firestore: $e");
    }

  }

  static String generateFriendCode([int length = 5]) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // exclude 0, O, 1
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static Future<String> generateUniqueFriendCode() async {
    final users = FirebaseFirestore.instance.collection('users');
    String code;
    bool exists;

    do {
      code = generateFriendCode();
      final doc = await users.doc(code).get();
      exists = doc.exists;
    } while (exists);

    return code;
  }

  static Future<String?> getCurrentUserFriendCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null; // Not signed in

    final users = FirebaseFirestore.instance.collection('users');

    final snapshot = await users.where('email', isEqualTo: user.email).limit(1).get();

    if (snapshot.docs.isEmpty) return null; // No user found

    return snapshot.docs.first.id;
  }

  static Future<Map<String, dynamic>?> getUserData(String friendCode) async {
    try {
      DocumentReference doc=FirebaseFirestore.instance.collection("users").doc(friendCode);//get users data in firebase
      final snapshot = await doc.get(); // returns DocumentSnapshot
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        return userData;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>?> getUserBooks(String friendCode)async{
    try {
      final userData = await getUserData(friendCode);
      if(userData != null){
        final books=userData["books"];
        return books;
      } else {
        return null;
      }
    } catch (e) {
      throw Exception("Failed to fetch user's books: $e");
    }
  }

  static Future<List<dynamic>?> getUserFriends(String friendCode) async {
    try {
      final userData = await getUserData(friendCode);
      if(userData != null){
        final friends=userData["friends"];
        return friends;
      } else {
        return null;
      }
    } catch (e) {
      throw Exception("Failed to fetch user's friends: $e");
    }
  }

  static Future<List<Map<String, dynamic>>?> searchUserByUsername(String username) async {
    try {
      final lower = username.toLowerCase();
      final end = '$lower\uf8ff';

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username_lower', isGreaterThanOrEqualTo: lower)
          .where('username_lower', isLessThanOrEqualTo: end)
          .get();

      return snapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUser(String friendCode, Map<String, dynamic> newData) async {
    final users = FirebaseFirestore.instance.collection('users');

    // If username is being updated, also update username_lower
    if (newData.containsKey('username')) {
      final username = newData['username'];
      if (username is String) {
        newData['username_lower'] = username.toLowerCase();
      }
    }

    await users.doc(friendCode).update(newData);
  }

  static Future<void> addFriend(String currentUserCode, String friendCode) async {
    final users = FirebaseFirestore.instance.collection('users');

    await users.doc(currentUserCode).update({
      "friends": FieldValue.arrayUnion([friendCode]),
    });
  }

  static Future<bool> isFriends(String currentUserCode, String friendCode) async {
    final users = FirebaseFirestore.instance.collection('users');

    final doc = await users.doc(currentUserCode).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final List friends = data["friends"] ?? [];

    return friends.contains(friendCode);
  }

  static Future<void> removeFriend(String currentUserCode, String friendCode) async {
    final users = FirebaseFirestore.instance.collection('users');

    await users.doc(currentUserCode).update({
      "friends": FieldValue.arrayRemove([friendCode]),
    });
  }
}