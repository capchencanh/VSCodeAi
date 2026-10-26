/* Sinh word/document.xml tu file .md cua TS (chuan CITEK).
   Tai su dung package .docx template -> giu nguyen styles/header/footer/numbering.

   Cach dung:  node md2docx.js <file.md> <out-document.xml> <template-document.xml>
   (tham so 3 = word/document.xml cua template, dung de lay sectPr: kho giay, le,
    header/footer reference -> khong hard-code theo 1 template cu the)

   FONT/MAU: doc truc tiep tu template BIDIPHAR_BP_SD_V2.0.docx, KHONG tu chon:
     - Font      : KHONG khai rFonts -> ke thua style Normal (Myriad Pro, 11pt)
     - Chu than  : 00586F (moi doan van, o bang, list deu to mau nay nhu template)
     - Vien bang : single sz 4 mau BFBFBF
     - Header cot bang than tai lieu : nen 00586F, chu FFFFFF dam, can giua
     - Bang trang bia : dong tieu de merge nen 00586F chu trang dam 14pt can giua;
                        cot nhan / header cot nen F5F5F5, chu 00586F dam
     - Duong ke trang bia : bottom border sz 24 mau A2D45E
     - Code      : Courier New

   TS la tai lieu gui khach hang -> moi section "PHU LUC" bi BO KHOI file Word. */
const fs = require('fs');

const SRC = process.argv[2];
const OUT = process.argv[3];
const TPL_DOC = process.argv[4];
if (!SRC || !OUT || !TPL_DOC) {
  console.error('Cach dung: node md2docx.js <file.md> <out-document.xml> <template-document.xml>');
  process.exit(1);
}

// ---- hang so lay tu template ----
const TEAL = '00586F';
const WHITE = 'FFFFFF';
const LIGHT = 'F5F5F5';
const BORDER = 'BFBFBF';
const LINE = 'A2D45E';
const MONO = '<w:rFonts w:ascii="Courier New" w:hAnsi="Courier New" w:cs="Courier New"/>';

// sectPr + be rong vung in lay tu chinh template
const tplXml = fs.readFileSync(TPL_DOC, 'utf8');
const sIdx = tplXml.lastIndexOf('<w:sectPr');
const SECTPR = tplXml.slice(sIdx, tplXml.indexOf('</w:sectPr>', sIdx) + '</w:sectPr>'.length);
const num = re => Number((re.exec(SECTPR) || [])[1] || 0);
const PAGE_TWIPS = num(/<w:pgSz [^>]*w:w="(\d+)"/) - num(/<w:pgMar [^>]*w:left="(\d+)"/) - num(/<w:pgMar [^>]*w:right="(\d+)"/);
if (!(PAGE_TWIPS > 0)) { console.error('Khong doc duoc kho giay tu sectPr cua template'); process.exit(1); }

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

// ---- inline: **bold**, `code`, *italic* ----
function runs(text, base) {
  base = base || {};
  const out = [];
  const re = /(\*\*[^*]+\*\*|`[^`]+`|\*[^*\n]+\*)/g;
  let last = 0, m;
  const push = (t, o) => { if (t !== '') out.push({ t, o: Object.assign({}, base, o) }); };
  while ((m = re.exec(text)) !== null) {
    push(text.slice(last, m.index), {});
    const tok = m[0];
    // **dam** co the chua `code` ben trong -> tach tiep
    if (tok.startsWith('**')) runs(tok.slice(2, -2), Object.assign({}, base, { b: true })).forEach(r => out.push(r));
    else if (tok.startsWith('`')) push(tok.slice(1, -1), { mono: true });
    else push(tok.slice(1, -1), { i: true });
    last = re.lastIndex;
  }
  push(text.slice(last), {});
  return out.length ? out : [{ t: '', o: base }];
}

// thu tu phan tu trong rPr theo schema: rFonts, b, i, color, sz, szCs
function runXml(r) {
  const o = r.o || {};
  let rPr = o.mono ? MONO : '';
  if (o.b) rPr += '<w:b/>';
  if (o.i) rPr += '<w:i/>';
  const color = o.color || (o.mono && o.codeBlock ? null : TEAL);
  if (color) rPr += `<w:color w:val="${color}"/>`;
  if (o.sz) rPr += `<w:sz w:val="${o.sz}"/><w:szCs w:val="${o.sz}"/>`;
  return `<w:r><w:rPr>${rPr}</w:rPr><w:t xml:space="preserve">${esc(r.t)}</w:t></w:r>`;
}

