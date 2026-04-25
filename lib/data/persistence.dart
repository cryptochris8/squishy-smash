import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/player_profile.dart';
import 'models/rarity.dart';

/// Wrapper around `SharedPreferences` for [PlayerProfile] storage.
///
/// **v3 (current) — single-blob layout.** The entire profile is JSON-
/// encoded into one key (`_kProfileBlobKey`). A successful write of
/// that key is therefore atomic — the platform either commits the
/// whole blob or none of it. Compare with v1/v2, which spread the
/// profile across ~20 sequential `setX` calls; an app kill mid-write
/// could leave coins deducted but a pack still locked, etc.
///
/// **Reading older installs.** On first launch under v3 we transparently
/// migrate from the v1/v2 per-field keys: the old keys are read once,
/// folded into a [PlayerProfile], and re-saved as a v3 blob. The legacy
/// keys are left in place as a passive safety net (they don't hurt and
/// give us something to fall back on if a future bug corrupts the blob).
class Persistence {
  Persistence._(this._prefs);

  /// Debounce window for [scheduleSave]. Rapid-fire hot-path mutations
  /// (combo bursts, coin awards, discovery marks) coalesce into a
  /// single disk write after this quiet period.
  static const Duration saveDebounce = Duration(milliseconds: 400);

  Timer? _saveTimer;
  PlayerProfile? _pendingSave;

  /// Current on-disk schema version for the [PlayerProfile] blob.
  ///
  /// Version history:
  ///   v0 — pre-versioning, no version key on disk
  ///   v1 — added `profile.schema_version` key (no data shape change)
  ///   v2 — added card progress fields (cardBurstCounts, cardsPurchased,
  ///        claimedAchievements). Additive only.
  ///   v3 — single-blob format. Profile lives under one JSON key,
  ///        making each save effectively atomic.
  static const int currentProfileVersion = 3;

  /// The single key all v3+ profile state lives under. Storing the
  /// whole profile here means a save is one platform call and either
  /// fully lands or doesn't — no torn state.
  static const String _kProfileBlobKey = 'profile.blob_v3';

  /// Legacy schema-version pointer from v1/v2. Still read on migration
  /// so we know whether to expect the v2 per-field layout.
  static const String _kLegacyVersionKey = 'profile.schema_version';

  // -- Legacy per-field keys (v1/v2). Read-only after the v3 migration:
  // we never write these going forward. Left in place so a v2 fallback
  // path still has data if the blob is lost or corrupted.
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
  static const String _cardBurstCountsKey = 'profile.card_burst_counts';
  static const String _cardsPurchasedKey = 'profile.cards_purchased';
  static const String _claimedAchievementsKey =
      'profile.claimed_achievements';

  // -- Settings keys are NOT part of the player profile blob — they're
  // device-level preferences that survive profile migrations.
  static const String _hapticsKey = 'settings.haptics';
  static const String _muteKey = 'settings.mute';

  final SharedPreferences _prefs;

  static Future<Persistence> open() async {
    final prefs = await SharedPreferences.getInstance();
    return Persistence._(prefs);
  }

  /// Read the stored profile version. Source order:
  ///   1. v3 blob if present → reads `schemaVersion` field inside
  ///   2. legacy standalone `profile.schema_version` key (v1/v2)
  ///   3. 0 (pre-versioning / fresh install)
  int get profileVersion {
    final blob = _readBlobMap();
    if (blob != null) {
      final v = blob['schemaVersion'];
      if (v is num) return v.toInt();
    }
    return _prefs.getInt(_kLegacyVersionKey) ?? 0;
  }

  PlayerProfile loadProfile() {
    // v3+ path — the blob is the source of truth.
    final blob = _readBlobMap();
    if (blob != null) return _profileFromBlob(blob);
    // Fall back to legacy per-field load for v0/v1/v2 installs.
    return _loadLegacyProfile();
  }

  /// Atomic save: a single `setString` of the JSON-encoded profile.
  /// On both Android (XML commit) and iOS (NSUserDefaults), a single
  /// key write is platform-atomic — the whole blob lands or nothing
  /// does. Cancels any pending debounced write since we're committing
  /// the latest state right now.
  Future<void> saveProfile(PlayerProfile p) async {
    _saveTimer?.cancel();
    _saveTimer = null;
    _pendingSave = null;
    final blob = _profileToBlob(p);
    await _prefs.setString(_kProfileBlobKey, jsonEncode(blob));
  }

