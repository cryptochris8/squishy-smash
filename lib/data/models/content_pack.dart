import 'rarity.dart';
import 'smashable_def.dart';

enum ReleaseType { launch, weekly, seasonal, event }

ReleaseType _parseReleaseType(String? raw) {
  switch (raw) {
    case 'weekly':
      return ReleaseType.weekly;
    case 'seasonal':
      return ReleaseType.seasonal;
    case 'event':
      return ReleaseType.event;
    case 'launch':
    default:
      return ReleaseType.launch;
  }
}

class PackPalette {
  const PackPalette({required this.primary, required this.secondary, required this.accent});

  final String primary;
  final String secondary;
  final String accent;

  factory PackPalette.fromJson(Map<String, dynamic> json) => PackPalette(
        primary: json['primary'] as String,
        secondary: json['secondary'] as String,
        accent: json['accent'] as String,
      );
}

/// Per-tier share of total spawn probability within a pack. Each
/// object's effective weight is derived from this share divided by the
/// number of objects of that rarity in the pack — so an 8C/4R/3E/1L
/// pack with defaults yields 68/22/8/2% per tier, with each common at
/// 8.5%, each rare at 5.5%, each epic at 2.67%, each legendary at 2%.
///
/// Values are fractions summing to 1.0 (approximately). Missing fields
/// fall back to the doc defaults.
class RarityOdds {
  const RarityOdds({
    this.common = 0.68,
    this.rare = 0.22,
    this.epic = 0.08,
    this.legendary = 0.02,
  });

  final double common;
  final double rare;
  final double epic;
  final double legendary;

  double shareFor(Rarity r) {
    switch (r) {
      case Rarity.common:
        return common;
      case Rarity.rare:
        return rare;
      case Rarity.epic:
        return epic;
      case Rarity.mythic:
        return legendary;
    }
  }

  factory RarityOdds.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RarityOdds();
    // The top-tier key accepts both `legendary` (player-facing /
    // canonical) and `mythic` (internal alias). `legendary` wins if
    // both are set so JSON authors get an obvious precedence; see
    // the Rarity enum doc for the naming-split rationale.
    final topTier = (json['legendary'] as num?)?.toDouble() ??
        (json['mythic'] as num?)?.toDouble() ??
        0.02;
    return RarityOdds(
      common: (json['common'] as num?)?.toDouble() ?? 0.68,
      rare: (json['rare'] as num?)?.toDouble() ?? 0.22,
      epic: (json['epic'] as num?)?.toDouble() ?? 0.08,
      legendary: topTier,
    );
  }
}

/// Minimum total-bursts-in-this-pack before each tier is eligible to
/// spawn from the pool. A value of 0 means the tier is unlocked from
/// the start. Commons are always implicitly 0.
class UnlockGates {
  const UnlockGates({
    this.rare = 3,
    this.epic = 10,
    this.legendary = 20,
  });

  final int rare;
  final int epic;
  final int legendary;

  int gateFor(Rarity r) {
    switch (r) {
      case Rarity.common:
        return 0;
      case Rarity.rare:
        return rare;
      case Rarity.epic:
        return epic;
      case Rarity.mythic:
        return legendary;
    }
  }

  factory UnlockGates.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UnlockGates();
    // Accept both `legendary` (canonical) and `mythic` (alias).
    final topTier = (json['legendary'] as num?)?.toInt() ??
        (json['mythic'] as num?)?.toInt() ??
        20;
    return UnlockGates(
      rare: (json['rare'] as num?)?.toInt() ?? 3,
      epic: (json['epic'] as num?)?.toInt() ?? 10,
      legendary: topTier,
    );
  }
}

/// Soft + hard pity thresholds per tier. Counts are dry-streaks in
/// the same pack (reveals since the last time that tier dropped).
///
///   * reveals below soft: no boost
///   * reveals in [soft, hard): linear ramp up to 2x base weight
///   * reveals at hard: force the tier (exclude lower tiers from pool)
class PityThresholds {
  const PityThresholds({
    this.rareSoft = 5,
    this.rareHard = 7,
    this.epicSoft = 14,
    this.epicHard = 20,
    this.legendarySoft = 25,
    this.legendaryHard = 50,
  });

  final int rareSoft;
  final int rareHard;
  final int epicSoft;
  final int epicHard;
  final int legendarySoft;
  final int legendaryHard;

