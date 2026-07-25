/**
 * Layout helpers shared by the PPTX builder.
 *
 * The `fit` helper is the important one: every image is placed by fitting it
 * inside a box at its true aspect ratio, so nothing is ever stretched
 * (docs/05_CLAUDE_CODE_BUILD_INSTRUCTIONS.md: "No low-resolution image
 * stretching").
 */

const fs = require('fs');
const path = require('path');
const { BRAND, SURFACE, FONT, SLIDE, M, TYPE, FOOTER } = require('./theme');

const STAGED = path.join(__dirname, '..', 'assets', 'staged');
const DIMS = JSON.parse(fs.readFileSync(path.join(STAGED, '_dims.json'), 'utf8'));

/** Absolute path to a staged asset, or null if it is missing. */
function asset(name) {
  for (const ext of ['', '.png', '.jpg']) {
    const p = path.join(STAGED, name + ext);
    if (fs.existsSync(p)) return p;
  }
  return null;
}

function dims(name) {
  for (const ext of ['', '.png', '.jpg']) {
    if (DIMS[name + ext]) return DIMS[name + ext];
  }
  return null;
}

/**
 * Fit an image inside {x,y,w,h} preserving aspect ratio.
 * @param {'center'|'bottom'|'top'} anchor vertical anchoring inside the box
 */
function fit(name, box, anchor = 'center') {
  const d = dims(name);
  if (!d) return null;
  const [iw, ih] = d;
  const scale = Math.min(box.w / iw, box.h / ih);
  const w = iw * scale;
  const h = ih * scale;
  const x = box.x + (box.w - w) / 2;
  let y;
  if (anchor === 'bottom') y = box.y + (box.h - h);
  else if (anchor === 'top') y = box.y;
  else y = box.y + (box.h - h) / 2;
  return { path: asset(name), x, y, w, h };
}

/** Place an image into a box, or draw a clearly-labelled placeholder. */
function image(slide, name, box, anchor = 'center') {
  const f = fit(name, box, anchor);
  if (f && f.path) {
    slide.addImage(f);
    return true;
  }
  placeholder(slide, box, name);
  return false;
}

/** A visibly-labelled missing-asset box (docs/04 placeholder rules). */
function placeholder(slide, box, label) {
  slide.addShape('roundRect', {
    ...box,
    rectRadius: 0.12,
    fill: { color: SURFACE.blush },
    line: { color: BRAND.pink, width: 1.5, dashType: 'dash' },
  });
  slide.addText(`ASSET NEEDED\n${label}`, {
    ...box,
    align: 'center',
    valign: 'middle',
    fontFace: FONT.pptxBody,
    fontSize: 11,
    color: '9A6B80',
  });
}

/** Slide background + footer + page number. Call first on every slide. */
function base(slide, { bg = SURFACE.white, dark = false, number, showFooter = true } = {}) {
  slide.background = { color: bg };
  if (!showFooter) return;
  slide.addText(FOOTER, {
    x: M.x,
    y: SLIDE.h - 0.42,
    w: 7,
    h: 0.25,
    fontFace: FONT.pptxBody,
    fontSize: TYPE.micro.size,
    color: dark ? '7A6B85' : 'A99BB0',
  });
  if (number != null) {
    slide.addText(String(number), {
      x: SLIDE.w - M.x - 0.6,
      y: SLIDE.h - 0.42,
      w: 0.6,
      h: 0.25,
      align: 'right',
      fontFace: FONT.pptxBody,
      fontSize: TYPE.micro.size,
      color: dark ? '7A6B85' : 'A99BB0',
    });
  }
}

/** Kicker + title block. Returns the y coordinate where content may begin. */
function header(slide, { kicker, title, accent = BRAND.pink, dark = false, w = 11.9 }) {
  let y = M.top;
  if (kicker) {
    slide.addText(kicker.toUpperCase(), {
      x: M.x,
      y,
      w,
      h: 0.28,
      fontFace: FONT.pptxBody,
      fontSize: TYPE.kicker.size,
      bold: true,
      charSpacing: TYPE.kicker.charSpacing,
      color: accent,
    });
    y += 0.42;
  }
  if (title) {
    slide.addText(title, {
      x: M.x,
      y,
      w,
      h: 0.78,
      fontFace: FONT.pptxHead,
      fontSize: TYPE.h2.size,
      bold: true,
      color: dark ? 'FFFFFF' : BRAND.ink,
    });
    y += 1.02;
  }
  // Short accent rule under the title.
  slide.addShape('rect', {
    x: M.x, y: y - 0.16, w: 0.86, h: 0.055,
    fill: { color: accent }, line: { width: 0 },
  });
  return y + 0.22;
}

/** A soft rounded panel. */
function panel(slide, box, { fill = SURFACE.cream, line = SURFACE.line, radius = 0.14 } = {}) {
  slide.addShape('roundRect', {
    ...box,
    rectRadius: radius,
    fill: { color: fill },
    line: line ? { color: line, width: 1 } : { width: 0 },
  });
}

/** Bulleted list with a coloured dot glyph. */
function bullets(slide, items, box, { color = BRAND.ink, accent = BRAND.pink, size = TYPE.body.size, gap = 0.34 } = {}) {
  items.forEach((t, i) => {
    const y = box.y + i * gap;
    slide.addShape('ellipse', {
      x: box.x, y: y + size / 200 + 0.045, w: 0.1, h: 0.1,
      fill: { color: accent }, line: { width: 0 },
    });
    slide.addText(t, {
      x: box.x + 0.22, y, w: box.w - 0.22, h: gap,
      fontFace: FONT.pptxBody, fontSize: size, color, valign: 'top',
    });
  });
  return box.y + items.length * gap;
}

/** Small italic disclaimer line — used for every "proposed / not final" note. */
function disclaimer(slide, text, { x = M.x, y, w = 11.9 }) {
  slide.addText(text, {
    x, y, w, h: 0.42,
    fontFace: FONT.pptxBody,
    fontSize: 10.5,
    italic: true,
    color: '7C6E86',
    valign: 'top',
  });
}

/**
 * A character render on a soft tinted disc.
 *
 * Several of the squishies are near-white (Blushy Bun Bunny, Soft Dumpling,
 * Mythic Plush Familiar). On a white or cream card they wash out and lose
 * their silhouette. The disc restores contrast and — because it is a fixed
 * size regardless of the model's own proportions — gives every character the
 * same visual weight in a row.
 */
function modelTile(slide, name, box, { tint = SURFACE.blush, inset = 0.1 } = {}) {
  const d = Math.min(box.w, box.h) * 0.94;
  slide.addShape('ellipse', {
    x: box.x + (box.w - d) / 2,
    y: box.y + (box.h - d) / 2,
    w: d,
    h: d,
    fill: { color: tint },
    line: { width: 0 },
  });
  image(slide, name, {
    x: box.x + box.w * inset,
    y: box.y + box.h * inset,
    w: box.w * (1 - inset * 2),
    h: box.h * (1 - inset * 2),
  });
}

/** Pill-shaped tag. */
function tag(slide, text, { x, y, w, h = 0.3, fill, color }) {
  slide.addShape('roundRect', {
    x, y, w, h, rectRadius: 0.5,
    fill: { color: fill }, line: { width: 0 },
  });
  slide.addText(text, {
    x, y, w, h,
    align: 'center', valign: 'middle',
    fontFace: FONT.pptxBody, fontSize: 9.5, bold: true, color,
  });
}

module.exports = { asset, dims, fit, image, placeholder, base, header, panel, bullets, disclaimer, tag, modelTile, STAGED };
