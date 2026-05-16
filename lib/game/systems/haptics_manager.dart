import 'dart:async';

import 'package:flutter/services.dart';

class HapticsManager {
  HapticsManager({this.enabled = true});

  bool enabled;

  void light() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  void medium() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  void selection() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Two heavy impacts spaced 80 ms apart — used for rare/epic
  /// reveals so the haptic tier is physically distinct from a
  /// common burst (GAME_POLISH_AUDIT.md P1-C). Re-checks `enabled`
  /// on the scheduled callback so a settings toggle mid-pulse
  /// silences the trailing impact rather than emitting half a
  /// pattern after the player asked for quiet.
  void doublePulse() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    Timer(const Duration(milliseconds: 80), () {
      if (!enabled) return;
      HapticFeedback.heavyImpact();
    });
  }

  /// Three heavy impacts spaced 80 ms apart — reserved for the
  /// rarest beats in the game (mythic reveals + mega bursts). Same
  /// gate-on-callback safety as [doublePulse].
  void triplePulse() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    Timer(const Duration(milliseconds: 80), () {
      if (!enabled) return;
      HapticFeedback.heavyImpact();
    });
    Timer(const Duration(milliseconds: 160), () {
      if (!enabled) return;
      HapticFeedback.heavyImpact();
    });
  }
}
