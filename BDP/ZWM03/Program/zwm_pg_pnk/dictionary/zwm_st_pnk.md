# Structure ZWM_ST_PNK – Phiếu nhập kho (dòng chi tiết)

Chưa có trên S/4 DEV (kiểm 12/10/2026). Tạo mới SE11, package `ZPK_WM`, Enhancement category *Can be enhanced (character-type or numeric)*.
Bản ECC cùng tên có 58 field gộp cả header lẫn dòng, nhưng S/4 không dùng lại: header đưa hết vào `GS_PARAMETER` (`ZCORE_ST_PARAMETER`).

| # | Field | Data element | Ý nghĩa (cột FS) |
|---|---|---|---|
| 1 | STT | INT4 | (1) STT |
| 2 | MBLNR | MBLNR | (15) Chứng từ kho – mẫu 3 |
| 3 | EBELN | EBELN | (2) Số PO |
| 4 | MATNR | MATNR | (3) Mã hàng |
| 5 | MAKTX | MAKTX | (4) Tên hàng (VI, thiếu thì EN; dòng không mã vật tư = EKPO-TXZ01) |
| 6 | MAKTX_EN | MAKTX | (4) Tên hàng EN – bản song ngữ |
| 7 | NODHL | CHAR255 | (5) Nồng độ – Hàm lượng – mẫu 1 |
| 8 | DOAM | CHAR255 | (6) Độ ẩm – mẫu 1 |
| 9 | NSXNS | CHAR255 | (7) NSX – Nước SX |
| 10 | SOLO | CHAR255 | (8) Số lô NSX |
| 11 | CHARG | CHARG_D | (8a) Số lô SAP |
| 12 | HANDUNG | DATUM | (9) Hạn dùng / Ngày KNL |
| 13 | GROES | CHAR255 | (10) Quy cách |
| 14 | ERFME | ERFME | (11) ĐVT (form hiển thị mã ngoài) |
| 15 | ERFME_EN | MSEHL | (11) ĐVT mô tả EN – bản song ngữ |
| 16 | ERFMG | ERFMG | (12) Số lượng – Reference field: `ZWM_ST_PNK-ERFME` |
| 17 | QUYDOI | CHAR255 | (13) SL quy đổi – mẫu 2, 3, 4 |
| 18 | BAOQUAN | CHAR255 | (14) ĐK bảo quản – mẫu 2, 3, 4 |
| 19 | LGORT | LGORT_D | Storage Location của dòng |
| 20 | WERKS | WERKS_D | Plant |