  /// Schedule a debounced profile save. Hot-path callers (per-burst
  /// mutations) use this so multiple rapid updates collapse into one
  /// disk write. A pending scheduled save is flushed automatically by
  /// any direct [saveProfile] call or by [flushPending].
  void scheduleSave(PlayerProfile p) {
    _pendingSave = p;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDebounce, () {
      final pending = _pendingSave;
      if (pending == null) return;
      _saveTimer = null;
      _pendingSave = null;
      saveProfile(pending);
    });
  }

  /// Force any pending scheduled save to flush now. No-op if nothing
  /// is pending. Await before reading from disk (e.g., re-opening a
  /// new [Persistence] instance in tests) to be sure the write has
  /// landed.
  Future<void> flushPending() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final pending = _pendingSave;
    _pendingSave = null;
    if (pending != null) {
      await saveProfile(pending);
    }
  }

  bool get hapticsEnabled => _prefs.getBool(_hapticsKey) ?? true;
  Future<void> setHapticsEnabled(bool v) => _prefs.setBool(_hapticsKey, v);

  bool get muted => _prefs.getBool(_muteKey) ?? false;
  Future<void> setMuted(bool v) => _prefs.setBool(_muteKey, v);

  // ---------------------------------------------------------------- v3 blob

  /// Read the v3 blob and decode to a Map. Returns null if no blob is
  /// present or if the JSON is malformed (treated as "not v3" — caller
  /// falls back to legacy load).
  Map<String, dynamic>? _readBlobMap() {
    final raw = _prefs.getString(_kProfileBlobKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // fall through to legacy load
    }
    return null;
  }

  Map<String, dynamic> _profileToBlob(PlayerProfile p) {
    return <String, dynamic>{
      'schemaVersion': currentProfileVersion,
      'coins': p.coins,
      'unlockedPackIds': p.unlockedPackIds.toList(),
      'bestScore': p.bestScore,
      'bestCombo': p.bestCombo,
      'sessionCount': p.sessionCount,
      'unlockedArenaKeys': p.unlockedArenaKeys.toList(),
      'activeArenaKey': p.activeArenaKey,
      'discoveredSmashableIds': p.discoveredSmashableIds.toList(),
      'rarestSeen': p.rarestSeen.token,
      'totalBurstsByPack': p.totalBurstsByPack,
      'rareDryByPack': p.rareDryByPack,
      'epicDryByPack': p.epicDryByPack,
      'legendaryDryByPack': p.legendaryDryByPack,
      'lastPlayDate': p.lastPlayDate,
      'currentStreak': p.currentStreak,
      'longestStreak': p.longestStreak,
      'boostTokens': p.boostTokens,
      'hasRemoveAds': p.hasRemoveAds,
      'starterBundleClaimed': p.starterBundleClaimed,
      // Drop zero-count entries so a deserialized + re-serialized
      // profile is bit-identical (matches the v1/v2 round-trip
      // contract that tests already pin).
      'guaranteedRevealTokens': <String, int>{
        for (final e in p.guaranteedRevealTokens.entries)
          if (e.value > 0) e.key.token: e.value,
      },
      'purchasedSkus': p.purchasedSkus.toList(),
      'cardBurstCounts': p.cardBurstCounts,
      'cardsPurchased': p.cardsPurchased.toList(),
      'claimedAchievements': p.claimedAchievements.toList(),
    };
  }

  PlayerProfile _profileFromBlob(Map<String, dynamic> blob) {
    return PlayerProfile(
      coins: (blob['coins'] as num?)?.toInt() ?? 0,
      unlockedPackIds: _strSet(blob['unlockedPackIds']) ??
          <String>{'launch_squishy_foods'},
      bestScore: (blob['bestScore'] as num?)?.toInt() ?? 0,
      bestCombo: (blob['bestCombo'] as num?)?.toInt() ?? 0,
      sessionCount: (blob['sessionCount'] as num?)?.toInt() ?? 0,
      unlockedArenaKeys: _strSet(blob['unlockedArenaKeys']) ??
          <String>{'mochi_sunset_beach'},
      activeArenaKey:
          (blob['activeArenaKey'] as String?) ?? 'mochi_sunset_beach',
      discoveredSmashableIds:
          _strSet(blob['discoveredSmashableIds']) ?? <String>{},
      rarestSeen: rarityFromToken(blob['rarestSeen'] as String?),
      totalBurstsByPack: _intMap(blob['totalBurstsByPack']),
      rareDryByPack: _intMap(blob['rareDryByPack']),
      epicDryByPack: _intMap(blob['epicDryByPack']),
      legendaryDryByPack: _intMap(blob['legendaryDryByPack']),
      lastPlayDate: blob['lastPlayDate'] as String?,
      currentStreak: (blob['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (blob['longestStreak'] as num?)?.toInt() ?? 0,
      boostTokens: (blob['boostTokens'] as num?)?.toInt() ?? 0,
      hasRemoveAds: (blob['hasRemoveAds'] as bool?) ?? false,
      starterBundleClaimed:
          (blob['starterBundleClaimed'] as bool?) ?? false,
      guaranteedRevealTokens:
          _rarityIntMap(blob['guaranteedRevealTokens']),
      purchasedSkus: _strSet(blob['purchasedSkus']) ?? <String>{},
      cardBurstCounts: _intMap(blob['cardBurstCounts']),
      cardsPurchased: _strSet(blob['cardsPurchased']) ?? <String>{},
      claimedAchievements:
          _strSet(blob['claimedAchievements']) ?? <String>{},
    );
  }

  /// Helper: coerce a JSON list of strings to a `Set<String>`. Returns
  /// null if the input is missing/invalid so the caller can fall back
  /// to a sensible default.
  Set<String>? _strSet(dynamic raw) {
    if (raw is List) {
      return raw.whereType<String>().toSet();
    }
    return null;
  }

  Map<String, int> _intMap(dynamic raw) {
    if (raw is Map) {
      final out = <String, int>{};
      raw.forEach((k, v) {
        if (k is String && v is num) out[k] = v.toInt();
      });
      return out;
    }
    return <String, int>{};
  }

  Map<Rarity, int> _rarityIntMap(dynamic raw) {
    if (raw is Map) {
      final out = <Rarity, int>{};
      raw.forEach((k, v) {
        final r = rarityFromToken(k as String?);
        if (v is num && v.toInt() > 0) out[r] = v.toInt();
      });
      return out;
    }
    return <Rarity, int>{};
  }

  // ------------------------------------------------------ legacy (v0-v2)

  /// Reconstruct a [PlayerProfile] from the legacy per-field keys.
  /// Used only on first launch under v3+ when the blob hasn't been
  /// written yet — the caller's first `saveProfile` will then write
  /// out the v3 blob and subsequent loads take the fast path.
  PlayerProfile _loadLegacyProfile() {
    final unlocks =
        _prefs.getStringList(_unlocksKey) ?? <String>['launch_squishy_foods'];
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
      totalBurstsByPack: _loadLegacyIntMap(_totalBurstsByPackKey),
      rareDryByPack: _loadLegacyIntMap(_rareDryByPackKey),
      epicDryByPack: _loadLegacyIntMap(_epicDryByPackKey),
      legendaryDryByPack: _loadLegacyIntMap(_legendaryDryByPackKey),
      lastPlayDate: _prefs.getString(_lastPlayDateKey),
      currentStreak: _prefs.getInt(_currentStreakKey) ?? 0,
      longestStreak: _prefs.getInt(_longestStreakKey) ?? 0,
      boostTokens: _prefs.getInt(_boostTokensKey) ?? 0,
      hasRemoveAds: _prefs.getBool(_hasRemoveAdsKey) ?? false,
      starterBundleClaimed:
          _prefs.getBool(_starterBundleClaimedKey) ?? false,
      guaranteedRevealTokens:
          _loadLegacyGuaranteedRevealTokens(_guaranteedRevealTokensKey),
      purchasedSkus:
          (_prefs.getStringList(_purchasedSkusKey) ?? const <String>[])
              .toSet(),
      cardBurstCounts: _loadLegacyIntMap(_cardBurstCountsKey),
      cardsPurchased:
          (_prefs.getStringList(_cardsPurchasedKey) ?? const <String>[])
              .toSet(),
      claimedAchievements:
          (_prefs.getStringList(_claimedAchievementsKey) ?? const <String>[])
              .toSet(),
    );
  }

  Map<Rarity, int> _loadLegacyGuaranteedRevealTokens(String key) {
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

  Map<String, int> _loadLegacyIntMap(String key) {
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
}
