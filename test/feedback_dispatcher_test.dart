import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/data/models/smashable_def.dart';
import 'package:squishy_smash/game/systems/combo_controller.dart';
import 'package:squishy_smash/game/systems/feedback_dispatcher.dart';
import 'package:squishy_smash/game/systems/sound_variant_picker.dart';

/// Test double that logs every call in the order it receives.
class RecordingFeedbackSink implements FeedbackSink {
  final List<String> calls = <String>[];

  @override
  void playOneShot(String path) => calls.add('playOneShot:$path');

  @override
  void playVariant(String key, List<String> options) =>
      calls.add('playVariant:$key:${options.length}');

  @override
  void voiceCallout(String path) => calls.add('voiceCallout:$path');

  @override
  void hapticLight() => calls.add('hapticLight');

  @override
  void hapticMedium() => calls.add('hapticMedium');

  @override
  void hapticHeavy() => calls.add('hapticHeavy');

  @override
  void hapticSelection() => calls.add('hapticSelection');

  @override
  void hapticDoublePulse() => calls.add('hapticDoublePulse');

  @override
  void hapticTriplePulse() => calls.add('hapticTriplePulse');

  @override
  void screenShake({double duration = 0.18, double intensity = 8}) =>
      calls.add('shake:${duration.toStringAsFixed(2)}:${intensity.toInt()}');

  int countOf(String prefix) =>
      calls.where((c) => c.startsWith(prefix)).length;
}

SmashableDef _def({
  String id = 'dumplio',
  Rarity rarity = Rarity.common,
  List<String> impactSounds = const [
    'audio/food/dumplio_squish_01.mp3',
    'audio/food/dumplio_squish_02.mp3',
  ],
  String burstSound = 'audio/food/dumplio_burst_01.mp3',
}) =>
    SmashableDef(
      id: id,
      name: 'Test',
      category: 'squishy_food',
      themeTag: 't',
      sprite: 's',
      thumbnail: 't',
      deformability: 0.8,
      elasticity: 0.5,
      burstThreshold: 0.75,
      gooLevel: 0.7,
      impactSounds: impactSounds,
      burstSound: burstSound,
      particlePreset: 'p',
      decalPreset: 'd',
      coinReward: 5,
      unlockTier: 1,
      searchTags: const [],
      rarity: rarity,
    );

