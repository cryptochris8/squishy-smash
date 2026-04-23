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
  late final List<SmashableDef> _pool;

  final Random _rng = Random();
  double _roundTimer = 60;
  int _coinsEarned = 0;
  int _smashes = 0;
  String? _activePackId;
  bool _ended = false;

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
    await ServiceLocator.progression.noteSessionStart();
    if (_activePackId != null) {
      events.levelStart(
        packId: _activePackId!,
        sessionIndex: ServiceLocator.progression.profile.sessionCount,
      );
    }

    _pool = ServiceLocator.packs.objectsForPacks(
      ServiceLocator.progression.profile.unlockedPackIds,
    );
    pitySelector = const RarityPitySelector();
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
    final def = pitySelector.pick(
      pool: _pool,
      rollsSinceRare: profile.rollsSinceRare,
      rollsSinceEpic: profile.rollsSinceEpic,
      rollsSinceMythic: profile.rollsSinceMythic,
      comboMultiplier: combo.multiplier,
      rng: _rng,
    );
    final (nextRare, nextEpic, nextMythic) = pitySelector.advanceCounters(
      pickedRarity: def.rarity,
      rollsSinceRare: profile.rollsSinceRare,
      rollsSinceEpic: profile.rollsSinceEpic,
      rollsSinceMythic: profile.rollsSinceMythic,
    );
    // Fire-and-forget persistence — pity counters don't need to block
    // the Flame tick. Worst case on a crash: a handful of rolls get
    // replayed next session, which is fine.
    ServiceLocator.progression.noteSpawnRoll(
      rollsSinceRare: nextRare,
      rollsSinceEpic: nextEpic,
      rollsSinceMythic: nextMythic,
    );
    return def;
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
    final isFirstBurst = !profile.discoveredSmashableIds.contains(c.def.id);
    if (isFirstBurst) {
      ServiceLocator.progression.markDiscovered(
        smashableId: c.def.id,
        rarity: c.def.rarity,
      );
      if (_activePackId != null) {
        events.collectionDiscovery(
          objectId: c.def.id,
          packId: _activePackId!,
          rarity: c.def.rarity,
          discoveredCount: profile.discoveredSmashableIds.length + 1,
        );
      }
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
