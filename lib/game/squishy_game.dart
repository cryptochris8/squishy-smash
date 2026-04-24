import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../analytics/events.dart';
import '../core/service_locator.dart';
import '../data/models/rarity.dart';
import '../data/models/smashable_def.dart';
import 'components/decal_manager.dart';
import 'components/particle_manager.dart';
import 'components/screen_shake.dart';
import 'components/skybox_component.dart';
import 'components/smashable_component.dart';
import 'systems/arena_registry.dart';
import 'systems/combo_controller.dart';
import 'systems/feedback_dispatcher.dart';
import 'systems/flame_feedback_sink.dart';
import 'systems/haptics_manager.dart';
import 'systems/pack_progression_gate.dart';
import 'systems/rarity_pity_selector.dart';
import 'systems/score_controller.dart';
import 'systems/spawn_manager.dart';
import 'systems/voice_line_registry.dart';
import 'world/arena_world.dart';

class SquishyGame extends FlameGame {
  SquishyGame({this.onRoundEnd, this.onMythicReveal});

  final void Function(int score, int combo, int coinsEarned)? onRoundEnd;

  /// Fires immediately after a mythic burst resolves, so the surrounding
  /// Flutter UI can show a "Save this clip?" prompt. Always called on
  /// the Flame tick; callers must use `WidgetsBinding.addPostFrameCallback`
  /// or similar if touching the widget tree.
  final VoidCallback? onMythicReveal;

  late final ArenaWorld arena;
  late final ScoreController score;
  late final ComboController combo;
  late final ParticleManager particles;
  late final DecalManager decals;
  late final HapticsManager haptics;
  late final SpawnManager spawner;
  late final ScreenShake shaker;
  late final SkyboxComponent skybox;
  late final GameEvents events;
  late final FeedbackDispatcher feedback;
  late final RarityPitySelector pitySelector;
  late final PackProgressionGate packGate;
  late final List<GatedObject> _pool;
  final Map<String, String> _defIdToPackId = <String, String>{};

  final Random _rng = Random();
  double _roundTimer = 60;
  int _coinsEarned = 0;
  int _smashes = 0;
  String? _activePackId;
  bool _ended = false;

  /// True for the single next spawn if a boost token is available at
  /// round start. Consumed on the first pick; subsequent picks in the
  /// same round use normal weighting. Keeps token burn predictable:
  /// one token per round until the player runs out.
  bool _useBoostOnNextSpawn = false;

  @override
  Color backgroundColor() => const Color(0xFF1A1320);

