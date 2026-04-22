import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/systems/skybox_reveal_controller.dart';

void main() {
  group('SkyboxRevealController idle state', () {
    test('not active on construction', () {
      final c = SkyboxRevealController();
      expect(c.isActive, isFalse);
      expect(c.revealAlpha, 0);
      expect(c.calmAlpha, 1);
      expect(c.flashAlpha, 0);
    });

    test('tick with no trigger stays idle', () {
      final c = SkyboxRevealController();
      for (var i = 0; i < 60; i++) {
        c.tick(1 / 60);
      }
      expect(c.isActive, isFalse);
      expect(c.revealAlpha, 0);
    });
  });

  group('SkyboxRevealController trigger → attack', () {
    test('revealAlpha ramps 0→1 over attack window', () {
      final c = SkyboxRevealController()..trigger(hold: 1.0);
      expect(c.revealAlpha, 0);
      c.tick(c.attack / 2);
      expect(c.revealAlpha, closeTo(0.5, 0.01));
      c.tick(c.attack / 2);
      expect(c.revealAlpha, closeTo(1.0, 0.01));
    });

    test('calmAlpha is always 1 - revealAlpha', () {
      final c = SkyboxRevealController()..trigger(hold: 1.0);
      for (var i = 0; i < 10; i++) {
        c.tick(0.05);
        expect(c.calmAlpha + c.revealAlpha, closeTo(1.0, 0.001));
      }
    });
  });

  group('SkyboxRevealController flash envelope', () {
    test('flash rises and falls with a peak near the mid-point', () {
      final c = SkyboxRevealController()..trigger(hold: 2.0);
      // Step to just before the flash starts.
      c.tick(0.11);
      expect(c.flashAlpha, 0);
      // Step to mid-point of flash (flashDelay + flashDuration/2 = 0.18).
      c.tick(0.07);
      expect(c.flashAlpha, closeTo(c.flashPeakAlpha, 0.05));
      // Step past flash end (0.12 + 0.12 = 0.24).
      c.tick(0.07);
      expect(c.flashAlpha, 0);
    });

    test('flashAlpha is 0 when not active', () {
      final c = SkyboxRevealController();
      expect(c.flashAlpha, 0);
    });
  });

  group('SkyboxRevealController hold + release', () {
    test('revealAlpha stays at 1 during hold window', () {
      final c = SkyboxRevealController()..trigger(hold: 1.0);
      // Skip past attack.
      c.tick(c.attack + 0.01);
      expect(c.revealAlpha, closeTo(1.0, 0.01));
      // Several ticks into hold — should still be 1.
      for (var i = 0; i < 10; i++) {
        c.tick(0.05);
      }
      expect(c.revealAlpha, closeTo(1.0, 0.01));
    });

    test('revealAlpha ramps 1→0 over release window', () {
      final c = SkyboxRevealController()..trigger(hold: 0.0);
      c.tick(c.attack); // finish attack
      expect(c.revealAlpha, closeTo(1.0, 0.01));
      c.tick(c.release / 2);
      expect(c.revealAlpha, closeTo(0.5, 0.05));
      c.tick(c.release / 2);
      expect(c.revealAlpha, closeTo(0.0, 0.05));
    });

    test('becomes inactive after total duration', () {
      final c = SkyboxRevealController()..trigger(hold: 0.5);
      final total = c.attack + 0.5 + c.release;
      c.tick(total + 0.01);
      expect(c.isActive, isFalse);
      expect(c.revealAlpha, 0);
    });
  });

  group('SkyboxRevealController trigger restart + cancel', () {
    test('trigger while active restarts the sequence from t=0', () {
      final c = SkyboxRevealController()..trigger(hold: 1.0);
      c.tick(0.2);
      expect(c.revealAlpha, closeTo(1.0, 0.01));
      c.trigger(hold: 1.0);
      expect(c.elapsed, 0);
      expect(c.revealAlpha, 0);
    });

    test('cancel stops the sequence immediately', () {
      final c = SkyboxRevealController()..trigger(hold: 1.0);
      c.tick(0.1);
      expect(c.isActive, isTrue);
      c.cancel();
      expect(c.isActive, isFalse);
      expect(c.revealAlpha, 0);
    });
  });
}
