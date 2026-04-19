import 'package:shared_preferences/shared_preferences.dart';

import 'models/player_profile.dart';

class Persistence {
  Persistence._(this._prefs);

  static const String _coinsKey = 'profile.coins';
  static const String _unlocksKey = 'profile.unlocks';
  static const String _bestScoreKey = 'profile.best_score';
  static const String _bestComboKey = 'profile.best_combo';
  static const String _hapticsKey = 'settings.haptics';
  static const String _muteKey = 'settings.mute';

  final SharedPreferences _prefs;

  static Future<Persistence> open() async {
    final prefs = await SharedPreferences.getInstance();
    return Persistence._(prefs);
  }

  PlayerProfile loadProfile() {
    final unlocks = _prefs.getStringList(_unlocksKey) ?? <String>['launch_squishy_foods'];
    return PlayerProfile(
      coins: _prefs.getInt(_coinsKey) ?? 0,
      unlockedPackIds: unlocks.toSet(),
      bestScore: _prefs.getInt(_bestScoreKey) ?? 0,
      bestCombo: _prefs.getInt(_bestComboKey) ?? 0,
    );
  }

  Future<void> saveProfile(PlayerProfile p) async {
    await _prefs.setInt(_coinsKey, p.coins);
    await _prefs.setStringList(_unlocksKey, p.unlockedPackIds.toList());
    await _prefs.setInt(_bestScoreKey, p.bestScore);
    await _prefs.setInt(_bestComboKey, p.bestCombo);
  }

  bool get hapticsEnabled => _prefs.getBool(_hapticsKey) ?? true;
  Future<void> setHapticsEnabled(bool v) => _prefs.setBool(_hapticsKey, v);

  bool get muted => _prefs.getBool(_muteKey) ?? false;
  Future<void> setMuted(bool v) => _prefs.setBool(_muteKey, v);
}
