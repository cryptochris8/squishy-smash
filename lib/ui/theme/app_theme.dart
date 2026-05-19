/// Design tokens for spacing and corner radii.
///
/// DS-2 from `GAME_POLISH_AUDIT.md`: collapses 11 distinct radii and 13
/// distinct spacing values used across screens/widgets down to a small,
/// named scale. All UI code should reach for these constants rather than
/// reintroducing magic numbers.
library;

import 'package:flutter/widgets.dart';

/// 4-based spacing ladder. Use for padding, margin, and gap values.
class AppSpacing {
  AppSpacing._();

  static const double xs2 = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

/// Corner radii. `dialog` is the outer frame of modal dialogs; the inner
/// content surface uses `dialog - 2` (exposed as `dialogInner`) to leave
/// the 2px border ring visible.
class AppRadii {
  AppRadii._();

  static const double chip = 6;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double dialog = 28;
  static const double dialogInner = 26;
  static const double full = 999;

  static const Radius chipR = Radius.circular(chip);
  static const Radius xsR = Radius.circular(xs);
  static const Radius smR = Radius.circular(sm);
  static const Radius mdR = Radius.circular(md);
  static const Radius lgR = Radius.circular(lg);
  static const Radius dialogR = Radius.circular(dialog);
  static const Radius dialogInnerR = Radius.circular(dialogInner);
  static const Radius fullR = Radius.circular(full);
}
