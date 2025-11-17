import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/design_wrapper.dart';
import 'package:testapp3/profile/profile.dart';

class FriendTile extends StatelessWidget {
  final String profilePic;
  final String username;
  final String friendCode;
  final int level;
  const FriendTile({super.key,required this.profilePic,required this.level, required this.friendCode, required this.username});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DesignWrapper(wrappedWidget: ProfileScreen(friendCode: friendCode))));
      },
      child: Container(
        margin: EdgeInsets.only(top: 20),
        height: 95,
        decoration: BoxDecoration(
          color: CupertinoColors.extraLightBackgroundGray,
      
        ),
        child: Container(padding: EdgeInsets.only(
            left: 5, right: 5
        ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 180,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 37,
                      backgroundImage: NetworkImage(profilePic),
                    ),
                    SizedBox(
                      width: 100,child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(username,style: TextStyle(fontSize: 20,fontFamily: "Voltaire"),),
                          Text(friendCode,style: TextStyle(fontSize: 21,fontFamily: "Voltaire"),),
                        ],
                      ),
                    ),
                    ),
                  ],
                ),
              ),
              Text("Level $level")
            ],
          ),
        ),
      ),
    );
  }
}
