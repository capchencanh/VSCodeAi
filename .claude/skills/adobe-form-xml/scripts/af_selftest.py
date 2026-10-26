# -*- coding: utf-8 -*-
"""Tự kiểm afgen trên form thật + form demo. Chạy lại sau mỗi lần sửa afgen.py.

    python af_selftest.py [thư mục hoặc file SFPF_/SFPI_*.XML ...]

1. Mỗi file mẫu: đọc -> sinh lại -> so TỪNG BYTE với file gốc (khung asXML, thứ tự heap, base64).
2. Mỗi SFPF mẫu: packet localeSet/config/connectionSet/datasets/xmpmeta + CACHE_INFO do afgen dựng
   = nội dung trong XDP gốc (bỏ qua config có psMap, xmp có pdfuaid - tuỳ chọn Designer).
3. inject_layout() lên SFPF mẫu đầu tiên -> af_validate PASS.
4. example_demo.py sinh 2 form demo -> af_validate PASS.
Không truyền tham số: dùng mẫu ở <skill>/examples (3 form + 3 interface export thật).
"""
import glob
import os
import re
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import afgen  # noqa: E402
import af_validate  # noqa: E402
import example_demo  # noqa: E402

DEFAULT = os.path.normpath(os.path.join(HERE, '..', 'examples'))


def block_of(lines, start, end):
    i = next(k for k, l in enumerate(lines) if l.startswith(start))
    j = next(k for k in range(i, len(lines)) if end in lines[k])
    return lines[i:j + 1]


def check_packets(f):
    x = f.xdp.decode('utf-8')
    lines = x.split('\r\n')
    ts, uid = re.search(r'timeStamp="([^"]+)"', x).group(1), re.search(r'uuid="([^"]+)"', x).group(1)
    base = re.search(r'<base>([^<]*)</base>', x)
    bad = []
    cfg = block_of(lines, '<config', '</config>')
    if not any('psMap' in l for l in cfg) and cfg != afgen._config(base.group(1) if base else ''):
        bad.append('config')
    xmp = block_of(lines, '<x:xmpmeta', '</x:xmpmeta>')
    if not any('pdfuaid' in l for l in xmp) and xmp != afgen._xmp(ts, uid):
        bad.append('xmpmeta')
    for name, got, exp in (('localeSet', block_of(lines, '<localeSet', '</localeSet>'), afgen._localeset()),
                           ('connectionSet', block_of(lines, '<connectionSet', '</connectionSet>'), afgen._connection(f.name)),
                           ('datasets', block_of(lines, '<xfa:datasets', '</xfa:datasets>'), afgen._datasets(f.data_description()))):
        if got != exp:
            bad.append(name)
    if f.cache_info != afgen._cache_info(ts, uid):
        bad.append('CACHE_INFO')
    return bad


def main():
    targets = sys.argv[1:] or [DEFAULT]
    files = []
    for t in targets:
        files += sorted(glob.glob(os.path.join(t, 'SFP[FI]_*.XML'))) if os.path.isdir(t) else [t]
    fails = 0
    if not files:
        print('Không có file mẫu (%s) - bỏ qua bước 1-3' % ', '.join(targets))
    for path in files:
        orig = open(path, 'rb').read()
        obj = (afgen.Interface if os.path.basename(path).upper().startswith('SFPI') else afgen.Form).parse(path)
        same = obj.render().encode('utf-8') == orig
        bad = check_packets(obj) if isinstance(obj, afgen.Form) and obj.xdp else []
        ok = same and not bad
        fails += not ok
        print('%s %s%s%s' % ('OK  ' if ok else 'FAIL', os.path.basename(path), '' if same else ' | sinh lại KHÁC file gốc',
                              ' | packet lệch: ' + ', '.join(bad) if bad else ''))
    out = tempfile.mkdtemp(prefix='afgen_')
    sfpf = [p for p in files if os.path.basename(p).upper().startswith('SFPF')]
    if sfpf:
        f = afgen.Form.parse(sfpf[0])
        lp = next(n for n in f.ctx.kids if isinstance(n, afgen.Loop))
        names = [d.name for d in lp.kids[0].kids][:5]
        dst = os.path.join(out, 'INJECT_' + os.path.basename(sfpf[0]))
        afgen.inject_layout(sfpf[0], dst, afgen.page((80, 40), margin=0), [afgen.repeat(lp.table, [afgen.block(
            [afgen.field(n, x=0, y=6 * i, w=78, h=6) for i, n in enumerate(names)], w=80, h=40)])])
        errs = af_validate.validate(dst)[0]
        fails += bool(errs)
        print('%s inject_layout -> %s%s' % ('FAIL' if errs else 'OK  ', os.path.basename(dst), ''.join('\n   ' + e for e in errs)))
    for sf, si in example_demo.build(out):
        errs, warns, _ = af_validate.validate(sf, si)
        fails += bool(errs)
        print('%s demo %s (%d cảnh báo)%s' % ('FAIL' if errs else 'OK  ', os.path.basename(sf), len(warns),
                                              ''.join('\n   ' + e for e in errs)))
    print('Thư mục kết quả tạm: %s' % out)
    print('PASS' if not fails else 'FAIL (%d)' % fails)
    sys.exit(1 if fails else 0)


if __name__ == '__main__':
    main()
