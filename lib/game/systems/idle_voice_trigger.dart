import 'dart:math';

/// Picks an ASMR idle voice line to play when the player has gone
/// quiet for a beat — the "ooh" / "squeeze me" whispers that fill the
/// silence between bursts and act as a first-90-second hook for new
/// installs who haven't tapped yet.
///
/// Pure logic, no Flame coupling — call [tick] every frame with the
/// frame delta and play whatever path it returns. Call [reset] on any
/// player interaction so the silence counter restarts.
///
/// Background — `GAME_POLISH_AUDIT.md` P1-A noted that the 5 idle VO
/// clips at `audio/vo/vo_asmr_idle_*.mp3` are warmed at boot by
/// [VoiceLineRegistry] but never played: the dispatcher map never
/// included them and no call site exists. This trigger closes that gap.
class IdleVoiceTrigger {
  IdleVoiceTrigger({
    required this.lines,
    Random? rng,
    this.silenceThreshold = 3.0,
    this.cooldown = 8.0,
  }) : _rng = rng ?? Random();

  /// Pool of idle VO asset paths to draw from. An empty list disables
  /// the trigger entirely (defensive — if VoiceLineRegistry is ever
  /// re-keyed and the asmrIdle bucket goes empty, the game keeps
  /// running with silence instead of throwing).
  final List<String> lines;

  /// Seconds of silence before the first idle line is eligible to fire.
  /// 3 s lands in the "the player is deciding whether to tap" window
  /// without firing the instant the round starts.
  final double silenceThreshold;

  /// Minimum gap between two idle plays. 8 s prevents the trigger from
  /// becoming chatter — players who pause repeatedly should hear ASMR
  /// breathing, not a clip every few seconds.
  final double cooldown;

  final Random _rng;

  double _silenceAccum = 0;
  double _cooldownRemaining = 0;

  /// Tick the timer forward by [dt] seconds. Returns a path to play
  /// when both (a) the silence threshold has been crossed and (b) the
  /// post-fire cooldown has elapsed; returns null otherwise.
  ///
  /// On a fire, the silence counter resets to 0 and the cooldown is
  /// armed — the next eligible fire is at least [cooldown] seconds
  /// from now, and only if the player stays quiet through that window.
  String? tick(double dt) {
    if (lines.isEmpty) return null;
    _silenceAccum += dt;
    if (_cooldownRemaining > 0) {
      _cooldownRemaining -= dt;
    }
    if (_silenceAccum >= silenceThreshold && _cooldownRemaining <= 0) {
      _cooldownRemaining = cooldown;
      _silenceAccum = 0;
      return lines[_rng.nextInt(lines.length)];
    }
    return null;
  }

  /// Player interaction (impact, burst, gesture). Clears the silence
  /// accumulator so the trigger can't fire mid-action. The cooldown
  /// counter is intentionally not reset — an interaction in the
  /// middle of a cooldown shouldn't instantly unlock the next fire.
  void reset() {
    _silenceAccum = 0;
  }
}
