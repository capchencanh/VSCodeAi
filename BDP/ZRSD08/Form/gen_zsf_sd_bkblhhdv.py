# -*- coding: utf-8 -*-
"""Sinh Smart Form ZSF_SD_BKBLHHDV - Bang ke ban le hang hoa dich vu (Bidiphar).

FS: BIDIPHAR_FS_SD_ZRSD08_BangKeBanLeHangHoaDichVu_V1.0 (1).docx (muc Mau bao cao).
Bo cuc: 1 window MAIN gom 2 table.
  Table 1 (IT_ITEM): Header event = khoi dau (logo, cong ty, nha thuoc, tieu de, don vi mua)
                     chi in trang dau (FPAGE) + dong tieu de cot lap lai moi trang;
                     Main = dong hang hoa; Footer = dong Tong cong.
  Table 2 (IT_TAX):  Main = moi muc thue suat 1 dong; Footer = tong tien thue, tong thanh toan,
                     so tien bang chu, ngay lap, chu ky.

Chay:  PYTHONUTF8=1 python gen_zsf_sd_bkblhhdv.py zsf_sd_bkblhhdv.xml
"""
import sys
import os

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    '..', '..', '..', '..', '.claude', 'skills', 'smartforms-xml', 'scripts'))

from sfgen import SF, ALL

# A4 doc 21.0 cm; le trai 2, phai 1.5 -> vung in rong 17.5 cm
W = 17.5
L = 2.0

# 7 cot bang chi tiet: STT | Ten hang | DVT | So luong | Don gia | Thanh tien | Thue suat GTGT
C = [1.1, 4.9, 1.3, 2.0, 2.3, 3.0, 2.9]
assert abs(sum(C) - W) < 0.005

sf = SF(formname='ZSF_SD_BKBLHHDV',
        caption='Bang ke ban le hang hoa dich vu',
        devclass='ZPK_BDP',
        user='DanhDH')

# ---- Line type -------------------------------------------------------------
LT_TOTAL = ('S1', [(C[0] + C[1] + C[2], ALL),                # nhan (cot 1-3)
                   (C[3] + C[4], ALL),                       # o trong (cot 4-5)
                   (C[5], ALL), (C[6], ALL)])                # so tien | o trong
LT_ITEM = [
    ('T1', [(6.3, ALL), (11.2, ALL)]),                       # logo | thong tin cong ty
    ('T2', [(W, ALL)]),                                      # 1 o full rong
    ('T3', [(12.3, ALL), (5.2, ALL)]),                       # ten don vi mua | MST
    ('L1', [(w, ALL) for w in C]),                           # bang chi tiet 7 cot
    LT_TOTAL,
]
LT_TAX = [
    ('S2', [(C[0] + C[1] + C[2], ALL),                       # nhan thue suat
            (C[3], ALL),                                     # gia tri thue suat
            (C[4], ALL),                                     # nhan tien thue
            (C[5], ALL), (C[6], ALL)]),                      # so tien | o trong
    LT_TOTAL,
    ('W1', [(3.8, ALL), (13.7, ALL)]),                       # nhan | so tien bang chu
    ('D1', [(9.8, ALL), (7.7, ALL)]),                        # o trong | ngay lap
    ('G1', [(6.3, ALL), (6.0, ALL), (5.2, ALL)]),            # 3 o ky
]
for name, cols in LT_ITEM + LT_TAX:
    assert abs(sum(w for w, _ in cols) - W) < 0.005, name


def t(lines, cnd=None, caption=None):
    return sf.text(lines, cnd=cnd, caption=caption)


def cell_t(caption, fmt, txt):
    return sf.cell(caption, [t([(fmt, txt)])])


BLANK = [('*', None)]


def check_code(lines):
    # dong code trong Smart Form toi da 72 ky tu
    for ln in lines:
        assert len(ln) <= 72, ln
    return lines


