# -*- coding: utf-8 -*-
"""In cấu trúc 1 file Adobe Form tải từ SFP: form (SFPF_*.XML) hoặc interface (SFPI_*.XML).

    python af_inspect.py <file.XML> [--xdp <ra.xdp>] [--all]

SFPI: tham số import, global data, code Initialization.
SFPF: interface, context, trang giấy, cây layout (subform/field + bind), dữ liệu (dataDescription),
      bind không phân giải được, field dữ liệu chưa dùng, font, thẻ chưa có trong mẫu.
--xdp: ghi layout XDP đã giải mã ra file.   --all: in cả text tĩnh (draw) và thuộc tính chi tiết.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import afgen  # noqa: E402

L = afgen._local


def short(s, n=45):
    s = re.sub(r'\s+', ' ', s or '').strip()
    return s if len(s) <= n else s[:n - 1] + '…'


def inspect_itf(path):
    itf = afgen.Interface.parse(path)
    print('== INTERFACE (SFPI): %s' % os.path.basename(path))
    print('Mô tả: %s | ngôn ngữ gốc: %s' % (itf.text or '(trống)', itf.lang))
    print('Tham số import:')
    for p in itf.imports:
        print('  %s %s %s%s%s' % (p['NAME'], p['TYPING'], p['TYPENAME'], ' [optional]' if p.get('OPTIONAL') else '',
                                  ' [default %s]' % p['DEFAULTVAL'] if p.get('DEFAULTVAL') else ''))
    print('Global data:' + ('' if itf.gdata else ' (không có)'))
    for g in itf.gdata:
        print('  %s %s %s%s' % (g['NAME'], g['TYPING'], g['TYPENAME'], ' [constant]' if g.get('CONSTANT') else ''))
    print('Code Initialization: %d dòng | input: %s | output: %s' % (len(itf.init_lines), ', '.join(itf.inputs) or '-',
                                                                     ', '.join(itf.outputs) or '-'))
    for l in itf.init_lines:
        print('  | ' + l)
    if itf.form_lines:
        print('Form routines: %d dòng' % len(itf.form_lines))
    if itf.unsupported:
        print('CHÚ Ý - phần có dữ liệu nhưng chưa có mẫu (afgen không sinh lại): %s' % ', '.join(itf.unsupported))


def print_ctx(n, ind=0):
    extra = ''
    if isinstance(n, afgen.Loop):
        extra = 'bảng %s, work area %s' % (n.table, n.work_area)
    elif isinstance(n, afgen.Data):
        extra = n.field
    elif isinstance(n, afgen.Graphic):
        extra = 'ảnh từ %s (%s)' % (n.field, n.mime)
    flags = (' [gen]' if n.generated else '') + (' [CÓ ĐIỀU KIỆN]' if n.has_condition else '') + \
            (' "%s"' % n.text if n.text else '')
    print('  %s%s %s %s%s' % ('  ' * ind, n.CLS.replace('CL_FP_', ''), n.name, extra, flags))
    leafs = [k for k in n.kids if isinstance(k, afgen.Data) and not k.kids and k.generated]
    if len(leafs) > 6 and len(leafs) == len(n.kids):
        print('  %s  %d field gen: %s' % ('  ' * ind, len(leafs), ', '.join(k.name for k in leafs)))
        return
    for k in n.kids:
        print_ctx(k, ind + 1)


def val_text(el, T):
    v = el.find(T + 'value')
    if v is None:
        return ''
    t = v.find(T + 'text')
    if t is not None:
        return t.text or ''
    x = v.find(T + 'exData')
    if x is not None:
        return ' / '.join(''.join(p.itertext()) for p in x.iter() if L(p.tag) == 'p')
    img = v.find(T + 'image')
    return '[ảnh %s]' % img.get('contentType') if img is not None else ''


def geom(el):
    w, h, x, y = el.get('w'), el.get('h') or (el.get('minH') and 'min' + el.get('minH')), el.get('x'), el.get('y')
    parts = ['%sx%s' % (w or '?', h or '?')] if (w or h) else []
    if x or y:
        parts.append('@%s,%s' % (x or '0', y or '0'))
    return ' '.join(parts)


def print_tpl(el, T, ind, show_all):
    tag, pad = L(el.tag), '  ' * ind
    b = el.find(T + 'bind')
    bind = ('bind %s' % b.get('ref') if b.get('match') == 'dataRef' else 'bind=%s' % b.get('match')) if b is not None else ''
    if tag in ('subform', 'subformSet', 'area', 'exclGroup'):
        occ = el.find(T + 'occur')
        keep = el.find(T + 'keep')
        parts = [tag.upper(), el.get('name') or '(không tên)', '[%s]' % el.get('layout') if el.get('layout') else '',
                 'cols=' + el.get('columnWidths') if el.get('columnWidths') else '', geom(el), bind,
                 'occur max=%s' % occ.get('max') if occ is not None and occ.get('max') else '',
                 'keep=%s' % keep.get('intact') if keep is not None and show_all else '']
        print(pad + ' '.join(p for p in parts if p))
        for k in el:
            if L(k.tag) in ('subform', 'subformSet', 'area', 'exclGroup', 'field', 'draw'):
                print_tpl(k, T, ind + 1, show_all)
    elif tag == 'field':
        ui = el.find(T + 'ui')
        kind = next((L(c.tag) for c in ui), 'textEdit') if ui is not None else 'textEdit'
        if kind == 'barcode':
            kind = ui[0].get('type')
        cap = el.find(T + 'caption')
        font = el.find(T + 'font')
        parts = ['FIELD', el.get('name'), kind, geom(el), bind,
                 'caption="%s"' % short(val_text(cap, T), 30) if cap is not None and val_text(cap, T) else '',
                 'font=' + ' '.join(v for v in (font.get('typeface'), font.get('size'), font.get('weight')) if v)
                 if font is not None and show_all else '']
        print(pad + ' '.join(p for p in parts if p))
    elif tag == 'draw' and show_all:
        print(pad + 'DRAW %s %s "%s"' % (el.get('name'), geom(el), short(val_text(el, T))))


def inspect_form(path, xdp_out=None, show_all=False):
    f = afgen.Form.parse(path)
    print('== FORM (SFPF): %s' % os.path.basename(path))
    print('Form: %s | interface: %s | mô tả: %s | ngôn ngữ: %s' % (f.name or '?', f.interface, f.text or '(trống)', f.lang))
    if f.unsupported:
        print('CHÚ Ý - thẻ đầu file có giá trị chưa gặp trong mẫu: %s' % ', '.join(f.unsupported))
    print('Context:')
    print_ctx(f.ctx)
    if not f.xdp:
        print('Layout: CHƯA CÓ (form chưa mở tab Layout lần nào)')
        return
    if xdp_out:
        open(xdp_out, 'wb').write(f.xdp)
        print('Đã ghi XDP: %s' % xdp_out)
    root, tpl, droot = afgen.parse_xdp(f.xdp)
    T = afgen.tns(tpl)
    gen = re.search(rb'<\?xfa generator="([^"]+)"', f.xdp)
    ts = root.get('timeStamp')
    print('Layout: %s | timeStamp %s | LAYOUT_TYPE %s | CACHE_INFO %s' % (
        gen.group(1).decode() if gen else '?', ts, f.layout_type,
        'khớp' if f.cache_info == afgen._cache_info(ts, root.get('uuid')) else 'KHÔNG khớp timeStamp/uuid'))
    base = re.search(rb'<base>([^<]*)</base>', f.xdp)
    if base:
        print('Base URL (Designer): %s' % base.group(1).decode())
    print('Trang:')
    for pa in tpl.iter(T + 'pageArea'):
        ca, md = pa.find(T + 'contentArea'), pa.find(T + 'medium')
        print('  %s: medium %s short=%s long=%s%s | contentArea %s' % (
            pa.get('name'), md.get('stock'), md.get('short'), md.get('long'),
            ' ' + md.get('orientation') if md.get('orientation') else '', geom(ca)))
        for k in pa:
            if L(k.tag) in ('draw', 'field', 'subform'):
                print_tpl(k, T, 2, True)
    print('Layout (template):')
    rs = tpl.find(T + 'subform')
    print('  ROOT %s [%s] locale=%s' % (rs.get('name'), rs.get('layout'), rs.get('locale')))
    for k in rs:
        if L(k.tag) in ('subform', 'subformSet', 'area', 'exclGroup', 'field', 'draw'):
            print_tpl(k, T, 2, show_all)
    if droot is None:
        print('Dữ liệu: KHÔNG có dataDescription')
        return
    print('Dữ liệu (dataDescription):')

    def pd(n, ind):
        leaves = [k.name for k in n.kids if not k.kids]
        print('  %s%s%s%s' % ('  ' * ind, n.name, ' [lặp]' if n.repeat else '', ': ' + ', '.join(leaves) if leaves else ''))
        for k in n.kids:
            if k.kids:
                pd(k, ind + 1)
    pd(droot, 1)
    errs, binds = afgen.check_bindings(tpl, droot)
    print('Bind: %d | lỗi: %d' % (len(binds), len(errs)))
    for e in errs:
        print('  LỖI ' + e)
    unused = [p for p, n in droot.leaves() if not n.used]
    print('Field dữ liệu chưa dùng trên layout (%d): %s' % (len(unused), ', '.join(p.split('.')[-1] for p in unused) or '-'))
    print('Font: %s' % ', '.join(afgen.fonts_used(tpl)))
    unseen = afgen.vocab_unseen(tpl)
    if unseen:
        print('Thẻ/thuộc tính chưa có trong 3 form mẫu: %s' % ', '.join('%s(%d)' % kv for kv in sorted(unseen.items())))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if not args:
        print(__doc__)
        sys.exit(1)
    xdp_out = sys.argv[sys.argv.index('--xdp') + 1] if '--xdp' in sys.argv else None
    if xdp_out:
        args.remove(xdp_out)
    path = args[0]
    head = open(path, 'rb').read(600)
    if b'<INTERFACE href=' in head:
        inspect_itf(path)
    else:
        inspect_form(path, xdp_out, '--all' in sys.argv)


if __name__ == '__main__':
    main()
