/// Named physics preset for a class of squishy object. Lets pack
/// authors pick a shared baseline (soft dumpling, wobbly jelly, sticky
/// goo, dense mochi, snappy stress ball, emotional creature) instead
/// of hand-tuning five numbers per object — which leads to subtle
/// drift across packs.
///
/// Objects can opt in by setting `behaviorProfile: "jelly_cube"` in
/// JSON; any explicit physics field in the same object overrides the
/// profile default. No profile + no fields is invalid; see
/// [SmashableDef.fromJson] for resolution order.
enum BehaviorProfile {
  dumpling,
  jellyCube,
  gooBall,
  mochi,
  stressBall,
  creature,
}

/// Physics defaults that a [BehaviorProfile] fills in when a specific
/// field is absent from an object's JSON.
class BehaviorProfileDefaults {
  const BehaviorProfileDefaults({
    required this.deformability,
    required this.elasticity,
    required this.burstThreshold,
    required this.gooLevel,
    required this.massHint,
  });

  final double deformability;
  final double elasticity;
  final double burstThreshold;
  final double gooLevel;
  final double massHint;
}

extension BehaviorProfileX on BehaviorProfile {
  String get token {
    switch (this) {
      case BehaviorProfile.dumpling:
        return 'dumpling';
      case BehaviorProfile.jellyCube:
        return 'jelly_cube';
      case BehaviorProfile.gooBall:
        return 'goo_ball';
      case BehaviorProfile.mochi:
        return 'mochi';
      case BehaviorProfile.stressBall:
        return 'stress_ball';
      case BehaviorProfile.creature:
        return 'creature';
    }
  }

  /// Preset physics values. Tuned to match the existing hand-authored
  /// objects in the launch packs, smoothing out per-object drift.
  BehaviorProfileDefaults get defaults {
    switch (this) {
      case BehaviorProfile.dumpling:
        // Soft bounce, warm dense squish, cozy feel.
        return const BehaviorProfileDefaults(
          deformability: 0.88,
          elasticity: 0.60,
          burstThreshold: 0.80,
          gooLevel: 0.85,
          massHint: 1.0,
        );
      case BehaviorProfile.jellyCube:
        // Wobble-heavy, glossy splat, translucent burst.
        return const BehaviorProfileDefaults(
          deformability: 0.74,
          elasticity: 0.75,
          burstThreshold: 0.68,
          gooLevel: 0.55,
          massHint: 0.9,
        );
      case BehaviorProfile.gooBall:
        // Sticky stretch, wet, delayed burst snap.
        return const BehaviorProfileDefaults(
          deformability: 0.88,
          elasticity: 0.55,
          burstThreshold: 0.72,
          gooLevel: 0.92,
          massHint: 1.0,
        );
      case BehaviorProfile.mochi:
        // Dense press, low thud, slower rebound, minimal splatter.
        return const BehaviorProfileDefaults(
          deformability: 0.76,
          elasticity: 0.65,
          burstThreshold: 0.88,
          gooLevel: 0.40,
          massHint: 1.3,
        );
      case BehaviorProfile.stressBall:
        // Strong elastic recoil, firmer resistance, snap-back.
        return const BehaviorProfileDefaults(
          deformability: 0.95,
          elasticity: 0.80,
          burstThreshold: 0.92,
          gooLevel: 0.42,
          massHint: 1.1,
        );
      case BehaviorProfile.creature:
        // Emotional facial reactions, playful sparkle burst.
        return const BehaviorProfileDefaults(
          deformability: 0.76,
          elasticity: 0.63,
          burstThreshold: 0.78,
          gooLevel: 0.55,
          massHint: 1.0,
        );
    }
  }
}

/// Parse a profile token. Returns null on unknown or absent input —
/// callers that require a profile should handle null explicitly.
BehaviorProfile? behaviorProfileFromToken(String? token) {
  switch (token) {
    case 'dumpling':
      return BehaviorProfile.dumpling;
    case 'jelly_cube':
      return BehaviorProfile.jellyCube;
    case 'goo_ball':
      return BehaviorProfile.gooBall;
    case 'mochi':
      return BehaviorProfile.mochi;
    case 'stress_ball':
      return BehaviorProfile.stressBall;
    case 'creature':
      return BehaviorProfile.creature;
    default:
      return null;
  }
}
