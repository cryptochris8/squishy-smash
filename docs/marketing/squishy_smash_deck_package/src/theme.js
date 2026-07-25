/**
 * Squishy Smash deck theme.
 *
 * The five accent colours are the OFFICIAL brand palette, read directly from
 * lib/core/constants.dart (class Palette) in the game repo — the single source
 * of truth shared by the iOS app, the marketing site and the book pipeline.
 * Per docs/03_DESIGN_SYSTEM.md the suggested fallback palette is therefore NOT
 * used.
 *
 *   bgDeep #120B17 · pink #FF8FB8 · cream #FFD36E
 *   jellyBlue #7FE7FF · toxicLime #B6FF5C · lavender #C98BFF
 *
 * Those five accents are tuned for the app's near-black background, so on a
 * light deck they are used for FILLS and SHAPES only. Text uses the *Deep
 * variants below, which are darkened to hold contrast on white.
 */

// Brand colours, verbatim (no leading # — PptxGenJS wants bare hex).
const BRAND = {
  ink: '120B17',        // Palette.bgDeep — used here as the primary text colour
  inkSoft: '4A3F52',
  pink: 'FF8FB8',
  cream: 'FFD36E',
  jellyBlue: '7FE7FF',
  toxicLime: 'B6FF5C',
  lavender: 'C98BFF',
};

// Darkened accents for text and thin strokes (WCAG-safe on white/cream).
const DEEP = {
  pink: 'C4306E',
  gold: 'A8761B',
  blue: '17788F',
  lime: '4F7A18',
  lavender: '6E37B0',
};

const SURFACE = {
  white: 'FFFFFF',
  cream: 'FFF8F3',      // warm paper
  blush: 'FFF0F6',      // pink-tinted panel
  mist: 'F2FAFD',       // blue-tinted panel
  line: 'E7DEE8',
};

const RARITY = {
  Common: 'B0B6C3',
  Rare: '7FE7FF',
  Epic: 'C98BFF',
  Legendary: 'FFD36E',
};
const RARITY_TEXT = {
  Common: '55606F',
  Rare: '17788F',
  Epic: '6E37B0',
  Legendary: 'A8761B',
};

/**
 * Fonts.
 *
 * PPTX uses Trebuchet MS / Arial: both ship with Windows AND macOS, so the
 * editable file opens correctly on any recipient's machine with no font
 * substitution or layout shift. docs/05 requires "no unsupported font
 * dependencies", and Fredoka is not installed on this system.
 *
 * The PDF embeds the real brand font (Fredoka) via @font-face, because a PDF
 * carries its own glyphs — so the artifact actually sent to manufacturers gets
 * correct brand typography with no dependency on the reader's machine.
 */
const FONT = {
  pptxHead: 'Trebuchet MS',
  pptxBody: 'Arial',
  pdfHead: 'Fredoka',
  pdfBody: 'Fredoka',
};

// 13.333 x 7.5in = 16:9 widescreen, per docs/03_DESIGN_SYSTEM.md.
const SLIDE = { w: 13.333, h: 7.5 };

// Safe margins — nothing but full-bleed art crosses these.
const M = { x: 0.72, top: 0.62, bottom: 0.58 };

const TYPE = {
  kicker: { size: 13, bold: true, charSpacing: 2.2 },
  h1: { size: 40, bold: true },
  h2: { size: 30, bold: true },
  h3: { size: 18, bold: true },
  body: { size: 14.5 },
  small: { size: 12 },
  micro: { size: 9.5 },
};

const FOOTER = 'Squishy Smash  |  Confidential Concept Presentation';

module.exports = { BRAND, DEEP, SURFACE, RARITY, RARITY_TEXT, FONT, SLIDE, M, TYPE, FOOTER };