// thu tu phan tu trong pPr theo schema: pStyle, keepNext, pBdr, spacing, ind, jc
function para(text, opt) {
  opt = opt || {};
  let pPr = '';
  if (opt.style) pPr += `<w:pStyle w:val="${opt.style}"/>`;
  if (opt.keepNext) pPr += '<w:keepNext/>';
  if (opt.border) pPr += `<w:pBdr><w:left w:val="single" w:sz="18" w:space="6" w:color="${TEAL}"/></w:pBdr>`;
  if (opt.bottomLine) pPr += `<w:pBdr><w:bottom w:val="single" w:sz="24" w:space="1" w:color="${LINE}"/></w:pBdr>`;
  if (opt.spacing) pPr += `<w:spacing w:before="${opt.spacing[0]}" w:after="${opt.spacing[1]}"${opt.tight ? ' w:line="240" w:lineRule="auto"' : ''}/>`;
  if (opt.indent) pPr += `<w:ind w:left="${opt.indent}"${opt.indentRight ? ` w:right="${opt.indentRight}"` : ''}/>`;
  if (opt.jc) pPr += `<w:jc w:val="${opt.jc}"/>`;
  pPr = pPr ? `<w:pPr>${pPr}</w:pPr>` : '';
  const brk = opt.pageBreakBefore ? '<w:r><w:br w:type="page"/></w:r>' : '';
  const rs = (opt.runs || runs(text, opt.run || {})).map(runXml).join('');
  return `<w:p>${pPr}${brk}${rs}</w:p>`;
}

const pageBreak = () => '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';

// ---- o bang: dung dinh dang template ----
// kind: 'band'  = dong tieu de merge (THONG TIN TAI LIEU / BANG GHI NHAN THAY DOI / MUC LUC)
//       'head'  = header cot bang than tai lieu (nen teal, chu trang dam)
//       'light' = header cot bang bia + cot nhan bang thong tin (nen F5F5F5, chu teal dam)
//       null    = o du lieu (chu teal)
function cell(text, opt) {
  opt = opt || {};
  let tcPr = `<w:tcW w:w="${opt.w}" w:type="dxa"/>`;
  if (opt.span) tcPr += `<w:gridSpan w:val="${opt.span}"/>`;
  const fill = { band: TEAL, head: TEAL, light: LIGHT }[opt.kind] || opt.fill;
  if (fill) tcPr += `<w:shd w:val="clear" w:color="auto" w:fill="${fill}"/>`;
  const m = opt.mar || (opt.kind === 'band' ? [100, 120] : [60, 100]);
  tcPr += `<w:tcMar><w:top w:w="${m[0]}" w:type="dxa"/><w:left w:w="${m[1]}" w:type="dxa"/>`
    + `<w:bottom w:w="${m[0]}" w:type="dxa"/><w:right w:w="${m[1]}" w:type="dxa"/></w:tcMar>`;
  tcPr += '<w:vAlign w:val="center"/>';
  let p;
  switch (opt.kind) {
    case 'band':
      p = para(text, { jc: 'center', run: { b: true, color: WHITE, sz: 28 } }); break;
    case 'head':
      p = para(text, { jc: 'center', run: { b: true, color: WHITE } }); break;
    case 'light':
      p = para(text, { jc: opt.jc, run: { b: true } }); break;
    default:
      p = para(text, { jc: opt.jc, run: opt.run });
  }
  return `<w:tc><w:tcPr>${tcPr}</w:tcPr>${p}</w:tc>`;
}

/* Do rong cot tinh theo NOI DUNG tung bang. Cong thuc: lay do dai lon nhat nhung
   bi keo ve phia trung binh (avg x 1.6) de 1 o dai bat thuong khong nuot ca bang;
   luon du cho tieu de cot; chan duoi 6 / chan tren 50 "ky tu". Tra ve twips,
   tong = be rong vung in cua template. */
