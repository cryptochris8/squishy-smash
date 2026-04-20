import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../core/service_locator.dart';
import '../data/models/smashable_def.dart';
import 'components/decal_manager.dart';
import 'components/particle_manager.dart';
import 'components/screen_shake.dart';
import 'components/smashable_component.dart';
import 'systems/combo_controller.dart';
import 'systems/haptics_manager.dart';
import 'systems/score_controller.dart';
import 'systems/spawn_manager.dart';
import 'world/arena_world.dart';

class SquishyGame extends FlameGame {
  SquishyGame({this.onRoundEnd});

  final void Function(int score, int combo, int coinsEarned)? onRoundEnd;

  late final ArenaWorld arena;
  late final ScoreController score;
  late final ComboController combo;
  late final ParticleManager particles;
  late final DecalManager decals;
  late final HapticsManager haptics;
  late final SpawnManager spawner;
  late final ScreenShake shaker;

  final Random _rng = Random();
  double _roundTimer = 60;
  int _coinsEarned = 0;
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

    particles = ParticleManager();
    decals = DecalManager();
    await arena.add(decals);
    await arena.add(particles);

    score = ScoreController();
    combo = ComboController();
    haptics = HapticsManager(enabled: ServiceLocator.persistence.hapticsEnabled);
    shaker = ScreenShake(camera: camera);
    await add(shaker);

    final pool = ServiceLocator.packs.objectsForPacks(
      ServiceLocator.progression.profile.unlockedPackIds,
    );
    spawner = SpawnManager(pool: pool, rng: _rng, onSpawn: _spawnNext);
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
    ServiceLocator.sounds.playRandom(c.def.impactSounds);
    haptics.light();
  }

  void _handleBurst(SmashableComponent c) {
    final bonus = 25 + (c.def.gooLevel * 30).round();
    score.addBurst(bonus, multiplier: combo.multiplier);
    _coinsEarned += c.def.coinReward;
    ServiceLocator.progression.awardCoins(c.def.coinReward);

    ServiceLocator.sounds.play(c.def.burstSound);
    haptics.heavy();
    shaker.shake();
    particles.burst(c.position, preset: c.def.particlePreset, intensity: c.def.gooLevel);
    decals.spawn(c.position, preset: c.def.decalPreset);

    c.removeFromParent();
    spawner.requestSpawn(0.4);
  }

  Future<void> _endRound() async {
    _ended = true;
    await ServiceLocator.progression.recordRound(
      score: score.total,
      combo: combo.peak,
    );
    onRoundEnd?.call(score.total, combo.peak, _coinsEarned);
  }
}
