# -*- coding: utf-8 -*-
"""Sinh Smart Form ZWM_SF_BBKNHH - Bien ban kiem nhan hang hoa (ZWM02), theo FS v1.0.

Chuong trinh goi form 1 lan cho moi chung tu (1 bien ban) trong cung SSF_OPEN.
Moi nhan, gia tri header do chuong trinh dien vao GS_PARAMETER:
  NAME/ADDRESS/HEADER11 : don vi (ten, dia chi, MST - DT - Fax)
  HEADER02 : ma bieu mau (chi in khi co)      HEADER03 : lan in / ban in lai
  TITLE_REPORT : tieu de theo nhom hang
  PARAMETER01..07 : nhan thong tin, HEADER04..10 : gia tri
  PARAMETER11..25 : tieu de 15 cot
  FOOTER01 ngay ky, FOOTER02..04 chuc danh ky, FOOTER06 Lai xe (chi mau gay nghien),
  FOOTER05 "(Ky, ghi ro ho ten)", FOOTER07 "Trang"
IT_DATA: LEVEL 1 = dong nhom (TABLE_HEADER), LEVEL 2 = dong chi tiet.

Chay:  PYTHONUTF8=1 python gen_zwm_sf_bbknhh.py FS_v1.0/ZWM_SF_BBKNHH.xml
"""
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', '..', '.claude', 'skills',
                                'smartforms-xml', 'scripts'))

from sfgen import SF, ALL, NONE

# A4 ngang 29.7 x 21.0 cm; le trai/phai 1.0 -> vung in rong 27.7 cm
W = 27.7
L = 1.0

# 15 cot: STT | Ten hang | SDK | NSX - Nuoc | So lo NSX | So lo SAP | Ngay SX | Han dung |
#         Quy cach | DVT | SL hoa don | SL thuc te | Ho so | Niem phong | Ghi chu
C = [0.8, 3.4, 1.6, 2.6, 1.8, 1.7, 1.6, 1.7, 1.9, 1.0, 1.7, 1.6, 2.0, 2.0, 2.3]
assert abs(sum(C) - W) < 0.005

sf = SF(formname='ZWM_SF_BBKNHH',
        caption='Bien ban kiem nhan hang hoa',
        devclass='ZPK_WM',
        user='DanhDH')

LT = [
    ('CO', [(2.5, NONE), (18.2, NONE), (7.0, NONE)]),            # logo | don vi | ma bieu mau + lan in
    ('TT', [(W, NONE)]),                                         # tieu de
    ('IN', [(4.0, NONE), (9.85, NONE), (4.0, NONE), (9.85, NONE)]),   # nhan | gia tri | nhan | gia tri
    ('CL', [(w, ALL) for w in C]),                               # bang chi tiet 15 cot
    ('GR', [(W, ALL)]),                                          # dong nhom NCC/KH - chung tu - hoa don
    ('SD', [(W, NONE)]),                                         # ngay ky
    ('SG', [(6.93, NONE), (6.92, NONE), (6.93, NONE), (6.92, NONE)]),                                 # 4 o ky
]
for name, cols in LT:
    assert abs(sum(w for w, _ in cols) - W) < 0.005, name

BLANK = [('*', None)]


def ne_blank(f):
    return sf.cond([('NE', f, "' '")])


def t(lines, cnd=None):
    return sf.text(lines, cnd=cnd)


def cell_t(caption, fmt, txt):
    return sf.cell(caption, [t([(fmt, txt)])])


