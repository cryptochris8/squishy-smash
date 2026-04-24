import '../core/analytics_stub.dart';
import '../data/models/rarity.dart';

/// Typed wrappers over the [Analytics] transport. Firebase-recommended
/// event names are used verbatim where they exist so the Firebase gaming
/// dashboards light up without custom dashboards — see
/// https://firebase.google.com/docs/analytics/events
///
/// This class is stateless; the [Analytics] sink it wraps is the one
/// registered at [ServiceLocator.analytics]. Swap the sink (NoOp ↔
/// Firebase) without touching callsites.
class GameEvents {
  GameEvents(this._sink);

  final Analytics _sink;

  // -- session lifecycle ----------------------------------------------
  // Firebase auto-logs session_start / first_open — don't re-log them.

  void tutorialBegin() => _sink.event('tutorial_begin');

  void tutorialComplete() => _sink.event('tutorial_complete');

  // -- core loop ------------------------------------------------------

  void levelStart({required String packId, required int sessionIndex}) {
    _sink.event('level_start', <String, Object?>{
      'pack_id': packId,
      'session_index': sessionIndex,
    });
  }

  void levelEnd({
    required String packId,
    required int smashes,
    required int durationMs,
    required bool success,
  }) {
    _sink.event('level_end', <String, Object?>{
      'pack_id': packId,
      'smashes': smashes,
      'duration_ms': durationMs,
      'success': success,
    });
  }

  void objectSmashed({
    required String objectId,
    required String packId,
    required int comboCount,
    required Rarity rarity,
  }) {
    _sink.event('object_smashed', <String, Object?>{
      'object_id': objectId,
      'pack_id': packId,
      'combo_count': comboCount,
      'rarity': rarity.token,
    });
  }

  void megaBurstTriggered({required int comboCount, required String packId}) {
    _sink.event('mega_burst_triggered', <String, Object?>{
      'combo_count': comboCount,
      'pack_id': packId,
    });
  }

  /// Fires the first time the player bursts a given smashable ID.
  /// [discoveredCount] is the total collection size after this pick so
  /// we can graph collection progress without a server-side join.
  void collectionDiscovery({
    required String objectId,
    required String packId,
    required Rarity rarity,
    required int discoveredCount,
  }) {
    _sink.event('collection_discovery', <String, Object?>{
      'object_id': objectId,
      'pack_id': packId,
      'rarity': rarity.token,
      'discovered_count': discoveredCount,
    });
  }

  /// Fires on every burst of an already-discovered object. Lets the
  /// dashboard measure duplicate frustration vs. reward feel.
  void duplicateAwarded({
    required String objectId,
    required String packId,
    required Rarity rarity,
    required int coinsAwarded,
  }) {
    _sink.event('duplicate_awarded', <String, Object?>{
      'object_id': objectId,
      'pack_id': packId,
      'rarity': rarity.token,
      'coins_awarded': coinsAwarded,
    });
  }

  /// Fires when the hard-pity floor forces a tier for the next pick
  /// (before that pick is resolved). Helps tune how often pity rescues
  /// fire vs. natural drops.
  void pityTriggered({
    required String packId,
    required Rarity forcedTier,
    required int bursts,
  }) {
    _sink.event('pity_triggered', <String, Object?>{
      'pack_id': packId,
      'forced_tier': forcedTier.token,
      'bursts_in_pack': bursts,
    });
  }

  /// Fires the very first time the player bursts an epic in a pack.
  /// Marks a major retention milestone.
  void firstEpicFound({required String packId, required String objectId}) {
    _sink.event('first_epic_found', <String, Object?>{
      'pack_id': packId,
      'object_id': objectId,
    });
  }

  /// Fires the very first time the player bursts a legendary in a pack.
  void firstLegendaryFound(
      {required String packId, required String objectId}) {
    _sink.event('first_legendary_found', <String, Object?>{
      'pack_id': packId,
      'object_id': objectId,
    });
  }

  /// Fires after each successful burst to report current collection
  /// progress in a pack — [discovered]/[total] counts of the pack's
  /// objects the player has bursted at least once.
  void packProgressUpdated({
    required String packId,
    required int discovered,
    required int total,
  }) {
    _sink.event('pack_progress_updated', <String, Object?>{
      'pack_id': packId,
      'discovered': discovered,
      'total': total,
    });
  }

  /// Fires when a one-shot boost token is granted (session streak,
  /// rewarded ad, or duplicate legendary).
  void boostGranted(
      {required String source, required int tokensAfter}) {
    _sink.event('boost_granted', <String, Object?>{
      'source': source,
      'tokens_after': tokensAfter,
    });
  }

  /// Fires when a boost token is consumed on the next pick.
  void boostUsed({required String packId}) {
    _sink.event('boost_used', <String, Object?>{'pack_id': packId});
  }

  // -- live-ops -------------------------------------------------------

  void packViewed({required String packId, required String source}) {
    _sink.event('pack_viewed', <String, Object?>{
      'pack_id': packId,
      'source': source,
    });
  }

  void packActivated({required String packId, required String source}) {
    _sink.event('pack_activated', <String, Object?>{
      'pack_id': packId,
      'source': source,
    });
  }

  void packCompleted({required String packId, required int durationMs}) {
    _sink.event('pack_completed', <String, Object?>{
      'pack_id': packId,
      'duration_ms': durationMs,
    });
  }

  // -- monetization ---------------------------------------------------
  // Firebase auto-logs ad_impression and in_app_purchase via AdMob +
  // StoreKit integrations; these are the custom wrappers.

  void adRewardEarned({
    required String placement,
    required String rewardType,
    required int amount,
  }) {
    _sink.event('ad_reward_earned', <String, Object?>{
      'placement': placement,
      'reward_type': rewardType,
      'amount': amount,
    });
  }

  void earnVirtualCurrency({
    required String currencyName,
    required int value,
    required String source,
  }) {
    // Uses Firebase recommended name: earn_virtual_currency
    _sink.event('earn_virtual_currency', <String, Object?>{
      'virtual_currency_name': currencyName,
      'value': value,
      'source': source,
    });
  }

  void spendVirtualCurrency({
    required String currencyName,
    required int value,
    required String itemName,
  }) {
    _sink.event('spend_virtual_currency', <String, Object?>{
      'virtual_currency_name': currencyName,
      'value': value,
      'item_name': itemName,
    });
  }

  // -- retention / share ----------------------------------------------

  void shareClip({
    required String objectId,
    required String destination,
    required Rarity rarity,
  }) {
    _sink.event('share_clip', <String, Object?>{
      'object_id': objectId,
      'destination': destination,
      'rarity': rarity.token,
    });
  }

  void settingsChanged({required String setting, required Object value}) {
    _sink.event('settings_changed', <String, Object?>{
      'setting': setting,
      'value': value,
    });
  }

  // -- error ----------------------------------------------------------

  void assetLoadFailed({required String assetPath, required String error}) {
    _sink.event('asset_load_failed', <String, Object?>{
      'asset_path': assetPath,
      'error': error,
    });
  }
}
