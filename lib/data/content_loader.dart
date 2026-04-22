import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models/content_pack.dart';
import 'models/liveops_schedule.dart';

class LoadedContent {
  const LoadedContent({required this.packs, required this.schedule});
  final List<ContentPack> packs;
  final LiveOpsSchedule schedule;
}

class ContentLoader {
  static const List<String> bundledPackPaths = <String>[
    'assets/data/packs/launch_squishy_foods.json',
    'assets/data/packs/goo_fidgets_drop_01.json',
    'assets/data/packs/creepy_cute_pack_01.json',
    'assets/data/packs/dumpling_squishy_drop_01.json',
  ];
  static const String schedulePath = 'assets/data/liveops_schedule.json';

  Future<LoadedContent> loadAll() async {
    final packs = <ContentPack>[];
    for (final path in bundledPackPaths) {
      final raw = await rootBundle.loadString(path);
      final map = json.decode(raw) as Map<String, dynamic>;
      packs.add(ContentPack.fromJson(map));
    }
    final scheduleRaw = await rootBundle.loadString(schedulePath);
    final schedule = LiveOpsSchedule.fromJson(
      json.decode(scheduleRaw) as Map<String, dynamic>,
    );
    return LoadedContent(packs: packs, schedule: schedule);
  }
}
