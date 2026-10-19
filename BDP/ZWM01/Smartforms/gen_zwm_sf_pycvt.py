# -*- coding: utf-8 -*-
"""Sinh Smart Form ZWM_SF_PYCVT - Phieu yeu cau vat tu (ZWM01), theo FS v1.0 muc 2.5.

Mot form dung chung cho 3 loai phieu va tuy chon song ngu:
  - tieu de, nhan, chu ky do chuong trinh dien vao GS_PARAMETER (theo loai phieu)
  - GW_FLAG = 'X' : in them dong tieng Anh duoi tieu de cot
Khong in thong tin so sanh ton (ket luan WS2 eWM).

Chay:  PYTHONUTF8=1 python gen_zwm_sf_pycvt.py FS_v1.0/ZWM_SF_PYCVT.xml
"""
import sys
import os
import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', '..', '.claude', 'skills',
                                'smartforms-xml', 'scripts'))

from sfgen import SF, ALL, NONE

# A4 doc 21.0 cm; le trai 2, phai 1.5 -> vung in rong 17.5 cm (FS 2.5.1)
W = 17.5
L = 2.0

# 10 cot: STT | Ma hang | Ten hang | DVT | SL yeu cau | SL thuc xuat |
#         So lo SAP | So lo NSX | Nha san xuat | Ghi chu
C = [0.9, 1.9, 3.0, 1.0, 1.8, 1.7, 1.9, 1.9, 1.9, 1.5]
assert abs(sum(C) - W) < 0.005

# Code chuyển dự án coi như tạo mới: không đánh dấu tên/ngày trong node code
# now = datetime.datetime.now()
# TAG_B = '"DanhDH add begin %s' % now.strftime('%d.%m.%Y %H:%M:%S')
# TAG_E = '"DanhDH add end %s' % now.strftime('%d.%m.%Y %H:%M:%S')

sf = SF(formname='ZWM_SF_PYCVT',
        caption='Phieu yeu cau vat tu',
        devclass='ZPK_BDP',
        user='DanhDH')

LT = [
    ('CO', [(3.5, NONE), (W - 3.5, NONE)]),                  # logo | ten - dia chi - MST - dien thoai
    ('FM', [(W - 6.0, NONE), (6.0, NONE)]),                  # trong | ma bieu mau + lan in
    ('TT', [(W, NONE)]),                                     # tieu de
    ('IN', [(4.0, NONE), (W - 4.0, NONE)]),                  # nhan | gia tri
    ('CL', [(w, ALL) for w in C]),                           # bang chi tiet 10 cot
    ('SD', [(W, NONE)]),                                     # ngay ky
    ('SG', [(4.38, NONE), (4.38, NONE), (4.38, NONE), (4.36, NONE)]),   # 4 o ky
]
for name, cols in LT:
    assert abs(sum(w for w, _ in cols) - W) < 0.005, name

BLANK = [('*', None)]
NE_BLANK = lambda f: sf.cond([('NE', f, "' '")])


def t(lines, cnd=None, caption=None):
    return sf.text(lines, cnd=cnd, caption=caption)


def cell_t(caption, fmt, txt):
    return sf.cell(caption, [t([(fmt, txt)])])


# ---- Header event: khoi dau trang (lap lai moi trang) ---------------------
row_company = sf.row('Logo va don vi', 'CO', [
    sf.cell('Logo', [sf.graphic(name_expr='ZLOGO_0001', caption='Logo BIDIPHAR', alignment='L')]),   # (H1)
    sf.cell('Don vi', [
        t([('*', '<B0>&GS_PARAMETER-HEADER02&</>')]),                                         # (H2) ten Plant
        t([('*', '<B0>&GS_PARAMETER-NAME&</>')], cnd=NE_BLANK('GS_PARAMETER-NAME')),         # ten tieng Anh (song ngu)
        t([('*', '&GS_PARAMETER-HEADER03&')]),                                                # (H3) dia chi
        t([('*', '&GS_PARAMETER-ADDRESS&')], cnd=NE_BLANK('GS_PARAMETER-ADDRESS')),          # dia chi tieng Anh
        t([('*', '&GS_PARAMETER-TAX&   &GS_PARAMETER-TEL_NUMBER&'),                           # (H4) MST, dien thoai
           ('*', '&GS_PARAMETER-FAX_NUMBER&')]),
    ]),
])
row_formcode = sf.row('Ma bieu mau va lan in', 'FM', [
    sf.cell('Trong', [t(BLANK)]),
    sf.cell('Ma va lan in', [
        t([('R', '&GS_PARAMETER-HEADER18&')], cnd=NE_BLANK('GS_PARAMETER-HEADER18')),         # (H5) ma bieu mau - cho BIDIPHAR
        t([('R', '&GS_PARAMETER-HEADER19&')], cnd=NE_BLANK('GS_PARAMETER-HEADER19')),         # (H6) lan in - cho nhat ky in
    ]),
])

