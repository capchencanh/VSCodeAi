/* Va cac part cua package .docx sau khi da copy template: header theo du an + metadata.

   Header template la bang 3 o:  [logo Citek] [2 dong chu dich vu] [logo khach hang]
   Dong 2 co dang "QUAN TRI DOANH NGHIEP SAP S/4HANA TAI <CONG TY KHACH HANG>".
   Ten cong ty va logo khach thay doi theo TUNG DU AN -> khong duoc giu cua template.

   Cach dung:
     node patch-package.js <thu-muc-giai-nen> --md <file.md> [--name "<CONG TY ...>"] [--logo <anh.png|jpg>]

   <thu-muc-giai-nen> chua dung duong dan trong zip:
     word/header*.xml, word/_rels/header*.xml.rels, [Content_Types].xml, docProps/core.xml
   Script sua tai cho va co the THEM file word/media/customer_logo.<ext>.

   - Khong co --name : ghi placeholder [TÊN CÔNG TY KHÁCH HÀNG] + canh bao (khong giu ten
                       khach cua template - lo thong tin du an khac).
   - Khong co --logo : bo logo khach cua template, o ben phai de trong + canh bao.
   - core.xml        : title = ten bao cao, creator = nguoi thiet ke (lay tu bang
                       THONG TIN TAI LIEU trong .md), xoa description cu cua template. */
const fs = require('fs');
const path = require('path');

const dir = process.argv[2];
const arg = k => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : undefined; };
const mdPath = arg('--md');
let name = arg('--name');
const logo = arg('--logo');
if (!dir || !fs.existsSync(dir)) { console.error('Khong tim thay thu muc:', dir); process.exit(1); }

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const rd = p => fs.readFileSync(path.join(dir, p), 'utf8');
const wr = (p, s) => fs.writeFileSync(path.join(dir, p), s, 'utf8');
const warn = [];

if (!name || !name.trim()) { name = '[TÊN CÔNG TY KHÁCH HÀNG]'; warn.push('Chua truyen -CustomerName -> header dang la placeholder [TÊN CÔNG TY KHÁCH HÀNG]'); }
name = name.trim().toLocaleUpperCase('vi-VN');

/** Tim khoi <w:r ...> ... </w:r> bao quanh vi tri idx. Tra [start,end] hoac null. */
function runAround(xml, idx) {
  let s = -1;
  for (let p = idx; p >= 0; p--) {
    if (xml[p] === '<' && xml.startsWith('<w:r', p)) {
      const c = xml[p + 4];
      if (c === '>' || c === ' ') { s = p; break; }
    }
  }
  if (s === -1) return null;
  const e = xml.indexOf('</w:r>', idx);
  return e === -1 ? null : [s, e + 6];
}

/** Kich thuoc anh PNG/JPEG (px). */
function imageSize(buf) {
  if (buf.readUInt32BE(0) === 0x89504E47) return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) };
  if (buf[0] === 0xFF && buf[1] === 0xD8) {
    let p = 2;
    while (p < buf.length) {
      if (buf[p] !== 0xFF) { p++; continue; }
      const mk = buf[p + 1];
      if (mk >= 0xC0 && mk <= 0xCF && mk !== 0xC4 && mk !== 0xC8 && mk !== 0xCC) {
        return { h: buf.readUInt16BE(p + 5), w: buf.readUInt16BE(p + 7) };
      }
      p += 2 + buf.readUInt16BE(p + 2);
    }
  }
  return null;
}

let logoBuf = null, logoExt = null, logoSize = null;
if (logo) {
  if (!fs.existsSync(logo)) { console.error('Khong tim thay file logo:', logo); process.exit(1); }
  logoBuf = fs.readFileSync(logo);
  logoSize = imageSize(logoBuf);
  logoExt = /\.jpe?g$/i.test(logo) ? 'jpeg' : 'png';
  if (!logoSize) { console.error('Logo phai la PNG hoac JPEG:', logo); process.exit(1); }
}

