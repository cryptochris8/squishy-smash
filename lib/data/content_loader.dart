import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

import 'models/content_pack.dart';
import 'models/liveops_schedule.dart';

class LoadedContent {
  const LoadedContent({required this.packs, required this.schedule});
  final List<ContentPack> packs;
  final LiveOpsSchedule schedule;
}

/// Current schema version understood by the loader. Bump when breaking
/// changes are made to the pack or liveops JSON shape; missing versions
/// on disk are treated as this value for backward compatibility with
/// pre-versioning content.
const int contentSchemaVersion = 1;

class ContentLoader {
  static const List<String> bundledPackPaths = <String>[
    'assets/data/packs/launch_squishy_foods.json',
    'assets/data/packs/goo_fidgets_drop_01.json',
    'assets/data/packs/creepy_cute_pack_01.json',
    'assets/data/packs/dumpling_squishy_drop_01.json',
  ];
  static const String schedulePath = 'assets/data/liveops_schedule.json';

  /// Load every bundled pack + the liveops schedule. Malformed or
  /// version-mismatched files are skipped with a debugPrint so one bad
  /// asset can't crash the app during bootstrap. Returns whatever
  /// loaded successfully; an empty packs list is possible but callers
  /// must handle that gracefully.
  Future<LoadedContent> loadAll() async {
    final packs = <ContentPack>[];
    for (final path in bundledPackPaths) {
      try {
        final raw = await rootBundle.loadString(path);
        final map = json.decode(raw) as Map<String, dynamic>;
        _assertSchemaVersion(path, map);
        packs.add(ContentPack.fromJson(map));
      } catch (e, st) {
        debugPrint('ContentLoader: failed to load pack "$path": $e\n$st');
      }
    }
    LiveOpsSchedule schedule = const LiveOpsSchedule(featuredRotation: []);
    try {
      final scheduleRaw = await rootBundle.loadString(schedulePath);
      final scheduleMap = json.decode(scheduleRaw) as Map<String, dynamic>;
      _assertSchemaVersion(schedulePath, scheduleMap);
      schedule = LiveOpsSchedule.fromJson(scheduleMap);
    } catch (e, st) {
      debugPrint('ContentLoader: failed to load schedule: $e\n$st');
    }
    return LoadedContent(packs: packs, schedule: schedule);
  }

  /// Missing schemaVersion is treated as the current version (pre-
  /// versioning files are assumed compatible). A future version throws
  /// so a newer content bundle shipped to an older app build fails loud
  /// instead of silently mis-parsing.
  void _assertSchemaVersion(String path, Map<String, dynamic> map) {
    final raw = map['schemaVersion'];
    if (raw == null) return;
    final v = (raw as num).toInt();
    if (v > contentSchemaVersion) {
      throw StateError(
        '$path schemaVersion=$v is newer than supported '
        '($contentSchemaVersion). Update the app to load this content.',
      );
    }
  }
}