# ---- Code node: tach ngay thanh ngay/thang/nam --------------------------------
# &field+6(2)& cua Smart Form cat tren chuoi da format theo user (dd.mm.yyyy) nen sai.
code_dates = sf.code(
    'Tach ngay', ['IS_HEAD'],
    ['GV_FD', 'GV_FM', 'GV_FY', 'GV_TD', 'GV_TM', 'GV_TY', 'GV_PD', 'GV_PM', 'GV_PY'],
    check_code(['gv_fd = is_head-date_fr+6(2).',
                'gv_fm = is_head-date_fr+4(2).',
                'gv_fy = is_head-date_fr(4).',
                'gv_td = is_head-date_to+6(2).',
                'gv_tm = is_head-date_to+4(2).',
                'gv_ty = is_head-date_to(4).',
                'gv_pd = is_head-prtdate+6(2).',
                'gv_pm = is_head-prtdate+4(2).',
                'gv_py = is_head-prtdate(4).']))

# ---- Header event: khoi dau (chi trang dau) --------------------------------
row_logo = sf.row('Logo + Cong ty', 'T1', [
    sf.cell('Logo', [sf.graphic(name_expr='&IS_HEAD-LOGO&', caption='LOGO cong ty', alignment='C')]),   # (1)
    sf.cell('Thong tin cong ty', [t([
        ('L', '<B1>&IS_HEAD-CNAME&</>'),                                                                # (2)
        ('L', '<N1>&IS_HEAD-CADDR&</>'),                                                                # (2.1)
        ('L', '<N1>Mã số thuế: &IS_HEAD-CTAXNO&</>'),                                                   # (2.2)
    ])]),
])
row_nhathuoc = sf.row('Nha thuoc', 'T1', [
    sf.cell('Trong', [t(BLANK)]),
    cell_t('Nha thuoc', 'L', '<N1>Nhà thuốc: &IS_HEAD-NHATHUOC& – &IS_HEAD-NHATHUOCNM&</>'),            # (3)(3.1)
])
row_title = sf.row('Tieu de', 'T2', [
    sf.cell('Tieu de', [t([
        ('C', '<B2>BẢNG KÊ BÁN LẺ HÀNG HOÁ DỊCH VỤ</>'),
        ('C', '<N1>Từ ngày &GV_FD& tháng &GV_FM& năm &GV_FY& '
              'đến ngày &GV_TD& tháng &GV_TM& năm &GV_TY&</>'),                                         # (4)(5)
    ])]),
])
row_fkart = sf.row('Loai hoa don', 'T2', [
    cell_t('Loai hoa don', 'C', '<B1>&IS_HEAD-FKART& - &IS_HEAD-FKARTX&</>'),                            # (6)(7)
])
row_payer = sf.row('Don vi mua hang', 'T3', [
    cell_t('Ten don vi mua hang', 'L', '<B1>Tên đơn vị mua hàng: &IS_HEAD-PAYERNM&</>'),               # (8)
    sf.cell('MST', [t([('L', '<B1>MST: &IS_HEAD-PAYERTAX&</>')],                                        # (8.1)
                      cnd=sf.cond([('NE', 'IS_HEAD-PAYERTAX', "' '")]))]),
])
row_addr = sf.row('Dia chi', 'T2', [
    cell_t('Dia chi', 'L', '<B1>Địa chỉ:</> <N1>&IS_HEAD-PAYERAD&</>'),                                  # (9)
])

folder_top = sf.folder(
    'Khoi dau - chi trang dau',
    [row_logo, row_nhathuoc, row_title, row_fkart, row_payer, row_addr],
    cnd=sf.cond(ocond=['FPAGE']))

# Dong tieu de cot - lap lai moi trang
HDR = ['STT', 'Tên hàng hóa', 'ĐVT', 'Số lượng', 'Đơn giá', 'Thành tiền', 'Thuế suất GTGT']
row_colhdr = sf.row('Tieu de cot', 'L1', [
    cell_t('H%d' % (i + 1), 'C', '<B1>%s</>' % h) for i, h in enumerate(HDR)])

# ---- Main event: moi dong hang hoa don -----------------------------------
# So luong / thue suat: nguyen thi bo phan thap phan, le thi giu so le
code_item = sf.code(
    'Dinh dang so luong va thue suat', ['GS_ITEM'], ['GV_QTY', 'GV_TAX'],
    check_code(['IF frac( gs_item-menge ) = 0.',
                '  gv_qty = |{ gs_item-menge NUMBER = USER DECIMALS = 0 }|.',
                'ELSE.',
                '  gv_qty = |{ gs_item-menge NUMBER = USER DECIMALS = 3 }|.',
                'ENDIF.',
                'IF frac( gs_item-taxrate ) = 0.',
                '  gv_tax = |{ gs_item-taxrate NUMBER = USER DECIMALS = 0 }%|.',
                'ELSE.',
                '  gv_tax = |{ gs_item-taxrate NUMBER = USER DECIMALS = 2 }%|.',
                'ENDIF.']))

