/**
 * Squishy Smash — Licensing & Manufacturing Deck (PPTX builder)
 *
 * Build:  node src/deck.js
 * Out:    output/Squishy_Smash_Licensing_Manufacturing_Deck.pptx
 *
 * Copy comes from src/content.js, styling from src/theme.js, layout
 * primitives from src/helpers.js. Every image is placed via helpers.image(),
 * which preserves aspect ratio and falls back to a labelled placeholder.
 */

const path = require('path');
const PptxGenJS = require('pptxgenjs');
const { SLIDES } = require('./content');
const T = require('./theme');
const H = require('./helpers');

const { BRAND, DEEP, SURFACE, RARITY, RARITY_TEXT, FONT, SLIDE, M, TYPE } = T;

const OUT = path.join(__dirname, '..', 'output', 'Squishy_Smash_Licensing_Manufacturing_Deck.pptx');

const pptx = new PptxGenJS();
pptx.defineLayout({ name: 'DECK16x9', width: SLIDE.w, height: SLIDE.h });
pptx.layout = 'DECK16x9';
pptx.author = 'Christopher Ryan Campbell';
pptx.company = 'Squishy Smash';
pptx.title = 'Squishy Smash — Licensing & Manufacturing Opportunity';
pptx.subject = 'Licensing and manufacturing partnership deck';

const ACCENTS = [DEEP.pink, DEEP.lavender, DEEP.blue, DEEP.gold, DEEP.lime];
const accentFor = (i) => ACCENTS[i % ACCENTS.length];

let pageNo = 0;

// ---------------------------------------------------------------- layouts --

function layoutCover(s, d) {
  H.base(s, { bg: BRAND.ink, dark: true, showFooter: false });

  H.image(s, 'logo', { x: 4.05, y: 0.5, w: 5.25, h: 2.55 });

  s.addText(d.subtitle, {
    x: M.x, y: 3.2, w: 11.9, h: 0.46,
    align: 'center', fontFace: FONT.pptxHead, fontSize: 21, bold: true,
    color: BRAND.cream, charSpacing: 1.2,
  });
  s.addText(d.support, {
    x: 2.4, y: 3.76, w: 8.5, h: 0.46,
    align: 'center', fontFace: FONT.pptxBody, fontSize: 13.5, color: 'C9BCD2',
  });

  // Hero row: transparent 3D model renders read beautifully on the dark plum.
  const n = d.models.length;
  const cw = 1.92, gap = 0.28;
  const total = n * cw + (n - 1) * gap;
  let x = (SLIDE.w - total) / 2;
  d.models.forEach((m) => {
    H.image(s, `model_${m}`, { x, y: 4.5, w: cw, h: 2.0 }, 'bottom');
    x += cw + gap;
  });

  s.addText(T.FOOTER, {
    x: M.x, y: SLIDE.h - 0.44, w: 8, h: 0.25,
    fontFace: FONT.pptxBody, fontSize: TYPE.micro.size, color: '6F6079',
  });
}

function layoutStatement(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  s.addText(d.body.join('\n\n'), {
    x: M.x, y, w: 7.1, h: 2.4,
    fontFace: FONT.pptxBody, fontSize: TYPE.body.size, color: BRAND.inkSoft,
    lineSpacingMultiple: 1.3, valign: 'top',
  });

  H.panel(s, { x: M.x, y: y + 2.55, w: 7.1, h: 1.15 }, { fill: SURFACE.blush, line: null });
  s.addShape('rect', {
    x: M.x, y: y + 2.55, w: 0.07, h: 1.15,
    fill: { color: DEEP.pink }, line: { width: 0 },
  });
  s.addText(d.callout, {
    x: M.x + 0.32, y: y + 2.55, w: 6.5, h: 1.15,
    valign: 'middle', fontFace: FONT.pptxHead, fontSize: 15.5, bold: true, color: BRAND.ink,
  });

  H.modelTile(s, d.art, { x: 8.5, y: y + 0.05, w: 3.9, h: 3.9 }, { tint: SURFACE.blush, inset: 0.07 });
}

