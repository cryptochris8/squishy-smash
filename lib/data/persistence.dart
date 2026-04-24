import 'dart:convert';

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
  static const String _discoveredIdsKey = 'profile.discovered_ids';
  static const String _rarestSeenKey = 'profile.rarest_seen';
  static const String _totalBurstsByPackKey = 'profile.total_bursts_by_pack';
  static const String _rareDryByPackKey = 'profile.rare_dry_by_pack';
  static const String _epicDryByPackKey = 'profile.epic_dry_by_pack';
  static const String _legendaryDryByPackKey =
      'profile.legendary_dry_by_pack';
  static const String _lastPlayDateKey = 'profile.last_play_date';
  static const String _currentStreakKey = 'profile.current_streak';
  static const String _longestStreakKey = 'profile.longest_streak';
  static const String _boostTokensKey = 'profile.boost_tokens';
  static const String _hasRemoveAdsKey = 'profile.has_remove_ads';
  static const String _starterBundleClaimedKey =
      'profile.starter_bundle_claimed';
  static const String _guaranteedRevealTokensKey =
      'profile.guaranteed_reveal_tokens';
  static const String _purchasedSkusKey = 'profile.purchased_skus';
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
      discoveredSmashableIds: discovered.toSet(),
      rarestSeen: rarityFromToken(_prefs.getString(_rarestSeenKey)),
      totalBurstsByPack: _loadIntMap(_totalBurstsByPackKey),
      rareDryByPack: _loadIntMap(_rareDryByPackKey),
      epicDryByPack: _loadIntMap(_epicDryByPackKey),
      legendaryDryByPack: _loadIntMap(_legendaryDryByPackKey),
      lastPlayDate: _prefs.getString(_lastPlayDateKey),
      currentStreak: _prefs.getInt(_currentStreakKey) ?? 0,
      longestStreak: _prefs.getInt(_longestStreakKey) ?? 0,
      boostTokens: _prefs.getInt(_boostTokensKey) ?? 0,
      hasRemoveAds: _prefs.getBool(_hasRemoveAdsKey) ?? false,
      starterBundleClaimed:
          _prefs.getBool(_starterBundleClaimedKey) ?? false,
      guaranteedRevealTokens:
          _loadGuaranteedRevealTokens(_guaranteedRevealTokensKey),
      purchasedSkus:
          (_prefs.getStringList(_purchasedSkusKey) ?? const <String>[])
              .toSet(),
    );
  }

  /// Decode the guaranteedRevealTokens map. Stored as JSON with rarity
  /// tokens as keys ({"rare":1,"epic":0}). Unknown tokens are ignored
  /// so a bad save can't crash load.
  Map<Rarity, int> _loadGuaranteedRevealTokens(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return <Rarity, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final out = <Rarity, int>{};
        decoded.forEach((k, v) {
          final r = rarityFromToken(k as String?);
          if (v is num && v.toInt() > 0) out[r] = v.toInt();
        });
        return out;
      }
    } catch (_) {
      // fall through
    }
    return <Rarity, int>{};
  }

  /// Deserialize a {pack_id -> int} map stored as a JSON string.
  /// Silently returns {} for missing or malformed state so a corrupt
  /// pref can't brick load.
  Map<String, int> _loadIntMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final out = <String, int>{};
        decoded.forEach((k, v) {
          if (k is String && v is num) out[k] = v.toInt();
        });
        return out;
      }
    } catch (_) {
      // fall through to empty map
    }
    return <String, int>{};
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
    await _prefs.setStringList(
      _discoveredIdsKey,
      p.discoveredSmashableIds.toList(),
    );
    await _prefs.setString(_rarestSeenKey, p.rarestSeen.token);
    await _prefs.setString(
      _totalBurstsByPackKey,
      jsonEncode(p.totalBurstsByPack),
    );
    await _prefs.setString(_rareDryByPackKey, jsonEncode(p.rareDryByPack));
    await _prefs.setString(_epicDryByPackKey, jsonEncode(p.epicDryByPack));
    await _prefs.setString(
      _legendaryDryByPackKey,
      jsonEncode(p.legendaryDryByPack),
    );
    if (p.lastPlayDate != null) {
      await _prefs.setString(_lastPlayDateKey, p.lastPlayDate!);
    } else {
      await _prefs.remove(_lastPlayDateKey);
    }
    await _prefs.setInt(_currentStreakKey, p.currentStreak);
    await _prefs.setInt(_longestStreakKey, p.longestStreak);
    await _prefs.setInt(_boostTokensKey, p.boostTokens);
    await _prefs.setBool(_hasRemoveAdsKey, p.hasRemoveAds);
    await _prefs.setBool(_starterBundleClaimedKey, p.starterBundleClaimed);
    final tokenMap = <String, int>{
      for (final e in p.guaranteedRevealTokens.entries)
        if (e.value > 0) e.key.token: e.value,
    };
    await _prefs.setString(
      _guaranteedRevealTokensKey,
      jsonEncode(tokenMap),
    );
    await _prefs.setStringList(_purchasedSkusKey, p.purchasedSkus.toList());
  }

  bool get hapticsEnabled => _prefs.getBool(_hapticsKey) ?? true;
  Future<void> setHapticsEnabled(bool v) => _prefs.setBool(_hapticsKey, v);

  bool get muted => _prefs.getBool(_muteKey) ?? false;
  Future<void> setMuted(bool v) => _prefs.setBool(_muteKey, v);
}