row_detail = sf.row('Dong du lieu', 'L1', [
    cell_t('STT', 'C', '<N1>&GS_ITEM-STT(ZC)&</>'),                                  # (10)
    cell_t('Ten hang', 'L', '<N1>&GS_ITEM-MAKTX&</>'),                              # (11)
    cell_t('DVT', 'C', '<N1>&GS_ITEM-MEINS&</>'),                                   # (12)
    sf.cell('So luong', [code_item, t([('R', '<N1>&GV_QTY(C)&</>')])]),                # (13)
    cell_t('Don gia', 'R', '<N1>&GS_ITEM-KBETR(C)&</>'),                               # (14)
    cell_t('Thanh tien', 'R', '<N1>&GS_ITEM-NETWR(C)&</>'),                            # (15)
    cell_t('Thue suat', 'C', '<N1>&GV_TAX(C)&</>'),                                  # (16)
])

# ---- Footer event cua table 1: dong Tong cong -----------------------------
row_total = sf.row('Tong cong', 'S1', [
    cell_t('Nhan', 'R', '<B1>Tổng cộng</>'),
    sf.cell('Trong', [t(BLANK)]),
    cell_t('Tien', 'R', '<B1>&IS_HEAD-TOTAL(C)&</>'),                           # (17)
    sf.cell('Trong 2', [t(BLANK)]),
])
folder_total = sf.folder(
    'Tong cong', [row_total],
    cnd=sf.cond(ocond=['FOOTER']), protect=True)

tbl_item = sf.table(
    caption='Bang ke ban le',
    width=W,
    linetypes=LT_ITEM,
    tabname='IT_ITEM',
    tabheader='GS_ITEM',
    events=[
        sf.event('Dau bang', 'H', [code_dates, folder_top, row_colhdr]),
        sf.event('Du lieu', 'B', [row_detail]),
        sf.event('Cuoi bang', 'F', [folder_total]),
    ])

# ---- Table 2: thue theo tung muc thue suat + khoi cuoi -----------------------
code_tax = sf.code(
    'Dinh dang thue suat va tien thue', ['GS_TAX'], ['GV_TAXR', 'GV_TAXA'],
    check_code(['IF frac( gs_tax-taxrate ) = 0.',
                '  gv_taxr = |{ gs_tax-taxrate NUMBER = USER DECIMALS = 0 } %|.',
                'ELSE.',
                '  gv_taxr = |{ gs_tax-taxrate NUMBER = USER DECIMALS = 2 } %|.',
                'ENDIF.',
                'WRITE gs_tax-taxamt TO gv_taxa CURRENCY gs_tax-waerk.',
                'CONDENSE gv_taxa.']))

row_tax = sf.row('Thue GTGT', 'S2', [
    cell_t('Nhan TS', 'R', '<B1>Thuế suất GTGT</>'),
    sf.cell('TS', [code_tax, t([('C', '<B1>&GV_TAXR(C)&</>')])]),               # (19.1)
    cell_t('Nhan TT', 'C', '<B1>Tiền thuế GTGT</>'),
    cell_t('Tien TT', 'R', '<B1>&GV_TAXA(C)&</>'),                              # (20)
    sf.cell('Trong', [t(BLANK)]),
])