function layoutHub(s, d, i) {
  H.base(s, { number: pageNo });
  H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  const cx = 6.667, cy = 4.42, rx = 4.25, ry = 1.98;
  const cardW = 2.0, cardH = 0.74;

  // Spoke connectors drawn first so cards sit on top.
  d.spokes.forEach((sp, k) => {
    const a = (-90 + k * (360 / d.spokes.length)) * (Math.PI / 180);
    const px = cx + rx * Math.cos(a);
    const py = cy + ry * Math.sin(a);
    s.addShape('line', {
      x: cx, y: cy, w: px - cx, h: py - cy,
      line: { color: sp.proposed ? DEEP.pink : SURFACE.line, width: sp.proposed ? 1.6 : 1.1, dashType: sp.proposed ? 'dash' : 'solid' },
    });
  });

  // Hub.
  s.addShape('ellipse', {
    x: cx - 1.02, y: cy - 0.86, w: 2.04, h: 1.72,
    fill: { color: BRAND.ink }, line: { color: BRAND.pink, width: 2 },
  });
  s.addText('SQUISHY\nSMASH', {
    x: cx - 1.02, y: cy - 0.86, w: 2.04, h: 1.72,
    align: 'center', valign: 'middle',
    fontFace: FONT.pptxHead, fontSize: 15, bold: true, color: 'FFFFFF', lineSpacingMultiple: 0.95,
  });

  d.spokes.forEach((sp, k) => {
    const a = (-90 + k * (360 / d.spokes.length)) * (Math.PI / 180);
    const px = cx + rx * Math.cos(a) - cardW / 2;
    const py = cy + ry * Math.sin(a) - cardH / 2;
    H.panel(s, { x: px, y: py, w: cardW, h: cardH }, {
      fill: sp.proposed ? SURFACE.blush : SURFACE.white,
      line: sp.proposed ? DEEP.pink : SURFACE.line,
      radius: 0.1,
    });
    s.addText(sp.label, {
      x: px, y: py + 0.08, w: cardW, h: 0.28,
      align: 'center', fontFace: FONT.pptxHead, fontSize: 11.5, bold: true, color: BRAND.ink,
    });
    s.addText(sp.note, {
      x: px, y: py + 0.36, w: cardW, h: 0.26,
      align: 'center', fontFace: FONT.pptxBody, fontSize: 8.8,
      color: sp.proposed ? DEEP.pink : '8B7F92',
    });
  });

  s.addText(d.body, {
    x: 2.6, y: 6.62, w: 8.1, h: 0.44,
    align: 'center', fontFace: FONT.pptxBody, fontSize: 12, color: BRAND.inkSoft,
  });
}

function layoutGrid48(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  s.addText(d.body, {
    x: M.x, y: y - 0.06, w: 11.9, h: 0.4,
    fontFace: FONT.pptxBody, fontSize: 13, color: BRAND.inkSoft,
  });

  // Heights below are tuned so the two-line supporting points clear the
  // footer at y=7.08. Enlarging the grid pushes them down — re-check if changed.
  H.image(s, 'grid_48_cards', { x: 0.75, y: y + 0.38, w: 11.83, h: 3.15 });

  s.addText(d.caption, {
    x: M.x, y: y + 3.6, w: 11.9, h: 0.3,
    align: 'center', fontFace: FONT.pptxBody, fontSize: 10.5, italic: true, color: '7C6E86',
  });

  const cw = 11.9 / 4;
  d.points.forEach((p, k) => {
    s.addShape('rect', {
      x: M.x + k * cw, y: y + 3.96, w: 0.5, h: 0.045,
      fill: { color: accentFor(k) }, line: { width: 0 },
    });
    s.addText(p, {
      x: M.x + k * cw, y: y + 4.08, w: cw - 0.4, h: 0.6,
      fontFace: FONT.pptxBody, fontSize: 11, color: BRAND.inkSoft, valign: 'top',
    });
  });
}

