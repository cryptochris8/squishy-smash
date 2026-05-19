import 'dart:math';

/// Picks the next sound variant from a list, enforcing anti-repetition:
/// the same index is never picked twice in a row, so "sfx_squish_wet_02"
/// doesn't play back-to-back and reveal the file count to the player.
///
/// Pure Dart with an injectable [Random] so tests can seed for determinism.
class SoundVariantPicker {
  SoundVariantPicker({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;
  final Map<String, int> _lastIndexByKey = <String, int>{};

  /// Pick one element from [options], scoped by [key] (typically the event
  /// category like "burst" or per-object id) so different categories
  /// maintain independent last-played state.
  ///
  /// Returns null when [options] is empty.
  T? pick<T>(String key, List<T> options) {
    if (options.isEmpty) return null;
    if (options.length == 1) {
      _lastIndexByKey[key] = 0;
      return options[0];
    }
    final lastIdx = _lastIndexByKey[key];
    int idx;
    if (lastIdx == null) {
      idx = _rng.nextInt(options.length);
    } else {
      // Uniform pick from the (length - 1) non-last options. Roll in
      // the shorter range and offset at-or-above the last index — the
      // previous (idx + 1) % length wrap doubled the probability of
      // whatever lived immediately after the last-played index.
      idx = _rng.nextInt(options.length - 1);
      if (idx >= lastIdx) idx += 1;
    }
    _lastIndexByKey[key] = idx;
    return options[idx];
  }

  /// Reset last-played state for a category. Useful on round end / scene
  /// change so the next session doesn't lock out the variant that happened
  /// to be last.
  void resetKey(String key) => _lastIndexByKey.remove(key);

  void resetAll() => _lastIndexByKey.clear();
}
