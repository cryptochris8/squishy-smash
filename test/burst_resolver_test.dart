import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/player_profile.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/data/models/smashable_def.dart';
import 'package:squishy_smash/game/systems/burst_resolver.dart';
import 'package:squishy_smash/game/systems/feedback_dispatcher.dart';

SmashableDef _def({
  String id = 'dumplio',
  Rarity rarity = Rarity.common,
  double gooLevel = 0.5,
  int coinReward = 10,
  String? cardNumber,
}) =>
    SmashableDef(
      id: id,
      name: id,
      category: 'test',
      themeTag: 'test',
      sprite: 'assets/images/objects/$id.png',
      thumbnail: 'assets/images/thumbnails/${id}_thumb.png',
      deformability: 0.5,
      elasticity: 0.5,
      burstThreshold: 0.7,
      gooLevel: gooLevel,
      impactSounds: <String>['audio/test/$id.mp3'],
      burstSound: 'audio/test/${id}_burst.mp3',
      particlePreset: 'test',
      decalPreset: 'test',
      coinReward: coinReward,
      unlockTier: 0,
      searchTags: const <String>[],
      rarity: rarity,
      cardNumber: cardNumber,
    );

void main() {
  const resolver = BurstResolver();

  group('BurstResolver score + coins', () {
    test('burstScoreBonus is 25 + round(gooLevel * 30)', () {
      final out = resolver.resolve(
        def: _def(gooLevel: 0.5),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.burstScoreBonus, 25 + 15); // round(0.5 * 30)
    });

    test('burstScoreBonus floors gooLevel correctly across the range', () {
      // Sanity check the rounding edges
      final low = resolver.resolve(
        def: _def(gooLevel: 0.0),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      final high = resolver.resolve(
        def: _def(gooLevel: 1.0),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(low.burstScoreBonus, 25);
      expect(high.burstScoreBonus, 55);
    });

    test('first burst awards no duplicate bonus', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.epic, coinReward: 30),
        profile: PlayerProfile.empty(), // empty discovered set
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.isFirstBurst, isTrue);
      expect(out.duplicateCoinBonus, 0);
      expect(out.totalCoinsAwarded, 30); // base only
    });

    test('duplicate burst awards rarity-scaled bonus', () {
      final p = PlayerProfile.empty()
        ..discoveredSmashableIds.add('dumplio');
      final out = resolver.resolve(
        def: _def(rarity: Rarity.mythic, coinReward: 50),
        profile: p,
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.isFirstBurst, isFalse);
      // Rarity.mythic.duplicateCoinBonus is 50
      expect(out.duplicateCoinBonus, 50);
      expect(out.totalCoinsAwarded, 100);
    });
  });

  group('BurstResolver feedback tier', () {
    test('mythic at combo 1 still triggers reveal (rarity beats combo)', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.mythic),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.feedbackTier, FeedbackTier.revealBurst);
    });

    test('common at combo 3+ upgrades to megaBurst', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.common),
        profile: PlayerProfile.empty(),
        comboMultiplier: 3,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.feedbackTier, FeedbackTier.megaBurst);
      expect(out.fireMegaBurstAnalytics, isTrue);
    });

    test('common at combo 1 is plain burst (no upgrade)', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.common),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.feedbackTier, FeedbackTier.burst);
      expect(out.fireMegaBurstAnalytics, isFalse);
    });

    test('rare at combo 5 reveals (rarity wins, not megaBurst)', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.rare),
        profile: PlayerProfile.empty(),
        comboMultiplier: 5,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.feedbackTier, FeedbackTier.revealBurst);
      expect(out.fireMegaBurstAnalytics, isFalse);
    });
  });

  group('BurstResolver visual-effect math', () {
    test('common: no reveal, no bloom, no shake', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.common),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.triggersReveal, isFalse);
      expect(out.bloomPeakOpacity, 0.0);
      expect(out.triggersMythicShake, isFalse);
      expect(out.fireMythicReveal, isFalse);
    });

    test('rare: reveal at 0.35 bloom, no shake', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.rare),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.triggersReveal, isTrue);
      expect(out.bloomPeakOpacity, 0.35);
      expect(out.triggersMythicShake, isFalse);
      expect(out.skyboxRevealHold, 1.0);
      expect(out.bloomDuration.inMilliseconds, 450);
    });

    test('epic: reveal at 0.50 bloom, no shake', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.epic),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.bloomPeakOpacity, 0.50);
      expect(out.triggersMythicShake, isFalse);
      expect(out.bloomDuration.inMilliseconds, 450);
    });

    test('mythic: reveal at 0.65 bloom, longer flash, shake, callback', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.mythic),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.bloomPeakOpacity, 0.65);
      expect(out.bloomDuration.inMilliseconds, 700);
      expect(out.skyboxRevealHold, 1.6);
      expect(out.triggersMythicShake, isTrue);
      expect(out.fireMythicReveal, isTrue);
    });
  });

  group('BurstResolver Starter Bundle paywall trigger', () {
    test('fires on first rare burst when bundle not yet claimed', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.rare),
        profile: PlayerProfile.empty(), // starterBundleClaimed = false
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.fireFirstRareReveal, isTrue);
    });

    test('does NOT fire if already fired this round (one-shot)', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.rare),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: true,
      );
      expect(out.fireFirstRareReveal, isFalse);
    });

    test('does NOT fire if Starter Bundle already claimed', () {
      final p = PlayerProfile.empty()..starterBundleClaimed = true;
      final out = resolver.resolve(
        def: _def(rarity: Rarity.rare),
        profile: p,
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.fireFirstRareReveal, isFalse);
    });

    test('does NOT fire on a common burst', () {
      final out = resolver.resolve(
        def: _def(rarity: Rarity.common),
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.fireFirstRareReveal, isFalse);
    });

    test('fires on epic + mythic too (any rare-or-better)', () {
      for (final r in [Rarity.epic, Rarity.mythic]) {
        final out = resolver.resolve(
          def: _def(rarity: r),
          profile: PlayerProfile.empty(),
          comboMultiplier: 1,
          firstRareAlreadyFiredThisRound: false,
        );
        expect(out.fireFirstRareReveal, isTrue, reason: '$r');
      }
    });
  });

  group('BurstResolver purity (no profile mutation)', () {
    test('does not mutate the input profile', () {
      // The resolver must be a read-only operation. The dispatcher
      // is responsible for any side effects.
      final p = PlayerProfile.empty()
        ..discoveredSmashableIds.add('jellyzap');
      final beforeDiscovered = Set<String>.from(p.discoveredSmashableIds);
      final beforeCoins = p.coins;
      final beforeStarter = p.starterBundleClaimed;

      resolver.resolve(
        def: _def(id: 'dumplio', rarity: Rarity.epic),
        profile: p,
        comboMultiplier: 5,
        firstRareAlreadyFiredThisRound: false,
      );

      expect(p.discoveredSmashableIds, beforeDiscovered);
      expect(p.coins, beforeCoins);
      expect(p.starterBundleClaimed, beforeStarter);
    });
  });

  group('BurstResolver outcome plumbing', () {
    test('def and rarity pass through unchanged', () {
      final def = _def(id: 'sparkle_mochi', rarity: Rarity.rare);
      final out = resolver.resolve(
        def: def,
        profile: PlayerProfile.empty(),
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.def, same(def));
      expect(out.rarity, Rarity.rare);
    });

    test('totalCoinsAwarded matches base + duplicate', () {
      final p = PlayerProfile.empty()
        ..discoveredSmashableIds.add('dumplio');
      final out = resolver.resolve(
        def: _def(id: 'dumplio', rarity: Rarity.epic, coinReward: 30),
        profile: p,
        comboMultiplier: 1,
        firstRareAlreadyFiredThisRound: false,
      );
      expect(out.totalCoinsAwarded,
          out.baseCoinReward + out.duplicateCoinBonus);
    });
  });
}