row_taxsum = sf.row('Tong tien thue', 'S1', [
    cell_t('Nhan', 'R', '<B1>Tổng cộng tiền thuế</>'),
    sf.cell('Trong', [t(BLANK)]),
    cell_t('Tien', 'R', '<B1>&IS_HEAD-TAXAMT(C)&</>'),                          # (19)
    sf.cell('Trong 2', [t(BLANK)]),
])
row_pay = sf.row('Tong thanh toan', 'S1', [
    cell_t('Nhan', 'R', '<B1>Tổng cộng tiền thanh toán</>'),
    sf.cell('Trong', [t(BLANK)]),
    cell_t('Tien', 'R', '<B1>&IS_HEAD-AMTPAY(C)&</>'),                          # (21)
    sf.cell('Trong 2', [t(BLANK)]),
])
row_words = sf.row('Bang chu', 'W1', [
    cell_t('Nhan', 'L', '<B1>Số tiền bằng chữ:</>'),
    cell_t('Bang chu', 'L', '<N1>&IS_HEAD-AMTWORD&</>'),                        # (21.1)
])
row_date = sf.row('Ngay lap', 'D1', [
    sf.cell('Trong', [t(BLANK)]),
    cell_t('Ngay', 'R', '<N1>Ngày &GV_PD& tháng &GV_PM& năm &GV_PY&</>'),         # (22)
])
row_sign = sf.row('Chuc danh', 'G1', [
    cell_t('Giam doc', 'C', '<B1>Giám đốc</>'),
    cell_t('Ke toan', 'C', '<B1>Kế toán</>'),
    cell_t('Nguoi lap', 'C', '<B1>Người lập biểu</>'),
])
row_sign_blank = sf.row('Cho ky', 'G1', [
    sf.cell('Ky 1', [t(BLANK * 4)]),
    sf.cell('Ky 2', [t(BLANK * 4)]),
    sf.cell('Ky 3', [t(BLANK * 4)]),
])

folder_foot = sf.folder(
    'Khoi cuoi va chu ky',
    [row_taxsum, row_pay, row_words, row_date, row_sign, row_sign_blank],
    cnd=sf.cond(ocond=['FOOTER']), protect=True)

tbl_tax = sf.table(
    caption='Thue GTGT theo thue suat',
    width=W,
    linetypes=LT_TAX,
    tabname='IT_TAX',
    tabheader='GS_TAX',
    events=[
        sf.event('Du lieu thue', 'B', [row_tax]),
        sf.event('Cuoi bang thue', 'F', [folder_foot]),
    ])

win_main = sf.window(
    iname='MAIN', caption='Main Window', wtype='M',
    content=[tbl_item, tbl_tax],
    geo=(L, W, 1.5, 26.7), wid=1)

INTERFACE = [
    ('I', 'IS_HEAD', 'TYPE', 'ZST_RSD08_HEAD'),
    ('T', 'IT_ITEM', 'TYPE', 'ZTT_RSD08_ITEM'),
    ('T', 'IT_TAX', 'TYPE', 'ZTT_RSD08_TAX'),
]

GDATA = [
    ('GS_ITEM', 'TYPE', 'ZST_RSD08_ITEM'),
    ('GS_TAX', 'TYPE', 'ZST_RSD08_TAX'),
    ('GV_FD', 'TYPE', 'CHAR2'), ('GV_FM', 'TYPE', 'CHAR2'), ('GV_FY', 'TYPE', 'CHAR4'),
    ('GV_TD', 'TYPE', 'CHAR2'), ('GV_TM', 'TYPE', 'CHAR2'), ('GV_TY', 'TYPE', 'CHAR4'),
    ('GV_PD', 'TYPE', 'CHAR2'), ('GV_PM', 'TYPE', 'CHAR2'), ('GV_PY', 'TYPE', 'CHAR4'),
    # biến gán trong code node nằm trong ô bảng: có default để Form Builder không cảnh báo "no defined value"
    ('GV_QTY', 'TYPE', 'CHAR30', "' '"),
    ('GV_TAX', 'TYPE', 'CHAR10', "' '"),
    ('GV_TAXR', 'TYPE', 'CHAR10', "' '"),
    ('GV_TAXA', 'TYPE', 'CHAR20', "' '"),
]

xml = sf.render(
    interface=INTERFACE,
    gdata=GDATA,
    windows=[win_main],
    orientation='P',
    pageformat='DINA4')

# Logo 121x66 px, 100 dpi: node phai dung 100 dpi thi moi ra dung 3.07 x 1.68 cm
xml = xml.replace('<RESOLUTION>0600</RESOLUTION>', '<RESOLUTION>0100</RESOLUTION>')

out = sys.argv[1] if len(sys.argv) > 1 else 'zsf_sd_bkblhhdv.xml'
sf.write(out, xml)
print('Da sinh form:', out)
