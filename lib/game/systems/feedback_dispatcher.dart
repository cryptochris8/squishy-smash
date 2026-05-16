import 'dart:math';

import '../../data/models/rarity.dart';
import '../../data/models/smashable_def.dart';
import 'combo_controller.dart';
import 'sound_variant_picker.dart';
import 'ui_sound_registry.dart';

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
  /// Two heavy impacts spaced ~80 ms apart — fired for rare/epic
  /// reveals. Distinct from heavy so the player can feel which
  /// tier just dropped (P1-C).
  void hapticDoublePulse();
  /// Three heavy impacts spaced ~80 ms apart — reserved for the
  /// rarest beats (mythic reveals + mega bursts).
  void hapticTriplePulse();
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

  /// Combo-milestone chime variants keyed by [ComboTier]. Populated from
  /// [ComboSoundRegistry.dispatcherMap] at game init. When a milestone
  /// fires, the dispatcher picks a variant from the matching tier's list
  /// via [SoundVariantPicker] (anti-repetition scoped per tier).
  /// [ComboTier.none] is never expected — the call site filters that out.
  final Map<ComboTier, List<String>> comboChimes = <ComboTier, List<String>>{};

  /// Probability a mega-burst triggers a VO callout. Default 1/3.
  double megaCalloutProbability = 1 / 3;

  /// Dispatch a feedback event.
  ///
  /// [comboTier] is required for [FeedbackTier.comboMilestone] so the
  /// dispatcher can play the matching chime — supplied by the call site
  /// (combo controller knows its current tier). Ignored for other tiers.
  void dispatch(
    FeedbackTier tier,
    SmashableDef def, {
    ComboTier? comboTier,
  }) {
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
        _fireComboMilestone(def, comboTier);
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
    // Layer the UI reveal stinger for every non-common reveal so the
    // rarity tier is audibly distinct from a plain common burst.
    // Pre-fix (P1.3) the stinger only fired on epic+; rare reveals
    // sounded identical to commons, which is the most-frequent
    // "wow moment" in the game.
    if (def.rarity != Rarity.common) {
      sink.playOneShot(UiSoundRegistry.revealStinger);
    }
    // P1-C: tier the haptic so a mythic doesn't feel identical to a
    // common burst. Pre-fix every reveal fired the same hapticHeavy()
    // — three pulses for mythic, two for rare/epic, one for any
    // unexpected common fall-through (defensive, shouldn't occur).
    switch (def.rarity) {
      case Rarity.mythic:
        sink.hapticTriplePulse();
        break;
      case Rarity.rare:
      case Rarity.epic:
        sink.hapticDoublePulse();
        break;
      case Rarity.common:
        sink.hapticHeavy();
        break;
    }
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

  /// A mid-combo milestone (streak 3/6/10/15 → starter/stronger/
  /// revealReady/mega). Not tied to a burst — fires a punchier haptic
  /// + small screen shake + tier-appropriate chime so the player both
  /// feels and hears the step-up. No voice line (those stay reserved
  /// for reveal moments).
  ///
  /// [tier] is the freshly-crossed [ComboTier] (caller filters out
  /// [ComboTier.none] before dispatching). When null or chimes aren't
  /// registered for the tier, the chime is skipped silently — haptic +
  /// shake still fire, so the milestone is never *invisible*.
  void _fireComboMilestone(SmashableDef def, ComboTier? tier) {
    sink.hapticMedium();
    sink.screenShake(duration: 0.10, intensity: 4);

    if (tier == null || tier == ComboTier.none) return;
    final chimes = comboChimes[tier];
    if (chimes != null && chimes.isNotEmpty) {
      sink.playVariant('combo_${tier.name}', chimes);
    }
  }

  void _fireMegaBurst(SmashableDef def) {
    sink.playOneShot(def.burstSound);
    // P1-C: mega bursts are even rarer than mythic reveals — triple
    // pulse so the player physically feels they crossed a threshold
    // most rounds never touch.
    sink.hapticTriplePulse();
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
