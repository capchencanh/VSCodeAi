// Sinh FormParameters/head.xml + hierarchy.xml + properties.xml cho 1
// form XLSX Workbench tu 1 khai bao cay don gian bang JS. Da dung
// thanh cong cho form ZCO_PG_CCGTSP_EXL (report ZCO07, HPDQ_ZCO07).
//
// CACH DUNG: sua phan "==== SUA O DAY ====" ben duoi cho dung form
// dang lam, roi chay: node gen_formparams.js <thu_muc_dich>
// (thu_muc_dich se co them subfolder FormParameters/ chua 3 file XML)
//
// Xem SKILL.md muc 2-4 de hieu dung cac truong CB_RELPATH/CB_VAL_RELPATH/
// CB_APR_RELPATH truoc khi sua - sai o day la nguyen nhan pho bien nhat
// khien field khong hien gia tri hoac dong lap khong dung mau.
const fs = require('fs');
const path = require('path');

const OUT = process.argv[2];
if (!OUT) { console.error('Dung: node gen_formparams.js <thu_muc_dich>'); process.exit(1); }

// ==================== SUA O DAY CHO DUNG FORM DANG LAM ====================
const FORMNAME = 'ZCO_PG_CCGTSP_EXL';   // Ten form (khop GC_XLWB_FORM ben ABAP)
const CONTEXTNAME = 'GTY_XLWB';         // Ten context - chi de mo ta, khong can la DDIC type that

// Cay node: goi addNode(...) theo THU TU ANH EM (thu tu khai bao =
// thu tu hien thi/render trong cung 1 cha). CHILD/NEXT/TLEVEL duoc tu
// dong tinh o cuoi file - khong tu dien tay.
//
//   comp_type: 'R' root | 'S' sheet | 'P' pattern (vung o) | 'F' field (1 o)
//              | 'L' loopstep (lap qua 1 table)
//   cb_relpath      : CHI dat cho node Loop ('L') - vd `${CONTEXTNAME}-TABLE_DATA`
//   cb_val_relpath  : CHI dat cho node Field ('F') - vd `${CONTEXTNAME}-H_WERKS`
//                     hoac (trong loop) `LINE-<TEN_FIELD>` (chu LINE la BAT BUOC,
//                     xem SKILL.md muc 2)
//   cb_apr_relpath  : (tuy chon, thuong dat cho Pattern con cua 1 Loop) -
//                     dieu kien hien: node CHI hien khi field nay khac rong.
//                     Dung `LINE-<CO_RIENG>` voi 1 co boolean rieng cho MOI
//                     Pattern anh em muon chon 1-trong-N khi lap.
//   top/left/rows/cols : toa do 1-based tren sheet1.xml (row/col)
//   sheetname       : CHI dat cho node Sheet ('S')
//   loop_from/loop_to: CHI dat cho node Loop ('L') - thuong 1 va 0 (khong gioi han)

let nextId = 1;
const nodes = [];
function addNode(n) { n.id = nextId++; nodes.push(n); return n.id; }

const rootId = addNode({ comp_type: 'R', comp_name: FORMNAME, cb_relpath: CONTEXTNAME, name: FORMNAME });
const sheetId = addNode({ parent: rootId, comp_type: 'S', comp_name: 'SHEET', sheetname: 'Sheet1' });

// --- Vi du: khoi header (khong loop) ---
const headerId = addNode({ parent: sheetId, comp_type: 'P', comp_name: 'HEADER', top: 1, left: 1, rows: 9, cols: 5 });
const headerFields = [
  { name: 'PLANT', val: 'H_WERKS', top: 1, left: 1, rows: 1, cols: 5 },
  { name: 'PERIOD', val: 'H_PERIOD', top: 3, left: 1, rows: 1, cols: 5 },
  // ... them field khac theo cung mau
];
for (const f of headerFields) {
  addNode({ parent: headerId, comp_type: 'F', comp_name: f.name, cb_val_relpath: `${CONTEXTNAME}-${f.val}`, top: f.top, left: f.left, rows: f.rows, cols: f.cols });
}

