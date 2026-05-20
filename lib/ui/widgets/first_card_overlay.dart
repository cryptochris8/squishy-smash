import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/rarity.dart';
import '../../data/models/smashable_def.dart';
import '../theme/app_theme.dart';

/// Once-per-profile celebration shown the very first time a player
/// discovers ANY card. Addresses GAME_POLISH_AUDIT.md UX-3 — previously
/// a first-card unlock used the same "+N coins" duplicate toast, so
/// the most meaningful moment of the early session felt identical to a
/// repeated burst on a known squishy.
///
/// Auto-dismisses after [_kAutoDismiss] so the round keeps moving;
/// tap outside or the "Keep going" CTA dismisses early. Caller is
/// responsible for gating to the one-shot moment (typically by
/// checking `discoveredSmashableIds.length == 1` immediately after
/// `markDiscovered`).
class FirstCardOverlay extends StatefulWidget {
  const FirstCardOverlay._({required this.def, required this.rarity});

  final SmashableDef def;
  final Rarity rarity;

  static const Duration _kAutoDismiss = Duration(milliseconds: 4000);

  static Future<void> show(
    BuildContext context, {
    required SmashableDef def,
    required Rarity rarity,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (_) => FirstCardOverlay._(def: def, rarity: rarity),
    );
  }

  @override
  State<FirstCardOverlay> createState() => _FirstCardOverlayState();
}

class _FirstCardOverlayState extends State<FirstCardOverlay> {
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _autoDismiss = Timer(FirstCardOverlay._kAutoDismiss, () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    super.dispose();
  }

  Color get _accent {
    switch (widget.rarity) {
      case Rarity.common:
        return Palette.cream;
      case Rarity.rare:
        return Palette.jellyBlue;
      case Rarity.epic:
        return Palette.lavender;
      case Rarity.mythic:
        return Palette.cream;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accent, Palette.pink, Palette.lavender],
          ),
          borderRadius: BorderRadius.circular(AppRadii.dialog),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.45),
              blurRadius: 48,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xs2),
        child: Container(
          decoration: BoxDecoration(
            color: Palette.bgSurface,
            borderRadius: BorderRadius.circular(AppRadii.dialogInner),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Palette.cream, size: 36),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'YOUR FIRST SQUISHY!',
                style: TextStyle(
                  color: Palette.cream,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.def.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(color: _accent, width: 1.4),
                ),
                child: Text(
                  widget.rarity.displayLabel.toUpperCase(),
                  style: TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Keep tapping to collect them all.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Palette.cream,
                ),
                child: const Text(
                  'Keep going',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
