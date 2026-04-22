import 'package:flutter_test/flutter_test.dart';
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
      final def = SmashableDef.fromJson(_base()..['rarity'] = 'legendary');
      expect(def.rarity, Rarity.common);
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
}