function layoutProcess(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  s.addText(d.body, {
    x: M.x, y: y - 0.06, w: 11.9, h: 0.66,
    fontFace: FONT.pptxBody, fontSize: 13, color: BRAND.inkSoft, lineSpacingMultiple: 1.25,
  });

  // Process flow.
  const sy = y + 0.74;
  const n = d.steps.length;
  const sw = 2.12, sgap = 0.36;
  let sx = (SLIDE.w - (n * sw + (n - 1) * sgap)) / 2;
  d.steps.forEach((st, k) => {
    const last = k === n - 1;
    H.panel(s, { x: sx, y: sy, w: sw, h: 0.68 }, {
      fill: last ? SURFACE.blush : SURFACE.cream,
      line: last ? DEEP.pink : SURFACE.line,
      radius: 0.34,
    });
    s.addText(st, {
      x: sx, y: sy, w: sw, h: 0.68,
      align: 'center', valign: 'middle',
      fontFace: FONT.pptxHead, fontSize: 10.5, bold: true,
      color: last ? DEEP.pink : BRAND.ink,
    });
    if (!last) {
      s.addText('›', {
        x: sx + sw, y: sy, w: sgap, h: 0.68,
        align: 'center', valign: 'middle',
        fontFace: FONT.pptxHead, fontSize: 20, bold: true, color: 'C3B6CB',
      });
    }
    sx += sw + sgap;
  });

  // Existing models on discs (consistent weight; pale characters stay legible).
  const my = sy + 1.02;
  const mw = 1.86;
  const tints = [SURFACE.blush, SURFACE.mist, SURFACE.cream];
  let mx = M.x + 0.1;
  d.models.forEach((m, k) => {
    H.modelTile(s, `model_${m}`, { x: mx, y: my, w: mw, h: 1.86 }, { tint: tints[k % tints.length] });
    mx += mw + 0.22;
  });
  s.addText('Existing 3D models, rendered from the GLB files', {
    x: M.x + 0.1, y: my + 1.94, w: 6.0, h: 0.28,
    fontFace: FONT.pptxBody, fontSize: 10, italic: true, color: '7C6E86',
  });

  H.bullets(s, d.points, { x: 6.9, y: my + 0.18, w: 5.7 }, { accent: DEEP.blue, size: 12.5, gap: 0.46 });

  H.disclaimer(s, d.disclaimer, { y: 6.5 });
}

function layoutSpec(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  const cols = 2, cw = 3.55, ch = 0.92, gx = 0.3, gy = 0.26;
  d.specs.forEach((sp, k) => {
    const x = M.x + (k % cols) * (cw + gx);
    const yy = y + Math.floor(k / cols) * (ch + gy);
    H.panel(s, { x, y: yy, w: cw, h: ch }, { fill: SURFACE.cream, line: SURFACE.line });
    s.addText(sp.label.toUpperCase(), {
      x: x + 0.24, y: yy + 0.13, w: cw - 0.4, h: 0.24,
      fontFace: FONT.pptxBody, fontSize: 9, bold: true, charSpacing: 1.4, color: accentFor(k),
    });
    s.addText(sp.value, {
      x: x + 0.24, y: yy + 0.4, w: cw - 0.4, h: 0.4,
      fontFace: FONT.pptxHead, fontSize: 13, bold: true, color: BRAND.ink,
    });
  });

  H.modelTile(s, d.art, { x: 8.6, y: y + 0.2, w: 3.8, h: 3.8 }, { tint: SURFACE.mist, inset: 0.07 });

  H.disclaimer(s, d.disclaimer, { y: 6.5 });
}

