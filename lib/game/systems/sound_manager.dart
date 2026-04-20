import 'dart:math';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class SoundManager {
  SoundManager();

  final Random _rng = Random();
  bool muted = false;

  /// Strip the leading "audio/" so paths match flame_audio's default
  /// AudioCache prefix of "assets/audio/".
  String _normalize(String assetPath) {
    if (assetPath.startsWith('audio/')) {
      return assetPath.substring('audio/'.length);
    }
    return assetPath;
  }

  Future<void> warm(List<String> assetPaths) async {
    final cleaned = assetPaths
        .map(_normalize)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return;
    try {
      await FlameAudio.audioCache.loadAll(cleaned);
      debugPrint('SoundManager: warmed ${cleaned.length} audio assets');
    } catch (e, st) {
      debugPrint('SoundManager: warm FAILED — $e\n$st');
    }
  }

  Future<void> play(String assetPath) async {
    if (muted) return;
    final normalized = _normalize(assetPath);
    try {
      await FlameAudio.play(normalized, volume: 0.9);
    } catch (e) {
      debugPrint('SoundManager: play("$normalized") FAILED — $e');
    }
  }

  Future<void> playRandom(List<String> options) async {
    if (options.isEmpty) return;
    final pick = options[_rng.nextInt(options.length)];
    await play(pick);
  }
}
