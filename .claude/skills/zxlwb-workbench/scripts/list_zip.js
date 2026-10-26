// Doc truc tiep central directory cua 1 file ZIP/OOXML de kiem tra
// entry name co dung sai chuan (phai la "/" khong duoc la "\") va
// khong co entry rac - dung SAU KHI dong goi bang zipwriter.js (hoac
// bat ky cach nao khac) truoc khi giao file .xlsx/.docx/.pptx cho SAP.
//
// Dùng: node list_zip.js <file.xlsx>
const fs = require('fs');

function listZip(file) {
  const buf = fs.readFileSync(file);
  let i = buf.length - 22;
  while (i >= 0 && buf.readUInt32LE(i) !== 0x06054b50) i--;
  if (i < 0) { console.error('Khong tim thay End Of Central Directory - file khong phai ZIP hop le'); process.exit(1); }
  const eocd = i;
  const cdOffset = buf.readUInt32LE(eocd + 16);
  const cdCount = buf.readUInt16LE(eocd + 10);
  console.log(`EOCD tai offset ${eocd}, central directory tai ${cdOffset}, ${cdCount} entries`);

  let p = cdOffset;
  let bad = 0;
  for (let n = 0; n < cdCount; n++) {
    const sig = buf.readUInt32LE(p);
    if (sig !== 0x02014b50) { console.error('SAI signature central directory tai offset', p); bad++; break; }
    const method = buf.readUInt16LE(p + 10);
    const compSize = buf.readUInt32LE(p + 20);
    const uncompSize = buf.readUInt32LE(p + 24);
    const nameLen = buf.readUInt16LE(p + 28);
    const extraLen = buf.readUInt16LE(p + 30);
    const commentLen = buf.readUInt16LE(p + 32);
    const name = buf.slice(p + 46, p + 46 + nameLen).toString('utf8');

    const hasBackslash = name.includes('\\');
    const isEmptyDir = name.endsWith('/') || name.endsWith('\\');
    const flag = hasBackslash ? '  <-- LOI: dung dau \\ (phai la /)'
               : isEmptyDir ? '  <-- CANH BAO: entry thu muc (co the la entry rac)'
               : '';
    if (hasBackslash) bad++;
    console.log(`  ${name}  [method=${method}, comp=${compSize}, uncomp=${uncompSize}]${flag}`);

    p += 46 + nameLen + extraLen + commentLen;
  }

  if (bad > 0) {
    console.error(`\n${bad} entry co van de - KHONG dung file nay, dong goi lai bang zipwriter.js`);
    process.exit(1);
  } else {
    console.log('\nOK - tat ca entry dung chuan (dau /, khong co entry rac)');
  }
}

const file = process.argv[2];
if (!file) { console.error('Dung: node list_zip.js <file.xlsx>'); process.exit(1); }
listZip(file);