function layoutLineup(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  s.addText(d.seriesName, {
    x: M.x, y: y - 0.1, w: 6.4, h: 0.36,
    fontFace: FONT.pptxHead, fontSize: 16, bold: true, color: DEEP.gold,
  });
  s.addText(d.body, {
    x: M.x, y: y + 0.3, w: 11.9, h: 0.62,
    fontFace: FONT.pptxBody, fontSize: 12.5, color: BRAND.inkSoft, lineSpacingMultiple: 1.22,
  });

  const n = d.lineup.length;
  const cw = 1.84, gap = 0.16;
  let x = (SLIDE.w - (n * cw + (n - 1) * gap)) / 2;
  const cy = y + 1.04;

  const lineupTints = { Common: SURFACE.mist, Rare: SURFACE.mist, Epic: SURFACE.blush, Legendary: 'FFF6E3' };
  d.lineup.forEach((c) => {
    H.panel(s, { x, y: cy, w: cw, h: 2.72 }, { fill: SURFACE.white, line: SURFACE.line });
    H.modelTile(s, `model_${c.slug}`, { x: x + 0.16, y: cy + 0.1, w: cw - 0.32, h: 1.44 },
      { tint: lineupTints[c.rarity] || SURFACE.blush, inset: 0.06 });
    s.addText(c.name, {
      x: x + 0.06, y: cy + 1.58, w: cw - 0.12, h: 0.52,
      align: 'center', valign: 'top',
      fontFace: FONT.pptxHead, fontSize: 10.5, bold: true, color: BRAND.ink,
    });
    s.addText(c.num, {
      x: x + 0.06, y: cy + 2.06, w: cw - 0.12, h: 0.22,
      align: 'center', fontFace: FONT.pptxBody, fontSize: 9, color: '8B7F92',
    });
    H.tag(s, c.rarity.toUpperCase(), {
      x: x + (cw - 1.06) / 2, y: cy + 2.31, w: 1.06, h: 0.28,
      fill: RARITY[c.rarity], color: RARITY_TEXT[c.rarity],
    });
    x += cw + gap;
  });

  // Benefits strip.
  const by = cy + 2.94;
  const bw = 11.9 / d.benefits.length;
  d.benefits.forEach((b, k) => {
    s.addText(`✓  ${b}`, {
      x: M.x + k * bw, y: by, w: bw - 0.1, h: 0.4,
      fontFace: FONT.pptxBody, fontSize: 10, color: BRAND.inkSoft, valign: 'top',
    });
  });

  H.disclaimer(s, d.disclaimer, { y: 6.62 });
}

function layoutTwoCol(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  [[d.colA, M.x, SURFACE.cream, DEEP.lavender], [d.colB, 6.95, SURFACE.mist, DEEP.blue]].forEach(
    ([col, x, fill, accent]) => {
      H.panel(s, { x, y, w: 5.66, h: 3.55 }, { fill, line: SURFACE.line });
      s.addText(col.heading, {
        x: x + 0.34, y: y + 0.28, w: 5.0, h: 0.36,
        fontFace: FONT.pptxHead, fontSize: 15, bold: true, color: accent,
      });
      H.bullets(s, col.items, { x: x + 0.34, y: y + 0.82, w: 5.0 }, { accent, size: 12.5, gap: 0.46 });
    }
  );

  H.panel(s, { x: M.x, y: y + 3.78, w: 11.9, h: 0.78 }, { fill: SURFACE.blush, line: null });
  s.addText(d.disclaimer, {
    x: M.x + 0.34, y: y + 3.78, w: 11.2, h: 0.78,
    valign: 'middle', fontFace: FONT.pptxBody, fontSize: 12, italic: true, color: BRAND.ink,
  });
}

function layoutDigital(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  s.addText(d.body, {
    x: M.x, y: y - 0.06, w: 11.9, h: 0.62,
    fontFace: FONT.pptxBody, fontSize: 12.5, color: BRAND.inkSoft, lineSpacingMultiple: 1.25,
  });

  const cw = 3.78, gap = 0.28, ph = 3.0;
  let x = M.x;
  const cy = y + 0.6;
  d.live.forEach((l, k) => {
    H.panel(s, { x, y: cy, w: cw, h: ph }, { fill: SURFACE.cream, line: SURFACE.line });
    // Phone captures are 1290x2796, so they stay narrow however wide the
    // panel is — give them height instead, which is what makes them readable.
    H.image(s, l.art, { x: x + 0.16, y: cy + 0.16, w: cw - 0.32, h: ph - 0.86 });
    s.addText(l.label, {
      x: x + 0.2, y: cy + ph - 0.62, w: cw - 0.4, h: 0.28,
      align: 'center', fontFace: FONT.pptxHead, fontSize: 12.5, bold: true, color: BRAND.ink,
    });
    s.addText(l.note, {
      x: x + 0.2, y: cy + ph - 0.34, w: cw - 0.4, h: 0.26,
      align: 'center', fontFace: FONT.pptxBody, fontSize: 9.5, color: accentFor(k),
    });
    x += cw + gap;
  });

  const py = cy + ph + 0.16;
  s.addText('Planned toy-to-digital connections (not yet implemented)', {
    x: M.x, y: py, w: 11.9, h: 0.28,
    fontFace: FONT.pptxBody, fontSize: 10.5, bold: true, charSpacing: 0.8, color: DEEP.pink,
  });
  const pw = 11.9 / d.planned.length;
  d.planned.forEach((p, k) => {
    s.addText(`·  ${p}`, {
      x: M.x + k * pw, y: py + 0.3, w: pw - 0.14, h: 0.4,
      fontFace: FONT.pptxBody, fontSize: 10, color: BRAND.inkSoft, valign: 'top',
    });
  });
}

