/// Canonical source-of-truth for the voice-line asset paths bundled with
/// the game. [FeedbackDispatcher.voiceLines] is populated from this, and
/// [SoundManager.warm] pre-caches them at boot.
///
/// All paths are relative to `assets/` and use the `audio/...` convention
/// that [SoundManager._normalize] strips before calling `flame_audio`.
class VoiceLineRegistry {
  VoiceLineRegistry._();

  static const List<String> revealRare = <String>[
    'audio/vo/vo_reveal_rare_a.mp3',
    'audio/vo/vo_reveal_rare_b.mp3',
  ];

  static const List<String> revealEpic = <String>[
    'audio/vo/vo_reveal_epic_a.mp3',
    'audio/vo/vo_reveal_epic_b.mp3',
  ];

  static const List<String> revealMythic = <String>[
    'audio/vo/vo_reveal_mythic_a.mp3',
    'audio/vo/vo_reveal_mythic_b.mp3',
  ];

  static const List<String> mega = <String>[
    'audio/vo/vo_mega_a.mp3',
    'audio/vo/vo_mega_b.mp3',
    'audio/vo/vo_mega_c.mp3',
  ];

  static const List<String> asmrIdle = <String>[
    'audio/vo/vo_asmr_idle_a.mp3',
    'audio/vo/vo_asmr_idle_b.mp3',
  ];

  /// Flat list of every bundled VO path. Passed to [SoundManager.warm]
  /// so first-play latency doesn't stutter on reveal moments.
  static List<String> get allPaths => <String>[
        ...revealRare,
        ...revealEpic,
        ...revealMythic,
        ...mega,
        ...asmrIdle,
      ];

  /// Map keyed by [FeedbackDispatcher.voiceLines] keys.
  static Map<String, List<String>> get dispatcherMap =>
      <String, List<String>>{
        'reveal_rare': revealRare,
        'reveal_epic': revealEpic,
        'reveal_mythic': revealMythic,
        'mega': mega,
      };
}
