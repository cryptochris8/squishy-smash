import 'dart:math';

import 'package:flame/components.dart';

import '../../data/models/rarity.dart';
import '../../data/models/smashable_def.dart';

class SpawnManager extends Component {
  SpawnManager({required this.pool, required this.rng, required this.onSpawn});

  final List<SmashableDef> pool;
  final Random rng;
  final void Function(SmashableDef def) onSpawn;
  double _delay = 0;
  bool _pending = false;

  void requestSpawn(double delaySeconds) {
    _delay = delaySeconds;
    _pending = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_pending) return;
    _delay -= dt;
    if (_delay <= 0) {
      _pending = false;
      if (pool.isEmpty) return;
      final def = weightedPick<SmashableDef>(
        items: pool,
        weightOf: (d) => d.effectiveDropWeight,
        rng: rng,
      );
      onSpawn(def);
    }
  }
}
