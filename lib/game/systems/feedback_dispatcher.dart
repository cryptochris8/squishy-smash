import 'dart:math';

import '../../data/models/rarity.dart';
import '../../data/models/smashable_def.dart';
import 'sound_variant_picker.dart';

/// Tiered feedback events that map to layered SFX + haptics + (optionally)
/// a reveal-moment skybox swap. Keyed by severity so pack authors don't
/// have to hand-tune each callsite.
enum FeedbackTier {
  hit,
  squish,
  burst,
  revealBurst,
  megaBurst,
  comboMilestone,
}

/// Abstract sink so the dispatcher is testable without Flame/Flutter.
/// Production implementations call through to [SoundManager] and
/// [HapticsManager]; tests use [RecordingFeedbackSink] (see tests).
abstract class FeedbackSink {
  void playOneShot(String path);
  void playVariant(String key, List<String> options);
  void voiceCallout(String path);
  void hapticLight();
  void hapticMedium();
  void hapticHeavy();
  void hapticSelection();
  void screenShake({double duration, double intensity});
}

/// Central event dispatcher. Keeps per-object variant state so back-to-back
/// bursts don't reveal the impact-sound file count, gates VO calls so the
/// hype announcer never becomes nagging, and supplies the right haptic tier
/// for each feedback event.
class FeedbackDispatcher {
  FeedbackDispatcher({
    required this.sink,
    SoundVariantPicker? variantPicker,
    Random? rng,
  })  : _picker = variantPicker ?? SoundVariantPicker(rng: rng),
        _rng = rng ?? Random();

  final FeedbackSink sink;
  final SoundVariantPicker _picker;
  final Random _rng;

  /// Optional VO callout paths — pack authors register these; the
  /// dispatcher plays them according to tier-specific gating rules.
  ///
  /// Expected keys:
  ///  - 'mega' — played 1 in 3 on megaBurst
  ///  - 'reveal_rare'   — played every revealBurst with rare tier
  ///  - 'reveal_epic'   — played every revealBurst with epic tier
  ///  - 'reveal_mythic' — played every revealBurst with mythic tier
  final Map<String, List<String>> voiceLines = <String, List<String>>{};

  /// Probability a mega-burst triggers a VO callout. Default 1/3.
  double megaCalloutProbability = 1 / 3;

  void dispatch(FeedbackTier tier, SmashableDef def) {
    switch (tier) {
      case FeedbackTier.hit:
        _fireHit(def);
        break;
      case FeedbackTier.squish:
        _fireSquish(def);
        break;
      case FeedbackTier.burst:
        _fireBurst(def);
        break;
      case FeedbackTier.revealBurst:
        _fireRevealBurst(def);
        break;
      case FeedbackTier.megaBurst:
        _fireMegaBurst(def);
        break;
      case FeedbackTier.comboMilestone:
        _fireComboMilestone(def);
        break;
    }
  }

  void _fireHit(SmashableDef def) {
    sink.playVariant('hit_${def.id}', def.impactSounds);
    sink.hapticLight();
  }

  void _fireSquish(SmashableDef def) {
    sink.playVariant('squish_${def.id}', def.impactSounds);
    sink.hapticSelection();
  }

  void _fireBurst(SmashableDef def) {
    sink.playOneShot(def.burstSound);
    sink.hapticHeavy();
    sink.screenShake(duration: 0.18, intensity: 8);
  }

  void _fireRevealBurst(SmashableDef def) {
    sink.playOneShot(def.burstSound);
    sink.hapticHeavy();
    sink.screenShake(duration: 0.22, intensity: 10);

    final key = switch (def.rarity) {
      Rarity.rare => 'reveal_rare',
      Rarity.epic => 'reveal_epic',
      Rarity.mythic => 'reveal_mythic',
      Rarity.common => null,
    };
    if (key != null) {
      final lines = voiceLines[key];
      if (lines != null && lines.isNotEmpty) {
        final pick = _picker.pick<String>('vo_$key', lines);
        if (pick != null) sink.voiceCallout(pick);
      }
    }
  }

  /// A mid-combo milestone (streak 3/6/10/15). Not tied to a burst —
  /// fires off a punchier haptic + a small screen shake so the player
  /// physically feels the step-up. No voice line (those stay reserved
  /// for reveal moments).
  void _fireComboMilestone(SmashableDef def) {
    sink.hapticMedium();
    sink.screenShake(duration: 0.10, intensity: 4);
  }

  void _fireMegaBurst(SmashableDef def) {
    sink.playOneShot(def.burstSound);
    sink.hapticHeavy();
    sink.screenShake(duration: 0.28, intensity: 12);

    final megaLines = voiceLines['mega'];
    if (megaLines != null && megaLines.isNotEmpty) {
      if (_rng.nextDouble() < megaCalloutProbability) {
        final pick = _picker.pick<String>('vo_mega', megaLines);
        if (pick != null) sink.voiceCallout(pick);
      }
    }
  }
}
