import '../models/content_pack.dart';
import '../models/liveops_schedule.dart';
import '../models/smashable_def.dart';

class PackRepository {
  PackRepository(this.packs, this.schedule);

  final List<ContentPack> packs;
  final LiveOpsSchedule schedule;

  ContentPack? byId(String packId) {
    for (final p in packs) {
      if (p.packId == packId) return p;
    }
    return null;
  }

  List<SmashableDef> objectsForPacks(Iterable<String> packIds) {
    final out = <SmashableDef>[];
    for (final id in packIds) {
      final p = byId(id);
      if (p != null) out.addAll(p.objects);
    }
    return out;
  }

  ContentPack get launchPack => byId('launch_squishy_foods')!;

  List<String> allObjectSoundPaths() {
    final paths = <String>{};
    for (final p in packs) {
      for (final o in p.objects) {
        paths.addAll(o.impactSounds);
        paths.add(o.burstSound);
      }
    }
    return paths.toList(growable: false);
  }
}
