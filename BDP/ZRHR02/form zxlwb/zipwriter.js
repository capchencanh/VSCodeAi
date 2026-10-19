// ZIP writer chuan (forward slash, method Deflate/Store), khong dung
// PowerShell Compress-Archive (da xac nhan tao entry name sai voi dau \).
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

// CRC32 chuan
const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    t[n] = c >>> 0;
  }
  return t;
})();
function crc32(buf) {
  let c = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xFF] ^ (c >>> 8);
  return (c ^ 0xFFFFFFFF) >>> 0;
}

function dosDateTime(d) {
  const time = ((d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1)) & 0xFFFF;
  const date = (((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate()) & 0xFFFF;
  return { time, date };
}

// files: [{name, content: Buffer}] - name PHAI dung forward slash
function buildZip(files) {
  const { time, date } = dosDateTime(new Date(2026, 8, 18, 12, 0, 0));
  const localParts = [];
  const centralParts = [];
  let offset = 0;

  for (const f of files) {
    const nameBuf = Buffer.from(f.name, 'utf8');
    const data = f.content;
    const crc = crc32(data);
    const compressed = zlib.deflateRawSync(data, { level: 9 });
    const useStore = compressed.length >= data.length;
    const method = useStore ? 0 : 8;
    const storedData = useStore ? data : compressed;

    const localHeader = Buffer.alloc(30);
    localHeader.writeUInt32LE(0x04034b50, 0);
    localHeader.writeUInt16LE(20, 4);        // version needed
    localHeader.writeUInt16LE(0, 6);         // flags
    localHeader.writeUInt16LE(method, 8);
    localHeader.writeUInt16LE(time, 10);
    localHeader.writeUInt16LE(date, 12);
    localHeader.writeUInt32LE(crc, 14);
    localHeader.writeUInt32LE(storedData.length, 18);
    localHeader.writeUInt32LE(data.length, 22);
    localHeader.writeUInt16LE(nameBuf.length, 26);
    localHeader.writeUInt16LE(0, 28);        // extra len

    localParts.push(localHeader, nameBuf, storedData);

    const centralHeader = Buffer.alloc(46);
    centralHeader.writeUInt32LE(0x02014b50, 0);
    centralHeader.writeUInt16LE(20, 4);      // version made by
    centralHeader.writeUInt16LE(20, 6);      // version needed
    centralHeader.writeUInt16LE(0, 8);       // flags
    centralHeader.writeUInt16LE(method, 10);
    centralHeader.writeUInt16LE(time, 12);
    centralHeader.writeUInt16LE(date, 14);
    centralHeader.writeUInt32LE(crc, 16);
    centralHeader.writeUInt32LE(storedData.length, 20);
    centralHeader.writeUInt32LE(data.length, 24);
    centralHeader.writeUInt16LE(nameBuf.length, 28);
    centralHeader.writeUInt16LE(0, 30);      // extra len
    centralHeader.writeUInt16LE(0, 32);      // comment len
    centralHeader.writeUInt16LE(0, 34);      // disk number start
    centralHeader.writeUInt16LE(0, 36);      // internal attrs
    centralHeader.writeUInt32LE(0, 38);      // external attrs
    centralHeader.writeUInt32LE(offset, 42); // local header offset

    centralParts.push(centralHeader, nameBuf);

    offset += localHeader.length + nameBuf.length + storedData.length;
  }

  const centralDirStart = offset;
  const centralDirBuf = Buffer.concat(centralParts);
  const eocd = Buffer.alloc(22);
  eocd.writeUInt32LE(0x06054b50, 0);
  eocd.writeUInt16LE(0, 4);
  eocd.writeUInt16LE(0, 6);
  eocd.writeUInt16LE(files.length, 8);
  eocd.writeUInt16LE(files.length, 10);
  eocd.writeUInt32LE(centralDirBuf.length, 12);
  eocd.writeUInt32LE(centralDirStart, 16);
  eocd.writeUInt16LE(0, 20);

  return Buffer.concat([...localParts, centralDirBuf, eocd]);
}

function walkDir(dir, base) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    const rel = base ? `${base}/${entry.name}` : entry.name;
    if (entry.isDirectory()) {
      out.push(...walkDir(full, rel));
    } else {
      out.push({ name: rel, content: fs.readFileSync(full) });
    }
  }
  return out;
}

const srcDir = process.argv[2];
const outFile = process.argv[3];
const files = walkDir(srcDir, '');
// [Content_Types].xml nen dung dau tien (khuyen nghi OPC, khong bat buoc nhung an toan hon)
files.sort((a, b) => {
  if (a.name === '[Content_Types].xml') return -1;
  if (b.name === '[Content_Types].xml') return 1;
  return 0;
});
const zipBuf = buildZip(files);
fs.writeFileSync(outFile, zipBuf);
console.log('OK - wrote', outFile, zipBuf.length, 'bytes,', files.length, 'entries');
files.forEach(f => console.log('  ', f.name));
