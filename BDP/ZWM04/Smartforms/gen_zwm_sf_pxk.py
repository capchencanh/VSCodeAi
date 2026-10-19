# -*- coding: utf-8 -*-
"""Sinh 3 Smart Form Phieu xuat kho (ZWM04) theo FS v1.0.

  ZWM_SF_PXK       mau 1 (Nguyen lieu) va mau 3 (Thuoc gay nghien): cung layout,
                   khac tieu de va so o chu ky (do chuong trinh dien GS_PARAMETER)
  ZWM_SF_PXK_OP2   mau 2 - Hang hoa, vat tu
  ZWM_SF_PXK_OP4   mau 4 - Xuat NVL lay mau kiem nghiem (layout ZWM20, khong STT)

Moi form dung cho ca ban Viet va song ngu: nhan song ngu do chuong trinh ZWM_PG_PXK
ghep san vao GS_PARAMETER. Cot "DK bao quan" chi hien khi GS_PARAMETER-PARAMETER14
co gia tri (ZWM_PG_PXK de trong khi khong chon hien thi cot nay).
Mapping field: CodeABAP/BDP/ZWM04/ghi_chu.md muc 6.

Chay:  PYTHONUTF8=1 python gen_zwm_sf_pxk.py FS_v1.0
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

# Cot theo so hieu FS 2.5: (nhan GS_PARAMETER, noi dung GS_DATA, canh le)
COLS = {
    1:  ('PARAMETER01', ['&GS_DATA-STT(C)&'], 'C'),
    2:  ('PARAMETER02', ['&GS_DATA-MATNR&'], 'L'),
    3:  ('PARAMETER03', ['&GS_DATA-MAKTX&', ('&GS_DATA-MAKTX_EN&', 'GS_DATA-MAKTX_EN')], 'L'),
    4:  ('PARAMETER04', ['&GS_DATA-NODHL&'], 'L'),
    5:  ('PARAMETER05', ['&GS_DATA-DOAM&'], 'L'),
    6:  ('PARAMETER06', ['&GS_DATA-NSXNS&'], 'L'),
    7:  ('PARAMETER07', ['&GS_DATA-SOLO&'], 'L'),
    8:  ('PARAMETER08', ['&GS_DATA-CHARG&'], 'L'),
    9:  ('PARAMETER09', ['&GS_DATA-HANDUNG(I)&'], 'L'),
    10: ('PARAMETER10', ['&GS_DATA-NGAYKN(I)&'], 'L'),
    11: ('PARAMETER11', ['&GS_DATA-GROES&'], 'L'),
    12: ('PARAMETER12', ['&GS_DATA-ERFME&', ('&GS_DATA-ERFME_EN&', 'GS_DATA-ERFME_EN')], 'C'),
    13: ('PARAMETER13', ['&GS_DATA-ERFMG(IC)&'], 'R'),
    14: ('PARAMETER14', ['&GS_DATA-BAOQUAN&'], 'L'),
}

# Cot va do rong (cm) tung mau: BQ = co cot (14) DK bao quan, NOBQ = khong co
LAYOUT_OP1_BQ = [(1, 0.8), (2, 1.8), (3, 3.2), (4, 1.8), (5, 1.2), (6, 2.7), (7, 2.3), (8, 1.7),
                 (9, 1.7), (10, 1.7), (11, 1.8), (12, 1.1), (13, 1.9), (14, 2.5)]
LAYOUT_OP1_NOBQ = [(1, 0.8), (2, 1.8), (3, 4.2), (4, 1.9), (5, 1.3), (6, 3.2), (7, 2.4), (8, 1.8),
                   (9, 1.8), (10, 1.8), (11, 2.1), (12, 1.1), (13, 2.0)]
LAYOUT_OP2_BQ = [(1, 0.8), (2, 1.9), (3, 4.0), (6, 3.0), (7, 2.5), (8, 2.0), (9, 1.9), (10, 1.9),
                 (11, 2.1), (12, 1.2), (13, 2.1), (14, 2.8)]
LAYOUT_OP2_NOBQ = [(1, 0.8), (2, 1.9), (3, 4.6), (6, 3.4), (7, 3.0), (8, 2.2), (9, 2.2), (10, 2.2),
                   (11, 2.6), (12, 1.2), (13, 2.1)]
LAYOUT_OP4 = [(2, 2.2), (3, 4.6), (6, 4.0), (7, 3.0), (8, 2.2), (9, 2.2), (10, 2.2), (11, 2.6),
              (12, 1.2), (13, 2.0)]

# (ten form, mo ta, layout co cot bao quan, layout khong co, mau 4)
FORMS = [
    ('ZWM_SF_PXK',     'Phieu xuat kho nguyen lieu, thuoc gay nghien', LAYOUT_OP1_BQ, LAYOUT_OP1_NOBQ, False),
    ('ZWM_SF_PXK_OP2', 'Phieu xuat kho hang hoa, vat tu',               LAYOUT_OP2_BQ, LAYOUT_OP2_NOBQ, False),
    ('ZWM_SF_PXK_OP4', 'Phieu xuat kho NVL lay mau kiem nghiem',         None,          LAYOUT_OP4,      True),
]


def build(formname, caption, layout_bq, layout_nobq, is_op4):
    for lay in (layout_bq, layout_nobq):
        if lay:
            assert abs(sum(w for _, w in lay) - W) < 0.005, (formname, sum(w for _, w in lay))

    sf = SF(formname=formname, caption=caption, devclass='ZPK_BDP', user='DanhDH')

    lt = [
        ('CO', [(2.5, NONE), (19.7, NONE), (4.0, NONE)]),               # logo | don vi | lan in
        ('TT', [(W, NONE)]),                                            # tieu de, ngay
        ('IN', [(4.5, NONE), (8.6, NONE), (4.5, NONE), (8.6, NONE)]),   # nhan | gia tri | nhan | gia tri
        ('IW', [(4.5, NONE), (21.7, NONE)]),                            # nhan | gia tri ca dong
    ]
    if layout_bq:
        lt.append(('CB', [(w, ALL) for _, w in layout_bq]))             # bang chi tiet co cot bao quan
    lt.append(('CN', [(w, ALL) for _, w in layout_nobq]))               # bang chi tiet khong co cot bao quan
    lt += [
        ('NT', [(W, NONE)]),                                            # chu thich dieu chinh, ngay ky
        ('S3', [(8.73, NONE), (8.74, NONE), (8.73, NONE)]),             # 3 o ky
        ('S5', [(5.24, NONE)] * 4 + [(5.24, NONE)]),                    # 5 o ky (mau 3)
    ]

    blank = [('*', None)]

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
            t([('C', '&GS_PARAMETER-HEADER08&')]),                                    # (H2)
        ]),
    ])

    def info(cap, lab1, val1, lab2, val2):
        return sf.row(cap, 'IN', [
            cell_t('Nhan 1', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab1),
            cell_t('Gia tri 1', 'L', '&GS_PARAMETER-%s&' % val1),
            cell_t('Nhan 2', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab2),
            cell_t('Gia tri 2', 'L', '&GS_PARAMETER-%s&' % val2),
        ])

    def wide(cap, lab, val):
        return sf.row(cap, 'IW', [
            cell_t('Nhan', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab),
            cell_t('Gia tri', 'L', '&GS_PARAMETER-%s&' % val),
        ])

    info_rows = [
        info('Ma don vi nhan - So CT kho', 'HEADER09', 'HEADER10', 'HEADER22', 'HEADER23'),      # (H3) (H9)
        info('Ten don vi nhan - So CT ke toan', 'HEADER11', 'HEADER12', 'HEADER24', 'HEADER25'),  # (H4) (H10)
        info('Kho xuat - Lenh xuat kho', 'HEADER16', 'HEADER17', 'HEADER20', 'HEADER21'),         # (H6) (H8)
        wide('Dia chi', 'HEADER13', 'HEADER14'),                                                  # (H5)
        wide('Dien giai', 'HEADER18', 'HEADER19'),                                                # (H7)
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
        texts = []
        for ln in lines:
            if isinstance(ln, tuple):
                texts.append(t([(fmt, ln[0])], cnd=ne_blank(ln[1])))
            else:
                texts.append(t([(fmt, ln)]))
        return sf.cell('Cot %d' % key, texts)

    def detail_row(cap, linetype, layout, cnd=None):
        return sf.row(cap, linetype, [detail_cell(key) for key, _ in layout], cnd=cnd)

    if layout_bq:
        bq_blank = P + 'PARAMETER14'
        head_rows = [colhdr_row('Tieu de cot co DK bao quan', 'CB', layout_bq, ne_blank(bq_blank)),
                     colhdr_row('Tieu de cot', 'CN', layout_nobq, eq_blank(bq_blank))]
        body_rows = [detail_row('Dong chi tiet co DK bao quan', 'CB', layout_bq, ne_blank(bq_blank)),
                     detail_row('Dong chi tiet', 'CN', layout_nobq, eq_blank(bq_blank))]
    else:
        head_rows = [colhdr_row('Tieu de cot', 'CN', layout_nobq)]
        body_rows = [detail_row('Dong chi tiet', 'CN', layout_nobq)]

    # ---- Cuoi bang: chu thich dieu chinh, ngay ky, chu ky (trang cuoi) --------
    row_note = sf.row('Chu thich dieu chinh', 'NT', [
        cell_t('Chu thich', 'L', '&GS_PARAMETER-LONG_TEXT1&'),
    ], cnd=ne_blank(P + 'LONG_TEXT1'))
    row_date = sf.row('Ngay ky', 'NT', [cell_t('Ngay', 'R', '&GS_PARAMETER-FOOTER05&')])

    def sign_cell(i, field):
        return sf.cell('Ky %d' % i, [
            t([('C', '<B0>&GS_PARAMETER-%s&</>' % field)]),
            t([('C', '&GS_PARAMETER-SIGN06&')]),
        ])

    def sign_rows(linetype, n, cnd_fn=None):
        # moi row 1 dieu kien rieng (INAME khong duoc trung)
        return [
            sf.row('Chuc danh ky %d o' % n, linetype,
                   [sign_cell(i, 'SIGN0%d' % i) for i in range(1, n + 1)],
                   cnd=cnd_fn() if cnd_fn else None),
            sf.row('Cho ky %d o' % n, linetype,
                   [sf.cell('Trong %d' % i, [t(blank * 4)]) for i in range(1, n + 1)],
                   cnd=cnd_fn() if cnd_fn else None),
        ]

    if is_op4:
        sign = sign_rows('S3', 3)
    elif formname == 'ZWM_SF_PXK':
        # Mau 3 co 5 o ky (SIGN04 co gia tri), mau 1 chi 3 o
        sign = (sign_rows('S3', 3, lambda: eq_blank(P + 'SIGN04')) +
                sign_rows('S5', 5, lambda: ne_blank(P + 'SIGN04')))
    else:
        sign = sign_rows('S3', 3)

    folder_sign = sf.folder('Chu thich, ngay ky, chu ky',
                            [row_note, row_date] + sign,
                            cnd=sf.cond(ocond=['FOOTER']), protect=True)

    tbl = sf.table(
        caption='Bang hang xuat kho',
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
    # (F1) thoi diem in + user, ban in lai (trai); trang x/y (phai)
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
                               ('T', 'IT_DATA', 'LIKE', 'ZWM_ST_PXK')],
                    gdata=[('GS_DATA', 'TYPE', 'ZWM_ST_PXK')],
                    windows=[win_main, win_print, win_page],
                    orientation='L', pageformat='DINA4')
    # Logo ZLOGO_0001 nap SE78 o 100 dpi
    xml = xml.replace('<RESOLUTION>0600</RESOLUTION>', '<RESOLUTION>0100</RESOLUTION>')
    return sf, xml


if __name__ == '__main__':
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'FS_v1.0')
    os.makedirs(out_dir, exist_ok=True)
    for name, cap, lay_bq, lay_nobq, op4 in FORMS:
        sf, xml = build(name, cap, lay_bq, lay_nobq, op4)
        path = os.path.join(out_dir, name + '.xml')
        sf.write(path, xml)
        print('Da sinh form:', path)
