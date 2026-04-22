/// Drives the calm ↔ reveal crossfade timing for a skybox, plus the
/// short radial flash that sells the transition.
///
/// Pure Dart (no Flame/Flutter deps) so the timing can be unit-tested
/// without spinning up a game loop.
///
/// Timeline when [trigger] is called with `hold = 1.2`:
///   t=0.00 — reveal alpha ramps 0 → 1 over attack (0.18s)
///   t=0.12 — flash alpha peaks (0.7) for 120ms window, then fades
///   t=0.18 — reveal fully visible
///   t=1.50 — release starts (t = attack + hold + 0.12 is earlier; see code)
///   t=1.90 — reveal alpha back to 0; calm fully visible
class SkyboxRevealController {
  SkyboxRevealController({
    this.attack = 0.18,
    this.release = 0.40,
    this.flashDelay = 0.12,
    this.flashDuration = 0.12,
    this.flashPeakAlpha = 0.7,
  });

  /// Crossfade-in duration.
  final double attack;

  /// Crossfade-out duration.
  final double release;

  /// How long after trigger the radial flash peaks.
  final double flashDelay;

  /// Total flash lifetime (rise + fall).
  final double flashDuration;

  final double flashPeakAlpha;

  // -- runtime state ---------------------------------------------------

  double _elapsed = 0;
  double _totalDuration = 0; // attack + hold + release
  double _holdWindowEnd = 0; // attack + hold (then release begins)
  bool _active = false;

  /// Start a reveal. [hold] is the time the reveal stays fully visible
  /// between attack and release. Calling trigger while one is already in
  /// flight restarts the sequence from t=0.
  void trigger({required double hold}) {
    _elapsed = 0;
    _holdWindowEnd = attack + hold;
    _totalDuration = _holdWindowEnd + release;
    _active = true;
  }

  /// Force-stop any in-flight reveal.
  void cancel() {
    _active = false;
    _elapsed = 0;
  }

  /// Advance the controller by [dt] seconds. Safe to call every frame.
  void tick(double dt) {
    if (!_active) return;
    _elapsed += dt;
    if (_elapsed >= _totalDuration) {
      _active = false;
      _elapsed = 0;
    }
  }

  // -- readable state --------------------------------------------------

  bool get isActive => _active;

  /// Alpha [0..1] for the calm layer. 1 when nothing is happening.
  double get calmAlpha => 1.0 - revealAlpha;

  /// Alpha [0..1] for the reveal overlay.
  double get revealAlpha {
    if (!_active) return 0;
    if (_elapsed < attack) {
      return (_elapsed / attack).clamp(0.0, 1.0);
    }
    if (_elapsed <= _holdWindowEnd) {
      return 1.0;
    }
    final releaseElapsed = _elapsed - _holdWindowEnd;
    return (1.0 - releaseElapsed / release).clamp(0.0, 1.0);
  }

  /// Alpha [0..flashPeakAlpha] for the radial flash overlay. Rises and
  /// falls symmetrically around [flashDelay] + [flashDuration]/2.
  double get flashAlpha {
    if (!_active) return 0;
    final start = flashDelay;
    final end = flashDelay + flashDuration;
    if (_elapsed < start || _elapsed > end) return 0;
    final mid = (start + end) / 2;
    final distFromMid = (_elapsed - mid).abs();
    final halfLife = (end - start) / 2;
    if (halfLife <= 0) return 0;
    final t = (1.0 - distFromMid / halfLife).clamp(0.0, 1.0);
    return t * flashPeakAlpha;
  }

  /// Seconds elapsed since the current trigger (0 when not active).
  double get elapsed => _elapsed;
}
