import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/friends/add_friend.dart';
import 'package:testapp3/util/firebase_utils.dart';

import 'friend_tile.dart';

class FriendsPage extends StatefulWidget {
  final String friendCode;

  const FriendsPage({super.key, required this.friendCode});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddFriendPage()));
        },
        child: Icon(Icons.add),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 21,
        ),
            Text("Friends",style: TextStyle(fontSize: 35,fontFamily: "Voltaire"),),
            SizedBox(height: 5,),
            Expanded(
              child: FutureBuilder(
                future: FirebaseUtils.getUserFriends(widget.friendCode),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No friends :("));
                  }
                  final userFriends = snapshot.data!;

                  return ListView.builder(
                    itemCount: userFriends.length,
                    itemBuilder: (context, index) {
                      final friendCode = userFriends[index];
                      return FutureBuilder(
                        future: FirebaseUtils.getUserData(friendCode),
                        builder: (context, asyncSnapshot) {
                          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          final friend = asyncSnapshot.data!;
                          return FriendTile(
                              profilePic: friend["profilePic"],
                              level: friend["level"],
                              friendCode: friend["friendCode"],
                              username: friend["username"]);
                        }
                      );
                    },
                  );
                }
              ),
            )
          ],
        ),
      ),
    );
  }
}
