import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures the current game frame from a [RepaintBoundary] and shares
/// it via the native share sheet. One instance lives on the Flutter-side
/// widget tree ([GameplayScreen]) and receives a [GlobalKey] wrapping
/// the `GameWidget`.
///
/// Cross-platform: on mobile/desktop, writes a PNG to the OS temp
/// directory and shares by path. On web, uses [XFile.fromData] so the
/// browser share sheet receives the bytes directly.
class ShareCaptureService {
  ShareCaptureService(this.boundaryKey);

  final GlobalKey boundaryKey;

  /// Captures the wrapped `RepaintBoundary` as PNG bytes at
  /// [pixelRatio] device-pixel scale. Returns null if the boundary
  /// isn't mounted yet (e.g. captured before first frame).
  Future<Uint8List?> capturePngBytes({double pixelRatio = 2.0}) async {
    final ctx = boundaryKey.currentContext;
    if (ctx == null) return null;
    final render = ctx.findRenderObject();
    if (render is! RenderRepaintBoundary) return null;
    final image = await render.toImage(pixelRatio: pixelRatio);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Capture + share. Returns [ShareResult] so the caller can log
  /// which destination the user picked (tiktok / messages / etc.) into
  /// analytics. [caption] is used verbatim; provide something with
  /// a comment-prompt hook for TikTok virality.
  Future<ShareResult?> shareSnapshot({
    String? caption,
    double pixelRatio = 2.0,
  }) async {
    final bytes = await capturePngBytes(pixelRatio: pixelRatio);
    if (bytes == null) return null;
    final effectiveCaption =
        caption ?? 'Just smashed this 🫠 #squishysmash';

    if (kIsWeb) {
      final file = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'squishy_smash.png',
      );
      return Share.shareXFiles(<XFile>[file], text: effectiveCaption);
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/squishy_smash_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = io.File(path);
    await file.writeAsBytes(bytes, flush: true);
    return Share.shareXFiles(
      <XFile>[XFile(file.path)],
      text: effectiveCaption,
    );
  }
}

/// Canonical share caption set. Rotated so the pre-filled text for a
/// share sheet looks fresh across repeat shares and includes at least
/// one comment-bait variant (per STRATEGY §9.6: "comment prompts drive
/// the participatory funnel").
class ShareCaptions {
  ShareCaptions._();

  static const List<String> mythic = <String>[
    'I found the 1% mythic 😭 #squishysmash',
    'Wait for the pop at the end 😳 #squishysmash',
    'This shouldn\'t exist?? #squishysmash',
    'Which drop next — blue or gold? #squishysmash',
  ];

  static const List<String> epic = <String>[
    'This pop is too satisfying 🫠 #squishysmash',
    'Ok but the audio 🎧 #squishysmash',
    'Rate this squish /10 👇 #squishysmash',
  ];

  static const List<String> generic = <String>[
    'Just smashed this 🫠 #squishysmash',
    'Why is this so addictive #squishysmash',
    'Squish it. Pop it. Smash it. #squishysmash',
  ];

  /// Pick a caption deterministically from [mythic] using [seed] so the
  /// same mythic share always gets the same caption — avoids collision
  /// when two players screenshot and share back-to-back.
  static String forMythic(int seed) => mythic[seed.abs() % mythic.length];

  /// Pick an epic-tier caption.
  static String forEpic(int seed) => epic[seed.abs() % epic.length];

  /// Pick a generic caption.
  static String forGeneric(int seed) =>
      generic[seed.abs() % generic.length];
}
