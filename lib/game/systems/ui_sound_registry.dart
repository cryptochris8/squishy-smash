import 'sound_manager.dart';

/// Canonical set of UI stinger paths. Pre-warmed by [SoundManager] at
/// boot, played by [UiSounds] from any widget callsite.
class UiSoundRegistry {
  UiSoundRegistry._();

  static const String buttonTap = 'audio/ui/ui_button_tap_01.mp3';
  static const String confirm = 'audio/ui/ui_confirm_01.mp3';
  static const String coinDing = 'audio/ui/ui_coin_ding_01.mp3';
  static const String unlockChime = 'audio/ui/ui_unlock_chime_01.mp3';
  static const String revealStinger = 'audio/ui/ui_reveal_stinger_01.mp3';
  static const String packSelect = 'audio/ui/ui_pack_select_01.mp3';
  static const String settingsToggle =
      'audio/ui/ui_settings_toggle_01.mp3';
  static const String back = 'audio/ui/ui_back_01.mp3';

  static const List<String> allPaths = <String>[
    buttonTap,
    confirm,
    coinDing,
    unlockChime,
    revealStinger,
    packSelect,
    settingsToggle,
    back,
  ];
}

/// Thin helper for playing UI stingers from widget callsites without
/// importing the full SoundManager surface. Takes a [SoundManager] so
/// callsites can swap it in tests.
class UiSounds {
  UiSounds(this._sounds);

  final SoundManager _sounds;

  void buttonTap() => _sounds.play(UiSoundRegistry.buttonTap);
  void confirm() => _sounds.play(UiSoundRegistry.confirm);
  void coinDing() => _sounds.play(UiSoundRegistry.coinDing);
  void unlockChime() => _sounds.play(UiSoundRegistry.unlockChime);
  void revealStinger() => _sounds.play(UiSoundRegistry.revealStinger);
  void packSelect() => _sounds.play(UiSoundRegistry.packSelect);
  void settingsToggle() => _sounds.play(UiSoundRegistry.settingsToggle);
  void back() => _sounds.play(UiSoundRegistry.back);
}
