import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../analytics/events.dart';
import '../systems/arena_registry.dart';
import '../systems/skybox_reveal_controller.dart';

/// Two-layer skybox backdrop with a radial flash overlay. The calm layer
/// is the active pack's ambient sky; the reveal layer crossfades in
/// briefly when a rare+ burst fires.
///
/// Prefers equirectangular PNG sprites (2048×1024) at
/// `assets/images/arenas/skybox_{theme}_{calm|reveal}.png`. Falls back
/// to a vertical gradient built from [ArenaTheme.calmColors] /
/// [revealColors] if the sprite isn't on disk yet — the game stays
/// playable even with partial art coverage.
///
/// Rendering uses [Canvas.drawImageRect] directly (no `saveLayer`) so
/// cover-fit positioning outside component bounds composites cleanly
/// across iOS/Android/web.
class SkyboxComponent extends PositionComponent {
  SkyboxComponent({
    required Vector2 size,
    required this.theme,
    SkyboxRevealController? controller,
    this.events,
  })  : controller = controller ?? SkyboxRevealController(),
        super(size: size);

  final ArenaTheme theme;
  final SkyboxRevealController controller;

  /// Optional analytics sink — when present, asset load failures are
  /// reported via [GameEvents.assetLoadFailed] so a remote telemetry
  /// backend (Sentry/Crashlytics/Firebase) can capture iOS-only decode
  /// failures without device-log access.
  final GameEvents? events;

  ui.Image? _calmImage;
  ui.Image? _revealImage;

  /// Per-layer load error string, or null if the layer loaded fine. The
  /// HUD overlay reads these to render an on-screen diagnostic banner so
  /// a TestFlight tester can screenshot the failure mode without needing
  /// a Mac to view the device console.
  String? calmError;
  String? revealError;
  bool get hasLoadFailure => calmError != null || revealError != null;

  @override
  Future<void> onLoad() async {
    final calmResult = await _tryLoad(theme.calmSpritePath);
    _calmImage = calmResult.image;
    calmError = calmResult.error;
    final revealResult = await _tryLoad(theme.revealSpritePath);
    _revealImage = revealResult.image;
    revealError = revealResult.error;
    debugPrint(
      'SkyboxComponent[${theme.key}]: '
      'calm=${_calmImage != null ? "${_calmImage!.width}x${_calmImage!.height}" : "FALLBACK-GRADIENT"}, '
      'reveal=${_revealImage != null ? "${_revealImage!.width}x${_revealImage!.height}" : "FALLBACK-GRADIENT"}',
    );
  }

  Future<({ui.Image? image, String? error})> _tryLoad(
    String imagesRelativePath,
  ) async {
    try {
      final image = await Flame.images.load(imagesRelativePath);
      return (image: image, error: null);
    } catch (e) {
      final errorString = e.toString();
      debugPrint(
        'SkyboxComponent: image load FAILED for $imagesRelativePath — $errorString',
      );
      events?.assetLoadFailed(
        assetPath: 'assets/images/$imagesRelativePath',
        error: errorString,
      );
      return (image: null, error: errorString);
    }
  }

  /// Public trigger — a rarity-gated reveal moment. [hold] controls how
  /// long the reveal stays fully visible between the 0.18s crossfade in
  /// and the 0.4s crossfade out.
  void triggerReveal({double hold = 1.2}) {
    controller.trigger(hold: hold);
  }

  @override
  void update(double dt) {
    super.update(dt);
    controller.tick(dt);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    _paintLayer(canvas, rect, _calmImage, theme.calmColors,
        controller.calmAlpha);
    if (controller.revealAlpha > 0) {
      _paintLayer(canvas, rect, _revealImage, theme.revealColors,
          controller.revealAlpha);
    }
    if (controller.flashAlpha > 0) {
      _paintRadialFlash(canvas, rect, controller.flashAlpha);
    }
  }

  void _paintLayer(
    Canvas canvas,
    Rect rect,
    ui.Image? image,
    List<Color> fallbackColors,
    double opacity,
  ) {
    if (opacity <= 0) return;
    if (image == null) {
      _paintGradient(canvas, rect, fallbackColors, opacity: opacity);
      return;
    }
    // Cover-fit: scale equirectangular image to match component height,
    // center horizontally so the readable strip of the panorama sits
    // center-frame, clip the overflow.
    final srcW = image.width.toDouble();
    final srcH = image.height.toDouble();
    final scale = rect.height / srcH;
    final drawW = srcW * scale;
    final drawH = rect.height;
    final dx = (rect.width - drawW) / 2;

    final src = Rect.fromLTWH(0, 0, srcW, srcH);
    final dst = Rect.fromLTWH(dx, 0, drawW, drawH);

    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0))
      ..filterQuality = FilterQuality.medium;

    canvas.save();
    canvas.clipRect(rect);
    canvas.drawImageRect(image, src, dst, paint);
    canvas.restore();
  }

  void _paintGradient(
    Canvas canvas,
    Rect rect,
    List<Color> colors, {
    required double opacity,
  }) {
    if (colors.isEmpty || opacity <= 0) return;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors
          .map((c) => c.withValues(alpha: c.a * opacity))
          .toList(growable: false),
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintRadialFlash(Canvas canvas, Rect rect, double alpha) {
    final center = rect.center;
    final maxRadius = rect.shortestSide * 0.8;
    final gradient = RadialGradient(
      colors: <Color>[
        const Color(0xFFFFFFFF).withValues(alpha: alpha),
        const Color(0x00FFFFFF),
      ],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: maxRadius),
      );
    canvas.drawRect(rect, paint);
  }
}