  @override
  Future<void> onLoad() async {
    arena = ArenaWorld();
    await add(arena);
    camera.world = arena;
    camera.viewport = FixedResolutionViewport(resolution: arena.arenaSize);
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();

    // Arena theme is player-controlled via the Settings screen — pulled
    // from PlayerProfile.activeArenaKey rather than the featured pack.
    // ArenaRegistry.byKey falls back to mochi_sunset_beach for unknown
    // keys so the game keeps rendering even if a save references an
    // arena that's been removed from the registry.
    final arenaTheme = ArenaRegistry.byKey(
      ServiceLocator.progression.profile.activeArenaKey,
    );

    // Create events early so SkyboxComponent can report load failures to
    // analytics during its own onLoad. Reused for the rest of the round.
    events = GameEvents(ServiceLocator.analytics);

    skybox = SkyboxComponent(
      size: arena.arenaSize.clone(),
      theme: arenaTheme,
      events: events,
    );
    await arena.add(skybox);

    particles = ParticleManager();
    decals = DecalManager();
    await arena.add(decals);
    await arena.add(particles);

    score = ScoreController();
    combo = ComboController();
    haptics = HapticsManager(enabled: ServiceLocator.persistence.hapticsEnabled);
    shaker = ScreenShake(camera: camera);
    await add(shaker);

    feedback = FeedbackDispatcher(
      sink: FlameFeedbackSink(
        sounds: ServiceLocator.sounds,
        haptics: haptics,
        shaker: shaker,
      ),
    )..voiceLines.addAll(VoiceLineRegistry.dispatcherMap);

    final featured = ServiceLocator.packs.schedule.currentWeek(DateTime.now());
    _activePackId = featured?.featuredPack ??
        (ServiceLocator.progression.profile.unlockedPackIds.isNotEmpty
            ? ServiceLocator.progression.profile.unlockedPackIds.first
            : null);
    final sessionResult =
        await ServiceLocator.progression.noteSessionStart();
    if (sessionResult.boostTokenAwarded) {
      events.boostGranted(
        source: 'session_streak_${sessionResult.milestone}',
        tokensAfter: ServiceLocator.progression.profile.boostTokens,
      );
    }
    // If the player has any tokens in the bank, arm the first spawn
    // to consume one. This keeps token usage predictable (one per
    // round) rather than silently burning all of them on consecutive
    // picks.
    if (ServiceLocator.progression.profile.boostTokens > 0) {
      _useBoostOnNextSpawn = true;
    }
    if (_activePackId != null) {
      events.levelStart(
        packId: _activePackId!,
        sessionIndex: ServiceLocator.progression.profile.sessionCount,
      );
    }

    final poolWithContext = ServiceLocator.packs.objectsForPacksWithContext(
      ServiceLocator.progression.profile.unlockedPackIds,
    );
    _pool = [
      for (final (pack, def) in poolWithContext)
        GatedObject(def: def, pack: pack),
    ];
    for (final entry in _pool) {
      // Duplicate IDs across packs resolve to first-wins — matches
      // PackRepository.objectsForPacksWithContext ordering.
      _defIdToPackId.putIfAbsent(entry.def.id, () => entry.packId);
    }
    pitySelector = const RarityPitySelector();
    packGate = const PackProgressionGate();
    spawner = SpawnManager(
      selectNext: _selectNextSmashable,
      onSpawn: _spawnNext,
    );
    await add(spawner);
    spawner.requestSpawn(0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_ended) return;
    combo.tick(dt);
    _roundTimer -= dt;
    if (_roundTimer <= 0) _endRound();
  }

  SmashableDef? _selectNextSmashable() {
    if (_pool.isEmpty) return null;
    final profile = ServiceLocator.progression.profile;
    final gated = packGate.filterPool(
      objectsByPack: _pool,
      totalBurstsByPack: profile.totalBurstsByPack,
    );
    // If gating produced an empty pool (pathological — every pack is
    // fully locked), fall back to the ungated pool so the game keeps
    // spawning. Should only happen if a pack author mis-configures
    // thresholds for a pack with no commons.
    final effectivePool = gated.isEmpty ? _pool : gated;
    final boost = _useBoostOnNextSpawn;
    if (boost) {
      _useBoostOnNextSpawn = false;
      // Fire-and-forget — consuming the token is a persistence write.
      // If the player quits mid-round they don't double-spend on
      // relaunch.
      ServiceLocator.progression.consumeBoostToken();
      if (_activePackId != null) {
        events.boostUsed(packId: _activePackId!);
      }
    }
    return pitySelector.pick(
      pool: effectivePool,
      rareDryByPack: profile.rareDryByPack,
      epicDryByPack: profile.epicDryByPack,
      legendaryDryByPack: profile.legendaryDryByPack,
      comboMultiplier: combo.multiplier,
      boostActive: boost,
      rng: _rng,
    );
  }

  void _spawnNext(SmashableDef def) {
    final size = arena.arenaSize;
    final pos = Vector2(size.x * 0.5, size.y * 0.55);
    final smashable = SmashableComponent(
      def: def,
      onImpact: _handleImpact,
      onBurst: _handleBurst,
    )..position = pos;
    arena.add(smashable);
  }

  void _handleImpact(SmashableComponent c, double force) {
    combo.bump();
    final base = (5 * force).round();
    score.addHit(base, multiplier: combo.multiplier);
    feedback.dispatch(FeedbackTier.hit, c.def);
  }

