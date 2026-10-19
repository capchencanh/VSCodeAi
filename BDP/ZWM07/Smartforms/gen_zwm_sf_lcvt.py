# -*- coding: utf-8 -*-
"""Sinh Smart Form Lenh chuyen vi tri (ZWM07) theo FS v1.0.

  ZWM_SF_LCVT   1 form cho ca 3 Option; nhan, tieu de, tieu de phu (Ban doi chieu) va so o chu ky
                (2 o, them Nguoi nhan khi SIGN03 co gia tri) do chuong trinh ZWM_PG_LCVT dien GS_PARAMETER.
                Moi lan goi form = 1 phieu (gom nhieu WT hoac 1 Warehouse Order).
Mapping field: CodeABAP/BDP/ZWM07/ghi_chu.md muc 5.

Chay:  PYTHONUTF8=1 python gen_zwm_sf_lcvt.py FS_v1.0
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

# Cot theo so hieu FS 2.5: (nhan GS_PARAMETER, noi dung GS_DATA, canh le); noi dung rong = cot ghi tay
# (1) Warehouse Task va (5) So WT cung nguon /SCWM/ORDIM_C - Whs Task theo FS
COLS = [
    (0,  'PARAMETER01', ['&GS_DATA-STT(C)&'], 'C', 0.8),
    (1,  'PARAMETER02', ['&GS_DATA-TANUM&'], 'L', 2.5),
    (2,  'PARAMETER03', [], 'C', 1.5),
    (3,  'PARAMETER04', ['&GS_DATA-VLPLA&'], 'L', 2.3),
    (4,  'PARAMETER05', ['&GS_DATA-NLPLA&'], 'L', 2.3),
    (5,  'PARAMETER06', ['&GS_DATA-TANUM&'], 'L', 2.5),
    (6,  'PARAMETER07', ['&GS_DATA-MATNR&'], 'L', 1.8),
    (7,  'PARAMETER08', ['&GS_DATA-MAKTX&'], 'L', 3.0),
    (8,  'PARAMETER09', ['&GS_DATA-CHARG&'], 'L', 1.8),
    (9,  'PARAMETER10', ['&GS_DATA-SOLO&'], 'L', 2.0),
    (10, 'PARAMETER11', ['&GS_DATA-MENGE(IC)&'], 'R', 1.7),
    (11, 'PARAMETER12', ['&GS_DATA-MEINS&'], 'C', 1.0),
    (12, 'PARAMETER13', [], 'C', 1.6),
    (13, 'PARAMETER14', [], 'C', 1.4),
]

FORMNAME = 'ZWM_SF_LCVT'
CAPTION = 'Lenh chuyen vi tri'


def build():
    assert abs(sum(c[4] for c in COLS) - W) < 0.005, sum(c[4] for c in COLS)

    sf = SF(formname=FORMNAME, caption=CAPTION, devclass='ZPK_BDP', user='DanhDH')

    lt = [
        ('CO', [(2.5, NONE), (19.7, NONE), (4.0, NONE)]),                  # logo | don vi | ma vach, lan in
        ('TT', [(W, NONE)]),                                               # tieu de, ngay
        ('IN', [(4.8, NONE), (8.3, NONE), (4.8, NONE), (8.3, NONE)]),      # nhan | gia tri | nhan | gia tri
        ('IW', [(4.8, NONE), (21.4, NONE)]),                               # nhan | gia tri ca dong
        ('CN', [(c[4], ALL) for c in COLS]),                               # bang chi tiet
        ('NT', [(W, NONE)]),                                               # ngay ky
        ('S2', [(13.1, NONE), (13.1, NONE)]),                              # 2 o ky
        ('S3', [(8.73, NONE), (8.74, NONE), (8.73, NONE)]),                # 3 o ky (them Nguoi nhan)
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

    # ---- Header bang (chi trang dau) ----------------------------------------------
    row_company = sf.row('Logo, don vi, ma vach', 'CO', [
        sf.cell('Logo', [sf.graphic(name_expr='ZLOGO_0001', caption='Logo BIDIPHAR', alignment='L')]),
        sf.cell('Don vi', [
            t([('*', '<B1>&GS_PARAMETER-HEADER01&</>')]),
            t([('*', '&GS_PARAMETER-HEADER02&')]),
            t([('*', '&GS_PARAMETER-HEADER05& – &GS_PARAMETER-HEADER03& – '
                     '&GS_PARAMETER-HEADER04& – &GS_PARAMETER-HEADER06&')]),
            t([('*', '<B0>&GS_PARAMETER-HEADER07&</>')]),                              # Warehouse
        ]),
        sf.cell('Ma vach, lan in', [
            t([('R', '<Z2>&GS_PARAMETER-BARCODE&</>')], cnd=ne_blank(P + 'BARCODE')),  # so Warehouse Order / WT
            t([('R', '&GS_PARAMETER-ISO_LINE01&')]),
        ]),
    ])
    row_title = sf.row('Tieu de', 'TT', [
        sf.cell('Tieu de', [
            t([('C', '<B5>&GS_PARAMETER-TITLE_REPORT&</>')]),
            t([('C', '<B0>&GS_PARAMETER-BELOW_TITLE_REPORT&</>')],
              cnd=ne_blank(P + 'BELOW_TITLE_REPORT')),                                 # Ban doi chieu
            t([('C', '&GS_PARAMETER-HEADER08&')]),                                     # ngay
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
        info('Plant/SLoc, chung tu tham chieu', 'HEADER09', 'HEADER10', 'HEADER13', 'HEADER14'),  # (H3) (H5)
        info('Nguoi tao, lenh SX/khach hang', 'HEADER11', 'HEADER12', 'HEADER15', 'HEADER16'),    # (H4) (H6)
        wide('Loai dieu chuyen', 'HEADER17', 'HEADER18'),                                          # (H7)
    ]
    folder_first = sf.folder('Thong tin phieu - chi trang dau', [row_company, row_title] + info_rows,
                             cnd=sf.cond(ocond=['FPAGE']))

    # Tieu de cot lap lai moi trang
    row_colhdr = sf.row('Tieu de cot', 'CN', [
        cell_t('H%d' % c[0], 'C', '<B0>&GS_PARAMETER-%s&</>' % c[1]) for c in COLS
    ])

    # ---- Dong chi tiet --------------------------------------------------------------
    def detail_cell(col):
        key, _, lines, fmt, _ = col
        if not lines:
            return sf.cell('Cot %d' % key, [t(blank)])
        return sf.cell('Cot %d' % key, [t([(fmt, ln)]) for ln in lines])

    row_detail = sf.row('Dong chi tiet', 'CN', [detail_cell(c) for c in COLS])

    # ---- Cuoi bang: ngay ky, chu ky (trang cuoi) ------------------------------------
    row_date = sf.row('Ngay ky', 'NT', [cell_t('Ngay', 'R', '&GS_PARAMETER-FOOTER05&')])

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

    # 3 o khi SIGN03 co gia tri (Option 2, 3), con lai 2 o
    sign = (sign_rows('S3', 3, lambda: ne_blank(P + 'SIGN03'))
            + sign_rows('S2', 2, lambda: eq_blank(P + 'SIGN03')))

    folder_sign = sf.folder('Ngay ky, chu ky', [row_date] + sign,
                            cnd=sf.cond(ocond=['FOOTER']), protect=True)

    tbl = sf.table(
        caption='Bang Warehouse Task',
        width=W,
        linetypes=lt,
        tabname='IT_DATA',
        tabheader='GS_DATA',
        events=[
            sf.event('Dau bang', 'H', [folder_first, row_colhdr]),
            sf.event('Du lieu', 'B', [row_detail]),
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
                               ('T', 'IT_DATA', 'LIKE', 'ZWM_ST_LCVT')],
                    gdata=[('GS_DATA', 'TYPE', 'ZWM_ST_LCVT')],
                    windows=[win_main, win_print, win_page],
                    orientation='L', pageformat='DINA4')
    # Logo ZLOGO_0001 nap SE78 o 100 dpi
    xml = xml.replace('<RESOLUTION>0600</RESOLUTION>', '<RESOLUTION>0100</RESOLUTION>')
    return sf, xml


if __name__ == '__main__':
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'FS_v1.0')
    os.makedirs(out_dir, exist_ok=True)
    sf, xml = build()
    path = os.path.join(out_dir, FORMNAME + '.xml')
    sf.write(path, xml)
    print('Da sinh form:', path)
