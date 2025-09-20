import 'package:flutter/material.dart';

class profilescreen extends StatefulWidget {
  const profilescreen({super.key});

  @override
  State<profilescreen> createState() => _profilescreenState();
}

class _profilescreenState extends State<profilescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Center(
        child: Column(
          children: [
            Container(
              child: Row(
                children: [
                  Container(
                    width: 111,
                    child: Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 37,
                            backgroundImage: NetworkImage('https://imgcdn.stablediffusionweb.com/2024/4/15/437c2a91-01ea-4d6b-b7c4-d489155207f7.jpg'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 111,
                    child: Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 37,
                            backgroundImage: NetworkImage('https://imgcdn.stablediffusionweb.com/2024/4/15/437c2a91-01ea-4d6b-b7c4-d489155207f7.jpg'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 111,
                    child: Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 37,
                            backgroundImage: NetworkImage('https://imgcdn.stablediffusionweb.com/2024/4/15/437c2a91-01ea-4d6b-b7c4-d489155207f7.jpg'),
                          ),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            height:200, width: 333,
              margin: EdgeInsets.only(top: 35, bottom:30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Color(0xfff2f2f7)
              ),
        )
          ],
        ),
      )
    );
  }

}
