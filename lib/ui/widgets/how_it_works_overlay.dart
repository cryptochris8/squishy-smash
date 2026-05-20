import 'package:flutter/material.dart';

import '../../analytics/events.dart';
import '../../core/constants.dart';
import '../../core/service_locator.dart';
import '../theme/app_theme.dart';
import 'brand_glyph.dart';

/// First-run "How it works" overlay — a single dismissible frame shown
/// once on first launch, then never again on this device.
///
/// Audit context (GAME_POLISH_AUDIT.md → UX-1): Reddit-acquired players
/// land on the menu, tap PLAY, and watch a squishy appear with no
/// context. The audit flagged this as the highest churn driver for the
/// 2026-05-29 Reddit launch. Two short lines + an OK CTA is enough —
/// the game itself is self-explanatory after the first tap.
///
/// Dismissal is persisted via [Persistence.setHowItWorksSeen]. The
/// flag lives in the device-level settings keyspace (not the
/// PlayerProfile blob) on purpose: a reinstall on a new device should
/// re-onboard the new session, not honor a cross-device "seen" mark.
///
/// Show via: `await HowItWorksOverlay.show(context)`.
class HowItWorksOverlay extends StatelessWidget {
  const HowItWorksOverlay._();

  static Future<void> show(BuildContext context) async {
    GameEvents(ServiceLocator.analytics).tutorialBegin();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const HowItWorksOverlay._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Palette.pink, Palette.lavender, Palette.jellyBlue],
          ),
          borderRadius: BorderRadius.circular(AppRadii.dialog),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FF8FB8),
              blurRadius: 40,
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
              const BrandGlyphIcon(
                BrandGlyph.sparkle,
                color: Palette.cream,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Welcome to Squishy Smash',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Tap squishies to smash them. The faster you tap, the bigger your combo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Every burst can unlock a new card — there are 48 to collect.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ServiceLocator.persistence
                        .setHowItWorksSeen(true);
                    GameEvents(ServiceLocator.analytics)
                        .tutorialComplete();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.cream,
                    foregroundColor: Palette.bgDeep,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
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