function colWidths(rows, hasHeader) {
  const n = Math.max(...rows.map(r => r.length));
  const plain = s => (s === undefined ? '' : String(s)).replace(/[*`]/g, '');
  const w = [];
  for (let c = 0; c < n; c++) {
    const body = rows.slice(hasHeader ? 1 : 0).map(r => plain(r[c]).length);
    const headLen = hasHeader ? plain(rows[0][c]).length : 0;
    const maxL = body.length ? Math.max(...body) : 0;
    const avgL = body.length ? body.reduce((a, b) => a + b, 0) / body.length : 0;
    const v = Math.max(headLen + 2, Math.min(maxL, avgL * 1.6));
    w.push(Math.min(Math.max(v, 6), 50));
  }
  const tw = scaleTo(w);

  // San toi thieu: cot phai du chua TU DAI NHAT (tieu de dam + noi dung) de Word
  // khong gay chu giua tu (VD "Defaul|t", "ZMM_PG_ZMB|51"). Uoc luong be rong ky tu
  // Myriad Pro 11pt: chu thuong ~105 twips, HOA/so/_ ~140 (ten object SAP toan chu hoa),
  // in dam x1.1, Courier New (`code`) ~132/ky tu; + le o 200.
  const charTw = ch => (/[A-Z0-9_ÀÁẢÃẠĂÂĐÈÉÊÌÍÒÓÔƠÙÚƯÝ]/.test(ch) ? 140 : 105);
  // Word duoc ngat dong sau dau '-' (MSEG-|USNAM_MKPF) nhung khong ngat o '_' hay '/'
  const wordTw = (s, bold) => Math.max(0, ...String(s || '').split(/\s+|(?<=-)/).map(t => {
    const clean = t.replace(/[*`]/g, '');
    if (/`/.test(t)) return clean.length * 132;
    return [...clean].reduce((a, ch) => a + charTw(ch), 0) * (bold ? 1.1 : 1);
  }));
  const minW = [];
  for (let c = 0; c < n; c++) {
    const head = hasHeader ? wordTw(rows[0][c], true) : 0;
    const body = Math.max(0, ...rows.slice(hasHeader ? 1 : 0).map(r => Math.min(wordTw(r[c], false), 22 * 132)));
    minW.push(Math.max(head, body) + 220);
  }
  // tong san vuot kho giay -> chia theo ti le san (cot nao cung it gay chu nhu nhau)
  if (minW.reduce((a, b) => a + b, 0) > PAGE_TWIPS) return scaleTo(minW);
  for (let guard = 0; guard < 20; guard++) {
    const deficit = tw.reduce((s, x, c) => s + Math.max(0, minW[c] - x), 0);
    if (deficit <= 0) break;
    const spare = tw.map((x, c) => Math.max(0, x - minW[c]));
    const spareSum = spare.reduce((a, b) => a + b, 0);
    for (let c = 0; c < n; c++) {
      if (tw[c] < minW[c]) tw[c] = minW[c];
      else tw[c] -= Math.round(deficit * spare[c] / spareSum);
    }
  }
  tw[tw.indexOf(Math.max(...tw))] += PAGE_TWIPS - tw.reduce((a, b) => a + b, 0);
  return tw;
}

// quy doi 1 bo trong so ve twips, tong dung PAGE_TWIPS, moi cot toi thieu ~2.4%
function scaleTo(weights) {
  const sum = weights.reduce((a, b) => a + b, 0);
  const min = Math.round(PAGE_TWIPS * 0.024);
  const tw = weights.map(v => Math.max(min, Math.round(v / sum * PAGE_TWIPS)));
  tw[tw.indexOf(Math.max(...tw))] += PAGE_TWIPS - tw.reduce((a, b) => a + b, 0);
  return tw;
}

function tblOpen(widths, borderColor) {
  const b = k => `<w:${k} w:val="single" w:sz="4" w:space="0" w:color="${borderColor || BORDER}"/>`;
  const total = widths.reduce((a, c) => a + c, 0);
  return `<w:tbl><w:tblPr><w:tblW w:w="${total}" w:type="dxa"/><w:jc w:val="center"/>`
    + `<w:tblBorders>${b('top')}${b('left')}${b('bottom')}${b('right')}${b('insideH')}${b('insideV')}</w:tblBorders>`
    + '<w:tblLayout w:type="fixed"/>'
    + '<w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/>'
    + '</w:tblPr><w:tblGrid>' + widths.map(x => `<w:gridCol w:w="${x}"/>`).join('') + '</w:tblGrid>';
}

/* opt.title   : dong tieu de merge nen teal (bang trang bia)
   opt.header  : dong dau la header cot
   opt.cover   : bang trang bia -> header cot nen F5F5F5 thay vi teal
   opt.label   : bang 2 cot "nhan | gia tri" -> cot 1 nen F5F5F5 chu dam
   opt.widths  : ep do rong (twips); mac dinh tinh theo noi dung
   opt.center  : danh sach index cot can giua
   opt.fill    : to nen moi o du lieu (placeholder anh) */
function table(rows, opt) {
  opt = opt || {};
  const n = Math.max(...rows.map(r => r.length));
  const widths = opt.widths || colWidths(rows, !!opt.header);
  const center = opt.center || [];
  const mar = opt.label ? [60, 120] : [60, 100];
  let body = '';
  if (opt.title) {
    body += `<w:tr><w:trPr><w:jc w:val="center"/></w:trPr>${cell(opt.title, { kind: 'band', span: n, w: PAGE_TWIPS })}</w:tr>`;
  }
  body += rows.map((r, i) => {
    const isHead = opt.header && i === 0;
    const trPr = '<w:trPr>' + (isHead && !opt.cover ? '<w:tblHeader/>' : '') + '<w:jc w:val="center"/></w:trPr>';
    const cells = [];
    for (let c = 0; c < r.length; c++) {
      const span = (r.length < n && c === r.length - 1) ? (n - r.length + 1) : 0;
      const w = span ? widths.slice(c).reduce((a, b) => a + b, 0) : widths[c];
      let kind = null;
      if (isHead) kind = opt.cover ? 'light' : 'head';
      else if (opt.label && c === 0) kind = 'light';
      const jc = isHead || center.includes(c) ? 'center' : null;
      cells.push(cell(r[c] === undefined ? '' : r[c], { kind, span, w, jc, mar, fill: isHead ? null : opt.fill }));
    }
    return `<w:tr>${trPr}${cells.join('')}</w:tr>`;
  }).join('');
  return tblOpen(widths) + body + '</w:tbl>';
}

function codeBlock(lines) {
  const inner = lines.map(l =>
    para('', { spacing: [0, 0], tight: true, runs: [{ t: l, o: { mono: true, codeBlock: true } }] })
  ).join('');
  return tblOpen([PAGE_TWIPS])
    + `<w:tr><w:tc><w:tcPr><w:tcW w:w="${PAGE_TWIPS}" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="${LIGHT}"/>`
    + '<w:tcMar><w:top w:w="60" w:type="dxa"/><w:left w:w="100" w:type="dxa"/><w:bottom w:w="60" w:type="dxa"/><w:right w:w="100" w:type="dxa"/></w:tcMar>'
    + `</w:tcPr>${inner}</w:tc></w:tr></w:tbl>`;
}

// MUC LUC: 1 o nen teal vien teal (dung template) + field TOC 3 cap
function tocBlock() {
  const band = tblOpen([PAGE_TWIPS], TEAL)
    + `<w:tr><w:trPr><w:jc w:val="center"/></w:trPr>${cell('MỤC LỤC', { kind: 'band', w: PAGE_TWIPS, mar: [80, 120] })}</w:tr></w:tbl>`;
  const field = '<w:p><w:pPr><w:spacing w:before="120"/></w:pPr>'
    + '<w:r><w:fldChar w:fldCharType="begin" w:dirty="true"/></w:r>'
    + '<w:r><w:instrText xml:space="preserve"> TOC \\o "1-3" \\h \\z \\u </w:instrText></w:r>'
    + '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
    + `<w:r><w:rPr><w:i/><w:color w:val="808080"/></w:rPr><w:t xml:space="preserve">[Bấm Ctrl+A rồi F9 để sinh mục lục]</w:t></w:r>`
    + '<w:r><w:fldChar w:fldCharType="end"/></w:r></w:p>';
  return pageBreak() + band + field;
}

// ---------------- parse markdown ----------------
// comment HTML <!-- ... --> (huong dan trong template-TS.md) khong bao gio vao file Word
const lines = fs.readFileSync(SRC, 'utf8').replace(/\r/g, '').replace(/<!--[\s\S]*?-->/g, '').split('\n');
const out = [];
let i = 0;
let titleDone = false;
let firstNumberedHeading = true;
let inCode = false, codeBuf = [];
let skipping = false;          // dang o trong 1 section PHU LUC -> bo qua
let droppedAppendix = 0;
let pendingCover = null;       // 'info' | 'log' -> bang ke tiep la bang trang bia
let tocDone = false;

const isTableRow = s => /^\s*\|/.test(s);
const splitRow = s => s.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map(x => x.trim());
const isSep = s => /^\s*\|[\s:|-]+\|\s*$/.test(s);
const isAppendix = t => /^PHỤ\s*LỤC\b/i.test(t);
const isLogNote = s => /^T\s*[-–]\s*(Tạo|Thêm) mới/.test(s.trim());
const isBlockStart = s => /^(#{1,6}\s|\s*[-*]\s|\s*\d+\.\s|\s*>|\s*\||\s*```|\s*---+\s*$)/.test(s);

// do rong 2 bang trang bia lay theo ti le trong template
const INFO_W = scaleTo([2835, 6497]);
const LOG_W = scaleTo([1417, 2551, 3118, 1020, 1224]);

while (i < lines.length) {
  const L = lines[i].replace(/﻿/g, '');

  // --- bo qua toan bo section PHU LUC (TS gui khach khong co phu luc) ---
  const hh = /^(#{1,6})\s+(.*)$/.exec(L);
  if (hh) {
    if (isAppendix(hh[2].trim())) { skipping = true; droppedAppendix++; i++; continue; }
    // heading cung cap hoac cao hon -> ket thuc vung bo qua
    if (skipping && hh[1].length <= 2) skipping = false;
  }
  if (skipping) { i++; continue; }

  // code fence
  if (/^\s*```/.test(L)) {
    if (!inCode) { inCode = true; codeBuf = []; i++; continue; }
    inCode = false;
    out.push(codeBlock(codeBuf));
    out.push(para('', { spacing: [0, 60] }));
    i++; continue;
  }
  if (inCode) { codeBuf.push(L); i++; continue; }

  // bang
  if (isTableRow(L)) {
    const block = [];
    while (i < lines.length && isTableRow(lines[i])) { block.push(lines[i]); i++; }
    let header = false;
    const rows = [];
    block.forEach((b, idx) => {
      if (isSep(b)) { if (idx === 1) header = true; return; }
      rows.push(splitRow(b));
    });
    // bang 2 cot kieu "nhan | gia tri" (hang header rong) -> bo hang header
    if (header && rows.length && rows[0].every(c => c === '')) { rows.shift(); header = false; }

    if (pendingCover === 'info') {
      out.push(table(rows, { title: 'THÔNG TIN TÀI LIỆU', label: true, widths: INFO_W }));
      out.push(para('', { spacing: [0, 120] }));
    } else if (pendingCover === 'log') {
      out.push(table(rows, { title: 'BẢNG GHI NHẬN THAY ĐỔI', header, cover: true, widths: LOG_W, center: [0, 3, 4] }));
    } else {
      out.push(table(rows, { header }));
      out.push(para('', { spacing: [0, 60] }));
    }
    pendingCover = null;
    continue;
  }

  // heading
  if (hh) {
    const lvl = Math.min(3, hh[1].length);
    const txt = hh[2].trim();
    // tieu de trang bia + dong phu de (doan van ngay sau, neu co) + duong ke xanh la
    if (!titleDone && hh[1].length === 1) {
      titleDone = true;
      out.push(para('', { spacing: [0, 240] }));
      out.push(para(txt, { jc: 'center', spacing: [120, 120], run: { b: true, sz: 40 } }));
      let k = i + 1;
      while (k < lines.length && lines[k].trim() === '') k++;
      if (k < lines.length && !isBlockStart(lines[k])) {
        out.push(para(lines[k].trim(), { jc: 'center', spacing: [0, 240], run: { i: true, sz: 32 } }));
        i = k;
      }
      out.push(para('', { bottomLine: true, spacing: [0, 360], indent: 3969, indentRight: 3969 }));
      i++; continue;
    }
    // 2 bang trang bia: tieu de la dong merge nam TRONG bang, khong phai doan van rieng
    if (/^THÔNG TIN TÀI LIỆU$/.test(txt)) { pendingCover = 'info'; i++; continue; }
    if (/^(QUẢN LÝ THAY ĐỔI|BẢNG GHI NHẬN THAY ĐỔI)$/.test(txt)) {
      pendingCover = 'log';
      out.push(pageBreak());
      out.push(para('', { spacing: [0, 120] }));
      i++; continue;
    }
    // bang ghi nhan thay doi khong co dong chu thich -> van phai co muc luc
    if (!tocDone && titleDone) { out.push(tocBlock()); tocDone = true; }
    const stripped = txt.replace(/^\d+(\.\d+)*\.?\s*/, '');
    const opt = { style: 'Heading' + lvl };
    if (firstNumberedHeading && lvl === 1) { opt.pageBreakBefore = true; firstNumberedHeading = false; }
    out.push(para(stripped, opt));
    i++; continue;
  }

  // blockquote
  if (/^\s*>/.test(L)) {
    const buf = [];
    while (i < lines.length && /^\s*>/.test(lines[i])) { buf.push(lines[i].replace(/^\s*>\s?/, '')); i++; }
    let acc = [];
    const flush = () => {
      if (!acc.length) return;
      out.push(para(acc.join(' '), { indent: 340, border: true, run: { i: true }, spacing: [60, 60] }));
      acc = [];
    };
    // placeholder anh co the viet tren nhieu dong '>' -> gop den dong trong / placeholder ke
    let ph = null;
    const flushPh = () => {
      if (ph === null) return;
      out.push(table([[ph]], { fill: LIGHT, widths: [PAGE_TWIPS] }));
      out.push(para('', { spacing: [0, 60] }));
      ph = null;
    };
    buf.forEach(b => {
      if (/📷/.test(b)) { flush(); flushPh(); ph = b.replace(/📷\s*/g, '').trim(); }
      else if (b.trim() === '') { flush(); flushPh(); }
      else if (ph !== null) ph += ' ' + b.trim();
      else acc.push(b);
    });
    flush(); flushPh();
    continue;
  }

  if (/^\s*---+\s*$/.test(L)) { i++; continue; }

  // list
  const li = /^(\s*)([-*]|\d+\.)\s+(.*)$/.exec(L);
  if (li) {
    const lvl = Math.min(4, Math.floor(li[1].length / 3));
    let txt = li[3];
    let bullet;
    if (/^\d+\.$/.test(li[2])) bullet = li[2] + ' ';
    else if (/^\[ \]\s/.test(txt)) { bullet = '☐ '; txt = txt.replace(/^\[ \]\s/, ''); }
    else bullet = '• ';
    i++;
    while (i < lines.length && /^\s{2,}\S/.test(lines[i]) && !/^(\s*)([-*]|\d+\.)\s+/.test(lines[i]) && !isTableRow(lines[i])) {
      txt += ' ' + lines[i].trim(); i++;
    }
    out.push(para('', {
      style: 'ListParagraph',
      indent: 340 + lvl * 340,
      runs: [{ t: bullet, o: { b: /^\d/.test(bullet) } }].concat(runs(txt, {}))
    }));
    continue;
  }

  // doan van thuong
  if (L.trim() === '') { i++; continue; }
  let ptxt = L.trim();
  i++;
  while (i < lines.length && lines[i].trim() !== '' && !isBlockStart(lines[i])) {
    ptxt += ' ' + lines[i].trim(); i++;
  }
  // dong chu thich T/S/X: nam NGOAI bang, in nghieng (dung template), sau do la MUC LUC
  if (isLogNote(ptxt)) {
    out.push(para(ptxt, { spacing: [0, 240], run: { i: true } }));
    if (!tocDone) { out.push(tocBlock()); tocDone = true; }
    continue;
  }
  out.push(para(ptxt, { jc: 'both' }));
}

const xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
  + '<w:document xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
  + 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
  + '<w:body>' + out.join('') + SECTPR + '</w:body></w:document>';

fs.writeFileSync(OUT, xml, 'utf8');
console.log('OK - khoi noi dung:', out.length, '- bytes:', Buffer.byteLength(xml, 'utf8'),
  '- vung in (twips):', PAGE_TWIPS, '- section PHU LUC da bo:', droppedAppendix);
