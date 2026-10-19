# Structure ZWM_ST_PXK – Phiếu xuất kho (dòng chi tiết)

Chưa có trên S/4 DEV (kiểm 13/10/2026). Tạo mới SE11, package `ZPK_WM`, Enhancement category *Not extensible* (giống `ZWM_ST_PNK`).
Bản ECC cùng tên gộp cả header lẫn dòng; S/4 không dùng lại: header đưa hết vào `GS_PARAMETER` (`ZCORE_ST_PARAMETER`).

| # | Field | Data element | Ý nghĩa (cột FS) |
|---|---|---|---|
| 1 | STT | INT4 | (1) STT |
| 2 | MBLNR | MBLNR | Chứng từ kho của dòng |
| 3 | MATNR | MATNR | (2) Mã hàng |
| 4 | MAKTX | MAKTX | (3) Tên hàng (VI, thiếu thì EN) |
| 5 | MAKTX_EN | MAKTX | (3) Tên hàng EN – bản song ngữ |
| 6 | NODHL | CHAR255 | (4) Nồng độ – Hàm lượng – mẫu 1, 3 |
| 7 | DOAM | CHAR255 | (5) Độ ẩm – mẫu 1, 3 |
| 8 | NSXNS | CHAR255 | (6) NSX – Nước SX |
| 9 | SOLO | CHAR255 | (7) Số lô NSX |
| 10 | CHARG | CHARG_D | (8) Số lô SAP |
| 11 | HANDUNG | DATUM | (9) Hạn dùng |
| 12 | NGAYKN | DATUM | (10) Ngày kiểm nghiệm lại |
| 13 | GROES | CHAR255 | (11) Quy cách |
| 14 | ERFME | ERFME | (12) ĐVT (form hiển thị mã ngoài) |
| 15 | ERFME_EN | MSEHL | (12) ĐVT mô tả EN – bản song ngữ |
| 16 | ERFMG | ERFMG | (13) Số lượng thực xuất – Reference field: `ZWM_ST_PXK-ERFME` |
| 17 | BAOQUAN | CHAR255 | (14) ĐK bảo quản – mẫu 1–3, khi chọn hiển thị |
| 18 | LGORT | LGORT_D | Storage Location của dòng |
| 19 | WERKS | WERKS_D | Plant |
