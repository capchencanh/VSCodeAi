# -*- coding: utf-8 -*-
"""Sinh 2 Smart Form Phieu chuyen kho (ZWM05) theo FS v1.0.

  ZWM_SF_PCK      mau 1, 2, 4 va phieu chuyen trang thai: cung layout, khac tieu de,
                  nhan va so o chu ky (do chuong trinh ZWM_PG_PCK dien GS_PARAMETER).
                  Mau 1 song ngu co them cot (15) Dang bao che (PARAMETER15 co gia tri).
  ZWM_SF_PCK_OP3  mau 3 - Nguyen lieu, bao bi: them 2 cot ky tay (13) Ngay cap / Thu kho
                  va (14) Nguoi nhan (de trong).

Moi form dung cho ca ban Viet va song ngu: nhan song ngu do chuong trinh ghep san vao
GS_PARAMETER. Header va chu ky doi theo tham so: chuyen kho co HEADER09 (don vi nhan),
chuyen trang thai co HEADER11 (loai ton); so o ky 1 / 3 / 4 theo SIGN01..SIGN04.
Mapping field: CodeABAP/BDP/ZWM05/ghi_chu.md muc 6.

Chay:  PYTHONUTF8=1 python gen_zwm_sf_pck.py FS_v1.0
"""
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', '..', '.claude', 'skills',
                                'smartforms-xml', 'scripts'))

from sfgen import SF, ALL, NONE

# A4 ngang 29.7 x 21.0 cm; le trai 2.0, phai 1.5, tren/duoi 1.5 -> vung in 26.2 x 18.0 cm
W = 26.2
L = 2.0
TOP = 1.5

P = 'GS_PARAMETER-'

# Cot theo so hieu FS 2.5: (nhan GS_PARAMETER, noi dung GS_DATA, canh le); noi dung rong = cot ky tay
COLS = {
    1:  ('PARAMETER01', ['&GS_DATA-STT(C)&'], 'C'),
    2:  ('PARAMETER02', ['&GS_DATA-MATNR&'], 'L'),
    3:  ('PARAMETER03', ['&GS_DATA-MAKTX&'], 'L'),
    4:  ('PARAMETER04', ['&GS_DATA-NSXNS&'], 'L'),
    5:  ('PARAMETER05', ['&GS_DATA-SOLO&'], 'L'),
    6:  ('PARAMETER06', ['&GS_DATA-CHARG&'], 'L'),
    7:  ('PARAMETER07', ['&GS_DATA-HANDUNG&'], 'L'),
    8:  ('PARAMETER08', ['&GS_DATA-GROES&'], 'L'),
    9:  ('PARAMETER09', ['&GS_DATA-MEINS&'], 'C'),
    10: ('PARAMETER10', ['&GS_DATA-MENGE(IC)&'], 'R'),
    11: ('PARAMETER11', ['&GS_DATA-QUYDOI&'], 'L'),
    12: ('PARAMETER12', ['&GS_DATA-BAOQUAN&'], 'L'),
    13: ('PARAMETER13', [], 'C'),
    14: ('PARAMETER14', [], 'C'),
    15: ('PARAMETER15', ['&GS_DATA-DANGBC&'], 'L'),
}

# Cot va do rong (cm) tung layout; tong = W
LAYOUT_BASE = [(1, 0.8), (2, 1.7), (3, 3.4), (4, 3.0), (5, 2.0), (6, 2.0), (7, 2.6), (8, 2.4),
               (9, 1.0), (10, 1.7), (11, 2.8), (12, 2.8)]
LAYOUT_DOSAGE = [(1, 0.8), (2, 1.6), (3, 3.2), (15, 2.0), (4, 2.7), (5, 1.8), (6, 1.8), (7, 2.8),
                 (8, 2.2), (9, 0.9), (10, 1.6), (11, 2.6), (12, 2.2)]
LAYOUT_OP3 = [(1, 0.8), (2, 1.6), (3, 3.0), (4, 2.6), (5, 1.8), (6, 1.8), (7, 2.3), (8, 2.0),
              (9, 0.9), (10, 1.5), (11, 2.4), (12, 2.0), (13, 1.8), (14, 1.7)]

