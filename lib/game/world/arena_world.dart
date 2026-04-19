import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class ArenaWorld extends World {
  ArenaWorld({Vector2? arenaSize})
      : arenaSize = arenaSize ?? Vector2(360, 640);

  final Vector2 arenaSize;

  Vector2 get arenaCenter => arenaSize / 2;

  @override
  Future<void> onLoad() async {
    final bg = RectangleComponent(
      size: arenaSize.clone(),
      paint: Paint()..color = const Color(0xFF24172C),
    )..position = Vector2.zero();
    await add(bg);
  }
}