function layoutPackaging(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  s.addText(d.body, {
    x: M.x, y: y - 0.06, w: 7.4, h: 0.9,
    fontFace: FONT.pptxBody, fontSize: 13, color: BRAND.inkSoft, lineSpacingMultiple: 1.28,
  });

  s.addText('PACKAGING COMPONENTS', {
    x: M.x, y: y + 0.92, w: 7.4, h: 0.26,
    fontFace: FONT.pptxBody, fontSize: 9.5, bold: true, charSpacing: 1.4, color: DEEP.lavender,
  });
  const half = Math.ceil(d.components.length / 2);
  H.bullets(s, d.components.slice(0, half), { x: M.x, y: y + 1.24, w: 3.5 }, { accent: DEEP.lavender, size: 11.5, gap: 0.36 });
  H.bullets(s, d.components.slice(half), { x: M.x + 3.7, y: y + 1.24, w: 3.5 }, { accent: DEEP.lavender, size: 11.5, gap: 0.36 });

  s.addText('FORMATS', {
    x: M.x, y: y + 2.82, w: 7.4, h: 0.26,
    fontFace: FONT.pptxBody, fontSize: 9.5, bold: true, charSpacing: 1.4, color: DEEP.blue,
  });
  // Wrap inside the left column — the card panel starts at x=8.5, and a pill
  // running under it would have its label hidden.
  const FORMAT_MAX_X = 8.2;
  let fx = M.x, fy = y + 3.14;
  d.formats.forEach((f) => {
    const w = 0.14 * f.length + 0.5;
    if (fx + w > FORMAT_MAX_X) { fx = M.x; fy += 0.46; }
    H.tag(s, f, { x: fx, y: fy, w, h: 0.34, fill: SURFACE.mist, color: DEEP.blue });
    fx += w + 0.16;
  });

  H.panel(s, { x: 8.5, y: y - 0.02, w: 4.1, h: 3.62 }, { fill: SURFACE.cream, line: SURFACE.line });
  H.image(s, d.art, { x: 8.72, y: y + 0.18, w: 3.66, h: 2.98 });
  s.addText('Existing trading card — design reference', {
    x: 8.6, y: y + 3.2, w: 3.9, h: 0.3,
    align: 'center', fontFace: FONT.pptxBody, fontSize: 9.5, italic: true, color: '7C6E86',
  });

  H.disclaimer(s, d.disclaimer, { y: 6.62 });
}

function layoutAudience(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  H.panel(s, { x: M.x, y, w: 5.3, h: 1.5 }, { fill: BRAND.ink, line: null });
  s.addText('PRIMARY AUDIENCE', {
    x: M.x + 0.36, y: y + 0.24, w: 4.6, h: 0.26,
    fontFace: FONT.pptxBody, fontSize: 9.5, bold: true, charSpacing: 1.4, color: BRAND.cream,
  });
  s.addText(d.primary, {
    x: M.x + 0.36, y: y + 0.56, w: 4.7, h: 0.7,
    fontFace: FONT.pptxHead, fontSize: 19, bold: true, color: 'FFFFFF',
  });

  s.addText('SECONDARY AUDIENCES', {
    x: M.x, y: y + 1.78, w: 5.3, h: 0.26,
    fontFace: FONT.pptxBody, fontSize: 9.5, bold: true, charSpacing: 1.4, color: DEEP.lavender,
  });
  H.bullets(s, d.secondary, { x: M.x, y: y + 2.12, w: 5.2 }, { accent: DEEP.lavender, size: 12.5, gap: 0.42 });

  s.addText('PURCHASE OCCASIONS', {
    x: 6.95, y, w: 5.66, h: 0.26,
    fontFace: FONT.pptxBody, fontSize: 9.5, bold: true, charSpacing: 1.4, color: DEEP.gold,
  });
  let ox = 6.95, oy = y + 0.36;
  d.occasions.forEach((o) => {
    const w = 0.135 * o.length + 0.52;
    if (ox + w > 12.61) { ox = 6.95; oy += 0.46; }
    H.tag(s, o, { x: ox, y: oy, w, h: 0.36, fill: SURFACE.cream, color: DEEP.gold });
    ox += w + 0.14;
  });

  H.modelTile(s, 'sprite_blushy_bun_bunny',
    { x: 8.55, y: oy + 0.62, w: 2.7, h: 2.7 }, { tint: SURFACE.blush, inset: 0.08 });

  H.disclaimer(s, d.disclaimer, { y: 6.62 });
}