// --- Vi du: loop voi N mau dong dieu kien theo co FL_* ---
const listId = addNode({ parent: sheetId, comp_type: 'L', comp_name: 'TABLES', cb_relpath: `${CONTEXTNAME}-TABLE_DATA`, loop_from: 1, loop_to: 0 });
const lineStyles = [
  { name: 'LINE_A', flag: 'FL_A', top: 13 },
  { name: 'LINE_B', flag: 'FL_B', top: 14 },
];
const lineCols = [
  { name: 'COL1', val: 'FIELD1', left: 1 },
  { name: 'COL2', val: 'FIELD2', left: 2 },
];
for (const ls of lineStyles) {
  const pId = addNode({ parent: listId, comp_type: 'P', comp_name: ls.name, cb_apr_relpath: `LINE-${ls.flag}`, top: ls.top, left: 1, rows: 1, cols: lineCols.length });
  for (const c of lineCols) {
    addNode({ parent: pId, comp_type: 'F', comp_name: `${ls.name}_${c.name}`, cb_val_relpath: `LINE-${c.val}`, top: ls.top, left: c.left, rows: 1, cols: 1 });
  }
}
// ==================== HET PHAN CAN SUA ====================

function pad(n) { return String(n).padStart(6, '0'); }
function xesc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }

// Tinh CHILD/NEXT tu thu tu khai bao (anh em)
const byParent = {};
for (const n of nodes) if (n.parent) (byParent[n.parent] = byParent[n.parent] || []).push(n.id);
for (const n of nodes) {
  const siblings = n.parent ? byParent[n.parent] : [];
  const idx = siblings.indexOf(n.id);
  n.child = (byParent[n.id] || [])[0] || 0;
  n.next = (idx >= 0 && idx < siblings.length - 1) ? siblings[idx + 1] : 0;
}
const levelOf = {};
(function computeLevel(id, lvl) { levelOf[id] = lvl; for (const c of (byParent[id] || [])) computeLevel(c, lvl + 1); })(rootId, 1);

// ---- hierarchy.xml ----
const hierAttrs = ["ID", "TYPE", "NAME", "TLEVEL", "LINK", "COMPRESS", "LEAF", "TLOCK", "PARENT", "CHILD", "NEXT", "NLENGTH", "COLOR", "INTENSIV", "TEXT", "TLENGTH", "TCOLOR", "TINTENSIV", "TPOS", "KIND", "TEXT1", "TLENGTH1", "TCOLOR1", "TINTENSIV1", "TPOS1", "KIND1", "TEXT2", "TLENGTH2", "TCOLOR2", "TINTENSIV2", "TPOS2", "KIND2", "TEXT3", "TLENGTH3", "TCOLOR3", "TINTENSIV3", "TPOS3", "KIND3", "TEXT4", "TLENGTH4", "TCOLOR4", "TINTENSIV4", "TPOS4", "KIND4", "TEXT5", "TLENGTH5", "TCOLOR5", "TINTENSIV5", "TPOS5", "KIND5", "TEXT6", "TLENGTH6", "TCOLOR6", "TINTENSIV6", "TPOS6", "KIND6", "TEXT7", "TLENGTH7", "TCOLOR7", "TINTENSIV7", "TPOS7", "KIND7", "TEXT8", "TLENGTH8", "TCOLOR8", "TINTENSIV8", "TPOS8", "KIND8", "TEXT9", "TLENGTH9", "TCOLOR9", "TINTENSIV9", "TPOS9", "KIND9", "HIDE", "FORCE_PLUS", "HOTSPOT", "HOTSPOT1", "HOTSPOT2", "HOTSPOT3", "HOTSPOT4", "HOTSPOT5", "HOTSPOT6", "HOTSPOT7", "HOTSPOT8", "HOTSPOT9", "INPUT", "INPUT1", "INPUT2", "INPUT3", "INPUT4", "INPUT5", "INPUT6", "INPUT7", "INPUT8", "INPUT9", "NODISPLAY", "MOREINFO", "PROPFAW0", "PROPFAW", "PROPFAW1", "PROPFAW2", "PROPFAW3", "PROPFAW4", "PROPFAW5", "PROPFAW6", "PROPFAW7", "PROPFAW8", "PROPFAW9", "STYLE0", "STYLE", "STYLE1", "STYLE2", "STYLE3", "STYLE4", "STYLE5", "STYLE6", "STYLE7", "STYLE8", "STYLE9", "NODEICON", "LASTHTEXT"];
const hierDefault = (a) => (a === 'NLENGTH' || a.startsWith('TLENGTH') || a.startsWith('STYLE')) ? '00' : (a === 'COLOR' || a.startsWith('TCOLOR')) ? '0' : '';

