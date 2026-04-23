import 'behavior_profile.dart';
import 'rarity.dart';

class SmashableDef {
  const SmashableDef({
    required this.id,
    required this.name,
    required this.category,
    required this.themeTag,
    required this.sprite,
    required this.thumbnail,
    required this.deformability,
    required this.elasticity,
    required this.burstThreshold,
    required this.gooLevel,
    required this.impactSounds,
    required this.burstSound,
    required this.particlePreset,
    required this.decalPreset,
    required this.coinReward,
    required this.unlockTier,
    required this.searchTags,
    this.hitsToBurst,
    this.massHint = 1.0,
    this.rarity = Rarity.common,
    this.dropWeight,
    this.behaviorProfile,
  });

  final String id;
  final String name;
  final String category;
  final String themeTag;
  final String sprite;
  final String thumbnail;
  final double deformability;
  final double elasticity;
  final double burstThreshold;
  final double gooLevel;
  final List<String> impactSounds;
  final String burstSound;
  final String particlePreset;
  final String decalPreset;
  final int coinReward;
  final int unlockTier;
  final List<String> searchTags;
  final int? hitsToBurst;
  final double massHint;
  final Rarity rarity;

  /// Optional per-object spawn weight override. When null, callers should
  /// use [Rarity.defaultWeight] so a pack without explicit weights still
  /// respects tier frequencies.
  final int? dropWeight;

  /// Effective spawn weight used by weighted selection.
  int get effectiveDropWeight => dropWeight ?? rarity.defaultWeight;

  /// Which material preset this object is based on. Null for objects
  /// that hand-tune every physics field without referencing a profile.
  final BehaviorProfile? behaviorProfile;

  factory SmashableDef.fromJson(Map<String, dynamic> json) {
    final profile =
        behaviorProfileFromToken(json['behaviorProfile'] as String?);
    final defaults = profile?.defaults;
    double physics(String key, double? fallback) {
      final raw = json[key];
      if (raw != null) return (raw as num).toDouble();
      if (fallback != null) return fallback;
      throw ArgumentError(
        'SmashableDef "${json['id']}": $key is missing and no '
        'behaviorProfile was specified to supply a default.',
      );
    }

    return SmashableDef(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      themeTag: json['themeTag'] as String,
      sprite: json['sprite'] as String,
      thumbnail: json['thumbnail'] as String,
      deformability: physics('deformability', defaults?.deformability),
      elasticity: physics('elasticity', defaults?.elasticity),
      burstThreshold: physics('burstThreshold', defaults?.burstThreshold),
      gooLevel: physics('gooLevel', defaults?.gooLevel),
      impactSounds: (json['impactSounds'] as List).cast<String>(),
      burstSound: json['burstSound'] as String,
      particlePreset: json['particlePreset'] as String,
      decalPreset: json['decalPreset'] as String,
      coinReward: (json['coinReward'] as num).toInt(),
      unlockTier: (json['unlockTier'] as num).toInt(),
      searchTags: (json['searchTags'] as List).cast<String>(),
      hitsToBurst: json['hitsToBurst'] == null
          ? null
          : (json['hitsToBurst'] as num).toInt(),
      massHint: json['massHint'] == null
          ? (defaults?.massHint ?? 1.0)
          : (json['massHint'] as num).toDouble(),
      rarity: rarityFromToken(json['rarity'] as String?),
      dropWeight: json['dropWeight'] == null
          ? null
          : (json['dropWeight'] as num).toInt(),
      behaviorProfile: profile,
    );
  }
}
