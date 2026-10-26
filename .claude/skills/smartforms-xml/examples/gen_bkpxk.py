# Sinh Smart Form ZMM_SF_BKPXK_DOC (Bảng kê phiếu xuất kho, ZMM_PG_PXK option P_BKXK)
# theo cách design của ZMM_SF_PXKPG_DOC. Thư viện: .claude/skills/smartforms-xml/scripts/sfgen.py
#   python gen_bkpxk.py zmm_sf_bkpxk_doc.xml
import datetime
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'scripts'))
from sfgen import SF, ALL, NONE  # noqa: E402

TAG = 'KhoaLD add begin 24.09.2026 14:58:56'
TAG_END = 'KhoaLD add end 24.09.2026 14:58:56'
sf = SF('ZMM_SF_BKPXK_DOC', 'Bảng kê phiếu xuất kho', devclass='ZPK_HPDQ', user='KHOALD',
        now=datetime.datetime(2026, 9, 24, 14, 58, 56))

# Layout: A4 ngang, MAIN rộng 28.70 cm
W = 28.70
# 17 cột chi tiết (theo mẫu in Bảng kê PXK - ticket #37135)
COLS = [  # (caption, header, width)
    ('STT', 'STT', 0.90),
    ('NHA MAY', 'Nhà máy', 1.10),
    ('SO CHUNG TU', 'Số chứng từ', 1.90),
    ('NGAY GIAO DICH', 'Ngày giao dịch', 1.80),
    ('KHO', 'Kho', 1.00),
    ('MA SAN PHAM', 'Mã sản phẩm', 2.30),
    ('TEN SAN PHAM', 'Tên sản phẩm', 2.50),
    ('LOAI GIAO DICH', 'Loại giao dịch', 1.90),
    ('LO', 'Lô', 2.00),
    ('KHOI LUONG', 'Khối lượng', 1.80),
    ('DVT', 'ĐVT', 0.90),
    ('BEN MUA', 'Bên mua', 1.90),
    ('DOCUMENT DATE', 'Document date', 1.80),
    ('SO OD', 'Số OD', 1.60),
    ('BEN NHAN', 'Bên nhận', 2.10),
    ('SO PHIEU CAN', 'Số phiếu cân', 1.60),
    ('KL QUA CAN', 'KL qua cân', 1.60),
]
widths = [c[2] for c in COLS]
w_sum1 = round(sum(widths[:9]), 2)          # cột 1..9  -> "Tổng cộng"
w_sum3 = round(W - w_sum1 - widths[9], 2)    # cột 11..17
LOGO_W = 6.00

LTS1 = [
    ('TOP', [(LOGO_W, NONE), (W - 2 * LOGO_W, NONE), (LOGO_W, NONE)]),
    ('FULL', [(W, NONE)]),
    ('HEADER', [(w, ALL) for w in widths]),
    ('DETAIL', [(w, (1, 0, 1, 1)) for w in widths]),
    ('SUM', [(w_sum1, (1, 1, 0, 1)), (widths[9], (0, 1, 0, 1)), (w_sum3, (0, 1, 1, 1))]),
]
LTS2 = [
    ('BLANK', [(W, NONE)]),
    ('SIGN', [(9.56, NONE), (9.57, NONE), (9.57, NONE)]),
]

C, L, R = 'C', 'L', 'R'
def fld(f, opt='C'):
    return '&GS_ITEM-%s(%s)&' % (f, opt)

# ---- header (chỉ in ở trang đầu) ----
hdr_first = sf.folder('HEADER TRANG DAU', [
    sf.row('LOGO', 'TOP', [
        sf.cell('LOGO', [sf.text([('*', None), ('*', None), ('*', None)], caption='Cho logo')]),
        sf.cell('New Column', []),
        sf.cell('New Column', []),
    ]),
    sf.row('TEN CONG TY', 'TOP', [
        sf.cell('TEN CONG TY', [sf.text([(C, '<B0>&GS_PARA-NAME&</>')], caption='Ten cong ty')]),
        sf.cell('New Column', []),
        sf.cell('New Column', []),
    ]),
    sf.row('TIEU DE', 'FULL', [
        sf.cell('TIEU DE', [sf.text([(C, '<B5>&GS_PARA-TITLE_REPORT&</>')], caption='Title')]),
    ]),
    sf.row('NGAY', 'FULL', [
        sf.cell('NGAY', [sf.text([(C, '<B0>Ngày:   &GS_PARA-PARAMETER20&</>')], caption='Ngay bang ke')]),
    ]),
    sf.row('DONG TRONG', 'FULL', [sf.cell('DONG TRONG', [sf.text([('*', None)])])]),
], cnd=sf.cond(ocond=['FPAGE']))

# ---- tiêu đề cột (lặp lại mỗi trang) ----
hdr_cols = sf.row('ten table', 'HEADER', [
    sf.cell(cap, [sf.text([(C, '<B0>%s</>' % h)])]) for cap, h, _ in COLS
])

# ---- dòng chi tiết (LEVEL = 1) ----
bo_decimal = ['"' + TAG,
              'IF FLOOR( GS_ITEM-ERFMG ) = GS_ITEM-ERFMG.',
              '  GV_ERFMG = GS_ITEM-ERFMG.',
              'ELSE.',
              '  CLEAR GV_ERFMG.',
              'ENDIF.',
              '"' + TAG_END] + [''] * 8