let hierXml = '<?xml version="1.0" encoding="utf-8" standalone="yes"?><table>';
for (const n of nodes) {
  const vals = {}; for (const a of hierAttrs) vals[a] = hierDefault(a);
  vals.ID = pad(n.id); vals.TLEVEL = String(levelOf[n.id]).padStart(2, '0');
  vals.PARENT = pad(n.parent || 0); vals.CHILD = pad(n.child || 0); vals.NEXT = pad(n.next || 0);
  if (n.name) vals.NAME = n.name;
  hierXml += '<row ' + hierAttrs.map((a) => `${a}="${xesc(vals[a])}"`).join(' ') + '/>';
}
hierXml += '</table>';

// ---- properties.xml ----
const propAttrs = ["ID", "COMP_TYPE", "COMP_NAME", "COMP_DESCR", "CB_LOOP_FROM", "CB_LOOP_TO", "CB_RELPATH", "CB_APR_RELPATH", "CB_APR_OFFSET", "CB_APR_MATCH", "CB_CELLRNG_RELPATH", "CB_CELLRNG_OFFSET", "CB_CELLRNG_MATCH", "CB_VAL_RELPATH", "CB_VAL_SUB_REQ", "CB_VAL_SUB_COL", "CB_VAL_SUB_ROW", "CB_VAL_OFFSET", "CB_VAL_MATCH", "CB_VAL_CONVERT", "CB_VALVLD_ATTR_RELPATH", "CB_VALVLD_FOR1_DATASET_ID", "CB_VALVLD_FOR1_DATASET_FLD", "CB_VALVLD_FOR1_RELPATH", "CB_VALVLD_FOR2_RELPATH", "TB_VAL_FORMULA", "TB_VAL_MATRIX", "TB_VAL_MATR_R", "TB_VAL_MATR_C", "TB_AREA_TEXTMARK", "TB_AREA_TOP", "TB_AREA_LEFT", "TB_AREA_ROWS", "TB_AREA_COLUMNS", "TB_SHEETNAME", "TB_SHEETSTATE", "TB_SHEETPROTECTION", "TB_DIRECTION", "TB_ROWPROP", "TB_COLPROP", "TB_ROWGROUP", "TB_ROWGROUP_CLP", "TB_COLGROUP", "TB_COLGROUP_CLP", "TB_DRWSTAT_FLAG", "TB_DRWSTAT_NAME", "TB_NOPGBRK_TOP", "TB_NOPGBRK_TOP_SHIFT", "TB_NOPGBRK_LEFT", "TB_NOPGBRK_LEFT_SHIFT", "TB_PGBRK_TOP", "TB_PGBRK_LEFT", "TB_PRINTTITLES_R", "TB_PRINTTITLES_C", "TB_AUTOFITMERGED_R", "TB_AUTOFITMERGED_C", "TB_MERGECELLS", "TREE_LAYOUT", "GRID_LAYOUT", "GRID_FLDSEQ", "GRID_FLDPROP", "DRAFT_SUBTREE", "DATASET_ID", "DATASET_SERIES", "CHART_SERIES_TITLE", "CHART_TITLE", "CHART_TITLE_RELPATH", "CHART_CATAX_TITLE", "CHART_CATAX_TITLE_RELPATH", "CHART_VALAX_TITLE", "CHART_VALAX_TITLE_RELPATH", "DRAWING_SIZE", "DRAWING_SIZE_H_RELPATH", "DRAWING_SIZE_W_RELPATH", "POSTPROC_VBS_CODE", "POSTPROC_VBS_TABLES", "DEFINEDNAMES_DONT_REMOVE"];
const propDefault = (a) => (['CB_LOOP_FROM', 'CB_LOOP_TO', 'CB_APR_OFFSET', 'CB_APR_MATCH', 'CB_CELLRNG_OFFSET', 'CB_CELLRNG_MATCH', 'CB_VAL_SUB_ROW', 'CB_VAL_OFFSET', 'CB_VAL_MATCH', 'TB_VAL_MATR_R', 'TB_VAL_MATR_C', 'TB_AREA_TOP', 'TB_AREA_LEFT', 'TB_AREA_ROWS', 'TB_AREA_COLUMNS', 'TB_NOPGBRK_TOP_SHIFT', 'TB_NOPGBRK_LEFT_SHIFT'].includes(a)) ? '0' : (['CB_VALVLD_FOR1_DATASET_ID', 'TB_PRINTTITLES_R', 'TB_PRINTTITLES_C', 'DATASET_ID'].includes(a)) ? '000000' : '';