# Tieu de + thong tin phieu: chi trang dau
INFO = [
    ('So phieu', 'HEADER04', 'HEADER15', None),            # (a)
    ('Ngay yeu cau', 'HEADER14', 'HEADER05', None),        # (b)
    ('Don vi nhan', 'HEADER06', 'HEADER07', None),         # (c)
    ('Don vi xuat', 'HEADER08', 'HEADER09', None),         # (d)
    ('Nguoi yeu cau', 'HEADER10', 'HEADER11', None),       # (e)
    ('Dien giai', 'HEADER12', 'HEADER13', None),           # (f)
    ('Thiet bi', 'HEADER16', 'HEADER17', 'GS_PARAMETER-HEADER17'),   # (g) chi khi co thiet bi
]
info_rows = []
for cap, lab, val, need in INFO:
    info_rows.append(sf.row(cap, 'IN', [
        cell_t('Nhan', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab),
        cell_t('Gia tri', 'L', '&GS_PARAMETER-%s&' % val),
    ], cnd=NE_BLANK(need) if need else None))

row_title = sf.row('Tieu de', 'TT', [
    cell_t('Tieu de', 'C', '<H2>&GS_PARAMETER-HEADER01&</>'),                                 # (T1)
])
folder_first = sf.folder('Tieu de va thong tin phieu - chi trang dau',
                         [row_title] + info_rows, cnd=sf.cond(ocond=['FPAGE']))

# Tieu de cot - lap lai moi trang. Dong tieng Anh chi in khi song ngu.
COLHDR = [(1, 11), (2, 12), (3, 13), (4, 14), (5, 15), (7, 17), (6, 16), (9, 19), (10, 20), (8, 18)]
# thu tu cot: STT, Ma, Ten, DVT, SL yeu cau, SL thuc xuat, So lo SAP, So lo NSX, NSX, Ghi chu
# PARAMETER 01..10 = tieu de VN, 11..20 = tieu de EN (chuong trinh GET_PARAMETER dien)
COLHDR = [(1, 11), (2, 12), (3, 13), (4, 14), (5, 15), (7, 17), (6, 16), (9, 19), (10, 20), (8, 18)]
cond_en = sf.cond([('EQ', 'GW_FLAG', "'X'")])
hdr_cells = []
for i, (vn, en) in enumerate(COLHDR):
    hdr_cells.append(sf.cell('H%d' % (i + 1), [
        t([('C', '<B0>&GS_PARAMETER-PARAMETER%02d&</>' % vn)]),
        t([('C', '<B0>&GS_PARAMETER-PARAMETER%02d&</>' % en)], cnd=sf.cond([('EQ', 'GW_FLAG', "'X'")])),
    ]))
row_colhdr = sf.row('Tieu de cot', 'CL', hdr_cells)

# ---- Main event: moi dong vat tu --------------------------------------------
code_stt = sf.code('Tang STT', ['GW_STT'], ['GW_STT'],
                   ['GW_STT = GW_STT + 1.'])
row_detail = sf.row('Dong du lieu', 'CL', [
    sf.cell('STT', [code_stt, t([('C', '&GW_STT(ZC)&')])]),                      # (1)
    cell_t('Ma hang', 'L', '&GS_DATA-MATNR&'),                                  # (2)
    cell_t('Ten hang', 'L', '&GS_DATA-MAKTX&'),                                 # (3)
    cell_t('DVT', 'C', '&GS_DATA-ERFME&'),                                      # (4)
    cell_t('SL yeu cau', 'R', '&GS_DATA-ERFMG(C)&'),                            # (5)
    sf.cell('SL thuc xuat', [t(BLANK)]),                                        # (6) de trong, ghi tay
    cell_t('So lo SAP', 'L', '&GS_DATA-CHARG&'),                                # (7)
    cell_t('So lo NSX', 'L', '&GS_DATA-Z_BATCH_NSX&'),                          # (8)
    cell_t('Nha san xuat', 'L', '&GS_DATA-Z_NSX&'),                             # (9)
    cell_t('Ghi chu', 'L', '&GS_DATA-ABLAD&'),                                  # (10)
])