# (ten form, mo ta, layout co cot dang bao che hoac None, layout thuong)
FORMS = [
    ('ZWM_SF_PCK',     'Phieu chuyen kho, phieu chuyen trang thai', LAYOUT_DOSAGE, LAYOUT_BASE),
    ('ZWM_SF_PCK_OP3', 'Phieu chuyen kho nguyen lieu, bao bi',      None,          LAYOUT_OP3),
]


def build(formname, caption, layout_dosage, layout_main):
    for lay in (layout_dosage, layout_main):
        if lay:
            assert abs(sum(w for _, w in lay) - W) < 0.005, (formname, sum(w for _, w in lay))

    sf = SF(formname=formname, caption=caption, devclass='ZPK_BDP', user='DanhDH')

    lt = [
        ('CO', [(2.5, NONE), (19.7, NONE), (4.0, NONE)]),               # logo | don vi | lan in
        ('TT', [(W, NONE)]),                                            # tieu de, ngay
        ('IN', [(4.5, NONE), (8.6, NONE), (4.5, NONE), (8.6, NONE)]),   # nhan | gia tri | nhan | gia tri
        ('IW', [(4.5, NONE), (21.7, NONE)]),                            # nhan | gia tri ca dong
    ]
    if layout_dosage:
        lt.append(('CB', [(w, ALL) for _, w in layout_dosage]))         # bang co cot dang bao che
    lt.append(('CN', [(w, ALL) for _, w in layout_main]))               # bang thuong
    lt += [
        ('NT', [(W, NONE)]),                                            # chu thich huy, ngay ky
        ('S1', [(W, NONE)]),                                            # 1 o ky (chuyen trang thai)
        ('S3', [(8.73, NONE), (8.74, NONE), (8.73, NONE)]),             # 3 o ky
        ('S4', [(6.55, NONE)] * 4),                                     # 4 o ky (them Truong phong QLCL)
    ]

    blank = [('*', None)]

    # Moi row / folder can 1 doi tuong dieu kien rieng (INAME khong duoc trung)
    def ne_blank(field):
        return sf.cond([('NE', field, "' '")])

    def eq_blank(field):
        return sf.cond([('EQ', field, "' '")])

    def t(lines, cnd=None):
        return sf.text(lines, cnd=cnd)

    def cell_t(cap, fmt, txt, cnd=None):
        return sf.cell(cap, [t([(fmt, txt)], cnd=cnd)])

    # ---- Header bang -----------------------------------------------------------
    row_company = sf.row('Logo, don vi, lan in', 'CO', [
        sf.cell('Logo', [sf.graphic(name_expr='ZLOGO_0001', caption='Logo BIDIPHAR', alignment='L')]),
        sf.cell('Don vi', [
            t([('*', '<B1>&GS_PARAMETER-HEADER01&</>')]),
            t([('*', '<B0>&GS_PARAMETER-HEADER39&</>')], cnd=ne_blank(P + 'HEADER39')),
            t([('*', '&GS_PARAMETER-HEADER02&')]),
            t([('*', '&GS_PARAMETER-HEADER40&')], cnd=ne_blank(P + 'HEADER40')),
            t([('*', '&GS_PARAMETER-HEADER05& – &GS_PARAMETER-HEADER03& – '
                     '&GS_PARAMETER-HEADER04& – &GS_PARAMETER-HEADER06&')]),
        ]),
        cell_t('Lan in', 'R', '&GS_PARAMETER-ISO_LINE01&'),
    ])
    row_title = sf.row('Tieu de', 'TT', [
        sf.cell('Tieu de', [
            t([('C', '<B5>&GS_PARAMETER-TITLE_REPORT&</>')]),
            t([('C', '<B2>&GS_PARAMETER-TITLE_REPORT_EN&</>')], cnd=ne_blank(P + 'TITLE_REPORT_EN')),
            t([('C', '&GS_PARAMETER-HEADER08&')]),                                    # (H3)
        ]),
    ])

    def info(cap, lab1, val1, lab2, val2, cnd):
        return sf.row(cap, 'IN', [
            cell_t('Nhan 1', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab1),
            cell_t('Gia tri 1', 'L', '&GS_PARAMETER-%s&' % val1),
            cell_t('Nhan 2', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab2),
            cell_t('Gia tri 2', 'L', '&GS_PARAMETER-%s&' % val2),
        ], cnd=cnd)

    def wide(cap, lab, val, cnd):
        return sf.row(cap, 'IW', [
            cell_t('Nhan', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab),
            cell_t('Gia tri', 'L', '&GS_PARAMETER-%s&' % val),
        ], cnd=cnd)

    # Chuyen kho (HEADER09 co gia tri): so yeu cau | so chung tu; kho xuat | don vi nhan; dien giai
    # Chuyen trang thai (HEADER11 co gia tri): kho | so chung tu; chuyen trang thai | dien giai
    info_rows = [
        info('Chuyen kho: so yeu cau, so chung tu', 'HEADER20', 'HEADER21', 'HEADER22', 'HEADER23',
             ne_blank(P + 'HEADER09')),                                               # (H5) (H2)
        info('Chuyen kho: kho xuat, don vi nhan', 'HEADER16', 'HEADER17', 'HEADER09', 'HEADER10',
             ne_blank(P + 'HEADER09')),                                               # (H7) (H4)
        wide('Chuyen kho: dien giai', 'HEADER18', 'HEADER19', ne_blank(P + 'HEADER09')),  # (H6)
        info('Trang thai: kho, so chung tu', 'HEADER16', 'HEADER17', 'HEADER22', 'HEADER23',
             ne_blank(P + 'HEADER11')),                                               # (H7) (H2)
        info('Trang thai: loai ton, dien giai', 'HEADER11', 'HEADER12', 'HEADER18', 'HEADER19',
             ne_blank(P + 'HEADER11')),                                               # (H8) (H6)
    ]
    folder_first = sf.folder('Thong tin phieu - chi trang dau', [row_company, row_title] + info_rows,
                             cnd=sf.cond(ocond=['FPAGE']))

    def colhdr_row(cap, linetype, layout, cnd=None):
        return sf.row(cap, linetype, [
            cell_t('H%d' % key, 'C', '<B0>&GS_PARAMETER-%s&</>' % COLS[key][0]) for key, _ in layout
        ], cnd=cnd)

    # ---- Dong chi tiet ---------------------------------------------------------
    def detail_cell(key):
        _, lines, fmt = COLS[key]
        if not lines:
            return sf.cell('Cot %d' % key, [t(blank)])
        return sf.cell('Cot %d' % key, [t([(fmt, ln)]) for ln in lines])

    def detail_row(cap, linetype, layout, cnd=None):
        return sf.row(cap, linetype, [detail_cell(key) for key, _ in layout], cnd=cnd)

    if layout_dosage:
        dosage = P + 'PARAMETER15'
        head_rows = [colhdr_row('Tieu de cot co dang bao che', 'CB', layout_dosage, ne_blank(dosage)),
                     colhdr_row('Tieu de cot', 'CN', layout_main, eq_blank(dosage))]
        body_rows = [detail_row('Dong chi tiet co dang bao che', 'CB', layout_dosage, ne_blank(dosage)),
                     detail_row('Dong chi tiet', 'CN', layout_main, eq_blank(dosage))]
    else:
        head_rows = [colhdr_row('Tieu de cot', 'CN', layout_main)]
        body_rows = [detail_row('Dong chi tiet', 'CN', layout_main)]

    # ---- Cuoi bang: chu thich huy, ngay ky, chu ky (trang cuoi) ----------------
    row_note = sf.row('Chu thich chung tu bi huy', 'NT', [
        cell_t('Chu thich', 'L', '&GS_PARAMETER-FOOTER04&'),
    ], cnd=ne_blank(P + 'FOOTER04'))
    row_date = sf.row('Ngay ky', 'NT', [cell_t('Ngay', 'R', '&GS_PARAMETER-FOOTER05&')],
                      cnd=ne_blank(P + 'SIGN01'))

    def sign_cell(i):
        return sf.cell('Ky %d' % i, [
            t([('C', '<B0>&GS_PARAMETER-SIGN0%d&</>' % i)]),
            t([('C', '&GS_PARAMETER-SIGN06&')]),
        ])

    def sign_rows(linetype, n, cnd_fn):
        return [
            sf.row('Chuc danh ky %d o' % n, linetype, [sign_cell(i) for i in range(1, n + 1)],
                   cnd=cnd_fn()),
            sf.row('Cho ky %d o' % n, linetype,
                   [sf.cell('Trong %d' % i, [t(blank * 4)]) for i in range(1, n + 1)],
                   cnd=cnd_fn()),
        ]

    # 4 o khi SIGN04 co gia tri; 3 o khi SIGN03 co gia tri, SIGN04 trong; 1 o khi chi co SIGN01.
    # Chi dung dieu kien don, long folder de thanh AND (sf_validate chua co mau cho LOP)
    folder_s1 = sf.folder('Chu ky 1 o', sign_rows('S1', 1, lambda: eq_blank(P + 'SIGN02')),
                          cnd=ne_blank(P + 'SIGN01'))
    folder_s3 = sf.folder('Chu ky 3 hoac 1 o',
                          sign_rows('S3', 3, lambda: ne_blank(P + 'SIGN03')) + [folder_s1],
                          cnd=eq_blank(P + 'SIGN04'))
    sign = sign_rows('S4', 4, lambda: ne_blank(P + 'SIGN04')) + [folder_s3]

    folder_sign = sf.folder('Chu thich, ngay ky, chu ky',
                            [row_note, row_date] + sign,
                            cnd=sf.cond(ocond=['FOOTER']), protect=True)

    tbl = sf.table(
        caption='Bang hang chuyen kho',
        width=W,
        linetypes=lt,
        tabname='IT_DATA',
        tabheader='GS_DATA',
        events=[
            sf.event('Dau bang', 'H', [folder_first] + head_rows),
            sf.event('Du lieu', 'B', body_rows),
            sf.event('Cuoi bang', 'F', [folder_sign]),
        ])

    win_main = sf.window(iname='MAIN', caption='Main Window', wtype='M', content=[tbl],
                         geo=(L, W, TOP, 16.9), wid=1001)
    # thoi diem in + user, ban in lai (trai); trang x/y (phai)
    win_print = sf.window(
        iname='%WINDOW1', caption='Thoi diem in', wtype='T',
        content=[t([('*', '&GS_PARAMETER-FOOTER03&')]),
                 t([('*', '&GS_PARAMETER-FOOTER07&')], cnd=ne_blank(P + 'FOOTER07'))],
        geo=(L, 14.0, 18.5, 1.0), wid=1002)
    win_page = sf.window(
        iname='%WINDOW2', caption='Trang', wtype='T',
        content=[t([('R', '&GS_PARAMETER-FOOTER06& &SFSY-PAGE&/&SFSY-FORMPAGES(3ZC)&')])],
        geo=(L + W - 6.0, 6.0, 18.5, 1.0), wid=1003)

    xml = sf.render(interface=[('I', 'GS_PARAMETER', 'TYPE', 'ZCORE_ST_PARAMETER'),
                               ('T', 'IT_DATA', 'LIKE', 'ZWM_ST_PCK')],
                    gdata=[('GS_DATA', 'TYPE', 'ZWM_ST_PCK')],
                    windows=[win_main, win_print, win_page],
                    orientation='L', pageformat='DINA4')
    # Logo ZLOGO_0001 nap SE78 o 100 dpi
    xml = xml.replace('<RESOLUTION>0600</RESOLUTION>', '<RESOLUTION>0100</RESOLUTION>')
    return sf, xml


if __name__ == '__main__':
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'FS_v1.0')
    os.makedirs(out_dir, exist_ok=True)
    for name, cap, lay_dosage, lay_main in FORMS:
        sf, xml = build(name, cap, lay_dosage, lay_main)
        path = os.path.join(out_dir, name + '.xml')
        sf.write(path, xml)
        print('Da sinh form:', path)
