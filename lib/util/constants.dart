import 'package:flutter/material.dart';

class Constants{
  static AppBar defaultAppBar = AppBar(
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
  );

  static ButtonStyle normalButton = OutlinedButton.styleFrom(
      backgroundColor: Color(0xFFEBFFEE),
      foregroundColor: Color(0xFF41BF41),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
      )
  );
}