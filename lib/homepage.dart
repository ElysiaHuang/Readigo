import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/friends/friends.dart';
import 'package:testapp3/profile/profile.dart';
import 'package:testapp3/quiz/generate_quiz.dart';

import 'gradebook.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  List<Widget> pages=[
   generatequizscreen(),
    friendspage(),
    Text("books"),
    profilescreen(),
  ];

  int selectedpage=0;
  void onItemTap(int index){
    setState(() {
      selectedpage=index;
    });
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey,selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.teal,
        currentIndex: selectedpage,
          onTap: onItemTap,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.quiz),label: "quiz"),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined),label: "friends"),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book),label: "books"),
            BottomNavigationBarItem(icon: Icon(Icons.person),label: "profile")
          ]
      ),
      body: Center(
        child: Container(
          child: pages[selectedpage],
        ),
      ),
    );
  }
}