// ---------- header ----------
const wordDir = path.join(dir, 'word');
let nameHit = 0;
for (const f of fs.readdirSync(wordDir).filter(f => /^header\d*\.xml$/.test(f))) {
  const rel = 'word/' + f;
  let xml = rd(rel);

  // 1. ten cong ty sau chu "TAI " (dong 2 cua o giua)
  xml = xml.replace(/(<w:t(?: [^>]*)?>)([^<]*?\bTẠI\s+)([^<]*)(<\/w:t>)/, (m, a, b, c, d) => {
    nameHit++;
    return a.includes('xml:space') ? a + b + esc(name) + d : a.replace('<w:t', '<w:t xml:space="preserve"') + b + esc(name) + d;
  });

  // 2. logo khach = khoi <w:drawing> CUOI (o ben phai); khoi dau la logo Citek
  const drawings = [];
  for (let p = xml.indexOf('<w:drawing>'); p !== -1; p = xml.indexOf('<w:drawing>', p + 1)) drawings.push(p);
  if (drawings.length >= 2) {
    const at = drawings[drawings.length - 1];
    const end = xml.indexOf('</w:drawing>', at) + '</w:drawing>'.length;
    if (logoBuf) {
      let d = xml.slice(at, end);
      const rid = (/r:embed="([^"]+)"/.exec(d) || [])[1];
      // vua khung logo cu, giu ti le anh moi
      const cx0 = Number((/<wp:extent cx="(\d+)"/.exec(d) || [])[1]);
      const cy0 = Number((/<wp:extent cx="\d+" cy="(\d+)"/.exec(d) || [])[1]);
      const k = Math.min(cx0 / logoSize.w, cy0 / logoSize.h);
      const cx = Math.round(logoSize.w * k), cy = Math.round(logoSize.h * k);
      d = d.replace(/<wp:extent cx="\d+" cy="\d+"\/>/, `<wp:extent cx="${cx}" cy="${cy}"/>`)
           .replace(/<a:ext cx="\d+" cy="\d+"\/>/, `<a:ext cx="${cx}" cy="${cy}"/>`);
      xml = xml.slice(0, at) + d + xml.slice(end);

      const relsPath = `word/_rels/${f}.rels`;
      let rels = rd(relsPath);
      const target = `media/customer_logo.${logoExt}`;
      rels = rels.replace(new RegExp(`(<Relationship [^>]*Id="${rid}"[^>]*Target=")[^"]+(")`), `$1${target}$2`)
                 .replace(new RegExp(`(<Relationship [^>]*Target=")[^"]+("[^>]*Id="${rid}")`), `$1${target}$2`);
      wr(relsPath, rels);
      fs.mkdirSync(path.join(wordDir, 'media'), { recursive: true });
      fs.writeFileSync(path.join(wordDir, 'media', `customer_logo.${logoExt}`), logoBuf);
      console.log(`${f}: da thay logo khach (${logoSize.w}x${logoSize.h}px -> ${cx}x${cy} EMU)`);
    } else {
      const r = runAround(xml, at);
      if (r) xml = xml.slice(0, r[0]) + xml.slice(r[1]);
      warn.push(`Chua truyen -CustomerLogo -> ${f}: da bo logo khach cua template, o ben phai de trong`);
    }
  }
  wr(rel, xml);
}
if (!nameHit) warn.push('Khong tim thay dong "... TẠI <cong ty>" trong header -> template khac cau truc, kiem tra lai bang mat');
else console.log(`Header: ten cong ty = "${name}"`);

// content type cho logo jpeg (png da co san trong template)
if (logoBuf) {
  let ct = rd('[Content_Types].xml');
  if (!new RegExp(`<Default Extension="${logoExt}"`, 'i').test(ct)) {
    ct = ct.replace('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
      `$&<Default Extension="${logoExt}" ContentType="image/${logoExt}"/>`);
    wr('[Content_Types].xml', ct);
  }
}

// ---------- core.xml ----------
if (mdPath && fs.existsSync(path.join(dir, 'docProps/core.xml'))) {
  const md = fs.readFileSync(mdPath, 'utf8');
  const row = label => ((new RegExp(`^\\|\\s*${label}\\s*\\|\\s*(.*?)\\s*\\|`, 'mi').exec(md) || [])[1] || '').replace(/[*`]/g, '');
  const title = row('Tên báo cáo');
  const author = row('Người thiết kế') || row('Người tạo');
  const now = new Date().toISOString().replace(/\.\d+Z$/, 'Z');
  let core = rd('docProps/core.xml');
  const set = (tag, val) => {
    const re = new RegExp(`<${tag}(?: [^>]*)?>[^<]*</${tag}>|<${tag}(?: [^>]*)?/>`);
    const open = tag.startsWith('dcterms:') ? `<${tag} xsi:type="dcterms:W3CDTF">` : `<${tag}>`;
    core = re.test(core) ? core.replace(re, `${open}${esc(val)}</${tag}>`) : core.replace('</cp:coreProperties>', `${open}${esc(val)}</${tag}></cp:coreProperties>`);
  };
  set('dc:title', title);
  set('dc:creator', author);
  set('cp:lastModifiedBy', author);
  set('dc:description', '');
  set('cp:revision', '1');
  set('dcterms:created', now);
  set('dcterms:modified', now);
  core = core.replace(/<cp:lastPrinted>[^<]*<\/cp:lastPrinted>/, '');
  wr('docProps/core.xml', core);
  console.log(`core.xml: title="${title}", creator="${author}"`);
}

warn.forEach(w => console.log('CANH BAO: ' + w));
