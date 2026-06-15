import 'package:flutter/material.dart';

/// Border radius tokens for cards, buttons, and inputs.
abstract final class AppRadius {
  static const double card = 16;
  static const double button = 12;
  static const double input = 12;

  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get buttonBorder => BorderRadius.circular(button);
  static BorderRadius get inputBorder => BorderRadius.circular(input);
}
