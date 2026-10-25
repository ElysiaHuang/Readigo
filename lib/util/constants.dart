import 'package:flutter/material.dart';

class Constants {
  // The palette comes from Bookfania's clay reading companion: oat paper,
  // cocoa covers, blush paw pads, and a small hint of reading-nook sage.
  static const Color butter = Color(0xFFF8F0E4);
  static const Color sky = Color(0xFFE5B8A8);
  static const Color ink = Color(0xFF4E382F);
  static const Color mutedInk = Color(0xFF7B675C);
  static const Color surfaceAlt = Color(0xFFE2E9D9);
  static const Color border = Color(0xFFD8C0AB);
  static const Color outline = Color(0xFFB99980);
  static const Color appBar = Color(0xFFFFF9F2);
  static const Color navSurface = Color(0xFFFFFCF7);
  static const Color cocoa = Color(0xFF6C4B3C);
  static const Color blush = Color(0xFFF3D0C6);
  static const Color sage = Color(0xFFB9C9AB);

  static ButtonStyle normalButton = OutlinedButton.styleFrom(
    backgroundColor: cocoa,
    foregroundColor: Colors.white,
    side: const BorderSide(color: outline, width: 1.2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    minimumSize: const Size.fromHeight(50),
  );

  static const Color primary = sky;
  static const Color accent = sky;
  static const Color surface = Color(0xFFFFFCF8);
  static const Color background = butter;

  static BoxDecoration cardBox = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: outline, width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}
