import 'package:flutter/material.dart';

/// Bookfania's reading companion. The transparent artwork lets it sit naturally
/// on cards, empty states, and the welcome screen.
class ReadingCat extends StatelessWidget {
  final double size;
  final Alignment alignment;
  final String? semanticLabel;

  const ReadingCat({
    super.key,
    this.size = 180,
    this.alignment = Alignment.bottomCenter,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: semanticLabel == null,
      child: Semantics(
        image: true,
        label: semanticLabel,
        child: SizedBox(
          width: size,
          height: size,
          child: Align(
            alignment: alignment,
            child: Image.asset(
              'assets/images/reading_cat.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
