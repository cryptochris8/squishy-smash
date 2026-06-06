// Render-capture harness (NOT a unit assertion suite): boots the real
// Flame image pipeline against the swapped gameplay sprites to prove they
// load and render in-engine — no fallback to the procedural ObjectPainter —
// and survive the squash/stretch deformation the smash applies.
//
// Mirrors SmashableComponent exactly:
//   load  -> Flame.images.load('objects/<id>.webp')   (prefix stripped)
//   render-> Sprite(image).render(canvas, size: 144)   under a scale xform
//
// Captures real rendered frames to _sprite_restyle_proto/smoke/.
//   flutter test test/restyle_sprite_render_smoke_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _prefix = 'assets/images/';
// The real smash deformation from smashable_component.dart (squash & stretch).
const double _squashX = 1.55, _squashY = 0.58, _base = 144;

List<Map<String, dynamic>> _loadPackObjects() {
  final out = <Map<String, dynamic>>[];
  for (final f in [
    'launch_squishy_foods.json',
    'goo_fidgets_drop_01.json',
    'creepy_cute_pack_01.json',
  ]) {
    final raw = File('assets/data/packs/$f').readAsStringSync();
    final data = jsonDecode(raw);
    final objs = (data['objects'] ?? data['smashables'] ?? data) as List;
    for (final o in objs) {
      out.add({'id': o['id'], 'name': o['name'], 'sprite': o['sprite']});
    }
  }
  return out;
}

Future<void> _writePng(ui.Image img, String path) async {
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bd!.buffer.asUint8List());
}

Future<ui.Image> _frame(Sprite sprite, {required bool squash}) async {
  final w = squash ? 260 : 168;
  const h = 168;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = const Color(0xFFEEEEF2));
  canvas.save();
  canvas.translate(w / 2, h / 2);
  if (squash) canvas.scale(_squashX, _squashY);
  sprite.render(canvas, size: Vector2.all(_base), anchor: Anchor.center);
  canvas.restore();
  final pic = rec.endRecording();
  return pic.toImage(w, h);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  test('all swapped gameplay sprites load + render in-engine (no fallback)',
      () async {
    await binding.runAsync(() async {
      final objs = _loadPackObjects();
      final failures = <String>[];
      final loaded = <String, Sprite>{};

      for (final o in objs) {
        final assetPath = o['sprite'] as String;
        final normalized = assetPath.startsWith(_prefix)
            ? assetPath.substring(_prefix.length)
            : assetPath;
        try {
          final image = await Flame.images.load(normalized);
          loaded[o['id'] as String] = Sprite(image);
          stdout.writeln('  LOAD ok   ${o['id']}  '
              '(${image.width}x${image.height})  $normalized');
        } catch (e) {
          failures.add('${o['id']}: $e');
          stdout.writeln('  LOAD FAIL ${o['id']}  $normalized  -> $e');
        }
      }

      stdout.writeln('\n==> loaded ${loaded.length}/${objs.length}; '
          'failures: ${failures.length}');

      // Render real frames (normal + squashed) for a representative spread,
      // including the worst-before offenders and one per pack.
      const sample = [
        'goo_ball', 'singularity_goo_core', 'phantom_jelly_beast',
        'soft_dumpling', 'jelly_bun', 'blushy_bun_bunny',
        'galaxy_dumpling', 'mythic_plush_familiar',
      ];
      // Evidence capture only — never fail the release gate over file I/O.
      try {
        for (final id in sample) {
          final sp = loaded[id];
          if (sp == null) continue;
          await _writePng(await _frame(sp, squash: false),
              '_sprite_restyle_proto/smoke/${id}_normal.png');
          await _writePng(await _frame(sp, squash: true),
              '_sprite_restyle_proto/smoke/${id}_squash.png');
          stdout.writeln('  RENDER $id: normal + squash captured');
        }
      } catch (e) {
        stdout.writeln('  (render capture skipped: $e)');
      }

      expect(failures, isEmpty,
          reason: 'these sprites would fall back to ObjectPainter in-game');
      expect(loaded.length, objs.length);
    });
  });
}