let propXml = '<?xml version="1.0" encoding="utf-8" standalone="yes"?><table>';
for (const n of nodes) {
  const vals = {}; for (const a of propAttrs) vals[a] = propDefault(a);
  vals.ID = pad(n.id); vals.COMP_TYPE = n.comp_type; vals.COMP_NAME = n.comp_name || '';
  if (n.cb_relpath) vals.CB_RELPATH = n.cb_relpath;
  if (n.cb_apr_relpath) vals.CB_APR_RELPATH = n.cb_apr_relpath;
  if (n.cb_val_relpath) vals.CB_VAL_RELPATH = n.cb_val_relpath;
  if (n.loop_from !== undefined) vals.CB_LOOP_FROM = String(n.loop_from);
  if (n.loop_to !== undefined) vals.CB_LOOP_TO = String(n.loop_to);
  if (n.top !== undefined) vals.TB_AREA_TOP = String(n.top);
  if (n.left !== undefined) vals.TB_AREA_LEFT = String(n.left);
  if (n.rows !== undefined) vals.TB_AREA_ROWS = String(n.rows);
  if (n.cols !== undefined) vals.TB_AREA_COLUMNS = String(n.cols);
  if (n.sheetname) vals.TB_SHEETNAME = n.sheetname;
  propXml += '<row ' + propAttrs.map((a) => `${a}="${xesc(vals[a])}"`).join(' ') + '/>';
}
propXml += '</table>';

// ---- head.xml ----
const today = '20260101'; // SUA lai ngay that neu can chinh xac (Date.now bi cam trong workflow script, khong bi cam o day)
const headXml = `<?xml version="1.0" encoding="utf-8" standalone="yes"?><row FORMNAME="${FORMNAME}" FORMDESCR="" CONTEXTNAME="${CONTEXTNAME}" ACTIVE="X" ROOT_ID="000001" CREATED_UNAME="CS_ClaudeAI" CREATED_DATUM="${today}" CHANGED_UNAME="CS_ClaudeAI" CHANGED_DATUM="${today}"/>`;

fs.mkdirSync(path.join(OUT, 'FormParameters'), { recursive: true });
fs.writeFileSync(path.join(OUT, 'FormParameters', 'head.xml'), headXml, 'utf8');
fs.writeFileSync(path.join(OUT, 'FormParameters', 'hierarchy.xml'), hierXml, 'utf8');
fs.writeFileSync(path.join(OUT, 'FormParameters', 'properties.xml'), propXml, 'utf8');

console.log('OK -', nodes.length, 'node, da ghi vao', path.join(OUT, 'FormParameters'));
console.log('NHO: con phai tu tao xl/worksheets/sheet1.xml (layout + style) khop dung');
console.log('toa do TB_AREA_TOP/LEFT cua tung node F/P o tren, va cac phan con lai cua');
console.log('file .xlsx (styles.xml, workbook.xml, rels, Content_Types...) - lay tu 1');
console.log('file .xlsx ZXLWB dang hoat dong tot lam mau roi dong goi lai bang zipwriter.js.');
