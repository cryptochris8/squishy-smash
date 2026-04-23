import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/behavior_profile.dart';

void main() {
  group('behaviorProfileFromToken', () {
    test('parses every known token', () {
      expect(behaviorProfileFromToken('dumpling'), BehaviorProfile.dumpling);
      expect(behaviorProfileFromToken('jelly_cube'),
          BehaviorProfile.jellyCube);
      expect(behaviorProfileFromToken('goo_ball'), BehaviorProfile.gooBall);
      expect(behaviorProfileFromToken('mochi'), BehaviorProfile.mochi);
      expect(behaviorProfileFromToken('stress_ball'),
          BehaviorProfile.stressBall);
      expect(behaviorProfileFromToken('creature'), BehaviorProfile.creature);
    });

    test('returns null for unknown or absent input', () {
      expect(behaviorProfileFromToken(null), isNull);
      expect(behaviorProfileFromToken(''), isNull);
      expect(behaviorProfileFromToken('nonsense'), isNull);
      // case-sensitive — lowercase tokens only.
      expect(behaviorProfileFromToken('Dumpling'), isNull);
    });

    test('tokens round-trip', () {
      for (final p in BehaviorProfile.values) {
        expect(behaviorProfileFromToken(p.token), p);
      }
    });
  });

  group('BehaviorProfile.defaults', () {
    test('every profile defines all five physics fields in valid ranges', () {
      for (final p in BehaviorProfile.values) {
        final d = p.defaults;
        expect(d.deformability, inInclusiveRange(0.0, 1.0),
            reason: '${p.token} deformability out of range');
        expect(d.elasticity, inInclusiveRange(0.0, 1.0),
            reason: '${p.token} elasticity out of range');
        expect(d.burstThreshold, inInclusiveRange(0.0, 1.0),
            reason: '${p.token} burstThreshold out of range');
        expect(d.gooLevel, inInclusiveRange(0.0, 1.0),
            reason: '${p.token} gooLevel out of range');
        expect(d.massHint, greaterThan(0.0),
            reason: '${p.token} massHint must be positive');
      }
    });

    test('stress_ball is snappier than mochi', () {
      final stress = BehaviorProfile.stressBall.defaults;
      final mochi = BehaviorProfile.mochi.defaults;
      expect(stress.elasticity, greaterThan(mochi.elasticity));
      expect(stress.deformability, greaterThan(mochi.deformability));
    });

    test('goo_ball has the highest gooLevel', () {
      final gooLevel = BehaviorProfile.gooBall.defaults.gooLevel;
      for (final p in BehaviorProfile.values) {
        if (p == BehaviorProfile.gooBall) continue;
        expect(gooLevel, greaterThanOrEqualTo(p.defaults.gooLevel),
            reason: '${p.token} is gooier than goo_ball');
      }
    });

    test('mochi is the heaviest (highest massHint)', () {
      final mass = BehaviorProfile.mochi.defaults.massHint;
      for (final p in BehaviorProfile.values) {
        if (p == BehaviorProfile.mochi) continue;
        expect(mass, greaterThanOrEqualTo(p.defaults.massHint),
            reason: '${p.token} is heavier than mochi');
      }
    });
  });
}
