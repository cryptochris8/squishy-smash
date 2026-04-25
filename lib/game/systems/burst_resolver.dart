import '../../data/models/player_profile.dart';
import '../../data/models/rarity.dart';
import '../../data/models/smashable_def.dart';
import 'feedback_dispatcher.dart';

/// Pure-data summary of what a burst should do — computed without any
/// Flame or persistence side effects. `SquishyGame._handleBurst` builds
/// one of these from current state, then applies the side effects
/// (analytics, persistence, visuals) using fields below as the recipe.
///
/// Pulling decision-making into this struct + [BurstResolver] keeps the
/// per-burst math unit-testable without spinning up a Flame harness or
/// initializing `ServiceLocator`.
class BurstOutcome {
  const BurstOutcome({
    required this.def,
    required this.rarity,
    required this.burstScoreBonus,
    required this.baseCoinReward,
    required this.duplicateCoinBonus,
    required this.isFirstBurst,
    required this.feedbackTier,
    required this.triggersReveal,
    required this.skyboxRevealHold,
    required this.bloomPeakOpacity,
    required this.bloomDuration,
    required this.triggersMythicShake,
    required this.fireMythicReveal,
    required this.fireFirstRareReveal,
    required this.fireMegaBurstAnalytics,
  });

  /// The smashable that just burst — passed through so dispatchers
  /// have it without reading the component again.
  final SmashableDef def;

  /// Convenience rarity accessor (== `def.rarity`).
  final Rarity rarity;

  /// Base score the burst contributes before applying combo multiplier.
  /// `score.addBurst(burstScoreBonus, multiplier: comboMultiplier)`.
  final int burstScoreBonus;

  /// Coins always awarded for the burst (regardless of duplicate).
  final int baseCoinReward;

  /// Extra coins for a duplicate burst. 0 when [isFirstBurst] is true.
  final int duplicateCoinBonus;

  /// Sum of coins to award. Caller routes both to the wallet and to
  /// the round's running total.
  int get totalCoinsAwarded => baseCoinReward + duplicateCoinBonus;

  /// True iff the player has never burst this smashable before.
  /// Source-of-truth check is against `profile.discoveredSmashableIds`
  /// at resolve time.
  final bool isFirstBurst;

  /// Which feedback bundle (sound + haptic + voice) to dispatch.
  /// Rarity wins over combo: a Mythic at combo 1 still reveals.
  final FeedbackTier feedbackTier;

  /// True when the rarity warrants a skybox swap + bloom flash.
  final bool triggersReveal;

  /// How long the skybox stays in its reveal variant. Mythic gets
  /// extra dwell so the moment lands.
  final double skyboxRevealHold;

  /// Peak opacity of the reveal bloom flash. 0.0 when no reveal.
  final double bloomPeakOpacity;

  /// How long the bloom flash takes to fade. Mythic stretches longer
  /// to extend the "whoa" beat.
  final Duration bloomDuration;

  /// Whether to fire the heavier screen shake (Mythic only).
  final bool triggersMythicShake;

  /// Whether to invoke the `onMythicReveal` callback (UI clip prompt).
  final bool fireMythicReveal;

  /// Whether to invoke the `onFirstRareReveal` callback (Starter Bundle
  /// paywall). Gated on rare+, not-yet-fired-this-round, and the
  /// starter bundle not already claimed.
  final bool fireFirstRareReveal;

  /// Whether to fire the `mega_burst_triggered` analytics event. Mirrors
  /// `feedbackTier == FeedbackTier.megaBurst` — exposed separately so
  /// callers don't need to import the FeedbackTier enum just to check.
  final bool fireMegaBurstAnalytics;
}

class BurstResolver {
  const BurstResolver();

  /// Compute the [BurstOutcome] for a burst event.
  ///
  /// All inputs are read-only — the resolver does not mutate the
  /// profile or any other state. The caller is responsible for applying
  /// the outcome's side effects in the order it sees fit.
  BurstOutcome resolve({
    required SmashableDef def,
    required PlayerProfile profile,
    required int comboMultiplier,
    required bool firstRareAlreadyFiredThisRound,
  }) {
    final rarity = def.rarity;
    final burstScoreBonus = _scoreBonusFor(def);
    final isFirstBurst = !profile.discoveredSmashableIds.contains(def.id);
    final duplicateBonus = isFirstBurst ? 0 : rarity.duplicateCoinBonus;
    final feedbackTier = _feedbackTierFor(rarity, comboMultiplier);
    final triggersReveal = rarity.triggersReveal;
    final isMythic = rarity == Rarity.mythic;

    // First-rare paywall trigger gates on three preconditions: the
    // rarity is rare-or-better, we haven't already fired this round,
    // and the starter bundle isn't already claimed.
    final fireFirstRareReveal = rarity.index >= Rarity.rare.index &&
        !firstRareAlreadyFiredThisRound &&
        !profile.starterBundleClaimed;

    return BurstOutcome(
      def: def,
      rarity: rarity,
      burstScoreBonus: burstScoreBonus,
      baseCoinReward: def.coinReward,
      duplicateCoinBonus: duplicateBonus,
      isFirstBurst: isFirstBurst,
      feedbackTier: feedbackTier,
      triggersReveal: triggersReveal,
      skyboxRevealHold: isMythic ? 1.6 : 1.0,
      bloomPeakOpacity: _bloomPeakFor(rarity),
      bloomDuration: Duration(milliseconds: isMythic ? 700 : 450),
      triggersMythicShake: isMythic,
      fireMythicReveal: isMythic,
      fireFirstRareReveal: fireFirstRareReveal,
      fireMegaBurstAnalytics: feedbackTier == FeedbackTier.megaBurst,
    );
  }

  static int _scoreBonusFor(SmashableDef def) =>
      25 + (def.gooLevel * 30).round();

  static FeedbackTier _feedbackTierFor(Rarity rarity, int comboMultiplier) {
    // Rarity wins over combo: a mythic at combo 1 should still reveal.
    // Common+ bursts upgrade to megaBurst once the multiplier hits 3+.
    if (rarity.triggersReveal) return FeedbackTier.revealBurst;
    if (comboMultiplier >= 3) return FeedbackTier.megaBurst;
    return FeedbackTier.burst;
  }

  static double _bloomPeakFor(Rarity rarity) {
    switch (rarity) {
      case Rarity.rare:
        return 0.35;
      case Rarity.epic:
        return 0.50;
      case Rarity.mythic:
        return 0.65;
      case Rarity.common:
        return 0.0;
    }
  }
}
