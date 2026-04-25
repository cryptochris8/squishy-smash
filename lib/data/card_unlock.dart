import 'models/card_entry.dart';
import 'models/economy_config.dart';
import 'models/rarity.dart';

/// Const-default config used when no [EconomyConfig] is passed.
/// Matches the v0.1.0 baseline so callers that omit the parameter
/// see exactly what shipped before the rebalance landed.
const EconomyConfig _defaultEconomy = EconomyConfig();

/// Rarity-tuned thresholds for the "play to earn" path. A card unlocks
/// once the player has burst the matching smashable this many times in
/// total (across all rounds, all packs that contain it).
///
/// **Reads from [EconomyConfig] when supplied.** Production callers
/// pass `ServiceLocator.economy` so a single JSON edit re-tunes
/// every threshold. Tests can omit the param to get the v0.1.0
/// baseline or pass a hand-built config to exercise specific values.
class CardUnlockThresholds {
  const CardUnlockThresholds._();

  static int requiredBursts(Rarity rarity, {EconomyConfig? config}) =>
      (config ?? _defaultEconomy).requiredBurstsFor(rarity);
}

/// Coin price for the "skip the grind" purchase path. Same config-
/// driven contract as [CardUnlockThresholds].
class CardCoinPrice {
  const CardCoinPrice._();

  static int coinsFor(Rarity rarity, {EconomyConfig? config}) =>
      (config ?? _defaultEconomy).coinPriceFor(rarity);
}

/// Pure unlock-derivation. Three independent paths: any one is enough.
///
/// 1. Burst threshold — `cardBurstCounts[card.cardNumber] >= threshold`
/// 2. Direct purchase — `cardsPurchased.contains(card.cardNumber)`
/// 3. Achievement reward — handled by the caller via `unlockedFromAchievements`
///
/// Returning a strongly-typed result rather than a bare `bool` so the
/// UI can show *how* the card was unlocked (badge on the card detail
/// view: "Earned", "Purchased", "Achievement").
enum CardUnlockSource { locked, burstThreshold, purchased, achievement }

CardUnlockSource resolveCardUnlock({
  required CardEntry card,
  required Map<String, int> cardBurstCounts,
  required Set<String> cardsPurchased,
  required Set<String> unlockedFromAchievements,
  Set<String> grandfatheredCards = const <String>{},
  EconomyConfig? config,
}) {
  if (cardsPurchased.contains(card.cardNumber)) {
    return CardUnlockSource.purchased;
  }
  if (unlockedFromAchievements.contains(card.cardNumber)) {
    return CardUnlockSource.achievement;
  }
  // Burst path — current threshold OR a grandfather snapshot from a
  // previous (looser) economy. Both report as `burstThreshold` since
  // semantically the player earned the card through play; the
  // distinction matters only at migration time.
  final bursts = cardBurstCounts[card.cardNumber] ?? 0;
  final required =
      CardUnlockThresholds.requiredBursts(card.rarity, config: config);
  if (bursts >= required || grandfatheredCards.contains(card.cardNumber)) {
    return CardUnlockSource.burstThreshold;
  }
  return CardUnlockSource.locked;
}

bool isCardUnlocked({
  required CardEntry card,
  required Map<String, int> cardBurstCounts,
  required Set<String> cardsPurchased,
  required Set<String> unlockedFromAchievements,
  Set<String> grandfatheredCards = const <String>{},
  EconomyConfig? config,
}) =>
    resolveCardUnlock(
      card: card,
      cardBurstCounts: cardBurstCounts,
      cardsPurchased: cardsPurchased,
      unlockedFromAchievements: unlockedFromAchievements,
      grandfatheredCards: grandfatheredCards,
      config: config,
    ) !=
    CardUnlockSource.locked;

/// Snapshot every card that the player would have had unlocked under
/// the v0.1.0 baseline economy into [profile.grandfatheredCards].
///
/// The migration runs once when transitioning from a pre-v4 save to
/// v4. After it runs, those cards stay unlocked forever even if a
/// later JSON tightening would have locked them — once-unlocked-
/// always-unlocked is the contract, and this is how we honor it.
///
/// Pure: mutates the passed [PlayerProfile] but has no I/O. Caller is
/// responsible for persisting the result.
void grandfatherUnlocksFromBaseline({
  required Iterable<CardEntry> cards,
  required Map<String, int> cardBurstCounts,
  required Set<String> grandfatheredOut,
}) {
  // Always evaluated against the const-default config (v0.1.0 baseline)
  // — the threshold the player was actually earning under at the time
  // these bursts happened.
  const baseline = EconomyConfig();
  for (final card in cards) {
    final bursts = cardBurstCounts[card.cardNumber] ?? 0;
    final required =
        baseline.requiredBurstsFor(card.rarity);
    if (bursts >= required) {
      grandfatheredOut.add(card.cardNumber);
    }
  }
}
