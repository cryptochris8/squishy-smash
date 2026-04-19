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
      );
}
