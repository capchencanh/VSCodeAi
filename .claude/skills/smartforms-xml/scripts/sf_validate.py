"""Kiểm tra file XML Smart Form sinh ra trước khi đưa user upload.

    python sf_validate.py <form_moi.xml> <form_mau_that.xml>

Kiểm tra:
  1. XML parse được.
  2. Mọi tag đều có trong form mẫu, và thứ tự con của từng phần tử khớp đúng 1 thứ tự đã có trong form mẫu.
  3. Không trùng INAME của node/outattr/condition.
  4. Mỗi line type: tổng độ rộng cột = độ rộng table; mỗi row có số cell = số cột của line type nó dùng.
  5. Mọi row đều trỏ tới line type có khai trong table.
Kết quả cuối: "PASS" hoặc danh sách lỗi + "FAIL".
"""
import sys
import xml.etree.ElementTree as ET
from collections import Counter

S = '{urn:sap-com:SmartForms:2000:internal-structure}'
I = '{urn:sap-com:sdixml-ifr:2000}'
ln = lambda e: e.tag.split('}')[-1]


def child_seqs(root):
    d = {}
    for p in root.iter():
        for e in p:
            key = (ln(p), ln(e)) if ln(e) == 'item' else (None, e.tag)
            seq = tuple(ln(c) for c in e if not (ln(e) != 'item' and ln(c) == 'item'))
            if ln(e) == 'SUCC':
                seq = ()
            d.setdefault(key, set()).add(seq)
    return d


def main():
    new = ET.parse(sys.argv[1]).getroot()
    tpl = ET.parse(sys.argv[2]).getroot()
    errors = []

    extra = {e.tag for e in new.iter()} - {e.tag for e in tpl.iter()}
    if extra:
        errors.append('Tag không có trong form mẫu: %s' % sorted(extra))

    t = child_seqs(tpl)
    for key, seqs in child_seqs(new).items():
        for s in seqs:
            if s not in t.get(key, set()):
                errors.append('Thứ tự con lạ ở %s: %s' % (key[0] or key[1].split('}')[-1], list(s)))

    names = Counter(x.findtext(I + 'INAME') for x in new.iter(I + 'NAME') if x.find(I + 'INAME') is not None)
    # INAME trong NEXTPAGE/T_CAPTION không nằm dưới NAME nên không bị đếm; mỗi đối tượng chỉ có 1 NAME/INAME
    dups = [k for k, v in names.items() if v > 1]
    if dups:
        errors.append('Trùng INAME: %s' % dups)

    for node in new.iter(S + 'NODE'):
        obj = node.find(S + 'OBJ')
        sec = obj[0] if obj is not None and len(obj) else None
        if sec is None or ln(sec) != 'SECTION' or sec.find(I + 'CELLS') is None:
            continue
        tname = sec.findtext(I + 'NAME/' + I + 'INAME')
        width = float(sec.findtext(I + 'WIDTH'))
        lts = {}
        for it in sec.find(I + 'CELLS'):
            lts.setdefault(it.findtext(I + 'NAME'), []).append(float(it.findtext(I + 'CWIDTH')))
        declared = [it.findtext(I + 'NAME') for it in sec.find(I + 'DYNLINES')]
        if sorted(declared) != sorted(lts):
            errors.append('%s: DYNLINES %s khác CELLS %s' % (tname, declared, list(lts)))
        for k, v in lts.items():
            if abs(sum(v) - width) > 0.005:
                errors.append('%s: line type %s tổng %.2f cm khác độ rộng table %.2f' % (tname, k, sum(v), width))
        for row in node.iter(S + 'NODE'):
            oa = row.find(S + 'OUTATTR/' + S + 'OUTATTR')
            lt = oa.findtext(I + 'T_LINETYPE') if oa is not None else None
            if not lt:
                continue
            rname = row.find(S + 'OBJ')[0].findtext(I + 'NAME/' + I + 'INAME')
            if lt not in lts:
                # row thuộc table lồng khác sẽ được kiểm ở vòng của table đó
                continue
            ncell = len(row.find(S + 'SUCC'))
            if ncell != len(lts[lt]):
                errors.append('%s: row %s có %d cell, line type %s có %d cột' % (tname, rname, ncell, lt, len(lts[lt])))

    all_lts = set()
    for sec in new.iter(S + 'SECTION'):
        if sec.find(I + 'CELLS') is not None:
            all_lts |= {it.findtext(I + 'NAME') for it in sec.find(I + 'CELLS')}
    for oa in new.iter(S + 'OUTATTR'):
        lt = oa.findtext(I + 'T_LINETYPE')
        if lt and lt not in all_lts:
            errors.append('Row dùng line type không tồn tại: %s' % lt)

    for e in errors:
        print('-', e)
    print('FAIL' if errors else 'PASS')
    sys.exit(1 if errors else 0)


if __name__ == '__main__':
    main()