# ---- Header: lap lai moi trang ----------------------------------------------
row_company = sf.row('Logo, don vi, ma bieu mau', 'CO', [
    sf.cell('Logo', [sf.graphic(name_expr='ZLOGO_0001', caption='Logo BIDIPHAR', alignment='L')]),   # (H1)
    sf.cell('Don vi', [
        t([('*', '<B0>&GS_PARAMETER-NAME&</>')]),
        t([('*', '&GS_PARAMETER-ADDRESS&')]),
        t([('*', '&GS_PARAMETER-HEADER11&')]),
    ]),
    sf.cell('Ma bieu mau va lan in', [
        t([('R', 'Mã biểu mẫu: &GS_PARAMETER-HEADER02&')], cnd=ne_blank('GS_PARAMETER-HEADER02')),  # (H2)
        t([('R', '&GS_PARAMETER-HEADER03&')]),                                                      # (H3)
    ]),
])
row_title = sf.row('Tieu de', 'TT', [
    cell_t('Tieu de', 'C', '<H2>&GS_PARAMETER-TITLE_REPORT&</>'),                                   # (T1)
])


def info_row(cap, lab1, val1, lab2, val2, cnd=None):
    return sf.row(cap, 'IN', [
        cell_t('Nhan 1', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab1),
        cell_t('Gia tri 1', 'L', '&GS_PARAMETER-%s&' % val1),
        cell_t('Nhan 2', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab2) if lab2 else sf.cell('Nhan 2', [t(BLANK)]),
        cell_t('Gia tri 2', 'L', '&GS_PARAMETER-%s&' % val2) if val2 else sf.cell('Gia tri 2', [t(BLANK)]),
    ], cnd=cnd)


# Thong tin bien ban: chi trang dau
info_rows = [
    info_row('Ngay kiem nhan - Nhap tai kho', 'PARAMETER01', 'HEADER04', 'PARAMETER04', 'HEADER07'),   # (H4) (H9)
    info_row('Thu kho - Nguoi giao hang', 'PARAMETER02', 'HEADER05', 'PARAMETER05', 'HEADER08'),       # (H5) (H7)
    info_row('Nguoi kiem nhan - So xe', 'PARAMETER03', 'HEADER06', 'PARAMETER06', 'HEADER09'),        # (H6) (H8)
    info_row('Giay phep NK', 'PARAMETER07', 'HEADER10', None, None,
             cnd=ne_blank('GS_PARAMETER-FOOTER06')),                                                  # (H10) mau gay nghien
]
folder_first = sf.folder('Thong tin bien ban - chi trang dau', info_rows, cnd=sf.cond(ocond=['FPAGE']))

row_colhdr = sf.row('Tieu de cot', 'CL', [
    cell_t('H%d' % (i + 1), 'C', '<B0>&GS_PARAMETER-PARAMETER%02d&</>' % (11 + i)) for i in range(15)
])

# ---- Main: dong nhom va dong chi tiet ---------------------------------------
row_group = sf.row('Dong nhom', 'GR', [
    cell_t('Nhom', 'L', '<B0>&GS_DATA-TABLE_HEADER&</>'),                         # (16) (17) (18)
], cnd=sf.cond([('EQ', 'GS_DATA-LEVEL', "'1'")]))

row_detail = sf.row('Dong chi tiet', 'CL', [
    cell_t('STT', 'C', '&GS_DATA-STT(C)&'),                  # (1)
    cell_t('Ten hang', 'L', '&GS_DATA-MAKTX&'),              # (2)
    cell_t('SDK', 'L', '&GS_DATA-NORMT&'),                   # (3)
    cell_t('NSX - Nuoc', 'L', '&GS_DATA-NSXNS&'),            # (4)
    cell_t('So lo NSX', 'L', '&GS_DATA-SOLO&'),              # (5)
    cell_t('So lo SAP', 'L', '&GS_DATA-CHARG&'),             # (6)
    cell_t('Ngay SX', 'L', '&GS_DATA-NGAYSX(I)&'),           # (7)
    cell_t('Han dung', 'L', '&GS_DATA-HANDUNG(I)&'),         # (8)
    cell_t('Quy cach', 'L', '&GS_DATA-GROES&'),              # (9)
    cell_t('DVT', 'C', '&GS_DATA-ERFME&'),                   # (10)
    cell_t('SL hoa don', 'R', '&GS_DATA-LSMNG(IC)&'),        # (11)
    cell_t('SL thuc te', 'R', '&GS_DATA-ERFMG(IC)&'),        # (12) nguon A de trong
    cell_t('Ho so', 'L', '&GS_DATA-SGTXT&'),                 # (13)
    cell_t('Niem phong', 'L', '&GS_DATA-TXZ01&'),            # (14)
    cell_t('Ghi chu', 'L', '&GS_DATA-GHICHU&'),              # (15)
], cnd=sf.cond([('EQ', 'GS_DATA-LEVEL', "'2'")]))