function layoutAsk(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  const cols = 3, cw = 3.83, ch = 0.86, gx = 0.2, gy = 0.2;
  d.items.forEach((it, k) => {
    const x = M.x + (k % cols) * (cw + gx);
    const yy = y + Math.floor(k / cols) * (ch + gy);
    H.panel(s, { x, y: yy, w: cw, h: ch }, { fill: SURFACE.white, line: SURFACE.line });
    s.addShape('ellipse', {
      x: x + 0.26, y: yy + ch / 2 - 0.11, w: 0.22, h: 0.22,
      fill: { color: accentFor(k) }, line: { width: 0 },
    });
    s.addText(it, {
      x: x + 0.62, y: yy, w: cw - 0.78, h: ch,
      valign: 'middle', fontFace: FONT.pptxHead, fontSize: 12.5, bold: true, color: BRAND.ink,
    });
  });

  const cy = y + 3 * ch + 2 * gy + 0.3;
  H.panel(s, { x: M.x, y: cy, w: 11.9, h: 0.86 }, { fill: SURFACE.blush, line: null });
  s.addText(d.callout, {
    x: M.x + 0.4, y: cy, w: 11.1, h: 0.86,
    valign: 'middle', fontFace: FONT.pptxHead, fontSize: 14.5, bold: true, color: BRAND.ink,
  });
}

function layoutWhy(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  const cols = 3, cw = 3.83, ch = 1.42, gx = 0.2, gy = 0.22;
  d.points.forEach((p, k) => {
    const x = M.x + (k % cols) * (cw + gx);
    const yy = y + Math.floor(k / cols) * (ch + gy);
    H.panel(s, { x, y: yy, w: cw, h: ch }, { fill: SURFACE.cream, line: SURFACE.line });
    s.addShape('rect', {
      x: x + 0.3, y: yy + 0.3, w: 0.42, h: 0.05,
      fill: { color: accentFor(k) }, line: { width: 0 },
    });
    s.addText(p.h, {
      x: x + 0.3, y: yy + 0.44, w: cw - 0.6, h: 0.34,
      fontFace: FONT.pptxHead, fontSize: 13.5, bold: true, color: BRAND.ink,
    });
    s.addText(p.d, {
      x: x + 0.3, y: yy + 0.8, w: cw - 0.6, h: 0.5,
      fontFace: FONT.pptxBody, fontSize: 11, color: BRAND.inkSoft, valign: 'top',
    });
  });

  const cy = y + 2 * ch + gy + 0.34;
  H.panel(s, { x: M.x, y: cy, w: 11.9, h: 0.9 }, { fill: BRAND.ink, line: null });
  s.addText(d.callout, {
    x: M.x, y: cy, w: 11.9, h: 0.9,
    align: 'center', valign: 'middle',
    fontFace: FONT.pptxHead, fontSize: 16, bold: true, color: BRAND.cream,
  });
}

