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
      body: Card(
        color: Colors.grey,
        child: Row(
          children: [
            Container(
              child: Column(
                  children: [
                    Text("hi")
                  ],
            ),
              width: 50,
            ),
            Container(
              child: Column(
                children: [
                  Text("hi")
                ],
              ),
              width: 50,
            ),
            Container(
              child: Column(
                children: [
                  Text("hi")
                ],
              ),
              width: 50,
            )



          ],
        ),
      ),
    );
  }

}
