"""Đọc nhanh 1 file XML Smart Form: interface, global data, code, line type, cây node.

    python sf_inspect.py <form.xml>             # toàn bộ
    python sf_inspect.py <form.xml> --node %ROW13 %TEXT54   # dump chi tiết vài node

Cây node in dạng: <NODETYPE> <INAME> "<CAPTION>" [LT=<line type>] [IF <điều kiện>] TXT=<nội dung text>
"""
import sys
import xml.etree.ElementTree as ET

S = '{urn:sap-com:SmartForms:2000:internal-structure}'
I = '{urn:sap-com:sdixml-ifr:2000}'
ln = lambda e: e.tag.split('}')[-1]


def cond_str(node):
    c = node.find(S + 'COND/' + S + 'CONDITION')
    if c is None:
        return ''
    parts = []
    for it in c.findall(I + 'COND/' + I + 'item'):
        parts.append(' '.join(filter(None, [it.findtext(I + 'LOP'), it.findtext(I + 'OP1'),
                                            it.findtext(I + 'COP'), it.findtext(I + 'OP2')])))
    oc = c.find(I + 'OCOND')
    if oc is not None:
        parts += [ln(x) for x in oc]
    return ' IF ' + ' '.join(parts)


def walk(e, d, out):
    if ln(e) == 'NODE':
        nt = e.findtext(I + 'NODETYPE')
        obj = e.find(S + 'OBJ')
        info = ''
        if obj is not None and len(obj):
            o = obj[0]
            iname = o.find('.//' + I + 'INAME')
            info = '%s "%s"' % (iname.text if iname is not None else '', o.findtext(I + 'CAPTION') or '')
            if ln(o) == 'SECTION' and o.findtext(I + 'TABNAME'):
                info += ' LOOP %s INTO %s' % (o.findtext(I + 'TABNAME'), o.findtext(I + 'TABHEADER'))
            txt = [x.findtext(I + 'TDLINE') or '' for x in o.findall(I + 'TEXT/' + I + 'item')]
            if txt:
                info += ' TXT=' + ' | '.join(txt)
        oa = e.find(S + 'OUTATTR/' + S + 'OUTATTR')
        if oa is not None and oa.findtext(I + 'T_LINETYPE'):
            info += ' LT=' + oa.findtext(I + 'T_LINETYPE')
        if oa is not None and oa.findtext(I + 'WLEFT'):
            info += ' POS(left,width,top,height)=' + ','.join(oa.findtext(I + k) for k in ('WLEFT', 'WWIDTH', 'WTOP', 'WHEIGHT'))
        if oa is not None and oa.findtext(I + 'PROTECT'):
            info += ' PROTECT'
        out.append('  ' * d + (nt or '') + ' ' + info + cond_str(e))
    for c in e:
        walk(c, d + (1 if ln(e) == 'NODE' else 0), out)


def dump(e, d=0):
    if ln(e) == 'T_CAPTION':
        return
    if ln(e) == 'SUCC' and d > 0:
        print('  ' * d + 'SUCC (%d con)' % len(e))
        return
    txt = (e.text or '').strip()
    print('  ' * d + ln(e) + (' ' + str(e.attrib) if e.attrib else '') + (' = ' + txt if txt else ''))
    for c in e:
        dump(c, d + 1)


def main():
    root = ET.parse(sys.argv[1]).getroot()
    if '--node' in sys.argv:
        want = set(sys.argv[sys.argv.index('--node') + 1:])
        for n in root.iter(S + 'NODE'):
            obj = n.find(S + 'OBJ')
            if obj is not None and len(obj):
                iname = obj[0].find('.//' + I + 'INAME')
                if iname is not None and iname.text in want:
                    print('=====', iname.text)
                    dump(n)
        return
    h = root.find(I + 'HEADER')
    print('FORM', h.findtext(I + 'FORMNAME'), '-', h.findtext(I + 'CAPTION'), '| package', h.findtext(I + 'DEVCLASS'))
    vh = root.find(S + 'VARHEADER')[0]
    print('PAGE', vh.findtext(I + 'PAGEFORMAT'), 'style', vh.findtext(I + 'STDSTYLE'),
          'orientation', next(root.iter(I + 'PAGEORTN')).text)
    print('== INTERFACE (không kể tham số chuẩn)')
    for it in root.find(I + 'INTERFACE'):
        if not it.findtext(I + 'STANDARD'):
            print('  ', it.findtext(I + 'IOTYPE'), it.findtext(I + 'NAME'), it.findtext(I + 'TYPING') or '', it.findtext(I + 'TYPENAME') or '')
    print('== GLOBAL DATA')
    for it in root.find(I + 'GDATA'):
        print('  ', it.findtext(I + 'NAME'), it.findtext(I + 'TYPING'), it.findtext(I + 'TYPENAME'))
    for sec in ('GCODING', 'FCODING'):
        node = root.find(I + sec)               # form không có GCODING/FCODING -> None
        lines = [x.text for x in node if x.text] if node is not None else []
        if lines:
            print('==', sec)
            print('\n'.join('   ' + l for l in lines))
    print('== LINE TYPE (tên: độ rộng các cột, cm)')
    for sec in root.iter(S + 'SECTION'):
        cells = sec.find(I + 'CELLS')
        if cells is None:
            continue
        print('  table', sec.findtext(I + 'NAME/' + I + 'INAME'), 'width', sec.findtext(I + 'WIDTH'))
        lt = {}
        for it in cells:
            lt.setdefault(it.findtext(I + 'NAME'), []).append(it.findtext(I + 'CWIDTH'))
        for k, v in lt.items():
            print('    %-14s %s' % (k, ' '.join(v)))
    print('== CÂY NODE')
    out = []
    walk(root.find(S + 'VARHEADER'), 0, out)
    print('\n'.join(out))


if __name__ == '__main__':
    main()
