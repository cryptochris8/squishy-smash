import 'package:shared_preferences/shared_preferences.dart';

import 'models/player_profile.dart';
import 'models/rarity.dart';

class Persistence {
  Persistence._(this._prefs);

  static const String _coinsKey = 'profile.coins';
  static const String _unlocksKey = 'profile.unlocks';
  static const String _bestScoreKey = 'profile.best_score';
  static const String _bestComboKey = 'profile.best_combo';
  static const String _sessionCountKey = 'profile.session_count';
  static const String _arenaUnlocksKey = 'profile.arena_unlocks';
  static const String _activeArenaKey = 'profile.active_arena';
  static const String _rollsSinceRareKey = 'profile.rolls_since_rare';
  static const String _rollsSinceEpicKey = 'profile.rolls_since_epic';
  static const String _rollsSinceMythicKey = 'profile.rolls_since_mythic';
  static const String _discoveredIdsKey = 'profile.discovered_ids';
  static const String _rarestSeenKey = 'profile.rarest_seen';
  static const String _hapticsKey = 'settings.haptics';
  static const String _muteKey = 'settings.mute';

  final SharedPreferences _prefs;

  static Future<Persistence> open() async {
    final prefs = await SharedPreferences.getInstance();
    return Persistence._(prefs);
  }

  PlayerProfile loadProfile() {
    final unlocks =
        _prefs.getStringList(_unlocksKey) ?? <String>['launch_squishy_foods'];
    // Pre-arena-unlocks saves: default to the free launch arena so
    // existing players don't lose their backdrop on app upgrade.
    final arenaUnlocks = _prefs.getStringList(_arenaUnlocksKey) ??
        <String>['mochi_sunset_beach'];
    final discovered =
        _prefs.getStringList(_discoveredIdsKey) ?? const <String>[];
    return PlayerProfile(
      coins: _prefs.getInt(_coinsKey) ?? 0,
      unlockedPackIds: unlocks.toSet(),
      bestScore: _prefs.getInt(_bestScoreKey) ?? 0,
      bestCombo: _prefs.getInt(_bestComboKey) ?? 0,
      sessionCount: _prefs.getInt(_sessionCountKey) ?? 0,
      unlockedArenaKeys: arenaUnlocks.toSet(),
      activeArenaKey:
          _prefs.getString(_activeArenaKey) ?? 'mochi_sunset_beach',
      rollsSinceRare: _prefs.getInt(_rollsSinceRareKey) ?? 0,
      rollsSinceEpic: _prefs.getInt(_rollsSinceEpicKey) ?? 0,
      rollsSinceMythic: _prefs.getInt(_rollsSinceMythicKey) ?? 0,
      discoveredSmashableIds: discovered.toSet(),
      rarestSeen: rarityFromToken(_prefs.getString(_rarestSeenKey)),
    );
  }

  Future<void> saveProfile(PlayerProfile p) async {
    await _prefs.setInt(_coinsKey, p.coins);
    await _prefs.setStringList(_unlocksKey, p.unlockedPackIds.toList());
    await _prefs.setInt(_bestScoreKey, p.bestScore);
    await _prefs.setInt(_bestComboKey, p.bestCombo);
    await _prefs.setInt(_sessionCountKey, p.sessionCount);
    await _prefs.setStringList(
      _arenaUnlocksKey,
      p.unlockedArenaKeys.toList(),
    );
    await _prefs.setString(_activeArenaKey, p.activeArenaKey);
    await _prefs.setInt(_rollsSinceRareKey, p.rollsSinceRare);
    await _prefs.setInt(_rollsSinceEpicKey, p.rollsSinceEpic);
    await _prefs.setInt(_rollsSinceMythicKey, p.rollsSinceMythic);
    await _prefs.setStringList(
      _discoveredIdsKey,
      p.discoveredSmashableIds.toList(),
    );
    await _prefs.setString(_rarestSeenKey, p.rarestSeen.token);
  }

  bool get hapticsEnabled => _prefs.getBool(_hapticsKey) ?? true;
  Future<void> setHapticsEnabled(bool v) => _prefs.setBool(_hapticsKey, v);

  bool get muted => _prefs.getBool(_muteKey) ?? false;
  Future<void> setMuted(bool v) => _prefs.setBool(_muteKey, v);
}
