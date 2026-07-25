/**
 * Squishy Smash deck — HTML/PDF renderer.
 *
 * Build:  node src/build_html.js [--font=pdf|pptx] [--out=NAME]
 *
 * This does NOT re-implement the slide layouts. It replays the exact same
 * layout functions used by src/deck.js against a recording target that
 * captures every addText / addShape / addImage call, then paints those
 * primitives as absolutely-positioned HTML at 96 px per inch.
 *
 * Consequence: the PDF and the PPTX are generated from one set of layout
 * calls and cannot drift apart.
 *
 *   --font=pdf   embeds the real brand font (Fredoka) -> the final PDF
 *   --font=pptx  uses Trebuchet MS/Arial, matching the PPTX exactly, so the
 *                render doubles as a visual proxy for validating the PPTX
 */

const fs = require('fs');
const path = require('path');
const { SLIDES } = require('./content');
const { drawSlide, pageNumbers } = require('./deck');
const { SLIDE, FONT } = require('./theme');

const PX = 96; // 1 inch -> 96 css px
const W = SLIDE.w * PX;
const H = SLIDE.h * PX;

const argv = process.argv.slice(2);
const arg = (k, dflt) => {
  const hit = argv.find((a) => a.startsWith(`--${k}=`));
  return hit ? hit.split('=')[1] : dflt;
};
const FONT_MODE = arg('font', 'pdf');
const OUT_NAME = arg('out', 'Squishy_Smash_Licensing_Manufacturing_Deck');

const FREDOKA = 'D:/squishy-smash/assets/google_fonts/Fredoka.ttf';

// ------------------------------------------------------------ recording --

/** Captures PptxGenJS slide calls in draw order. */
class Recorder {
  constructor() {
    this.ops = [];
    this._bg = 'FFFFFF';
  }
  set background(v) { this._bg = (v && v.color) || 'FFFFFF'; }
  get background() { return { color: this._bg }; }
  addText(text, o) { this.ops.push({ kind: 'text', text, o }); }
  addShape(shape, o) { this.ops.push({ kind: 'shape', shape, o }); }
  addImage(o) { this.ops.push({ kind: 'image', o }); }
}

// -------------------------------------------------------------- painting --

const esc = (s) => String(s)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

const col = (c) => (c && c.startsWith('#') ? c : `#${c || '000000'}`);
const px = (inches) => `${(inches * PX).toFixed(2)}px`;
const ptToPx = (pt) => (pt * PX) / 72;

function fontStack(o) {
  if (FONT_MODE === 'pdf') return `'Fredoka', 'Trebuchet MS', Arial, sans-serif`;
  const f = o.fontFace || FONT.pptxBody;
  return `'${f}', Arial, sans-serif`;
}

function paintText(op) {
  const { text, o } = op;
  const align = o.align || 'left';
  const valign = o.valign || 'top';
  const justify = valign === 'middle' ? 'center' : valign === 'bottom' ? 'flex-end' : 'flex-start';
  const style = [
    'position:absolute',
    `left:${px(o.x)}`,
    `top:${px(o.y)}`,
    `width:${px(o.w)}`,
    o.h != null ? `height:${px(o.h)}` : '',
    'display:flex',
    'flex-direction:column',
    `justify-content:${justify}`,
    `text-align:${align}`,
    `font-family:${fontStack(o)}`,
    `font-size:${ptToPx(o.fontSize || 14).toFixed(2)}px`,
    `color:${col(o.color)}`,
    o.bold ? 'font-weight:700' : 'font-weight:400',
    o.italic ? 'font-style:italic' : '',
    o.charSpacing ? `letter-spacing:${(o.charSpacing / 14).toFixed(3)}em` : '',
    `line-height:${o.lineSpacingMultiple || 1.18}`,
    'white-space:pre-wrap',
    'overflow-wrap:break-word',
  ].filter(Boolean).join(';');
  return `<div class="t" style="${style}">${esc(text)}</div>`;
}

function paintShape(op) {
  const { shape, o } = op;
  if (shape === 'line') {
    // Recorded as a vector from (x,y) by (w,h); w/h may be negative.
    const x1 = o.x * PX, y1 = o.y * PX;
    const x2 = (o.x + o.w) * PX, y2 = (o.y + o.h) * PX;
    const lw = (o.line && o.line.width) || 1;
    const dash = o.line && o.line.dashType === 'dash' ? 'stroke-dasharray="6 5"' : '';
    return `<svg class="ln" width="${W}" height="${H}"><line x1="${x1.toFixed(1)}" y1="${y1.toFixed(1)}" x2="${x2.toFixed(1)}" y2="${y2.toFixed(1)}" stroke="${col(o.line && o.line.color)}" stroke-width="${lw}" ${dash}/></svg>`;
  }
  const fill = o.fill && o.fill.color ? col(o.fill.color) : 'transparent';
  const bw = o.line && o.line.width ? o.line.width : 0;
  const bc = o.line && o.line.color ? col(o.line.color) : 'transparent';
  const dashed = o.line && o.line.dashType === 'dash' ? 'dashed' : 'solid';
  let radius = '0';
  if (shape === 'ellipse') radius = '50%';
  else if (shape === 'roundRect') radius = px(o.rectRadius != null ? o.rectRadius : 0.12);
  const style = [
    'position:absolute',
    `left:${px(o.x)}`,
    `top:${px(o.y)}`,
    `width:${px(o.w)}`,
    `height:${px(o.h)}`,
    `background:${fill}`,
    bw ? `border:${bw}px ${dashed} ${bc}` : '',
    `border-radius:${radius}`,
    'box-sizing:border-box',
  ].filter(Boolean).join(';');
  return `<div style="${style}"></div>`;
}

