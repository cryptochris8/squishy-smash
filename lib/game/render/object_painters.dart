import 'dart:math';

import 'package:flutter/painting.dart';

import '../../data/models/smashable_def.dart';
import '../../core/constants.dart';

class ObjectPainter {
  ObjectPainter._();

  static void paint(Canvas canvas, double radius, SmashableDef def) {
    switch (def.category) {
      case 'goo_fidget':
        _paintGoo(canvas, radius, def);
        break;
      case 'creepy_cute':
        _paintCreature(canvas, radius, def);
        break;
      case 'squishy_food':
      default:
        _paintFood(canvas, radius, def);
        break;
    }
  }

  static Color _bodyColor(SmashableDef def) {
    switch (def.themeTag) {
      case 'jelly_cube':
        return Palette.jellyBlue;
      case 'soft_dessert':
        return const Color(0xFFFFE6BD);
      case 'viral_food_energy':
        return const Color(0xFFFFC4D6);
      case 'anti_stress':
        return Palette.toxicLime;
      case 'slime_pod':
        return const Color(0xFF7DE38A);
      case 'pop_pod':
        return Palette.jellyBlue;
      case 'blind_box_vibe':
        return const Color(0xFFB084F2);
      case 'snaggletooth':
        return const Color(0xFFE5A7FF);
      case 'mischievous_blob':
        return const Color(0xFF8C66E0);
      default:
        return Palette.pink;
    }
  }

  static Color _shadeOf(Color c, double pct) {
    return Color.from(
      alpha: c.a,
      red: (c.r * pct).clamp(0.0, 1.0),
      green: (c.g * pct).clamp(0.0, 1.0),
      blue: (c.b * pct).clamp(0.0, 1.0),
    );
  }

  static void _paintFood(Canvas canvas, double r, SmashableDef def) {
    final body = _bodyColor(def);
    final shadow = _shadeOf(body, 0.78);
    final center = Offset(r, r);

    if (def.themeTag == 'jelly_cube') {
      _paintJellyCube(canvas, r, body, shadow);
      return;
    }

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 1.1,
        colors: [body, shadow],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r * 0.96, bodyPaint);

    if (def.themeTag == 'viral_food_energy') {
      final pleat = Paint()
        ..color = shadow.withValues(alpha: 0.5)
        ..strokeWidth = r * 0.06
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 5; i++) {
        final a = -pi / 2 + (i - 2) * 0.45;
        canvas.drawLine(
          Offset(r + cos(a) * r * 0.18, r * 0.3),
          Offset(r + cos(a) * r * 0.85, r * 0.85),
          pleat,
        );
      }
    }

    _paintGloss(canvas, r, def.gooLevel);
  }

  static void _paintJellyCube(Canvas canvas, double r, Color body, Color shadow) {
    final rect = Rect.fromLTWH(r * 0.18, r * 0.18, r * 1.64, r * 1.64);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r * 0.32));
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [body, shadow],
      ).createShader(rect);
    canvas.drawRRect(rrect, bodyPaint);

    final highlight = Paint()..color = const Color(0x88FFFFFF);
    final hRect = Rect.fromLTWH(r * 0.32, r * 0.3, r * 0.5, r * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hRect, Radius.circular(r * 0.08)),
      highlight,
    );
  }

  static void _paintGoo(Canvas canvas, double r, SmashableDef def) {
    final body = _bodyColor(def);
    final shadow = _shadeOf(body, 0.7);
    final center = Offset(r, r);

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.2,
        colors: [body, shadow],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    if (def.themeTag == 'pop_pod') {
      final pods = 7;
      for (var i = 0; i < pods; i++) {
        final a = (i / pods) * pi * 2;
        final cx = r + cos(a) * r * 0.55;
        final cy = r + sin(a) * r * 0.55;
        canvas.drawCircle(Offset(cx, cy), r * 0.32, bodyPaint);
      }
      canvas.drawCircle(center, r * 0.4, bodyPaint);
    } else {
      canvas.drawCircle(center, r * 0.95, bodyPaint);
      if (def.gooLevel > 0.7) {
        final drip = Paint()..color = shadow;
        canvas.drawCircle(Offset(r * 0.4, r * 1.55), r * 0.16, drip);
        canvas.drawCircle(Offset(r * 1.55, r * 1.45), r * 0.12, drip);
      }
    }

    _paintGloss(canvas, r, def.gooLevel);
  }

  static void _paintCreature(Canvas canvas, double r, SmashableDef def) {
    final body = _bodyColor(def);
    final shadow = _shadeOf(body, 0.65);
    final center = Offset(r, r);

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.4),
        radius: 1.1,
        colors: [body, shadow],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    if (def.themeTag == 'mischievous_blob') {
      final path = Path()
        ..moveTo(r, r * 0.15)
        ..cubicTo(r * 1.95, r * 0.3, r * 1.95, r * 1.6, r, r * 1.85)
        ..cubicTo(r * 0.05, r * 1.6, r * 0.05, r * 0.3, r, r * 0.15)
        ..close();
      canvas.drawPath(path, bodyPaint);
    } else {
      canvas.drawCircle(center, r * 0.95, bodyPaint);
    }

    final eyeWhite = Paint()..color = const Color(0xFFFFFFFF);
    final pupil = Paint()..color = const Color(0xFF1B0F25);

    final eyeY = r * 0.85;
    final eyeR = r * 0.22;
    final pupilR = r * 0.11;

    canvas.drawCircle(Offset(r * 0.65, eyeY), eyeR, eyeWhite);
    canvas.drawCircle(Offset(r * 1.35, eyeY), eyeR, eyeWhite);
    canvas.drawCircle(Offset(r * 0.7, eyeY + r * 0.04), pupilR, pupil);
    canvas.drawCircle(Offset(r * 1.4, eyeY + r * 0.04), pupilR, pupil);

    final shine = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(r * 0.66, eyeY - r * 0.04), pupilR * 0.45, shine);
    canvas.drawCircle(Offset(r * 1.36, eyeY - r * 0.04), pupilR * 0.45, shine);

    if (def.themeTag == 'snaggletooth') {
      final fang = Paint()..color = const Color(0xFFFFFFFF);
      final fangPath = Path()
        ..moveTo(r * 0.92, r * 1.18)
        ..lineTo(r * 1.04, r * 1.18)
        ..lineTo(r * 0.98, r * 1.4)
        ..close();
      canvas.drawPath(fangPath, fang);
    } else {
      final mouth = Paint()
        ..color = const Color(0xCC1B0F25)
        ..strokeWidth = r * 0.06
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final mouthRect = Rect.fromLTWH(r * 0.78, r * 1.15, r * 0.44, r * 0.18);
      canvas.drawArc(mouthRect, 0, pi, false, mouth);
    }

    _paintGloss(canvas, r, 0.4);
  }

  static void _paintGloss(Canvas canvas, double r, double intensity) {
    final highlight = Paint()
      ..color = Color.fromARGB((110 * intensity.clamp(0.2, 1.0)).toInt(), 255, 255, 255);
    canvas.drawCircle(Offset(r * 0.62, r * 0.55), r * 0.28, highlight);
    final tinyShine = Paint()..color = const Color(0x88FFFFFF);
    canvas.drawCircle(Offset(r * 0.5, r * 0.42), r * 0.08, tinyShine);
  }
}