  void _handleBurst(SmashableComponent c) {
    final bonus = 25 + (c.def.gooLevel * 30).round();
    score.addBurst(bonus, multiplier: combo.multiplier);
    _coinsEarned += c.def.coinReward;
    _smashes += 1;
    ServiceLocator.progression.awardCoins(c.def.coinReward);

    // Collection tracking: first-burst check is against the in-memory
    // profile so we can fire the analytics event synchronously. The
    // repo persists asynchronously.
    final profile = ServiceLocator.progression.profile;
    final owningPackId = _defIdToPackId[c.def.id] ?? _activePackId;
    final isFirstBurst = !profile.discoveredSmashableIds.contains(c.def.id);
    if (isFirstBurst) {
      ServiceLocator.progression.markDiscovered(
        smashableId: c.def.id,
        rarity: c.def.rarity,
      );
      if (owningPackId != null) {
        events.collectionDiscovery(
          objectId: c.def.id,
          packId: owningPackId,
          rarity: c.def.rarity,
          discoveredCount: profile.discoveredSmashableIds.length,
        );
        if (c.def.rarity == Rarity.epic) {
          events.firstEpicFound(
              packId: owningPackId, objectId: c.def.id);
        } else if (c.def.rarity == Rarity.mythic) {
          events.firstLegendaryFound(
              packId: owningPackId, objectId: c.def.id);
        }
      }
    } else {
      // Duplicate — award scaled coin bonus and fire analytics so we
      // can dashboard duplicate frustration vs. reward feel.
      final bonus = c.def.rarity.duplicateCoinBonus;
      _coinsEarned += bonus;
      ServiceLocator.progression.awardCoins(bonus);
      if (owningPackId != null) {
        events.duplicateAwarded(
          objectId: c.def.id,
          packId: owningPackId,
          rarity: c.def.rarity,
          coinsAwarded: bonus,
        );
      }
    }

    // Pack-progress update — fires on every burst so dashboards can
    // plot collection completion over time per pack.
    if (owningPackId != null) {
      final owningPack = ServiceLocator.packs.byId(owningPackId);
      if (owningPack != null) {
        final discoveredInPack = owningPack.objects
            .where((o) => profile.discoveredSmashableIds.contains(o.id))
            .length;
        events.packProgressUpdated(
          packId: owningPackId,
          discovered: discoveredInPack,
          total: owningPack.objects.length,
        );
      }
    }

    // Per-pack burst tracking drives unlock gates + pity dry streaks.
    // Every burst — even commons — counts toward totalBurstsByPack
    // (unlock gates) and advances / resets the tier dry counters.
    if (owningPackId != null) {
      ServiceLocator.progression.noteBurstForPack(
        packId: owningPackId,
        rarity: c.def.rarity,
      );
    }

    // Pick a feedback tier. Rarity wins over combo (a mythic at combo 1
    // should still reveal); common-tier bursts upgrade to megaBurst once
    // the combo multiplier hits 3+.
    final rarity = c.def.rarity;
    final FeedbackTier tier;
    if (rarity.triggersReveal) {
      tier = FeedbackTier.revealBurst;
    } else if (combo.multiplier >= 3) {
      tier = FeedbackTier.megaBurst;
    } else {
      tier = FeedbackTier.burst;
    }
    feedback.dispatch(tier, c.def);

    // Mythic gets an extra-heavy shake override on top of the dispatcher
    // default; rarity also swaps the skybox to its reveal variant.
    if (rarity.triggersReveal) {
      skybox.triggerReveal(hold: rarity == Rarity.mythic ? 1.6 : 1.0);
      if (rarity == Rarity.mythic) {
        shaker.shake(duration: 0.28, intensity: 14);
        onMythicReveal?.call();
      }
    }

    particles.burst(c.position, preset: c.def.particlePreset, intensity: c.def.gooLevel);
    decals.spawn(c.position, preset: c.def.decalPreset);

    if (_activePackId != null) {
      events.objectSmashed(
        objectId: c.def.id,
        packId: _activePackId!,
        comboCount: combo.multiplier,
        rarity: rarity,
      );
      if (tier == FeedbackTier.megaBurst) {
        events.megaBurstTriggered(
          comboCount: combo.multiplier,
          packId: _activePackId!,
        );
      }
    }

    c.removeFromParent();
    spawner.requestSpawn(0.4);
  }

  Future<void> _endRound() async {
    _ended = true;
    await ServiceLocator.progression.recordRound(
      score: score.total,
      combo: combo.peak,
    );
    if (_activePackId != null) {
      events.levelEnd(
        packId: _activePackId!,
        smashes: _smashes,
        durationMs: 60000,
        success: _smashes > 0,
      );
    }
    onRoundEnd?.call(score.total, combo.peak, _coinsEarned);
  }
}
