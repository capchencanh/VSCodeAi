# -*- coding: utf-8 -*-
"""Ví dụ đầy đủ dùng afgen - sinh 2 form demo (tên/structure giả định, KHÔNG có trên hệ thống nào):

  ZAF_DEMO_TEM  tem 80x40mm, 1 dòng GT_DATA = 1 tem (y như mẫu ZAF_BC_NHAN_BARCODE): QR + field.
  ZAF_DEMO_PXK  phiếu A4, 1 lần gọi = 1 phiếu: GT_HDR (1 dòng) + bảng GT_ITEM tự sang trang + chữ ký.

    python example_demo.py [thư mục ra]

Script thật của 1 form đặt trong thư mục project (VD CodeABAP/<project>/adobe/gen_<form>.py),
copy khung này rồi sửa. Danh sách field truyền vào loop() phải ĐỦ và ĐÚNG THỨ TỰ line type trong SE11.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from afgen import Interface, Form, page, text, field, qrcode, block, repeat, table  # noqa: E402

USER = 'KhoaLD'   # lấy từ UserName.md ở gốc repo


def build_tem(out):
    Interface('Tem demo').param('GT_DATA', 'ZTT_DEMO_TEM').write(os.path.join(out, 'SFPI_ZIF_DEMO_TEM.XML'))
    f = Form('ZAF_DEMO_TEM', 'ZIF_DEMO_TEM', 'Tem demo')
    f.loop('GT_DATA', ['ID_BARCODE', 'MATNR', 'MAKTX', 'CHARG', 'QRCODE'])
    tem = block([
        qrcode('QRCODE', data_length=26, x=1, y=2, size=36),
        field('MATNR', x=38, y=2, w=41, h=6, bold=True, font='Times New Roman'),
        field('MAKTX', x=38, y=8, w=41, h=14, bold=True, multiline=True, valign='top', font='Times New Roman'),
        field('CHARG', x=38, y=22, w=41, h=6, bold=True, font='Times New Roman', caption='Lô:', caption_w=8),
        field('ID_BARCODE', x=38, y=32, w=41, h=6, size=8, font='Times New Roman', caption='ID:', caption_w=6),
    ], w=80, h=40, name='Tem')                       # h = cao contentArea -> mỗi dòng 1 trang (tem)
    f.layout(page((80, 40), margin=0), [repeat('GT_DATA', [tem], w=80)], font='Times New Roman')
    return f.write(os.path.join(out, 'SFPF_ZAF_DEMO_TEM.XML')), os.path.join(out, 'SFPI_ZIF_DEMO_TEM.XML')


def build_pxk(out):
    hdr = ['SOCT', 'NGAY_TXT', 'TENCTY', 'DIACHI', 'NGUOINHAN', 'LYDO', 'KHO', 'TONG_SL']
    itm = ['STT', 'MATNR', 'MAKTX', 'MEINS', 'MENGE_TXT', 'GHICHU']
    (Interface('Phiếu xuất kho demo')
     .param('GT_HDR', 'ZTT_DEMO_PXK_HDR').param('GT_ITEM', 'ZTT_DEMO_PXK_ITM')
     .write(os.path.join(out, 'SFPI_ZIF_DEMO_PXK.XML')))
    f = Form('ZAF_DEMO_PXK', 'ZIF_DEMO_PXK', 'Phiếu xuất kho demo')
    f.loop('GT_HDR', hdr)
    f.loop('GT_ITEM', itm)

    def h(name):                                     # field header: dòng đầu của GT_HDR
        return '$.GT_HDR.DATA[0].' + name

    header = block([
        field(h('TENCTY'), x=0, y=0, w=125, h=6, bold=True),
        field(h('DIACHI'), x=0, y=6, w=125, h=6, size=9),
        field(h('SOCT'), x=135, y=0, w=55, h=6, caption='Số:', caption_w=10, bold=True),
        text('PHIẾU XUẤT KHO', x=0, y=14, w=190, h=10, size=16, bold=True, align='center', valign='middle'),
        field(h('NGAY_TXT'), x=0, y=24, w=190, h=6, align='center', valign='middle'),
    ], w=190, h=32, name='Header')
    info = block([
        field(h('NGUOINHAN'), x=0, y=0, w=190, h=6, caption='Người nhận hàng:', caption_w=35),
        field(h('LYDO'), x=0, y=6, w=190, h=6, caption='Lý do xuất:', caption_w=35),
        field(h('KHO'), x=0, y=12, w=190, h=6, caption='Xuất tại kho:', caption_w=35),
    ], w=190, h=20, name='Info')
    items = table('GT_ITEM', [(10, 'STT', 'STT', 'center'), (30, 'Mã hàng', 'MATNR'), (80, 'Tên hàng', 'MAKTX'),
                              (15, 'ĐVT', 'MEINS', 'center'), (25, 'Số lượng', 'MENGE_TXT', 'right'),
                              (30, 'Ghi chú', 'GHICHU')],
                  row_h=7, size=9, header_fill=(230, 230, 230),
                  footer=[None, None, ('Tổng cộng', 'right'), None, (h('TONG_SL'), 'right'), None], name='Items')
    sign = block([
        text('Người lập phiếu\n<ni>(Ký, họ tên)</ni>', x=0, y=4, w=47.5, h=12, bold=True, align='center'),
        text('Người nhận hàng\n<ni>(Ký, họ tên)</ni>', x=47.5, y=4, w=47.5, h=12, bold=True, align='center'),
        text('Thủ kho\n<ni>(Ký, họ tên)</ni>', x=95, y=4, w=47.5, h=12, bold=True, align='center'),
        text('Kế toán trưởng\n<ni>(Ký, họ tên)</ni>', x=142.5, y=4, w=47.5, h=12, bold=True, align='center'),
    ], w=190, h=40, name='Sign')
    f.layout(page('A4', margin=10), [header, info, items, sign], font='Times New Roman')
    return f.write(os.path.join(out, 'SFPF_ZAF_DEMO_PXK.XML')), os.path.join(out, 'SFPI_ZIF_DEMO_PXK.XML')


def build(out):
    os.makedirs(out, exist_ok=True)
    return [build_tem(out), build_pxk(out)]


if __name__ == '__main__':
    for sfpf, sfpi in build(sys.argv[1] if len(sys.argv) > 1 else '.'):
        print(sfpf, sfpi)
