import 'package:flame/components.dart';

import '../../data/models/smashable_def.dart';

class SpawnManager extends Component {
  SpawnManager({required this.selectNext, required this.onSpawn});

  /// Chooses which smashable to spawn next. Caller owns pity counters
  /// and combo state — see [RarityPitySelector] in
  /// `rarity_pity_selector.dart` for the selection policy.
  final SmashableDef? Function() selectNext;
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
      final def = selectNext();
      if (def == null) return;
      onSpawn(def);
    }
  }
}
