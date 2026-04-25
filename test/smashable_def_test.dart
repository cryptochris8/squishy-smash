import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/behavior_profile.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/data/models/smashable_def.dart';

Map<String, dynamic> _base() => <String, dynamic>{
      'id': 'dumplio',
      'name': 'Dumplio',
      'category': 'squishy_food',
      'themeTag': 'viral_food_energy',
      'sprite': 'assets/images/objects/dumplio.png',
      'thumbnail': 'assets/images/thumbnails/dumplio_thumb.png',
      'deformability': 0.88,
      'elasticity': 0.62,
      'burstThreshold': 0.79,
      'gooLevel': 0.83,
      'impactSounds': <String>['audio/food/dumplio_squish_01.mp3'],
      'burstSound': 'audio/food/dumplio_burst_01.mp3',
      'particlePreset': 'pink_soup_burst',
      'decalPreset': 'soft_peach_splat',
      'coinReward': 8,
      'unlockTier': 1,
      'searchTags': <String>['squishy', 'dumpling'],
    };

void main() {
  group('SmashableDef.fromJson rarity', () {
    test('defaults to common when field missing (backward compat)', () {
      final def = SmashableDef.fromJson(_base());
      expect(def.rarity, Rarity.common);
      expect(def.dropWeight, isNull);
      expect(def.effectiveDropWeight, Rarity.common.defaultWeight);
    });

    test('parses explicit rarity token', () {
      final def = SmashableDef.fromJson(_base()..['rarity'] = 'mythic');
      expect(def.rarity, Rarity.mythic);
      expect(def.effectiveDropWeight, Rarity.mythic.defaultWeight);
    });

    test('unknown rarity token falls back to common', () {
      // "legendary" used to be unknown, but was deliberately added as
      // an alias for `Rarity.mythic` (see rarity.dart). Use a token
      // that's still unknown to assert the fallback behavior.
      final def =
          SmashableDef.fromJson(_base()..['rarity'] = 'made_up_tier');
      expect(def.rarity, Rarity.common);
    });

    test('"legendary" parses as Rarity.mythic (player-facing alias)', () {
      // Pins the new aliasing behavior at the SmashableDef boundary
      // — the loader uses `rarityFromToken` which accepts both forms.
      final def = SmashableDef.fromJson(_base()..['rarity'] = 'legendary');
      expect(def.rarity, Rarity.mythic);
    });

    test('explicit dropWeight overrides tier default', () {
      final def = SmashableDef.fromJson(
        _base()
          ..['rarity'] = 'rare'
          ..['dropWeight'] = 999,
      );
      expect(def.rarity, Rarity.rare);
      expect(def.dropWeight, 999);
      expect(def.effectiveDropWeight, 999);
    });

    test('preserves existing optional fields (hitsToBurst, massHint)', () {
      final def = SmashableDef.fromJson(
        _base()
          ..['hitsToBurst'] = 3
          ..['massHint'] = 1.8,
      );
      expect(def.hitsToBurst, 3);
      expect(def.massHint, 1.8);
    });

    test('massHint defaults to 1.0', () {
      final def = SmashableDef.fromJson(_base());
      expect(def.massHint, 1.0);
    });
  });

  group('SmashableDef.fromJson behavior profiles', () {
    Map<String, dynamic> stripped() {
      // A base JSON with physics fields removed — relies entirely on
      // a behaviorProfile to supply defaults.
      return <String, dynamic>{
        'id': 'dumplio',
        'name': 'Dumplio',
        'category': 'squishy_food',
        'themeTag': 'viral_food_energy',
        'sprite': 'assets/images/objects/dumplio.png',
        'thumbnail': 'assets/images/thumbnails/dumplio_thumb.png',
        'impactSounds': <String>['audio/food/dumplio_squish_01.mp3'],
        'burstSound': 'audio/food/dumplio_burst_01.mp3',
        'particlePreset': 'pink_soup_burst',
        'decalPreset': 'soft_peach_splat',
        'coinReward': 8,
        'unlockTier': 1,
        'searchTags': <String>['squishy', 'dumpling'],
      };
    }

    test('profile alone fills every physics field', () {
      final def = SmashableDef.fromJson(
        stripped()..['behaviorProfile'] = 'jelly_cube',
      );
      final expected = BehaviorProfile.jellyCube.defaults;
      expect(def.behaviorProfile, BehaviorProfile.jellyCube);
      expect(def.deformability, expected.deformability);
      expect(def.elasticity, expected.elasticity);
      expect(def.burstThreshold, expected.burstThreshold);
      expect(def.gooLevel, expected.gooLevel);
      expect(def.massHint, expected.massHint);
    });

    test('explicit fields override profile defaults', () {
      final def = SmashableDef.fromJson(
        stripped()
          ..['behaviorProfile'] = 'mochi'
          ..['deformability'] = 0.99
          ..['gooLevel'] = 0.01,
      );
      expect(def.behaviorProfile, BehaviorProfile.mochi);
      // Overrides win.
      expect(def.deformability, 0.99);
      expect(def.gooLevel, 0.01);
      // Non-overridden fields come from the mochi profile.
      expect(def.elasticity, BehaviorProfile.mochi.defaults.elasticity);
      expect(def.burstThreshold,
          BehaviorProfile.mochi.defaults.burstThreshold);
      expect(def.massHint, BehaviorProfile.mochi.defaults.massHint);
    });

    test('unknown profile token is ignored; explicit fields still work', () {
      final def = SmashableDef.fromJson(
        _base()..['behaviorProfile'] = 'made_up_profile',
      );
      // Profile falls back to null (unknown token), but explicit
      // physics fields in _base() carry the def through.
      expect(def.behaviorProfile, isNull);
      expect(def.deformability, 0.88);
      expect(def.elasticity, 0.62);
    });

    test(
        'missing physics field without a profile throws a descriptive error',
        () {
      final json = stripped(); // no behaviorProfile, no physics fields
      expect(
        () => SmashableDef.fromJson(json),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('deformability'),
        )),
      );
    });

    test('missing physics field with an unknown profile also throws', () {
      final json = stripped()..['behaviorProfile'] = 'made_up_profile';
      expect(() => SmashableDef.fromJson(json), throwsArgumentError);
    });

    test('no profile + all fields (legacy shape) still parses clean', () {
      final def = SmashableDef.fromJson(_base());
      expect(def.behaviorProfile, isNull);
      expect(def.deformability, 0.88);
    });
  });

  group('SmashableDef.fromJson cardNumber', () {
    test('cardNumber defaults to null when field is missing', () {
      // Backward compat: pre-v2 pack JSONs have no cardNumber field.
      final def = SmashableDef.fromJson(_base());
      expect(def.cardNumber, isNull);
    });

    test('cardNumber parses through verbatim when present', () {
      final def = SmashableDef.fromJson(
        _base()..['cardNumber'] = '016/048',
      );
      expect(def.cardNumber, '016/048');
    });

    test('cardNumber preserves the canonical "NNN/048" format', () {
      // The format is the wire contract between pack JSON and the
      // cards manifest — anything else would silently fail to match
      // a CardEntry. Pin the format here.
      final def = SmashableDef.fromJson(
        _base()..['cardNumber'] = '001/048',
      );
      expect(
        def.cardNumber,
        matches(RegExp(r'^\d{3}/048$')),
        reason: 'cardNumber must match the manifest card_number format',
      );
    });
  });
}
