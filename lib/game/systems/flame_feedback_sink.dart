import '../components/screen_shake.dart';
import 'feedback_dispatcher.dart';
import 'haptics_manager.dart';
import 'sound_manager.dart';
import 'sound_variant_picker.dart';

/// Production [FeedbackSink] that delegates to the real game systems
/// (SoundManager, HapticsManager, ScreenShake). Owns its own
/// [SoundVariantPicker] so `playVariant` enforces anti-repetition on
/// squish/hit SFX just like the dispatcher does for VO.
class FlameFeedbackSink implements FeedbackSink {
  FlameFeedbackSink({
    required this.sounds,
    required this.haptics,
    required this.shaker,
    SoundVariantPicker? picker,
  }) : _picker = picker ?? SoundVariantPicker();

  final SoundManager sounds;
  final HapticsManager haptics;
  final ScreenShake shaker;
  final SoundVariantPicker _picker;

  @override
  void playOneShot(String path) {
    sounds.play(path);
  }

  @override
  void playVariant(String key, List<String> options) {
    final pick = _picker.pick<String>(key, options);
    if (pick != null) sounds.play(pick);
  }

  @override
  void voiceCallout(String path) {
    sounds.play(path);
  }

  @override
  void hapticLight() => haptics.light();

  @override
  void hapticMedium() => haptics.medium();

  @override
  void hapticHeavy() => haptics.heavy();

  @override
  void hapticSelection() => haptics.selection();

  @override
  void screenShake({double duration = 0.18, double intensity = 8}) {
    shaker.shake(duration: duration, intensity: intensity);
  }
}
