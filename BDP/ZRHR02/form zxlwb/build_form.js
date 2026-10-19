// Sinh form ZXLWB ZXL_SD_DSNVBH cho report ZRHR02
// Bo attribute lay tu form that cua he BDP: ZXLSX_SD_ZUTGB02_TNTT.xlsx
// (properties 79 attribute, hierarchy 122 attribute)
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const FORMNAME = 'ZXL_SD_DSNVBH';
const CONTEXT = 'ZST_SD_DSNVBH';

// ---------------------------------------------------------------- template
const PROP_TPL = {
  ID: '', COMP_TYPE: '', COMP_NAME: '', COMP_DESCR: '',
  CB_LOOP_FROM: '0 ', CB_LOOP_TO: '0 ', CB_RELPATH: '',
  CB_APR_RELPATH: '', CB_APR_OFFSET: '0 ', CB_APR_MATCH: '0 ',
  CB_CELLRNG_RELPATH: '', CB_CELLRNG_OFFSET: '0 ', CB_CELLRNG_MATCH: '0 ',
  CB_VAL_RELPATH: '', CB_VAL_SUB_REQ: '', CB_VAL_SUB_COL: '',
  CB_VAL_SUB_ROW: '0 ', CB_VAL_OFFSET: '0 ', CB_VAL_MATCH: '0 ',
  CB_VAL_CONVERT: '', CB_VALVLD_ATTR_RELPATH: '',
  CB_VALVLD_FOR1_DATASET_ID: '000000', CB_VALVLD_FOR1_DATASET_FLD: '',
  CB_VALVLD_FOR1_RELPATH: '', CB_VALVLD_FOR2_RELPATH: '',
  TB_VAL_FORMULA: '', TB_VAL_MATRIX: '', TB_VAL_MATR_R: '0 ', TB_VAL_MATR_C: '0 ',
  TB_AREA_TEXTMARK: '', TB_AREA_TOP: '0 ', TB_AREA_LEFT: '0 ',
  TB_AREA_ROWS: '0 ', TB_AREA_COLUMNS: '0 ',
  TB_SHEETNAME: '', TB_SHEETSTATE: '', TB_SHEETPROTECTION: '',
  TB_DIRECTION: '', TB_ROWPROP: '', TB_COLPROP: '',
  TB_ROWGROUP: '', TB_ROWGROUP_CLP: '', TB_COLGROUP: '', TB_COLGROUP_CLP: '',
  TB_DRWSTAT_FLAG: '', TB_DRWSTAT_NAME: '',
  TB_NOPGBRK_TOP: '', TB_NOPGBRK_TOP_SHIFT: '0 ',
  TB_NOPGBRK_LEFT: '', TB_NOPGBRK_LEFT_SHIFT: '0 ',
  TB_PGBRK_TOP: '', TB_PGBRK_LEFT: '',
  TB_PRINTTITLES_R: '000000', TB_PRINTTITLES_C: '000000',
  TB_AUTOFITMERGED_R: '', TB_AUTOFITMERGED_C: '', TB_MERGECELLS: '',
  TB_RESPATTERN_PLACE: '', TB_KEEP_FORMULAS: '',
  TREE_LAYOUT: '', GRID_LAYOUT: '', GRID_FLDSEQ: '', GRID_FLDPROP: '',
  DRAFT_SUBTREE: '', DATASET_ID: '000000', DATASET_SERIES: '',
  CHART_SERIES_TITLE: '', CHART_TITLE: '', CHART_TITLE_RELPATH: '',
  CHART_CATAX_TITLE: '', CHART_CATAX_TITLE_RELPATH: '',
  CHART_VALAX_TITLE: '', CHART_VALAX_TITLE_RELPATH: '',
  DRAWING_SIZE: '', DRAWING_SIZE_H_RELPATH: '', DRAWING_SIZE_W_RELPATH: '',
  POSTPROC_VBS_CODE: '', POSTPROC_VBS_TABLES: '', DEFINEDNAMES_DONT_REMOVE: '',
};

