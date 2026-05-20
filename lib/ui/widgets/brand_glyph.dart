import 'package:flutter/widgets.dart';

/// The six brand glyphs that replace Material icons across the UI
/// (DS-3 from `GAME_POLISH_AUDIT.md`). Each maps to a white-on-
/// transparent PNG in `assets/images/glyphs/`.
enum BrandGlyph { coin, lock, share, fire, sparkle, check }

/// Drop-in replacement for [Icon] backed by the brand glyph artwork.
///
/// The glyph PNGs are pure white on transparent, so [color] tints them
/// via `BlendMode.srcIn` — matching how the Material `Icon` it replaces
/// took a color. Pass the same `size`/`color` the old `Icon` resolved
/// to (icons inside an `IconButton` inherit `iconSize`/`color`, so make
/// those explicit here).
class BrandGlyphIcon extends StatelessWidget {
  const BrandGlyphIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color,
  });

  final BrandGlyph glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/glyphs/${glyph.name}.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
    );
  }
}