void main() {
  group('FeedbackDispatcher tier routing', () {
    test('hit plays variant + light haptic', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.dispatch(FeedbackTier.hit, _def());
      expect(sink.calls, [
        'playVariant:hit_dumplio:2',
        'hapticLight',
      ]);
    });

    test('squish plays variant + selection haptic', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.dispatch(FeedbackTier.squish, _def());
      expect(sink.calls, [
        'playVariant:squish_dumplio:2',
        'hapticSelection',
      ]);
    });

    test('burst plays one-shot + heavy haptic + screen shake', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.dispatch(FeedbackTier.burst, _def());
      expect(sink.calls, [
        'playOneShot:audio/food/dumplio_burst_01.mp3',
        'hapticHeavy',
        'shake:0.18:8',
      ]);
    });

    test('revealBurst uses a heavier shake than plain burst', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.dispatch(FeedbackTier.revealBurst, _def(rarity: Rarity.rare));
      final shake = sink.calls.firstWhere((c) => c.startsWith('shake:'));
      expect(shake, 'shake:0.22:10');
    });

    test('revealBurst on rare/epic/mythic layers the UI stinger', () {
      // Rare was previously silent — only epic+ got the stinger, so a
      // rare reveal sounded identical to a plain common burst. The
      // stinger should now fire for any non-common revealBurst.
      for (final rarity in [Rarity.rare, Rarity.epic, Rarity.mythic]) {
        final sink = RecordingFeedbackSink();
        final d = FeedbackDispatcher(sink: sink, rng: Random(1));
        d.dispatch(FeedbackTier.revealBurst, _def(rarity: rarity));
        expect(
          sink.calls,
          contains('playOneShot:audio/ui/ui_reveal_stinger_01.mp3'),
          reason: 'rarity=$rarity should layer the reveal stinger',
        );
      }
    });

    test('revealBurst on common does NOT layer the UI stinger', () {
      // The stinger is reserved for rarity step-ups. A common-tier
      // revealBurst (edge case path) should fire the per-object burst
      // sound but not the UI stinger.
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.dispatch(FeedbackTier.revealBurst, _def(rarity: Rarity.common));
      expect(
        sink.calls,
        isNot(contains('playOneShot:audio/ui/ui_reveal_stinger_01.mp3')),
      );
    });

    test('megaBurst uses the heaviest shake tier', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.dispatch(FeedbackTier.megaBurst, _def());
      final shake = sink.calls.firstWhere((c) => c.startsWith('shake:'));
      expect(shake, 'shake:0.28:12');
    });

    // GAME_POLISH_AUDIT.md P1-C tier-haptic routing — pre-fix every
    // reveal fired the identical hapticHeavy() so a mythic felt the
    // same as a common burst, killing the rarest moment in the game.
    test('revealBurst rare/epic fires hapticDoublePulse (not heavy)', () {
      for (final rarity in [Rarity.rare, Rarity.epic]) {
        final sink = RecordingFeedbackSink();
        final d = FeedbackDispatcher(sink: sink, rng: Random(1));
        d.dispatch(FeedbackTier.revealBurst, _def(rarity: rarity));
        expect(sink.calls, contains('hapticDoublePulse'),
            reason: '$rarity must fire the two-pulse haptic tier');
        expect(sink.calls, isNot(contains('hapticTriplePulse')));
        expect(sink.calls, isNot(contains('hapticHeavy')));
      }
    });

    test('revealBurst mythic fires hapticTriplePulse (rarest tier)', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.dispatch(FeedbackTier.revealBurst, _def(rarity: Rarity.mythic));
      expect(sink.calls, contains('hapticTriplePulse'));
      expect(sink.calls, isNot(contains('hapticDoublePulse')));
      expect(sink.calls, isNot(contains('hapticHeavy')));
    });

    test('megaBurst fires hapticTriplePulse (was heavy, pre-P1-C)', () {
      // Mega bursts are even rarer than mythic reveals — the player
      // should physically feel they crossed a threshold most rounds
      // never touch.
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.dispatch(FeedbackTier.megaBurst, _def());
      expect(sink.calls, contains('hapticTriplePulse'));
      expect(sink.calls, isNot(contains('hapticHeavy')));
    });

    test('plain burst (non-reveal) keeps the single hapticHeavy', () {
      // P1-C tiers the *reveal* haptic; the common-tier burst path
      // (FeedbackTier.burst, not revealBurst) intentionally stays
      // on hapticHeavy so the rarity gradient is preserved.
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.dispatch(FeedbackTier.burst, _def());
      expect(sink.calls, contains('hapticHeavy'));
      expect(sink.calls, isNot(contains('hapticDoublePulse')));
      expect(sink.calls, isNot(contains('hapticTriplePulse')));
    });
  });

  group('FeedbackDispatcher VO gating', () {
    test('common-tier revealBurst plays no VO (edge case)', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.voiceLines['reveal_rare'] = const ['audio/vo/rare_a.wav'];
      d.voiceLines['reveal_epic'] = const ['audio/vo/epic_a.wav'];
      d.voiceLines['reveal_mythic'] = const ['audio/vo/mythic_a.wav'];

      d.dispatch(FeedbackTier.revealBurst, _def(rarity: Rarity.common));

      expect(sink.countOf('voiceCallout'), 0);
    });

    test('rare/epic/mythic revealBurst each play the matching VO pool', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.voiceLines['reveal_rare'] = const ['audio/vo/rare_a.wav'];
      d.voiceLines['reveal_epic'] = const ['audio/vo/epic_a.wav'];
      d.voiceLines['reveal_mythic'] = const ['audio/vo/mythic_a.wav'];

      d.dispatch(FeedbackTier.revealBurst, _def(rarity: Rarity.rare));
      d.dispatch(FeedbackTier.revealBurst, _def(rarity: Rarity.epic));
      d.dispatch(FeedbackTier.revealBurst, _def(rarity: Rarity.mythic));

      expect(sink.calls, containsAll(<String>[
        'voiceCallout:audio/vo/rare_a.wav',
        'voiceCallout:audio/vo/epic_a.wav',
        'voiceCallout:audio/vo/mythic_a.wav',
      ]));
    });

    test('mega callout probability 0 → never plays VO', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1))
        ..megaCalloutProbability = 0.0;
      d.voiceLines['mega'] = const ['audio/vo/mega_a.wav'];

      for (var i = 0; i < 100; i++) {
        d.dispatch(FeedbackTier.megaBurst, _def());
      }
      expect(sink.countOf('voiceCallout'), 0);
    });

    test('mega callout probability 1 → always plays VO', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1))
        ..megaCalloutProbability = 1.0;
      d.voiceLines['mega'] = const ['audio/vo/mega_a.wav'];

      for (var i = 0; i < 50; i++) {
        d.dispatch(FeedbackTier.megaBurst, _def());
      }
      expect(sink.countOf('voiceCallout'), 50);
    });

    test('mega callout probability 1/3 → roughly 33% fires over many trials',
        () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(12345))
        ..megaCalloutProbability = 1 / 3;
      d.voiceLines['mega'] = const [
        'audio/vo/mega_a.wav',
        'audio/vo/mega_b.wav',
      ];
      const trials = 3000;
      for (var i = 0; i < trials; i++) {
        d.dispatch(FeedbackTier.megaBurst, _def());
      }
      final rate = sink.countOf('voiceCallout') / trials;
      expect(rate, greaterThan(0.28));
      expect(rate, lessThan(0.39));
    });

    test('no voice lines registered → no VO plays even on reveal', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.dispatch(FeedbackTier.revealBurst, _def(rarity: Rarity.mythic));
      d.dispatch(FeedbackTier.megaBurst, _def());
      expect(sink.countOf('voiceCallout'), 0);
    });
  });

  group('FeedbackDispatcher VO variant anti-repetition', () {
    test('consecutive megaBurst calls do not replay the same VO variant',
        () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(
        sink: sink,
        variantPicker: SoundVariantPicker(rng: Random(77)),
        rng: Random(99),
      )..megaCalloutProbability = 1.0;
      d.voiceLines['mega'] = const [
        'a.wav',
        'b.wav',
        'c.wav',
        'd.wav',
      ];
      final sequence = <String>[];
      for (var i = 0; i < 80; i++) {
        d.dispatch(FeedbackTier.megaBurst, _def());
        final last = sink.calls.last;
        if (last.startsWith('voiceCallout:')) {
          sequence.add(last);
        }
      }
      for (var i = 1; i < sequence.length; i++) {
        expect(sequence[i], isNot(equals(sequence[i - 1])),
            reason: 'VO repeat at index $i');
      }
    });
  });

  group('FeedbackDispatcher combo milestone chimes', () {
    test('comboMilestone always fires haptic + shake (chime is additive)', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      // No chimes registered — milestone should still produce
      // haptic + shake so the player never gets a *silent* milestone.
      d.dispatch(FeedbackTier.comboMilestone, _def());
      expect(sink.calls, ['hapticMedium', 'shake:0.10:4']);
      expect(sink.countOf('playVariant'), 0);
    });

    test('comboMilestone with comboTier=null plays no chime', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.comboChimes[ComboTier.starter] = const ['a.mp3', 'b.mp3'];

      d.dispatch(FeedbackTier.comboMilestone, _def(),
          comboTier: null);

      expect(sink.countOf('playVariant'), 0);
    });

    test('comboMilestone with comboTier=none plays no chime', () {
      // Defensive: even though the call site filters out `none` before
      // dispatching, the dispatcher should not crash or play a chime
      // if it somehow receives `none`.
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.comboChimes[ComboTier.starter] = const ['a.mp3', 'b.mp3'];

      d.dispatch(FeedbackTier.comboMilestone, _def(),
          comboTier: ComboTier.none);

      expect(sink.countOf('playVariant'), 0);
    });

    test('comboMilestone routes each tier to its registered chime pool', () {
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(sink: sink, rng: Random(1));
      d.comboChimes[ComboTier.starter] = const ['s_a.mp3', 's_b.mp3'];
      d.comboChimes[ComboTier.stronger] = const ['m_a.mp3', 'm_b.mp3'];
      d.comboChimes[ComboTier.revealReady] = const ['r_a.mp3', 'r_b.mp3'];
      d.comboChimes[ComboTier.mega] = const ['x_a.mp3', 'x_b.mp3'];

      d.dispatch(FeedbackTier.comboMilestone, _def(),
          comboTier: ComboTier.starter);
      d.dispatch(FeedbackTier.comboMilestone, _def(),
          comboTier: ComboTier.stronger);
      d.dispatch(FeedbackTier.comboMilestone, _def(),
          comboTier: ComboTier.revealReady);
      d.dispatch(FeedbackTier.comboMilestone, _def(),
          comboTier: ComboTier.mega);

      expect(sink.calls.where((c) => c.startsWith('playVariant:')), [
        'playVariant:combo_starter:2',
        'playVariant:combo_stronger:2',
        'playVariant:combo_revealReady:2',
        'playVariant:combo_mega:2',
      ]);
    });

    test('comboMilestone variant keys are scoped per tier (independent state)',
        () {
      // The variant picker keys "combo_starter", "combo_stronger" etc.
      // need to be distinct so the anti-repetition state for one tier
      // doesn't bleed into another (e.g., crossing starter then later
      // crossing stronger should NOT influence which stronger variant
      // plays first).
      final sink = RecordingFeedbackSink();
      final d = FeedbackDispatcher(
        sink: sink,
        variantPicker: SoundVariantPicker(rng: Random(7)),
        rng: Random(11),
      );
      d.comboChimes[ComboTier.starter] = const ['s_a', 's_b'];
      d.comboChimes[ComboTier.mega] = const ['x_a', 'x_b'];

      d.dispatch(FeedbackTier.comboMilestone, _def(),
          comboTier: ComboTier.starter);
      d.dispatch(FeedbackTier.comboMilestone, _def(),
          comboTier: ComboTier.mega);

      // Each playVariant key uses tier name — confirms scoping.
      expect(sink.calls.where((c) => c.startsWith('playVariant:')).toList(), [
        'playVariant:combo_starter:2',
        'playVariant:combo_mega:2',
      ]);
    });
  });
}
