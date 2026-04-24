import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/player_profile.dart';
import 'models/rarity.dart';

class Persistence {
  Persistence._(this._prefs);

  /// Debounce window for [scheduleSave]. Rapid-fire hot-path mutations
  /// (combo bursts, coin awards, discovery marks) coalesce into a
  /// single disk write after this quiet period, instead of producing
  /// one full-profile write per event.
  static const Duration saveDebounce = Duration(milliseconds: 400);

  Timer? _saveTimer;
  PlayerProfile? _pendingSave;

  /// Current on-disk schema version for the PlayerProfile blob.
  /// Bump this when any stored field is renamed, removed, or changes
  /// type. Add a branch in `_migrateIfNeeded` for each old version so
  /// existing installs upgrade cleanly. v0 = pre-versioning (no
  /// migration needed to reach v1; v1 simply records the version
  /// going forward).
  static const int currentProfileVersion = 1;

  static const String _profileVersionKey = 'profile.schema_version';
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
    _migrateIfNeeded();
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

  /// Read the stored profile version. 0 means "no version key yet"
  /// (either first launch or pre-versioning save). Saves always write
  /// [currentProfileVersion], so a 0 read only happens once per install.
  int get profileVersion => _prefs.getInt(_profileVersionKey) ?? 0;

  /// Apply any version→version migrations needed to bring an on-disk
  /// profile up to [currentProfileVersion]. Today there is only one
  /// step (0→1, which is a no-op — v1 just adds the version key).
  /// Future schema changes add branches here.
  void _migrateIfNeeded() {
    final loaded = profileVersion;
    if (loaded == currentProfileVersion) return;
    if (loaded > currentProfileVersion) {
      // Newer profile on an older app build. Don't rewrite the key;
      // attempt to load what we can and let the app run.
      return;
    }
    // loaded < currentProfileVersion. No data transformations needed
    // for 0→1; the current save path writes the v1 key on the next
    // save, which upgrades the install silently.
  }

  /// Schedule a debounced profile save. Callers on the hot path (per-
  /// burst mutations) use this instead of [saveProfile] so multiple
  /// rapid updates collapse into one disk write. A pending scheduled
  /// save is flushed automatically by any direct [saveProfile] call
  /// (so discrete user actions like purchases still write immediately)
  /// or by [flushPending] at explicit checkpoints (round end, app
  /// background).
  void scheduleSave(PlayerProfile p) {
    _pendingSave = p;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDebounce, () {
      // Fire-and-forget — we're on a timer callback, no async context
      // to propagate errors to. Any write failure surfaces via the
      // underlying SharedPreferences logging.
      final pending = _pendingSave;
      if (pending == null) return;
      _saveTimer = null;
      _pendingSave = null;
      saveProfile(pending);
    });
  }

  /// Flush any pending scheduled save immediately. Safe to call when
  /// nothing is pending — it's a no-op in that case. Await the returned
  /// future before reading from disk (e.g., opening a second
  /// [Persistence] instance in tests) to be sure the write has landed.
  Future<void> flushPending() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final pending = _pendingSave;
    _pendingSave = null;
    if (pending != null) {
      await saveProfile(pending);
    }
  }

  Future<void> saveProfile(PlayerProfile p) async {
    // Immediate write — cancel any pending debounce since we're about
    // to write the latest profile state anyway. Keeps the disk in
    // sync without a trailing redundant write from the timer.
    _saveTimer?.cancel();
    _saveTimer = null;
    _pendingSave = null;
    await _prefs.setInt(_profileVersionKey, currentProfileVersion);
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