  (int soft, int hard) forTier(Rarity r) {
    switch (r) {
      case Rarity.rare:
        return (rareSoft, rareHard);
      case Rarity.epic:
        return (epicSoft, epicHard);
      case Rarity.mythic:
        return (legendarySoft, legendaryHard);
      case Rarity.common:
        return (0, 0);
    }
  }

  factory PityThresholds.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PityThresholds();
    // Top-tier pity accepts both `legendarySoft/legendaryHard`
    // (canonical) and `mythicSoft/mythicHard` (alias). `legendary`
    // wins on conflict so authors mixing both forms see consistent
    // behavior.
    final topSoft = (json['legendarySoft'] as num?)?.toInt() ??
        (json['mythicSoft'] as num?)?.toInt() ??
        25;
    final topHard = (json['legendaryHard'] as num?)?.toInt() ??
        (json['mythicHard'] as num?)?.toInt() ??
        50;
    return PityThresholds(
      rareSoft: (json['rareSoft'] as num?)?.toInt() ?? 5,
      rareHard: (json['rareHard'] as num?)?.toInt() ?? 7,
      epicSoft: (json['epicSoft'] as num?)?.toInt() ?? 14,
      epicHard: (json['epicHard'] as num?)?.toInt() ?? 20,
      legendarySoft: topSoft,
      legendaryHard: topHard,
    );
  }
}

/// Pack-level drop-economy config. Missing blocks (or missing fields
/// within a block) fall back to the tuning-doc defaults. This shape
/// drives [RarityPitySelector] and [PackProgressionGate] behavior.
class PackProgression {
  const PackProgression({
    this.baseOdds = const RarityOdds(),
    this.unlockGates = const UnlockGates(),
    this.pity = const PityThresholds(),
  });

  final RarityOdds baseOdds;
  final UnlockGates unlockGates;
  final PityThresholds pity;

  factory PackProgression.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PackProgression();
    return PackProgression(
      baseOdds:
          RarityOdds.fromJson(json['baseOdds'] as Map<String, dynamic>?),
      unlockGates:
          UnlockGates.fromJson(json['unlockGates'] as Map<String, dynamic>?),
      pity: PityThresholds.fromJson(json['pity'] as Map<String, dynamic>?),
    );
  }
}

class ContentPack {
  const ContentPack({
    required this.packId,
    required this.displayName,
    required this.themeTag,
    required this.releaseType,
    required this.palette,
    required this.arenaSuggestion,
    required this.featuredAudioSet,
    required this.objects,
    this.unlockCost = 0,
    this.releaseWindow,
    this.progression = const PackProgression(),
  });

  final String packId;
  final String displayName;
  final String themeTag;
  final ReleaseType releaseType;
  final PackPalette palette;
  final String arenaSuggestion;
  final String featuredAudioSet;
  final List<SmashableDef> objects;
  final int unlockCost;
  final String? releaseWindow;

  /// Drop-economy config (base odds / unlock gates / pity). Missing
  /// fields default to the tuning-doc values in [PackProgression].
  final PackProgression progression;

  /// Number of objects in this pack at the given rarity tier. The
  /// pity selector uses this to derive per-object weight from each
  /// tier's share: object_weight = (tier_share / tier_count) * scale.
  int countAtTier(Rarity r) =>
      objects.where((o) => o.rarity == r).length;

  factory ContentPack.fromJson(Map<String, dynamic> json) => ContentPack(
        packId: json['packId'] as String,
        displayName: json['displayName'] as String,
        themeTag: json['themeTag'] as String,
        releaseType: _parseReleaseType(json['releaseType'] as String?),
        palette: PackPalette.fromJson(json['palette'] as Map<String, dynamic>),
        arenaSuggestion: json['arenaSuggestion'] as String,
        featuredAudioSet: json['featuredAudioSet'] as String,
        objects: (json['objects'] as List)
            .cast<Map<String, dynamic>>()
            .map(SmashableDef.fromJson)
            .toList(growable: false),
        unlockCost: json['unlockCost'] == null
            ? 0
            : (json['unlockCost'] as num).toInt(),
        releaseWindow: json['releaseWindow'] as String?,
        progression: PackProgression.fromJson(
          json['packProgression'] as Map<String, dynamic>?,
        ),
      );
}
