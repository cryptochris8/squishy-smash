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

class Palette {
  const Palette({required this.primary, required this.secondary, required this.accent});

  final String primary;
  final String secondary;
  final String accent;

  factory Palette.fromJson(Map<String, dynamic> json) => Palette(
        primary: json['primary'] as String,
        secondary: json['secondary'] as String,
        accent: json['accent'] as String,
      );
}

/// Acquisition-gating thresholds for a pack. Default values (both 0)
/// disable gating entirely — that's the back-compat path for packs
/// authored before the collectible rarity map system. Well-formed
/// packs (8 common / 4 rare / 3 epic / 1 legendary) should declare
/// these in JSON to pace the collection.
class PackProgression {
  const PackProgression({
    this.epicUnlockRareBursts = 0,
    this.legendaryUnlockEpicBursts = 0,
  });

  /// How many rare-or-better bursts the player must have in this pack
  /// before epic-tier objects are eligible to spawn. Repeat bursts count
  /// so even a small pool of rares can unlock the gate.
  final int epicUnlockRareBursts;

  /// How many epic-or-better bursts the player must have in this pack
  /// before legendary-tier objects are eligible to spawn.
  final int legendaryUnlockEpicBursts;

  bool get isGated =>
      epicUnlockRareBursts > 0 || legendaryUnlockEpicBursts > 0;

  factory PackProgression.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PackProgression();
    return PackProgression(
      epicUnlockRareBursts:
          (json['epicUnlockRareBursts'] as num?)?.toInt() ?? 0,
      legendaryUnlockEpicBursts:
          (json['legendaryUnlockEpicBursts'] as num?)?.toInt() ?? 0,
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
  final Palette palette;
  final String arenaSuggestion;
  final String featuredAudioSet;
  final List<SmashableDef> objects;
  final int unlockCost;
  final String? releaseWindow;

  /// Acquisition gating config. See [PackProgression] — defaults to an
  /// ungated pack so existing content keeps its current behavior.
  final PackProgression progression;

  factory ContentPack.fromJson(Map<String, dynamic> json) => ContentPack(
        packId: json['packId'] as String,
        displayName: json['displayName'] as String,
        themeTag: json['themeTag'] as String,
        releaseType: _parseReleaseType(json['releaseType'] as String?),
        palette: Palette.fromJson(json['palette'] as Map<String, dynamic>),
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
