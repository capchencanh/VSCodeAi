# Structure ZWM_ST_PCK – Phiếu chuyển kho (dòng chi tiết)

Chưa có trên S/4 DEV (kiểm 13/10/2026). Tạo mới SE11, package `ZPK_WM`, Enhancement category *Not extensible* (giống `ZWM_ST_PXK`).
Bản ECC cùng tên gộp header và dòng (60 field) và có thêm `ZWM_ST_PCK_QUYDOI`; S/4 không dùng lại: header đưa hết vào `GS_PARAMETER` (`ZCORE_ST_PARAMETER`), quy đổi SL gộp thành 1 chuỗi `QUYDOI`.

| # | Field | Data element | Ý nghĩa (cột FS) |
|---|---|---|---|
| 1 | STT | INT4 | (1) STT |
| 2 | MBLNR | MBLNR | Chứng từ kho của dòng |
| 3 | MATNR | CHAR255 | (2) Mã hàng; đổi mã vật tư: "mã xuất → mã nhận" |
| 4 | MAKTX | MAKTX | (3) Tên hàng (VI, thiếu thì EN) |
| 5 | NSXNS | CHAR255 | (4) NSX – Nước SX |
| 6 | SOLO | CHAR255 | (5) Số lô NSX |
| 7 | CHARG | CHAR255 | (6) Số lô SAP; lô nhận khác: "lô xuất → lô nhận" |
| 8 | HANDUNG | CHAR255 | (7) Hạn dùng; nhóm retest thêm "KNL dd/mm/yyyy"; mẫu 1 song ngữ ghép "Ngày SX - Hạn dùng" |
| 9 | GROES | CHAR255 | (8) Quy cách |
| 10 | MEINS | MEINS | (9) ĐVT cơ sở (form hiển thị mã ngoài) |
| 11 | MENGE | MENGE_D | (10) Số lượng theo ĐVT cơ sở – Reference field: `ZWM_ST_PCK-MEINS` |
| 12 | QUYDOI | CHAR255 | (11) SL quy đổi, VD "3 THÙNG 65 HỘP 2 VỈ" |
| 13 | BAOQUAN | CHAR255 | (12) ĐK bảo quản |
| 14 | DANGBC | CHAR255 | (15) Dạng bào chế – mẫu 1 song ngữ (chưa có nguồn, để trống) |
| 15 | LGORT | LGORT_D | Storage Location xuất của dòng |
| 16 | WERKS | WERKS_D | Plant xuất |

DDL gợi ý (giống cách tạo `ZWM_ST_PXK`: `MENGE` cần `@Semantics.quantity.unitOfMeasure : 'zwm_st_pck.meins'`).