# ---- Footer event: ngay ky + chu ky (chi trang cuoi) -------------------------
row_date = sf.row('Ngay ky', 'SD', [
    cell_t('Ngay', 'R', '&GS_PARAMETER-FOOTER05&'),                              # (S1)
])
row_sign = sf.row('Chuc danh', 'SG', [
    sf.cell('Ky %d' % i, [t([('C', '<B0>&GS_PARAMETER-FOOTER0%d&</>' % i),
                            ('C', '(Ký, ghi rõ họ tên)')]),
                          t([('C', '(Signature, full name)')], cnd=sf.cond([('EQ', 'GW_FLAG', "'X'")]))]) for i in (1, 2, 3, 4)])   # (S2)
row_sign_blank = sf.row('Cho ky', 'SG', [sf.cell('Ky %d' % i, [t(BLANK * 4)]) for i in (1, 2, 3, 4)])

folder_sign = sf.folder('Ngay ky va chu ky', [row_date, row_sign, row_sign_blank],
                        cnd=sf.cond(ocond=['FOOTER']), protect=True)

tbl = sf.table(
    caption='Bang vat tu',
    width=W,
    linetypes=LT,
    tabname='GT_DATA',
    tabheader='GS_DATA',
    events=[
        sf.event('Dau bang', 'H', [row_company, row_formcode, folder_first, row_colhdr]),
        sf.event('Du lieu', 'B', [row_detail]),
        sf.event('Cuoi bang', 'F', [folder_sign]),
    ])

# Chuong trinh goi form nhieu lan trong 1 SSF_OPEN (moi Reservation 1 phieu)
# -> GW_STT la bien global, phai reset dau moi phieu de STT bat dau lai tu 1
code_reset_stt = sf.code('Reset STT', [], ['GW_STT'], ['CLEAR GW_STT.'])

win_main = sf.window(iname='MAIN', caption='Main Window', wtype='M', content=[code_reset_stt, tbl],
                     geo=(L, W, 1.5, 25.75), wid=1001)
# (F1)(F2): thoi diem in + user (trai), trang x/y (phai)
win_print = sf.window(
    iname='%WINDOW1', caption='Ngay gio in', wtype='T',
    content=[t([('*', '&SFSY-DATE&  &SFSY-TIME&  &SFSY-USERNAME&')])],
    geo=(L, 8.5, 27.3, 0.9), wid=1002)
win_page = sf.window(
    iname='%WINDOW2', caption='Trang in', wtype='T',
    content=[t([('R', '&GS_PARAMETER-FOOTER06& &SFSY-PAGE&/&SFSY-FORMPAGES(3ZC)&')])],
    geo=(L + W - 4.4, 4.4, 27.3, 0.9), wid=1003)

INTERFACE = [
    ('I', 'GS_PARAMETER', 'TYPE', 'ZCORE_ST_PARAMETER'),
    ('I', 'GW_FLAG', 'TYPE', 'CHAR1'),
    ('T', 'GT_DATA', 'LIKE', 'ZWM_ST_PYCVT'),
]
GDATA = [
    ('GS_DATA', 'TYPE', 'ZWM_ST_PYCVT'),
    ('GW_STT', 'TYPE', 'INT4'),
]

xml = sf.render(interface=INTERFACE, gdata=GDATA,
                windows=[win_main, win_print, win_page],
                orientation='P', pageformat='DINA4')

# Logo ZLOGO_0001 nap SE78 o 100 dpi
xml = xml.replace('<RESOLUTION>0600</RESOLUTION>', '<RESOLUTION>0100</RESOLUTION>')

out = sys.argv[1] if len(sys.argv) > 1 else 'ZWM_SF_PYCVT.xml'
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
sf.write(out, xml)
print('Da sinh form:', out)
