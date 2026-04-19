import 'dart:math';

import 'package:flame_audio/flame_audio.dart';

import '../../core/constants.dart';

class SoundManager {
  SoundManager();

  final Random _rng = Random();
  bool muted = false;

  Future<void> warm(List<String> assetPaths) async {
    final cleaned = assetPaths
        .where((p) => p.startsWith('audio/'))
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return;
    try {
      await FlameAudio.audioCache.loadAll(cleaned);
    } catch (_) {
      // Placeholder audio may not exist on disk yet — non-fatal for MVP.
    }
  }

  Future<void> play(String assetPath) async {
    if (muted) return;
    if (!assetPath.startsWith('audio/')) return;
    try {
      await FlameAudio.play(assetPath, volume: 0.85);
    } catch (_) {
      // swallow — keep gameplay alive without final SFX assets
    }
  }

  Future<void> playRandom(List<String> options) async {
    if (options.isEmpty) return;
    final pick = options[_rng.nextInt(options.length)];
    await play(pick);
    // Pitch jitter is omitted here to stay format-agnostic; flame_audio
    // does not expose pitch directly. Wire raw audioplayers later if needed.
    // ignore: unused_local_variable
    final jitter = (_rng.nextDouble() - 0.5) * Tunables.pitchJitter;
  }
}
