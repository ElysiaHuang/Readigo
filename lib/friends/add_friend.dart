import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/friends/friend_tile.dart';

import '../util/firebase_utils.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final friendSearchController = TextEditingController();
  List<Map<String, dynamic>> friendList = [];
  String listMessage = "Search for a friend";

  void searchFriend() async {
    final String friendSearch = friendSearchController.text;

    if(friendSearch.isEmpty){
      setState(() {
        friendList.clear();
        listMessage = "Type something in the search bar";
      });
      return;
    }

    final user = await FirebaseUtils.getUserData(friendSearch);
    if(user == null){ // if we couldn't find the friend using code
      final users = await FirebaseUtils.searchUserByUsername(friendSearch);
      if(users != null) { //If we found users with that username
        friendList = users;
      } else { // No users found.
        friendList.clear();
        listMessage = "No users found :(";
      }
    } else {
      friendList.clear();
      friendList.add(user);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Readigo",
              style: TextStyle(
                  fontSize: 36,
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.greenAccent,offset: Offset(3, 3),blurRadius: 15)]
              ),
            ),
            Image.asset(height: 87,"assets/images/ReadigoLogo.png")

          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 21,
            ),
            Text("Add Friend",style: TextStyle(fontSize: 35,fontFamily: "Voltaire"),),
            SizedBox(height: 5,),
            Container(
              height: 50, width: 320,
              decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(20)

              ),
              child: Row(
                children: [
                  Container(
                    padding:
                    EdgeInsets.only(
                        left: 25
                    ),
                    height: 36, width: 264,
                    child: TextField(
                      controller: friendSearchController,
                      decoration: InputDecoration(
                        hintText: "Type friend code or username"
                      ),
                    ),
                  ),
                  IconButton(onPressed:() => searchFriend(), icon: Icon(Icons.search, size: 36,)  ,)
                ],
              ),
            ),
            Expanded(
              child: friendList.isEmpty
                  ? Center(child: Text(listMessage))
                  : ListView.builder(
                    itemCount: friendList.length,
                    itemBuilder: (context, index) {
                      final friend = friendList[index];
                      return FriendTile(
                          profilePic: friend["profilePic"],
                          level: friend["level"],
                          friendCode: friend["friendCode"],
                          username: friend["username"]);
                    },
                  )
              ),
          ],
        ),
      ),
    );
  }
}
