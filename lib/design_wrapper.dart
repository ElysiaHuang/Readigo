import 'package:flutter/material.dart';
import 'package:testapp3/util/constants.dart';

class DesignWrapper extends StatelessWidget {
  final Widget wrappedWidget;

  const DesignWrapper({super.key, required this.wrappedWidget});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 58,
        centerTitle: false,
        elevation: 0,
        backgroundColor: Constants.appBar,
        foregroundColor: Constants.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const Text(
          "Bookfania",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Constants.ink,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Constants.butter, Constants.surfaceAlt],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: wrappedWidget,
      ),
    );
  }
}