const HIER_TPL = (() => {
  const o = { ID: '', TYPE: '', NAME: '', TLEVEL: '01', LINK: '', COMPRESS: '',
    LEAF: '', TLOCK: '', PARENT: '000000', CHILD: '000000', NEXT: '000000',
    NLENGTH: '00', COLOR: '0', INTENSIV: '', TEXT: '', TLENGTH: '00',
    TCOLOR: '0', TINTENSIV: '', TPOS: '', KIND: '' };
  for (let i = 1; i <= 9; i++) {
    o['TEXT' + i] = ''; o['TLENGTH' + i] = '00'; o['TCOLOR' + i] = '0';
    o['TINTENSIV' + i] = ''; o['TPOS' + i] = ''; o['KIND' + i] = '';
  }
  o.HIDE = ''; o.FORCE_PLUS = ''; o.HOTSPOT = '';
  for (let i = 1; i <= 9; i++) o['HOTSPOT' + i] = '';
  o.INPUT = '';
  for (let i = 1; i <= 9; i++) o['INPUT' + i] = '';
  o.NODISPLAY = ''; o.MOREINFO = ''; o.PROPFAW0 = ''; o.PROPFAW = '';
  for (let i = 1; i <= 9; i++) o['PROPFAW' + i] = '';
  o.STYLE0 = '00'; o.STYLE = '00';
  for (let i = 1; i <= 9; i++) o['STYLE' + i] = '00';
  o.NODEICON = ''; o.LASTHTEXT = '';
  return o;
})();

// ---------------------------------------------------------------- cay node
// 14 cot theo FS muc 2.4 (STT khong in trong form ky duyet van giu de dong bo)
const COLS = ['STT', 'PERNR', 'PARVW', 'ENAME', 'ORGEH_TX', 'ORGEH',
              'VKBUR_TX', 'VKBUR', 'PLANS_TX', 'PLANS', 'PERIOD',
              'SPGRP_TX', 'SPGRP', 'NETWR'];

const HDR_FIELDS = ['COMPANY', 'BRANCH', 'TITLE', 'PERIOD', 'DECIDE'];

const nodes = [];
let seq = 0;
const nid = () => String(++seq).padStart(6, '0');

const ROOT = nid();
nodes.push({ id: ROOT, parent: '000000', p: { COMP_TYPE: 'R', COMP_NAME: FORMNAME, CB_RELPATH: CONTEXT } });

const SHEET = nid();
nodes.push({ id: SHEET, parent: ROOT, p: { COMP_TYPE: 'S', COMP_NAME: 'SHEET', TB_SHEETNAME: 'Sheet1' } });

// Pattern HEADER: dong 1..7 (tieu de + phan tieu de cot)
const PHEAD = nid();
nodes.push({ id: PHEAD, parent: SHEET, p: {
  COMP_TYPE: 'P', COMP_NAME: 'HEADER',
  TB_AREA_TOP: '1 ', TB_AREA_LEFT: '1 ', TB_AREA_ROWS: '7 ', TB_AREA_COLUMNS: '14 ' } });

HDR_FIELDS.forEach(f => {
  nodes.push({ id: nid(), parent: PHEAD, p: {
    COMP_TYPE: 'F', COMP_NAME: f,
    CB_VAL_RELPATH: `${CONTEXT}-${f}`, TB_AREA_TEXTMARK: `[${f}]` } });
});

// Loop ITEM
const LOOP = nid();
nodes.push({ id: LOOP, parent: SHEET, p: {
  COMP_TYPE: 'L', COMP_NAME: 'ITEM',
  CB_RELPATH: `${CONTEXT}-ITEM`, CB_LOOP_FROM: '1 ' } });

// Pattern LINE: dong 8, 14 cot
const PLINE = nid();
nodes.push({ id: PLINE, parent: LOOP, p: {
  COMP_TYPE: 'P', COMP_NAME: 'LINE',
  TB_AREA_TOP: '8 ', TB_AREA_LEFT: '1 ', TB_AREA_ROWS: '1 ', TB_AREA_COLUMNS: '14 ' } });

COLS.forEach(f => {
  nodes.push({ id: nid(), parent: PLINE, p: {
    COMP_TYPE: 'F', COMP_NAME: f,
    CB_VAL_RELPATH: `LINE-${f}`, TB_AREA_TEXTMARK: `[${f}]` } });
});

// Pattern FOOTER: phan ky duyet, dong 10..13
const PFOOT = nid();
nodes.push({ id: PFOOT, parent: SHEET, p: {
  COMP_TYPE: 'P', COMP_NAME: 'FOOTER',
  TB_AREA_TOP: '10 ', TB_AREA_LEFT: '1 ', TB_AREA_ROWS: '4 ', TB_AREA_COLUMNS: '14 ' } });

// -------------------------------------------------- tinh CHILD/NEXT/TLEVEL
const byId = {};
nodes.forEach(n => { byId[n.id] = n; n.children = []; });
nodes.forEach(n => { if (byId[n.parent]) byId[n.parent].children.push(n.id); });

function setLevel(id, lv) {
  const n = byId[id];
  n.tlevel = String(lv).padStart(2, '0');
  n.children.forEach(c => setLevel(c, lv + 1));
}
setLevel(ROOT, 1);

