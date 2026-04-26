import 'dart:math';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../../core/service_locator.dart';

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
      // P1.23: success log only in debug — release builds shouldn't
      // ship per-boot info-level chatter to device stdout.
      if (kDebugMode) {
        debugPrint('SoundManager: warmed ${cleaned.length} audio assets');
      }
    } catch (e, st) {
      ServiceLocator.diagnostics.record(
        source: 'audio',
        error: 'warm failed: $e',
        stack: st,
      );
    }
  }

  Future<void> play(String assetPath) async {
    if (muted) return;
    final normalized = _normalize(assetPath);
    try {
      await FlameAudio.play(normalized, volume: 0.9);
    } catch (e, st) {
      ServiceLocator.diagnostics.record(
        source: 'audio',
        error: 'play("$normalized") failed: $e',
        stack: st,
      );
    }
  }

  Future<void> playRandom(List<String> options) async {
    if (options.isEmpty) return;
    final pick = options[_rng.nextInt(options.length)];
    await play(pick);
  }
}
