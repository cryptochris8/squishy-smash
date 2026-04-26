/// One celebratory reward callout — "+N coins · reason!" — fired by
/// the burst pipeline when the player crosses something worth
/// noticing. The UI's RewardToastOverlay subscribes to a stream of
/// these and renders each as a floating drift-and-fade toast.
///
/// Pure data — keep this Flutter-free so the firing code in
/// SquishyGame and the test harness can both construct events
/// without pulling in widgets.
class RewardEvent {
  const RewardEvent({
    required this.id,
    required this.coinAmount,
    required this.label,
    required this.tint,
  });

  /// Unique identifier so the overlay can `Key`-match each toast and
  /// remove it cleanly when its lifetime ends. Built from a
  /// monotonic counter — see `RewardEvent.duplicate` / `.milestone`.
  final int id;

  /// Coins awarded. Always positive — we don't surface negative
  /// adjustments through this channel.
  final int coinAmount;

  /// Subtitle line, e.g. `"Duplicate!"` or `"Pack 50%!"`. Kept short
  /// (≤ 16 chars) so the toast fits a phone screen.
  final String label;

  /// Color hint passed to the toast for tinting the text + glow.
  /// 0xAARRGGBB ARGB encoding. The widget converts to a Flutter
  /// Color at render time.
  final int tint;

  // -- Convenience constructors. Keep the tint palette in one place
  // here rather than scattered across firing call-sites.

  /// Cream/gold — used for duplicate-burst coin bonuses.
  static const int _kDuplicateTint = 0xFFFFD36E;

  /// Toxic-lime — used for pack-completion milestones (more
  /// "achievement" energy).
  static const int _kMilestoneTint = 0xFFB6FF5C;

  /// Jelly-blue — used for the "boost token applied" notice so the
  /// player can SEE the token being spent rather than have it vanish
  /// into the first spawn (P1.7).
  static const int _kBoostTint = 0xFF7FE7FF;

  const RewardEvent.duplicate({
    required this.id,
    required this.coinAmount,
  })  : label = 'Duplicate!',
        tint = _kDuplicateTint;

  /// Milestone reward. The `percent` param expands into the label
  /// `"Pack N%!"` — done via string interpolation in the const
  /// initializer so this stays const-constructible (factory bodies
  /// can't be const).
  const RewardEvent.milestone({
    required this.id,
    required this.coinAmount,
    required int percent,
  })  : label = 'Pack $percent%!',
        tint = _kMilestoneTint;

  /// Boost token consumed announcement. Zero coins (it's a status
  /// callout, not a reward) but reuses the toast channel so the
  /// player gets visible feedback that their token was spent.
  const RewardEvent.boostUsed({
    required this.id,
  })  : coinAmount = 0,
        label = 'Boost ready!',
        tint = _kBoostTint;
}