# ---- Footer bang: ngay ky + chu ky (chi trang cuoi) -------------------------
row_date = sf.row('Ngay ky', 'SD', [cell_t('Ngay', 'R', '&GS_PARAMETER-FOOTER01&')])


def sign_cell(i, field, cnd_field=None):
    cnd = ne_blank(cnd_field) if cnd_field else None
    return sf.cell('Ky %d' % i, [
        t([('C', '<B0>&GS_PARAMETER-%s&</>' % field)], cnd=cnd),
        t([('C', '&GS_PARAMETER-FOOTER05&')], cnd=ne_blank(cnd_field) if cnd_field else None),
    ])


row_sign = sf.row('Chuc danh ky', 'SG', [
    sign_cell(1, 'FOOTER02'),
    sign_cell(2, 'FOOTER03'),
    sign_cell(3, 'FOOTER04'),
    sign_cell(4, 'FOOTER06', 'GS_PARAMETER-FOOTER06'),       # Lai xe: chi mau gay nghien
])
row_sign_blank = sf.row('Cho ky', 'SG', [sf.cell('Trong %d' % i, [t(BLANK * 4)]) for i in (1, 2, 3, 4)])

folder_sign = sf.folder('Ngay ky va chu ky', [row_date, row_sign, row_sign_blank],
                        cnd=sf.cond(ocond=['FOOTER']), protect=True)

tbl = sf.table(
    caption='Bang hang hoa',
    width=W,
    linetypes=LT,
    tabname='IT_DATA',
    tabheader='GS_DATA',
    events=[
        sf.event('Dau bang', 'H', [row_company, row_title, folder_first, row_colhdr]),
        sf.event('Du lieu', 'B', [row_group, row_detail]),
        sf.event('Cuoi bang', 'F', [folder_sign]),
    ])

win_main = sf.window(iname='MAIN', caption='Main Window', wtype='M', content=[tbl],
                     geo=(L, W, 1.0, 18.4), wid=1001)
# (F1) thoi diem in + user (trai), (F2) trang x/y (phai)
win_print = sf.window(
    iname='%WINDOW1', caption='Thoi diem in', wtype='T',
    content=[t([('*', 'In lúc: &SFSY-DATE& &SFSY-TIME& – User: &SFSY-USERNAME&')])],
    geo=(L, 12.0, 19.6, 0.8), wid=1002)
win_page = sf.window(
    iname='%WINDOW2', caption='Trang', wtype='T',
    content=[t([('R', '&GS_PARAMETER-FOOTER07& &SFSY-PAGE&/&SFSY-FORMPAGES(3ZC)&')])],
    geo=(L + W - 5.0, 5.0, 19.6, 0.8), wid=1003)

INTERFACE = [
    ('I', 'GS_PARAMETER', 'TYPE', 'ZCORE_ST_PARAMETER'),
    ('T', 'IT_DATA', 'LIKE', 'ZWM_ST_BBKNHH'),
]
GDATA = [
    ('GS_DATA', 'TYPE', 'ZWM_ST_BBKNHH'),
]

xml = sf.render(interface=INTERFACE, gdata=GDATA,
                windows=[win_main, win_print, win_page],
                orientation='L', pageformat='DINA4')

# Logo ZLOGO_0001 nap SE78 o 100 dpi
xml = xml.replace('<RESOLUTION>0600</RESOLUTION>', '<RESOLUTION>0100</RESOLUTION>')

out = sys.argv[1] if len(sys.argv) > 1 else 'ZWM_SF_BBKNHH.xml'
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
sf.write(out, xml)
print('Da sinh form:', out)
