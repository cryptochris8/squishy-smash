/// Per-smashable economy throttle.
///
/// Tracks the timestamp of the last *credited* burst per smashable id.
/// A subsequent burst on the same id within [cooldownMs] is suppressed:
/// the dispatcher still plays ASMR feedback (sounds, particles) but
/// skips coin awards, card-burst credit, and score additions. Bursts
/// on a *different* smashable run on independent timers, so varied
/// play feels normal — only repeat-spam on the same object loses
/// economic value.
///
/// The cooldown updates only on credited bursts. A kid hammering at
/// 5 taps/sec on the same smashable gets ~1 credit/sec at
/// `cooldownMs == 1000`; everything else still pops, ricochets, and
/// pings just like before. Silent throttle, never visible.
///
/// Pure data class — no Flame or persistence dependencies. Lives in
/// memory; resets when the app process ends. The map is bounded by
/// the number of unique smashable ids (~50), so no eviction needed.
class AntiSpamCooldown {
  AntiSpamCooldown({required this.cooldownMs}) : assert(cooldownMs >= 0);

  /// Window in milliseconds. 0 disables throttling entirely.
  final int cooldownMs;

  final Map<String, int> _lastCreditedMs = <String, int>{};

  /// True if a burst on [smashableId] at [nowMs] should be suppressed
  /// (within the cooldown of the previous credit). False otherwise.
  /// Pure — does not mutate state. Call [markCredited] when actually
  /// crediting the burst.
  bool shouldSuppress({
    required String smashableId,
    required int nowMs,
  }) {
    if (cooldownMs == 0) return false;
    final last = _lastCreditedMs[smashableId];
    if (last == null) return false;
    return (nowMs - last) < cooldownMs;
  }

  /// Record that a burst on [smashableId] at [nowMs] was credited.
  /// Subsequent bursts within [cooldownMs] of [nowMs] will be
  /// suppressed by [shouldSuppress] until the window elapses.
  void markCredited({
    required String smashableId,
    required int nowMs,
  }) {
    _lastCreditedMs[smashableId] = nowMs;
  }

  /// Clear all tracked timestamps. Useful for ending a round /
  /// resetting state in tests. Production rarely needs this — the
  /// map is bounded and untracked timestamps just sit harmlessly.
  void reset() => _lastCreditedMs.clear();
}
