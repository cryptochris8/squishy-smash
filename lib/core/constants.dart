import 'package:flutter/painting.dart';

import '../data/models/rarity.dart';

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
  static const Color lavender = Color(0xFFC98BFF);
  static const Color rarityCommon = Color(0xFFB0B6C3);

  /// Single source of truth for the per-rarity tint used everywhere
  /// the UI signals "this is a rare/epic/legendary thing" — collection
  /// album tiles, card detail pills, HUD combo styling, shop badges.
  /// Adding a new rarity tier or recoloring an existing one is a
  /// one-file change here; everywhere else just calls this function.
  static Color rarityColor(Rarity r) {
    switch (r) {
      case Rarity.common:
        return rarityCommon;
      case Rarity.rare:
        return jellyBlue;
      case Rarity.epic:
        return lavender;
      case Rarity.mythic:
        return cream;
    }
  }
}