nodes.forEach(n => {
  n.child = n.children.length ? n.children[0] : '000000';
  const sib = byId[n.parent] ? byId[n.parent].children : [];
  const i = sib.indexOf(n.id);
  n.next = (i >= 0 && i + 1 < sib.length) ? sib[i + 1] : '000000';
});

// ---------------------------------------------------------------- sinh XML
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
  .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const attrs = o => Object.entries(o).map(([k, v]) => `${k}="${esc(v)}"`).join(' ');
const XMLHEAD = '<?xml version="1.0" encoding="utf-8" standalone="yes"?>';

const propsXml = XMLHEAD + '<table>' + nodes.map(n =>
  `<row ${attrs({ ...PROP_TPL, ...n.p, ID: n.id })}/>`).join('') + '</table>';

const hierXml = XMLHEAD + '<table>' + nodes.map(n =>
  `<row ${attrs({ ...HIER_TPL, ID: n.id, NAME: n.id === ROOT ? FORMNAME : '',
    TLEVEL: n.tlevel, PARENT: n.parent, CHILD: n.child, NEXT: n.next })}/>`).join('') + '</table>';

const today = new Date();
const dt = today.getFullYear() + String(today.getMonth() + 1).padStart(2, '0') +
           String(today.getDate()).padStart(2, '0');
const headXml = XMLHEAD + `<row FORMNAME="${FORMNAME}" FORMDESCR="Bao cao doanh so nhan vien ban hang" ` +
  `CONTEXTNAME="${CONTEXT}" ACTIVE="X" ROOT_ID="${ROOT}" ` +
  `CREATED_UNAME="CT.CSTECH" CREATED_DATUM="${dt}" CHANGED_UNAME="CT.CSTECH" CHANGED_DATUM="${dt}"/>`;

// ---------------------------------------------------------------- sheet1
const HDR_TEXT = [
  'CÔNG TY CP DƯỢC - TTBYT BÌNH ĐỊNH',
  '[BRANCH]',
  '[TITLE]',
  '[PERIOD]',
  '[DECIDE]',
];
const COL_TITLE = ['STT', 'Mã Nhân Viên', 'Partner Function', 'Tên Nhân Viên',
  'Tên Phòng Ban/ Chi Nhánh (HRM)', 'Mã Phòng Ban/ Mã Chi Nhánh (HRM)',
  'Tên Phòng Ban/ Chi Nhánh (SAP)', 'Mã Phòng Ban/ Mã Chi Nhánh (SAP)',
  'Vị Trí Công Việc', 'Mã VTCV', 'Tháng Áp Dụng',
  'Nhóm Sản Phẩm', 'Mã Nhóm Sản Phẩm', 'Doanh Số'];
const SIGN_TITLE = ['Kế toán trưởng công ty', 'NV quyết toán', 'Quản lý bộ phận', 'Người lập biểu'];

const shared = [];
const sid = t => { let i = shared.indexOf(t); if (i < 0) { shared.push(t); i = shared.length - 1; } return i; };

const colLetter = n => { let s = ''; while (n > 0) { const m = (n - 1) % 26; s = String.fromCharCode(65 + m) + s; n = (n - m - 1) / 26; } return s; };
const rows = [];
const cell = (r, c, txt, style) => `<c r="${colLetter(c)}${r}" s="${style}" t="s"><v>${sid(txt)}</v></c>`;

// dong 1-5: tieu de (style 1 = dam, giua)
HDR_TEXT.forEach((t, i) => {
  rows.push(`<row r="${i + 1}">${cell(i + 1, 1, t, i === 2 ? 2 : 1)}</row>`);
});
rows.push('<row r="6"/>');
// dong 7: tieu de cot (style 3 = dam, vien, giua)
rows.push(`<row r="7">${COL_TITLE.map((t, i) => cell(7, i + 1, t, 3)).join('')}</row>`);
// dong 8: mau du lieu (style 4 = vien)
rows.push(`<row r="8">${COLS.map((f, i) => cell(8, i + 1, `[${f}]`, i === 13 ? 5 : 4)).join('')}</row>`);
rows.push('<row r="9"/>');
// dong 10-13: phan ky duyet
rows.push(`<row r="10">${SIGN_TITLE.map((t, i) => cell(10, i * 4 + 1, t, 1)).join('')}</row>`);
rows.push('<row r="11"/>', '<row r="12"/>', '<row r="13"/>');

