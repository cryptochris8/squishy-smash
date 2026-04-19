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
}
