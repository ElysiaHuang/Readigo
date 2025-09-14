import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class friendspage extends StatefulWidget {
  const friendspage({super.key});

  @override
  State<friendspage> createState() => _friendspageState();
}

class _friendspageState extends State<friendspage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(
            height: 21,
      ),
          Text("Friends",style: TextStyle(fontSize: 35,fontFamily: "Voltaire"),),
          SizedBox(height: 5,),
          Container(
            height: 50, width: 300,
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

                  ),
                ),
                Icon(Icons.search,size: 36  ,)
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                friendtile(

                  profilepic: 'https://imgcdn.stablediffusionweb.com/2024/4/15/437c2a91-01ea-4d6b-b7c4-d489155207f7.jpg',
username: "Dogg_12323", message: 'HIII!!!!', friendcode: '#00001',

                ),
                friendtile(

                  profilepic: 'https://imgcdn.stablediffusionweb.com/2024/4/15/437c2a91-01ea-4d6b-b7c4-d489155207f7.jpg',
                  username: "Dogg_12323", message: 'HIII!!!!', friendcode: '#00002',

                ),
                friendtile(

                  profilepic: 'https://imgcdn.stablediffusionweb.com/2024/2/23/da8fbab2-4c52-469c-8f91-437b89850f61.jpg',
                  username: "Cattt_12323", message: ':(((!', friendcode: '#00003',

                ),



              ],
            ),
          )
        ],
      ),
    );
  }
}
class friendtile extends StatefulWidget {
  final String profilepic;
  final String username;
  final String friendcode;
  final String message;
  const friendtile({super.key,required this.profilepic,required this.message, required this.friendcode, required this.username});

  @override
  State<friendtile> createState() => _friendtileState();
}

class _friendtileState extends State<friendtile> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
                    backgroundImage: NetworkImage(widget.profilepic),
                  ),
                  SizedBox(
                    width: 100,child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.username,style: TextStyle(fontSize: 20,fontFamily: "Voltaire"),),
                        Text(widget.friendcode,style: TextStyle(fontSize: 21,fontFamily: "Voltaire"),),
                      ],
                                ),
                    ),
                  ),
                ],
              ),
            ),
             Text(widget.message)
          ],
        ),
      ),
    );
  }
}
