import '../data/content_loader.dart';
import '../data/persistence.dart';
import '../data/repositories/pack_repository.dart';
import '../data/repositories/progression_repo.dart';
import '../game/systems/sound_manager.dart';
import '../game/systems/ui_sound_registry.dart';
import '../game/systems/voice_line_registry.dart';
import 'analytics_stub.dart';

class ServiceLocator {
  ServiceLocator._();

  static late final Persistence persistence;
  static late final PackRepository packs;
  static late final ProgressionRepository progression;
  static late final SoundManager sounds;
  static late final UiSounds ui;
  static late final Analytics analytics;

  static Future<void> bootstrap() async {
    persistence = await Persistence.open();
    final loader = ContentLoader();
    final loaded = await loader.loadAll();
    packs = PackRepository(loaded.packs, loaded.schedule);
    progression = ProgressionRepository(persistence, packs);
    sounds = SoundManager();
    await sounds.warm(<String>[
      ...packs.allObjectSoundPaths(),
      ...VoiceLineRegistry.allPaths,
      ...UiSoundRegistry.allPaths,
    ]);
    ui = UiSounds(sounds);
    analytics = const NoOpAnalytics();
  }
}
