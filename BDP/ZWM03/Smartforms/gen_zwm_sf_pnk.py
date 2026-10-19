# -*- coding: utf-8 -*-
"""Sinh 4 Smart Form Phieu nhap kho (ZWM03) theo FS v1.0.

  ZWM_SF_PNK       mau 1 - Nguyen lieu
  ZWM_SF_PNK_OP2   mau 2 - Hang hoa, vat tu
  ZWM_SF_PNK_OP3   mau 3 - Thanh pham (nhieu chung tu 1 phieu, so chung tu tren tung dong)
  ZWM_SF_PNK_OP4   mau 4 - NL, BB co quy doi

Moi form dung cho ca ban Viet va song ngu: nhan song ngu do chuong trinh ZWM_PG_PNK
ghep san vao GS_PARAMETER. Mapping field: CodeABAP/BDP/ZWM03/ghi_chu.md muc 6.

Chay:  PYTHONUTF8=1 python gen_zwm_sf_pnk.py FS_v1.0
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

# Cot theo so hieu FS: (nhan GS_PARAMETER, noi dung GS_DATA, canh le)
COLS = {
    '1':  ('PARAMETER01', ['&GS_DATA-STT(C)&'], 'C'),
    '2':  ('PARAMETER02', ['&GS_DATA-EBELN&'], 'L'),
    '3':  ('PARAMETER03', ['&GS_DATA-MATNR&'], 'L'),
    '4':  ('PARAMETER04', ['&GS_DATA-MAKTX&', ('&GS_DATA-MAKTX_EN&', 'GS_DATA-MAKTX_EN')], 'L'),
    '5':  ('PARAMETER05', ['&GS_DATA-NODHL&'], 'L'),
    '6':  ('PARAMETER06', ['&GS_DATA-DOAM&'], 'L'),
    '7':  ('PARAMETER07', ['&GS_DATA-NSXNS&'], 'L'),
    '8':  ('PARAMETER08', ['&GS_DATA-SOLO&'], 'L'),
    '8a': ('PARAMETER09', ['&GS_DATA-CHARG&'], 'L'),
    '9':  ('PARAMETER10', ['&GS_DATA-HANDUNG(I)&'], 'L'),
    '10': ('PARAMETER11', ['&GS_DATA-GROES&'], 'L'),
    '11': ('PARAMETER12', ['&GS_DATA-ERFME&', ('&GS_DATA-ERFME_EN&', 'GS_DATA-ERFME_EN')], 'C'),
    '12': ('PARAMETER13', ['&GS_DATA-ERFMG(IC)&'], 'R'),
    '13': ('PARAMETER14', ['&GS_DATA-QUYDOI&'], 'L'),
    '14': ('PARAMETER15', ['&GS_DATA-BAOQUAN&'], 'L'),
    '15': ('PARAMETER16', ['&GS_DATA-MBLNR&'], 'L'),
}

# Cot va do rong (cm) tung mau - FS 2.5
LAYOUT_L1 = [('1', 0.8), ('2', 1.9), ('3', 1.8), ('4', 4.2), ('5', 2.2), ('6', 1.5), ('7', 3.0),
             ('8', 1.8), ('8a', 1.8), ('9', 1.7), ('10', 2.2), ('11', 1.1), ('12', 2.2)]
LAYOUT_L2 = [('1', 0.8), ('2', 1.9), ('3', 1.8), ('4', 4.0), ('7', 2.8), ('8', 1.7), ('8a', 1.7),
             ('9', 1.7), ('10', 2.0), ('11', 1.1), ('12', 1.9), ('13', 2.4), ('14', 2.4)]
LAYOUT_L3 = [('1', 0.8), ('15', 1.9), ('3', 1.8), ('4', 4.0), ('7', 2.8), ('8', 1.7), ('8a', 1.7),
             ('9', 1.7), ('10', 2.0), ('11', 1.1), ('12', 1.9), ('13', 2.4), ('14', 2.4)]

FORMS = [
    ('ZWM_SF_PNK',      'Phieu nhap kho nguyen lieu',      LAYOUT_L1, False),
    ('ZWM_SF_PNK_OP2',  'Phieu nhap kho hang hoa, vat tu', LAYOUT_L2, False),
    ('ZWM_SF_PNK_OP3', 'Phieu nhap kho thanh pham',       LAYOUT_L3, True),
    ('ZWM_SF_PNK_OP4',  'Phieu nhap kho NL, BB co quy doi', LAYOUT_L2, False),
]


def build(formname, caption, layout, is_op3):
    assert abs(sum(w for _, w in layout) - W) < 0.005, formname

    sf = SF(formname=formname, caption=caption, devclass='ZPK_WM', user='DanhDH')

    lt = [
        ('CO', [(2.5, NONE), (19.7, NONE), (4.0, NONE)]),               # logo | don vi | lan in
        ('TT', [(W, NONE)]),                                            # tieu de, ngay
        ('IN', [(4.5, NONE), (8.6, NONE), (4.5, NONE), (8.6, NONE)]),   # nhan | gia tri | nhan | gia tri
        ('IW', [(4.5, NONE), (21.7, NONE)]),                            # nhan | gia tri ca dong
        ('CL', [(w, ALL) for _, w in layout]),                          # bang chi tiet
        ('NT', [(W, NONE)]),                                            # chu thich dieu chinh, ngay ky
        ('SG', [(8.73, NONE), (8.74, NONE), (8.73, NONE)]),             # 3 o ky
    ]

    blank = [('*', None)]

    def ne_blank(field):
        return sf.cond([('NE', field, "' '")])

    def t(lines, cnd=None):
        return sf.text(lines, cnd=cnd)

    def cell_t(cap, fmt, txt, cnd=None):
        return sf.cell(cap, [t([(fmt, txt)], cnd=cnd)])

    # ---- Header bang -----------------------------------------------------------
    row_company = sf.row('Logo, don vi, lan in', 'CO', [
        sf.cell('Logo', [sf.graphic(name_expr='ZLOGO_0001', caption='Logo BIDIPHAR', alignment='L')]),
        sf.cell('Don vi', [                                                         # (H1)
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
            t([('C', '<B5>&GS_PARAMETER-TITLE_REPORT&</>')]),                        # (T1)
            t([('C', '<B2>&GS_PARAMETER-TITLE_REPORT_EN&</>')], cnd=ne_blank(P + 'TITLE_REPORT_EN')),
            t([('C', '&GS_PARAMETER-HEADER08&')]),                                   # (H2)
        ]),
    ])

    def info(cap, lab1, val1, lab2=None, val2=None):
        cells = [
            cell_t('Nhan 1', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab1),
            cell_t('Gia tri 1', 'L', '&GS_PARAMETER-%s&' % val1),
        ]
        if lab2:
            cells += [cell_t('Nhan 2', 'L', '<B0>&GS_PARAMETER-%s&</>' % lab2),
                      cell_t('Gia tri 2', 'L', '&GS_PARAMETER-%s&' % val2)]
        else:
            cells += [sf.cell('Nhan 2', [t(blank)]), sf.cell('Gia tri 2', [t(blank)])]
        return sf.row(cap, 'IN', cells)

    row_descr = sf.row('Dien giai', 'IW', [
        cell_t('Nhan', 'L', '<B0>&GS_PARAMETER-HEADER27&</>'),
        cell_t('Gia tri', 'L', '&GS_PARAMETER-HEADER28&'),                           # (H14)
    ])

    if is_op3:
        # Mau 3 (hinh 5 FS): khong in so chung tu kho, dia chi, MST, loai tien, chung tu ke toan
        info_rows = [
            info('NCC - Nhap tai kho', 'HEADER09', 'HEADER10', 'HEADER21', 'HEADER26'),   # (H3) (H11)
            info('Ma NCC - So HD goc', 'HEADER12', 'HEADER13', 'HEADER22', 'HEADER34'),   # (H4) (H12)
            row_descr,
        ]
    else:
        info_rows = [
            info('NCC - So CT kho', 'HEADER09', 'HEADER10', 'HEADER19', 'HEADER32'),      # (H3) (H9)
            info('Ma NCC - So CT ke toan', 'HEADER12', 'HEADER13', 'HEADER20', 'HEADER33'),  # (H4) (H10)
            info('Dia chi - Nhap tai kho', 'HEADER14', 'HEADER15', 'HEADER21', 'HEADER26'),  # (H5) (H11)
            info('MST - So HD goc', 'HEADER16', 'HEADER17', 'HEADER22', 'HEADER34'),      # (H6) (H12)
            info('Loai tien - Ngay HD goc', 'HEADER24', 'HEADER30', 'HEADER25', 'HEADER35'),  # (H7) (H13)
            info('Ty gia', 'HEADER23', 'HEADER31'),                                       # (H8)
            row_descr,
        ]
    folder_first = sf.folder('Thong tin phieu - chi trang dau', [row_company, row_title] + info_rows,
                             cnd=sf.cond(ocond=['FPAGE']))

    row_colhdr = sf.row('Tieu de cot', 'CL', [
        cell_t('H' + key, 'C', '<B0>&GS_PARAMETER-%s&</>' % COLS[key][0]) for key, _ in layout
    ])

    # ---- Dong chi tiet ---------------------------------------------------------
    def detail_cell(key):
        _, lines, fmt = COLS[key]
        texts = []
        for ln in lines:
            if isinstance(ln, tuple):
                texts.append(t([(fmt, ln[0])], cnd=ne_blank(ln[1])))
            else:
                texts.append(t([(fmt, ln)]))
        return sf.cell('Cot ' + key, texts)

    row_detail = sf.row('Dong chi tiet', 'CL', [detail_cell(key) for key, _ in layout])

    # ---- Cuoi bang: chu thich dieu chinh, ngay ky, chu ky (trang cuoi) --------
    row_note = sf.row('Chu thich dieu chinh', 'NT', [
        cell_t('Chu thich', 'L', '&GS_PARAMETER-LONG_TEXT1&'),
    ], cnd=ne_blank(P + 'LONG_TEXT1'))
    row_date = sf.row('Ngay ky', 'NT', [cell_t('Ngay', 'R', '&GS_PARAMETER-FOOTER05&')])

    def sign_cell(i, field):
        return sf.cell('Ky %d' % i, [
            t([('C', '<B0>&GS_PARAMETER-%s&</>' % field)]),
            t([('C', '&GS_PARAMETER-SIGN02&')]),
        ])

    row_sign = sf.row('Chuc danh ky', 'SG', [
        sign_cell(1, 'SIGN01' if is_op3 else 'FOOTER01'),
        sign_cell(2, 'FOOTER02'),
        sign_cell(3, 'FOOTER04'),
    ])
    row_sign_blank = sf.row('Cho ky', 'SG', [sf.cell('Trong %d' % i, [t(blank * 4)]) for i in (1, 2, 3)])

    folder_sign = sf.folder('Chu thich, ngay ky, chu ky',
                            [row_note, row_date, row_sign, row_sign_blank],
                            cnd=sf.cond(ocond=['FOOTER']), protect=True)

    tbl = sf.table(
        caption='Bang hang nhap kho',
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
    # (F1) thoi diem in + user, ban in lai (trai); (F2) trang x/y (phai)
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
                               ('T', 'IT_DATA', 'LIKE', 'ZWM_ST_PNK')],
                    gdata=[('GS_DATA', 'TYPE', 'ZWM_ST_PNK')],
                    windows=[win_main, win_print, win_page],
                    orientation='L', pageformat='DINA4')
    # Logo ZLOGO_0001 nap SE78 o 100 dpi
    xml = xml.replace('<RESOLUTION>0600</RESOLUTION>', '<RESOLUTION>0100</RESOLUTION>')
    return sf, xml


if __name__ == '__main__':
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'FS_v1.0')
    os.makedirs(out_dir, exist_ok=True)
    for name, cap, layout, is_op3 in FORMS:
        sf, xml = build(name, cap, layout, is_op3)
        path = os.path.join(out_dir, name + '.xml')
        sf.write(path, xml)
        print('Da sinh form:', path)
