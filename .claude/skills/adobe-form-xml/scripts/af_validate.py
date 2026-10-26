# -*- coding: utf-8 -*-
"""Kiểm tra file Adobe Form trước khi đưa user upload (SFP -> Utilities -> Upload).

    python af_validate.py <SFPF_FORM.XML> [<SFPI_INTERFACE.XML>]

LỖI (-> FAIL):
  1. asXML: id heap trùng, href trỏ tới id không có, PARENT của node lệch cây CHILD/SUCCESSOR.
  2. Context: GUID node trùng/không phải 32 hex; LOOP không có đúng 1 con DATA; field sinh tự động
     có FIELD khác <WORK_AREA>-<NAME>.
  3. Layout: không giải mã/parse được; thiếu packet; subform gốc không tên 'data';
     CACHE_INFO lệch timeStamp/uuid của XDP.
  4. dataDescription khác cây suy từ context.
  5. Bind dataRef không trỏ tới node dữ liệu / field bind vào nhóm / subform bind vào field lá.
  6. (có SFPI) bảng của LOOP không phải tham số import; GRAPHIC_FIELD, input/output của Initialization
     không khai báo.
CẢNH BÁO (vẫn PASS): node/thẻ/thuộc tính/font chưa có trong 3 form mẫu, đối tượng vượt khung.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import afgen  # noqa: E402


def check_asxml(path, errs, warns):
    vals, heap = afgen._load(path)
    raw = open(path, 'rb').read().decode('utf-8')
    ids = re.findall(r' id="(o\d+)"', raw)
    dup = sorted({i for i in ids if ids.count(i) > 1})
    if dup:
        errs.append('asXML: id heap trùng: %s' % ', '.join(dup))
    refs = re.findall(r' href="#([^"]+)"', raw)
    for r in sorted(set(refs) - set(ids)):
        errs.append('asXML: href "#%s" không có đối tượng' % r)
    orphan = sorted(set(ids) - set(refs))
    if orphan:
        warns.append('asXML: đối tượng heap không ai tham chiếu: %s' % ', '.join(orphan))
    return heap


def check_context(f, heap, errs, warns):
    guids = []
    for n in f.ctx.walk():
        guids.append(n.guid)
        if not re.match(r'^[0-9A-F]{32}$', n.guid or ''):
            errs.append('Context: node %s có ID "%s" không phải GUID 32 hex hoa' % (n.name, n.guid))
        nd = heap[n.oid].find('CL_FP_NODE')
        par = afgen._href(nd, 'PARENT')
        if par != (n.parent.oid if n.parent else None):
            errs.append('Context: node %s có PARENT %s, cây thật là %s' % (n.name, par, n.parent.oid if n.parent else None))
        if isinstance(n, afgen.Other):
            warns.append('Context: node %s loại %s chưa có mẫu (afgen không sinh lại được; inject_layout vẫn dùng được)'
                         % (n.name, n.CLS))
        if n.has_condition:
            warns.append('Context: node %s có điều kiện/WHERE - chưa có mẫu' % n.name)
        if isinstance(n, afgen.Loop):
            rows = [k for k in n.kids if isinstance(k, afgen.LoopData)]
            if len(rows) != 1 or len(n.kids) != 1 or rows[0].name != 'DATA':
                errs.append('Context: LOOP %s phải có đúng 1 con LOOP_DATA tên DATA' % n.name)
            for row in rows:
                for d in row.kids:
                    if isinstance(d, afgen.Data) and d.generated and d.field != '%s-%s' % (n.work_area, d.name):
                        errs.append('Context: field %s có FIELD=%s, cần %s-%s' % (d.name, d.field, n.work_area, d.name))
    dup = sorted({g for g in guids if guids.count(g) > 1})
    if dup:
        errs.append('Context: GUID node trùng: %s' % ', '.join(dup))


def compare_dd(expect, got, path, errs):
    """expect: afgen.E (từ context), got: afgen.DNode (trong XDP)."""
    here = '%s/%s' % (path, expect.tag)
    if expect.tag != got.name:
        errs.append('dataDescription: %s - context có "%s", XDP có "%s"' % (path, expect.tag, got.name))
        return
    if (expect.attrs.get('dd:maxOccur') == '-1') != got.repeat:
        errs.append('dataDescription: %s - cờ lặp (maxOccur=-1) lệch context' % here)
    a, b = [k.tag for k in expect.kids], [k.name for k in got.kids]
    if a != b:
        errs.append('dataDescription: %s - con theo context %s, trong XDP %s' % (here, a, b))
        return
    for x, y in zip(expect.kids, got.kids):
        compare_dd(x, y, here, errs)


def check_layout(f, errs, warns, infos):
    if not f.xdp:
        errs.append('Layout: rỗng (form chưa có layout)')
        return
    try:
        root, tpl, droot = afgen.parse_xdp(f.xdp)
    except Exception as e:      # XML hỏng
        errs.append('Layout: XDP không parse được: %s' % e)
        return
    tags = [afgen._local(c.tag) for c in root]
    for p in ('template', 'config', 'connectionSet', 'datasets', 'localeSet'):
        if p not in tags:
            errs.append('Layout: thiếu packet <%s>' % p)
    if tpl is None:
        return
    T = afgen.tns(tpl)
    rs = tpl.find(T + 'subform')
    if rs is None or rs.get('name') != 'data':
        errs.append('Layout: subform gốc phải tên "data" (khớp gốc dữ liệu SAP)')
    if f.cache_info != afgen._cache_info(root.get('timeStamp'), root.get('uuid')):
        errs.append('Layout: CACHE_INFO "%s" lệch timeStamp/uuid của XDP' % f.cache_info)
    if droot is None:
        errs.append('Layout: thiếu dd:dataDescription')
        return
    try:
        expect = f.data_description()
    except ValueError as e:
        warns.append('dataDescription: không đối chiếu được với context (%s)' % e)
    else:
        compare_dd(expect, droot, '', errs)
    berrs, binds = afgen.check_bindings(tpl, droot)
    errs.extend('Bind: ' + e for e in berrs)
    unseen = afgen.vocab_unseen(tpl)
    if unseen:
        warns.append('Thẻ/thuộc tính chưa có trong 3 form mẫu (xem lại trên Designer/bản in): %s'
                     % ', '.join('%s(%d)' % kv for kv in sorted(unseen.items())))
    odd = [x for x in afgen.fonts_used(tpl) if x not in afgen.SEEN_FONTS]
    if odd:
        warns.append('Font chưa thấy trong mẫu (xác nhận ADS có font, tiếng Việt hiển thị đúng): %s' % ', '.join(odd))
    warns.extend('Hình học: ' + w for w in afgen.geometry_warnings(tpl))
    unused = [p.split('.')[-1] for p, n in droot.leaves() if not n.used]
    infos.append('%d bind; field dữ liệu chưa dùng trên layout (%d): %s'
                 % (len(binds), len(unused), ', '.join(unused) or '-'))


def check_interface(f, ipath, errs, warns):
    itf = afgen.Interface.parse(ipath)
    m = re.match(r'SFPI_(.+)\.XML$', os.path.basename(ipath), re.I)
    if m and m.group(1).upper() != f.interface:
        warns.append('Tên file interface %s khác INTERFACE của form (%s)' % (os.path.basename(ipath), f.interface))
    params = {p['NAME'] for p in itf.imports}
    gdata = {g['NAME'] for g in itf.gdata}
    for n in f.ctx.kids:
        if isinstance(n, afgen.Loop) and n.table not in params:
            errs.append('Interface: LOOP %s không phải tham số import (%s)' % (n.table, ', '.join(sorted(params))))
        if isinstance(n, afgen.Graphic) and n.field not in gdata | params:
            errs.append('Interface: graphic %s lấy từ %s nhưng chưa khai global data' % (n.name, n.field))
    for v in itf.outputs:
        if v not in gdata:
            errs.append('Interface: output %s của Initialization chưa khai global data' % v)
    for v in itf.inputs:
        if v not in gdata | params:
            errs.append('Interface: input %s của Initialization không phải tham số/global data' % v)
    if itf.unsupported:
        warns.append('Interface: phần chưa có mẫu: %s' % ', '.join(itf.unsupported))


def validate(path, ipath=None):
    """Trả (lỗi, cảnh báo, thông tin)."""
    errs, warns, infos = [], [], []
    heap = check_asxml(path, errs, warns)
    f = afgen.Form.parse(path)
    if f.unsupported:
        warns.append('Thẻ đầu file có giá trị chưa gặp trong mẫu: %s' % ', '.join(f.unsupported))
    check_context(f, heap, errs, warns)
    check_layout(f, errs, warns, infos)
    if ipath:
        check_interface(f, ipath, errs, warns)
    return errs, warns, infos


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    path, ipath = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else None)
    errs, warns, infos = validate(path, ipath)
    print('== af_validate: %s%s' % (os.path.basename(path), ' + ' + os.path.basename(ipath) if ipath else ''))
    for title, items in (('LỖI', errs), ('CẢNH BÁO', warns), ('THÔNG TIN', infos)):
        if items:
            print('%s (%d):' % (title, len(items)))
            for i in items:
                print('  - ' + i)
    print('FAIL' if errs else 'PASS')
    sys.exit(1 if errs else 0)


if __name__ == '__main__':
    main()
