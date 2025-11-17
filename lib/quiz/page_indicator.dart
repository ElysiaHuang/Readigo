import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const PageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        bool isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF41BF41)   // active color
                : const Color(0xFFC0FFC0), // inactive
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }
}