function layoutExpansion(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  H.panel(s, { x: M.x, y, w: 3.5, h: 1.5 }, { fill: SURFACE.blush, line: DEEP.pink });
  s.addText(d.focus.label, {
    x: M.x + 0.3, y: y + 0.34, w: 2.9, h: 0.5,
    fontFace: FONT.pptxHead, fontSize: 16, bold: true, color: DEEP.pink,
  });
  s.addText(d.focus.note, {
    x: M.x + 0.3, y: y + 0.86, w: 2.9, h: 0.3,
    fontFace: FONT.pptxBody, fontSize: 11.5, color: BRAND.inkSoft,
  });

  s.addText('Broader licensing potential', {
    x: 4.62, y: y + 0.06, w: 8, h: 0.32,
    fontFace: FONT.pptxBody, fontSize: 10, bold: true, charSpacing: 1.2, color: '8B7F92',
  });

  let cx = 4.62, cyy = y + 0.46;
  d.categories.forEach((c, k) => {
    const w = 0.135 * c.length + 0.6;
    if (cx + w > 12.61) { cx = 4.62; cyy += 0.5; }
    H.tag(s, c, { x: cx, y: cyy, w, h: 0.4, fill: SURFACE.cream, color: accentFor(k) });
    cx += w + 0.16;
  });

  // Same 3D renders used on slides 5-7, so the character treatment reads as
  // one consistent system across the whole deck.
  const sy = Math.max(y + 1.86, cyy + 0.72);
  const models = ['soft_dumpling', 'goo_ball', 'blushy_bun_bunny', 'celestial_dumpling_core', 'singularity_goo_core', 'mythic_plush_familiar'];
  const tints = [SURFACE.blush, SURFACE.mist, SURFACE.cream];
  let mx = M.x + 0.32;
  models.forEach((m, k) => {
    H.modelTile(s, `model_${m}`, { x: mx, y: sy, w: 1.7, h: 1.7 }, { tint: tints[k % tints.length], inset: 0.07 });
    mx += 1.88;
  });

  H.disclaimer(s, d.disclaimer, { y: 6.62 });
}

function layoutContact(s, d) {
  H.base(s, { bg: BRAND.ink, dark: true, number: pageNo });

  s.addShape('ellipse', {
    x: 7.6, y: 0.7, w: 5.6, h: 5.6,
    fill: { color: '241634' }, line: { width: 0 },
  });
  H.image(s, d.art, { x: 8.1, y: 1.2, w: 4.6, h: 4.6 });

  s.addText(d.title, {
    x: M.x, y: 1.5, w: 7.0, h: 1.5,
    fontFace: FONT.pptxHead, fontSize: 34, bold: true, color: 'FFFFFF',
  });
  s.addShape('rect', {
    x: M.x, y: 3.06, w: 0.86, h: 0.055,
    fill: { color: BRAND.pink }, line: { width: 0 },
  });
  s.addText(d.body, {
    x: M.x, y: 3.3, w: 6.7, h: 0.9,
    fontFace: FONT.pptxBody, fontSize: 13.5, color: 'C9BCD2', lineSpacingMultiple: 1.3,
  });

  const c = d.contact;
  const rows = [
    ['Contact', c.name],
    ['Company', c.company],
    ['Email', c.email],
    ['Website', c.website],
    ['Phone', c.phone],
  ];
  rows.forEach(([k, v], idx) => {
    const yy = 4.35 + idx * 0.42;
    s.addText(k.toUpperCase(), {
      x: M.x, y: yy, w: 1.5, h: 0.32,
      fontFace: FONT.pptxBody, fontSize: 9.5, bold: true, charSpacing: 1.2, color: '8B7F92',
    });
    s.addText(v, {
      x: M.x + 1.55, y: yy, w: 5.2, h: 0.32,
      fontFace: FONT.pptxHead, fontSize: 13, bold: true,
      color: v.startsWith('[') ? BRAND.pink : 'FFFFFF',
    });
  });

  s.addText(`© ${require('./content').VERIFIED.year} ${c.name} / ${c.company}. All rights reserved.`, {
    x: M.x, y: 6.62, w: 7.5, h: 0.3,
    fontFace: FONT.pptxBody, fontSize: 9.5, color: '6F6079',
  });
}

function layoutAppendixGallery(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  s.addText(d.body, {
    x: M.x, y: y - 0.06, w: 11.9, h: 0.36,
    fontFace: FONT.pptxBody, fontSize: 12.5, color: BRAND.inkSoft,
  });
  // Must terminate above the caption at y=6.62 — at h=4.4 the bottom card row
  // rendered straight over it.
  H.image(s, 'grid_48_cards', { x: 0.9, y: y + 0.42, w: 11.5, h: 3.72 });
  s.addText(d.caption, {
    x: M.x, y: 6.62, w: 11.9, h: 0.3,
    align: 'center', fontFace: FONT.pptxBody, fontSize: 11, italic: true, color: '7C6E86',
  });
}

