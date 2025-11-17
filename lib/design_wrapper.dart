import 'package:flutter/material.dart';

class DesignWrapper extends StatelessWidget {
  final Widget wrappedWidget;

  const DesignWrapper({super.key, required this.wrappedWidget});

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
        child: Container(
          child: wrappedWidget,
        ),
      ),
    );
  }
}