const sheetXml = XMLHEAD +
  '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
  '<sheetPr><pageSetUpPr fitToPage="1"/></sheetPr>' +
  '<dimension ref="A1:N13"/><sheetViews><sheetView tabSelected="1" workbookViewId="0"/></sheetViews>' +
  '<sheetFormatPr defaultRowHeight="15"/>' +
  '<cols><col min="1" max="1" width="6" customWidth="1"/>' +
  '<col min="2" max="2" width="14" customWidth="1"/>' +
  '<col min="3" max="3" width="18" customWidth="1"/>' +
  '<col min="4" max="4" width="28" customWidth="1"/>' +
  '<col min="5" max="5" width="30" customWidth="1"/>' +
  '<col min="6" max="6" width="18" customWidth="1"/>' +
  '<col min="7" max="7" width="30" customWidth="1"/>' +
  '<col min="8" max="8" width="18" customWidth="1"/>' +
  '<col min="9" max="9" width="24" customWidth="1"/>' +
  '<col min="10" max="10" width="12" customWidth="1"/>' +
  '<col min="11" max="11" width="14" customWidth="1"/>' +
  '<col min="12" max="12" width="28" customWidth="1"/>' +
  '<col min="13" max="13" width="16" customWidth="1"/>' +
  '<col min="14" max="14" width="18" customWidth="1"/></cols>' +
  '<sheetData>' + rows.join('') + '</sheetData>' +
  '<mergeCells count="9">' +
  [1, 2, 3, 4, 5].map(r => `<mergeCell ref="A${r}:N${r}"/>`).join('') +
  '<mergeCell ref="A10:D10"/><mergeCell ref="E10:H10"/>' +
  '<mergeCell ref="I10:K10"/><mergeCell ref="L10:N10"/>' +
  '</mergeCells>' +
  '<pageMargins left="0.59" right="0.59" top="0.59" bottom="0.59" header="0.3" footer="0.3"/>' +
  '<pageSetup paperSize="9" orientation="landscape" fitToWidth="1" fitToHeight="0"/>' +
  '</worksheet>';

const sharedXml = XMLHEAD +
  `<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${shared.length}" uniqueCount="${shared.length}">` +
  shared.map(t => `<si><t xml:space="preserve">${esc(t)}</t></si>`).join('') + '</sst>';

// style: 0 thuong | 1 dam-giua | 2 dam 16-giua | 3 header cot | 4 o du lieu | 5 o so
const stylesXml = XMLHEAD +
  '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
  '<numFmts count="1"><numFmt numFmtId="164" formatCode="#,##0"/></numFmts>' +
  '<fonts count="3">' +
  '<font><sz val="10"/><name val="Times New Roman"/></font>' +
  '<font><b/><sz val="10"/><name val="Times New Roman"/></font>' +
  '<font><b/><sz val="16"/><name val="Times New Roman"/></font>' +
  '</fonts>' +
  '<fills count="2"><fill><patternFill patternType="none"/></fill>' +
  '<fill><patternFill patternType="gray125"/></fill></fills>' +
  '<borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border>' +
  '<border><left style="thin"/><right style="thin"/><top style="thin"/><bottom style="thin"/><diagonal/></border></borders>' +
  '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
  '<cellXfs count="6">' +
  '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' +
  '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment horizontal="center"/></xf>' +
  '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment horizontal="center"/></xf>' +
  '<xf numFmtId="0" fontId="1" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>' +
  '<xf numFmtId="49" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1"/>' +
  '<xf numFmtId="164" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right"/></xf>' +
  '</cellXfs>' +
  '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>' +
  '</styleSheet>';

const files = {
  '[Content_Types].xml': XMLHEAD +
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
    '<Default Extension="xml" ContentType="application/xml"/>' +
    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
    '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
    '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>' +
    '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
    '</Types>',
  '_rels/.rels': XMLHEAD +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
    '</Relationships>',
  'xl/workbook.xml': XMLHEAD +
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" ' +
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
    '<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>',
  'xl/_rels/workbook.xml.rels': XMLHEAD +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>' +
    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>' +
    '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' +
    '</Relationships>',
  'xl/worksheets/sheet1.xml': sheetXml,
  'xl/sharedStrings.xml': sharedXml,
  'xl/styles.xml': stylesXml,
  'FormParameters/head.xml': headXml,
  'FormParameters/hierarchy.xml': hierXml,
  'FormParameters/properties.xml': propsXml,
};

// Ghi ra thu muc tam roi dong goi bang zipwriter (khong dung Compress-Archive)
const stage = path.join(__dirname, '.stage');
fs.rmSync(stage, { recursive: true, force: true });
Object.entries(files).forEach(([rel, content]) => {
  const full = path.join(stage, rel);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, content, 'utf8');
});

const out = path.join(__dirname, FORMNAME + '.xlsx');
execFileSync(process.execPath, [path.join(__dirname, 'zipwriter.js'), stage, out],
             { stdio: 'inherit' });
fs.rmSync(stage, { recursive: true, force: true });

console.log('So node:', nodes.length, '| shared strings:', shared.length);