function layoutAppendixRfq(s, d, i) {
  H.base(s, { number: pageNo });
  const y = H.header(s, { kicker: d.kicker, title: d.title, accent: accentFor(i) });

  s.addText(d.intro, {
    x: M.x, y: y - 0.06, w: 11.9, h: 0.34,
    fontFace: FONT.pptxHead, fontSize: 13, bold: true, color: BRAND.ink,
  });

  s.addText('WE CAN PROVIDE', {
    x: M.x, y: y + 0.38, w: 3.5, h: 0.26,
    fontFace: FONT.pptxBody, fontSize: 9, bold: true, charSpacing: 1.4, color: DEEP.blue,
  });
  H.bullets(s, d.inputsWeProvide, { x: M.x, y: y + 0.7, w: 3.3 }, { accent: DEEP.blue, size: 10.5, gap: 0.32 });

  s.addText('INFORMATION REQUESTED', {
    x: 4.5, y: y + 0.38, w: 8, h: 0.26,
    fontFace: FONT.pptxBody, fontSize: 9, bold: true, charSpacing: 1.4, color: DEEP.pink,
  });
  const half = Math.ceil(d.questions.length / 2);
  d.questions.forEach((q, k) => {
    const col = k < half ? 0 : 1;
    const row = k < half ? k : k - half;
    s.addText(`${k + 1}.  ${q}`, {
      x: 4.5 + col * 4.15, y: y + 0.7 + row * 0.3, w: 4.0, h: 0.3,
      fontFace: FONT.pptxBody, fontSize: 10, color: BRAND.inkSoft, valign: 'top',
    });
  });

  const sy = y + 0.7 + half * 0.3 + 0.16;
  H.panel(s, { x: M.x, y: sy, w: 11.9, h: 0.62 }, { fill: SURFACE.mist, line: null });
  s.addText(d.safety, {
    x: M.x + 0.3, y: sy, w: 11.3, h: 0.62,
    valign: 'middle', fontFace: FONT.pptxBody, fontSize: 10.5, color: BRAND.ink,
  });

  H.disclaimer(s, d.disclaimer, { y: sy + 0.72 });
}

const LAYOUTS = {
  cover: layoutCover,
  statement: layoutStatement,
  hub: layoutHub,
  grid48: layoutGrid48,
  process: layoutProcess,
  spec: layoutSpec,
  lineup: layoutLineup,
  twocol: layoutTwoCol,
  digital: layoutDigital,
  packaging: layoutPackaging,
  audience: layoutAudience,
  ask: layoutAsk,
  why: layoutWhy,
  expansion: layoutExpansion,
  contact: layoutContact,
  appendixGallery: layoutAppendixGallery,
  appendixRfq: layoutAppendixRfq,
};

// ------------------------------------------------------------------ build --

/**
 * Draw one slide's layout onto any target implementing the PptxGenJS slide
 * interface (addText / addShape / addImage / .background).
 *
 * src/build_html.js passes a recording target instead of a real slide, so the
 * PDF is generated from the EXACT same layout calls as the PPTX. There is no
 * second copy of the layout code to drift out of sync.
 */
function drawSlide(target, d, i, number) {
  const fn = LAYOUTS[d.layout];
  if (!fn) throw new Error(`No layout registered for "${d.layout}" (slide ${d.id})`);
  const prev = pageNo;
  pageNo = number;
  try {
    fn(target, d, i);
  } finally {
    pageNo = prev;
  }
}

/** Page numbers: the cover is unnumbered, everything after it counts from 1. */
function pageNumbers() {
  let n = 0;
  return SLIDES.map((d) => (d.layout === 'cover' ? null : (n += 1)));
}

function build() {
  const numbers = pageNumbers();
  SLIDES.forEach((d, i) => {
    const s = pptx.addSlide();
    drawSlide(s, d, i, numbers[i]);
  });
  return pptx.writeFile({ fileName: OUT }).then(() => {
    console.log(`PPTX written: ${OUT}`);
    console.log(`Slides: ${SLIDES.length}`);
  });
}

module.exports = { drawSlide, pageNumbers, LAYOUTS };

if (require.main === module) build();