detail_cells = [
    sf.cell('STT', [sf.text([(C, '<N0>%s</>' % fld('STT'))])]),
    sf.cell('NHA MAY', [sf.text([(C, '<N0>%s</>' % fld('WERKS'))])]),
    sf.cell('SO CHUNG TU', [sf.text([(C, '<N0>%s</>' % fld('MBLNR'))])]),
    sf.cell('NGAY GIAO DICH', [sf.text([(C, '<N0>&GS_ITEM-BUDAT&</>')])]),
    sf.cell('KHO', [sf.text([(C, '<N0>%s</>' % fld('LGORT'))])]),
    sf.cell('MA SAN PHAM', [sf.text([(C, '<N0>%s</>' % fld('MATNR'))])]),
    sf.cell('TEN SAN PHAM', [sf.text([(L, '<N0>%s</>' % fld('MAKTX'))])]),
    sf.cell('LOAI GIAO DICH', [sf.text([(L, '<N0>%s</>' % fld('BTEXT'))])]),
    sf.cell('LO', [
        sf.text([(C, '<N0>%s</>' % fld('CHARG'))], caption='So lo'),
        sf.text([(C, '<N0>%s</>' % fld('ZSLED'))], caption='SLED/BBD',
                cnd=sf.cond([('NE', 'GS_ITEM-ZSLED', "' '")])),
    ]),
    sf.cell('KHOI LUONG', [
        sf.code('bo decimal', ['GS_ITEM-ERFMG'], ['GV_ERFMG'], bo_decimal),
        sf.text([(R, '<N0>&GV_ERFMG(<ZC)&</>')], cnd=sf.cond([('NE', 'GV_ERFMG', '0')])),
        sf.text([(R, '<N0>&GS_ITEM-ERFMG(<ZC)&</>')], cnd=sf.cond([('EQ', 'GV_ERFMG', '0')])),
    ]),
    sf.cell('DVT', [sf.text([(C, '<N0>%s</>' % fld('ERFME'))])]),
    sf.cell('BEN MUA', [sf.text([(L, '<N0>%s</>' % fld('NAMESO'))])]),
    sf.cell('DOCUMENT DATE', [sf.text([(C, '<N0>&GS_ITEM-BLDAT&</>')])]),
    sf.cell('SO OD', [sf.text([(C, '<N0>%s</>' % fld('VBELN_IM'))])]),
    sf.cell('BEN NHAN', [sf.text([(L, '<N0>%s</>' % fld('NAMESH'))])]),
    sf.cell('SO PHIEU CAN', [sf.text([(C, '<N0>%s</>' % fld('SOPHIEUCAN'))])]),
    sf.cell('KL QUA CAN', [sf.text([(R, '<N0>%s</>' % fld('KLQUACAN', 'CI'))])]),
]
row_detail = sf.row('detail', 'DETAIL', detail_cells, cnd=sf.cond([('EQ', 'GS_ITEM-LEVEL', '1')]))

# ---- dòng tổng cộng (LEVEL = 2, chương trình append) ----
row_sum = sf.row('sum', 'SUM', [
    sf.cell('tong cong', [sf.text([(C, '<B0>Tổng cộng</>')])]),
    sf.cell('khoi luong', [
        sf.code('bo decimal', ['GS_ITEM-ERFMG'], ['GV_ERFMG'], bo_decimal),
        sf.text([(R, '<B0>&GV_ERFMG(<ZC)&</>')], cnd=sf.cond([('NE', 'GV_ERFMG', '0')])),
        sf.text([(R, '<B0>&GS_ITEM-ERFMG(<ZC)&</>')], cnd=sf.cond([('EQ', 'GV_ERFMG', '0')])),
    ]),
    sf.cell('New Column', []),
], cnd=sf.cond([('EQ', 'GS_ITEM-LEVEL', '2')]))

table1 = sf.table('Bang ke', W, LTS1, [
    sf.event('Header', 'H', [hdr_first, hdr_cols]),
    sf.event('Main Area', 'B', [row_detail, row_sum]),
    sf.event('Footer', 'F', []),
], tabname='GT_ITEM', tabheader='GS_ITEM')

# ---- chữ ký: Người lập phiếu | Trưởng bộ phận | P. KT (ticket #37135) ----
def sign(title):
    return sf.cell(title.upper(), [sf.text([(C, '<B0>%s</>' % title), (C, '<N0>Ký ghi rõ họ tên</>')])])
table2 = sf.table('Chu ky', W, LTS2, [
    sf.event('Header', 'H', []),
    sf.event('Main Area', 'B', []),
    sf.event('Footer', 'F', [
        sf.folder('CHU KY', [
            sf.row('dong trong', 'BLANK', [sf.cell('dong trong', [sf.text([('*', None)])])]),
            sf.row('3 CHU KY', 'SIGN', [sign('Người lập phiếu'), sign('Trưởng bộ phận'), sign('P. KT')]),
        ], cnd=sf.cond(ocond=['FOOTER']), protect=True),
    ]),
])

main = sf.window('MAIN', 'Main Window', 'M', [
    sf.folder('BANG KE', [table1]),
    sf.folder('CHU KY', [table2]),
], (0.50, W, 0.50, 20.00), wid=1082, oacap='New Display Option')

logo = sf.window('%WINDOW1', 'LOGO', 'T', [sf.graphic()], (0.60, 5.00, 0.50, 1.30),
                 wid=833, cnd=sf.cond(ocond=['FPAGE']))

xml = sf.render(
    interface=[('I', 'GS_PARA', 'TYPE', 'ZCORE_ST_PARAMETER'),
               ('T', 'GT_ITEM', 'LIKE', 'ZMM_ST_PXK')],
    gdata=[('GS_ITEM', 'TYPE', 'ZMM_ST_PXK'), ('GV_ERFMG', 'TYPE', 'I')],
    windows=[logo, main], orientation='L')
sf.write(sys.argv[1], xml)
print('written', len(xml))
