import 'models/card_entry.dart';
import 'models/rarity.dart';

/// Rarity-tuned thresholds for the "play to earn" path. A card unlocks
/// once the player has burst the matching smashable this many times in
/// total (across all rounds, all packs that contain it). Values picked
/// to give Commons a single-tap reveal moment, while making Legendaries
/// feel like a milestone — bursting one Legendary squishy 15 times is
/// roughly half a dozen rounds even with pity boosts.
class CardUnlockThresholds {
  const CardUnlockThresholds._();

  static int requiredBursts(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return 1;
      case Rarity.rare:
        return 3;
      case Rarity.epic:
        return 7;
      case Rarity.mythic:
        return 15;
    }
  }
}

/// Coin price for the "skip the grind" purchase path. Scales with
/// rarity so Common cards stay affordable on a casual coin budget while
/// Legendaries cost a serious chunk — they should still feel earned
/// even when bought.
class CardCoinPrice {
  const CardCoinPrice._();

  static int coinsFor(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return 50;
      case Rarity.rare:
        return 200;
      case Rarity.epic:
        return 750;
      case Rarity.mythic:
        return 2500;
    }
  }
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
}) {
  if (cardsPurchased.contains(card.cardNumber)) {
    return CardUnlockSource.purchased;
  }
  if (unlockedFromAchievements.contains(card.cardNumber)) {
    return CardUnlockSource.achievement;
  }
  final bursts = cardBurstCounts[card.cardNumber] ?? 0;
  if (bursts >= CardUnlockThresholds.requiredBursts(card.rarity)) {
    return CardUnlockSource.burstThreshold;
  }
  return CardUnlockSource.locked;
}

bool isCardUnlocked({
  required CardEntry card,
  required Map<String, int> cardBurstCounts,
  required Set<String> cardsPurchased,
  required Set<String> unlockedFromAchievements,
}) =>
    resolveCardUnlock(
      card: card,
      cardBurstCounts: cardBurstCounts,
      cardsPurchased: cardsPurchased,
      unlockedFromAchievements: unlockedFromAchievements,
    ) !=
    CardUnlockSource.locked;
