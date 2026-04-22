import 'package:flame/components.dart';

class ArenaWorld extends World {
  ArenaWorld({Vector2? arenaSize})
      : arenaSize = arenaSize ?? Vector2(360, 640);

  final Vector2 arenaSize;

  Vector2 get arenaCenter => arenaSize / 2;

  // Background is now supplied by [SkyboxComponent], which is added by
  // SquishyGame.onLoad() as the first child of this world so it renders
  // behind decals, particles, and smashables.
}
