import 'package:flutter/material.dart';

import '../squishy_game.dart';
import '../systems/combo_controller.dart';
import '../../core/constants.dart';
import '../../ui/theme/app_theme.dart';

/// Thin Flutter overlay for the score/multiplier/fill bar. Listens to
/// `SquishyGame.hudNotifier` so it only rebuilds on real state changes
/// (score bumps, combo tier crossings, or 1% fill-bar deltas) — not on
/// a fixed polling interval.
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final SquishyGame game;

  /// Color + size styling for the multiplier text driven by the
  /// current combo milestone tier. Matches the tuning-doc intent:
  /// higher combo should feel progressively more charged.
  ({Color color, double fontSize, FontWeight weight}) _multStyleFor(
      ComboTier tier) {
    switch (tier) {
      case ComboTier.none:
        return (color: Colors.white70, fontSize: 22, weight: FontWeight.w700);
      case ComboTier.starter:
        return (
          color: Palette.cream,
          fontSize: 24,
          weight: FontWeight.w800,
        );
      case ComboTier.stronger:
        return (
          color: const Color(0xFFFFB05C),
          fontSize: 28,
          weight: FontWeight.w900,
        );
      case ComboTier.revealReady:
        return (
          color: Palette.pink,
          fontSize: 32,
          weight: FontWeight.w900,
        );
      case ComboTier.mega:
        return (
          color: Palette.toxicLime,
          fontSize: 36,
          weight: FontWeight.w900,
        );
    }
  }

  Color _barColorFor(ComboTier tier) {
    switch (tier) {
      case ComboTier.none:
      case ComboTier.starter:
        return Palette.pink;
      case ComboTier.stronger:
        return Palette.cream;
      case ComboTier.revealReady:
        return Palette.lavender;
      case ComboTier.mega:
        return Palette.toxicLime;
    }
  }

  /// On-screen banner shown only when the skybox failed to load — gives a
  /// TestFlight tester (no Mac, no device console) something concrete to
  /// screenshot and report back. Returns null when everything loaded.
  Widget? _skyboxDiagnostic() {
    try {
      final sky = game.skybox;
      if (!sky.hasLoadFailure) return null;
      final lines = <String>[
        'SKYBOX LOAD FAILED — theme=${sky.theme.key}',
        if (sky.calmError != null) 'calm: ${sky.calmError}',
        if (sky.revealError != null) 'reveal: ${sky.revealError}',
      ];
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: const Color(0xCC8B0000),
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: lines
              .map((line) => Text(
                    line,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.3,
                    ),
                  ))
              .toList(growable: false),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Round countdown chip, anchored top-right opposite the score.
  /// UX-10 — first-time players had no on-screen cue that a round is
  /// time-boxed. Turns urgent (pink) for the final 10 seconds.
  Widget _roundTimerChip(int secondsLeft) {
    final low = secondsLeft <= 10;
    final minutes = secondsLeft ~/ 60;
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return Semantics(
      label: 'Time left: $secondsLeft seconds',
      liveRegion: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Text(
          '$minutes:$seconds',
          style: TextStyle(
            fontSize: 20,
            fontWeight: low ? FontWeight.w900 : FontWeight.w800,
            color: low ? Palette.pink : Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HudSnapshot>(
      valueListenable: game.hudNotifier,
      builder: (context, data, _) {
        final diag = _skyboxDiagnostic();
        final multStyle = _multStyleFor(data.tier);
        final barColor = _barColorFor(data.tier);
        final barHeight = data.tier == ComboTier.mega ? 12.0 : 8.0;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // P1.12 — VoiceOver announces score updates via this
                // live region. Pre-fix the score number was read as a
                // bare digit with no context; with liveRegion set,
                // assistive tech re-announces on each value change.
                //
                // UX-10 — the round timer sits center, between the
                // score (left) and the gameplay screen's share/close
                // controls (right), so the three read as one top bar.
                // Equal-flex spacers either side keep it screen-centered
                // regardless of how wide the score grows.
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Semantics(
                          label: 'Score: ${data.score}',
                          liveRegion: true,
                          excludeSemantics: true,
                          child: Text(
                            '${data.score}',
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _roundTimerChip(data.secondsLeft),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Semantics(
                      label: 'Combo multiplier x${data.mult}',
                      liveRegion: true,
                      excludeSemantics: true,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 140),
                        style: TextStyle(
                          fontSize: multStyle.fontSize,
                          fontWeight: multStyle.weight,
                          color: multStyle.color,
                        ),
                        child: Text('x${data.mult}'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: barHeight,
                          child: LinearProgressIndicator(
                            minHeight: barHeight,
                            value: data.fill,
                            backgroundColor: Colors.white12,
                            color: barColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (diag != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  diag,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
