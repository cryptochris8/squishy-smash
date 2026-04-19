import 'package:flutter/painting.dart';

class Tunables {
  Tunables._();

  static const Duration tapToHoldPromotion = Duration(milliseconds: 120);
  static const Duration squashRecover = Duration(milliseconds: 220);
  static const Duration crushRamp = Duration(milliseconds: 700);

  static const Duration comboDecay = Duration(milliseconds: 1400);
  static const int comboMaxMultiplier = 8;

  static const int decalCap = 30;
  static const Duration decalFade = Duration(seconds: 5);

  static const double pitchJitter = 0.06;
  static const double minRespawnDelaySeconds = 0.35;
}

class Palette {
  Palette._();

  static const Color bgDeep = Color(0xFF120B17);
  static const Color bgSurface = Color(0xFF1A1320);
  static const Color pink = Color(0xFFFF8FB8);
  static const Color cream = Color(0xFFFFD36E);
  static const Color jellyBlue = Color(0xFF7FE7FF);
  static const Color toxicLime = Color(0xFFB6FF5C);
}