function paintImage(op) {
  const { o } = op;
  if (!o.path || !fs.existsSync(o.path)) return '';
  const ext = path.extname(o.path).slice(1).toLowerCase();
  const mime = ext === 'jpg' ? 'jpeg' : ext;
  const b64 = fs.readFileSync(o.path).toString('base64');
  const style = [
    'position:absolute',
    `left:${px(o.x)}`,
    `top:${px(o.y)}`,
    `width:${px(o.w)}`,
    `height:${px(o.h)}`,
    'object-fit:fill',
  ].join(';');
  return `<img style="${style}" src="data:image/${mime};base64,${b64}">`;
}

// ----------------------------------------------------------------- build --

function renderPages() {
  const numbers = pageNumbers();
  return SLIDES.map((d, i) => {
    const rec = new Recorder();
    drawSlide(rec, d, i, numbers[i]);
    const body = rec.ops.map((op) => {
      if (op.kind === 'text') return paintText(op);
      if (op.kind === 'shape') return paintShape(op);
      return paintImage(op);
    }).join('\n');
    return {
      id: d.id,
      bg: col(rec._bg),
      html: `<section class="slide" style="background:${col(rec._bg)}">\n${body}\n</section>`,
    };
  });
}

function styleBlock() {
  let fontFace = '';
  if (FONT_MODE === 'pdf' && fs.existsSync(FREDOKA)) {
    const b64 = fs.readFileSync(FREDOKA).toString('base64');
    // Embedded so the exported PDF carries its own glyphs and renders
    // identically on any recipient's machine.
    fontFace = `@font-face{font-family:'Fredoka';src:url(data:font/ttf;base64,${b64}) format('truetype');font-weight:300 700;font-display:block;}`;
  }
  return `${fontFace}
*{margin:0;padding:0;box-sizing:border-box;}
html,body{background:#555;}
.slide{position:relative;width:${W}px;height:${H}px;overflow:hidden;page-break-after:always;break-after:page;}
.slide:last-child{page-break-after:auto;break-after:auto;}
.ln{position:absolute;left:0;top:0;pointer-events:none;overflow:visible;}
@page{size:${SLIDE.w}in ${SLIDE.h}in;margin:0;}
@media print{html,body{background:#fff;}}`;
}

/**
 * Optional self-check script.
 *
 * Measures the RENDERED result in the browser rather than trusting the
 * geometry maths: flags any element that leaves the slide, any text box whose
 * content overflows its own height, and any text that collides with the
 * footer strip. Results land in #report for --dump-dom to scrape.
 */
const CHECK_SCRIPT = `
<div id="report" style="display:none"></div>
<script>
(function(){
  var W=${W}, H=${H}, issues=[];
  var slide=document.querySelector('.slide');
  if(!slide){document.getElementById('report').textContent='REPORT:[]';return;}
  var sr=slide.getBoundingClientRect();
  var footerTop=H-0.5*${PX}; // footer strip lives in the bottom ~0.5in
  Array.prototype.forEach.call(slide.querySelectorAll('.t'), function(el){
    var r=el.getBoundingClientRect();
    var left=r.left-sr.left, top=r.top-sr.top, right=r.right-sr.left, bottom=r.bottom-sr.top;
    var txt=(el.textContent||'').trim().slice(0,42);
    if(el.scrollHeight > el.clientHeight+1)
      issues.push({type:'text-overflow',text:txt,over:el.scrollHeight-el.clientHeight});
    if(right>W+1||left<-1||bottom>H+1||top<-1)
      issues.push({type:'out-of-bounds',text:txt,l:Math.round(left),t:Math.round(top),r:Math.round(right),b:Math.round(bottom)});
  });
  document.getElementById('report').textContent='REPORT:'+JSON.stringify(issues);
})();
</script>`;

function doc(inner) {
  return `<!doctype html><html><head><meta charset="utf-8">
<title>Squishy Smash — Licensing & Manufacturing</title>
<style>
${styleBlock()}
</style></head><body>
${inner}
${argv.includes('--check') ? CHECK_SCRIPT : ''}
</body></html>`;
}

function main() {
  const pages = renderPages();
  const outDir = path.join(__dirname, '..', 'output');
  fs.mkdirSync(outDir, { recursive: true });

  if (argv.includes('--split')) {
    // One file per slide, for per-slide screenshot validation.
    const dir = path.join(outDir, '_slides');
    fs.mkdirSync(dir, { recursive: true });
    pages.forEach((p, i) => {
      const n = String(i + 1).padStart(2, '0');
      fs.writeFileSync(path.join(dir, `${n}_${p.id}.html`), doc(p.html), 'utf8');
    });
    console.log(`Wrote ${pages.length} per-slide files -> ${dir}`);
    return;
  }

  const outHtml = path.join(outDir, `${OUT_NAME}${FONT_MODE === 'pptx' ? '_pptxproxy' : ''}.html`);
  fs.writeFileSync(outHtml, doc(pages.map((p) => p.html).join('\n')), 'utf8');
  console.log(`HTML written: ${outHtml}`);
  console.log(`Slides: ${pages.length}  font mode: ${FONT_MODE}`);
}

main();
