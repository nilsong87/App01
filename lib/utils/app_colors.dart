import 'package:flutter/material.dart';

Map<int, Color> getMaterialColor(int hexColor) {
  return {
    50: Color(hexColor).withAlpha((255 * 0.1).round()),
    100: Color(hexColor).withAlpha((255 * 0.2).round()),
    200: Color(hexColor).withAlpha((255 * 0.3).round()),
    300: Color(hexColor).withAlpha((255 * 0.4).round()),
    400: Color(hexColor).withAlpha((255 * 0.5).round()),
    500: Color(hexColor).withAlpha((255 * 0.6).round()),
    600: Color(hexColor).withAlpha((255 * 0.7).round()),
    700: Color(hexColor).withAlpha((255 * 0.8).round()),
    800: Color(hexColor).withAlpha((255 * 0.9).round()),
    900: Color(hexColor).withAlpha((255 * 1.0).round()),
  };
}

final MaterialColor primaryColor = MaterialColor(
  0xFF72577C,
  getMaterialColor(0xFF72577C),
);
final MaterialColor accentColor = MaterialColor(
  0xFF562155,
  getMaterialColor(0xFF562155),
);
final MaterialColor lightBlue = MaterialColor(
  0xFFC5F7F0,
  getMaterialColor(0xFFC5F7F0),
);
final MaterialColor mediumBlue = MaterialColor(
  0xFFA9C2C9,
  getMaterialColor(0xFFA9C2C9),
);
final MaterialColor grayPurple = MaterialColor(
  0xFF8E8CA3,
  getMaterialColor(0xFF8E8CA3),
);
