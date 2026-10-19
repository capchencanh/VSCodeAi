# Structure ZWM_ST_LCVT – Lệnh chuyển vị trí (dòng chi tiết)

Đã tạo và active trên S/4 DEV bằng MCP (14/10/2026, TR `DEVK900602`), package `ZPK_WM`, Enhancement category *Not extensible* (giống `ZWM_ST_PCK`).
Bản ECC cùng tên gộp header và dòng (LTAK/LTAP) và có thêm `ZWM_ST_LCVT_A_QUYDOI`; S/4 không dùng lại: header đưa hết vào `GS_PARAMETER` (`ZCORE_ST_PARAMETER`), FS ZWM07 không có cột quy đổi SL.

| # | Field | Data element | Ý nghĩa (cột FS 2.5) |
|---|---|---|---|
| 1 | STT | INT4 | (0) STT |
| 2 | TANUM | CHAR20 | (1) Warehouse Task và (5) Số WT (FS ghi cùng nguồn `/SCWM/ORDIM_C-TANUM`), đã bỏ số 0 đầu |
| 3 | VLPLA | /SCWM/LTAP_VLPLA | (3) Bin nguồn |
| 4 | NLPLA | /SCWM/LTAP_NLPLA | (4) Bin đích (WT đã xác nhận: Bin đã xác nhận) |
| 5 | MATNR | MATNR | (6) Mã hàng, đã bỏ số 0 đầu |
| 6 | MAKTX | MAKTX | (7) Tên hàng (`MAKT-MAKTX`, VI thiếu thì EN) |
| 7 | CHARG | CHARG_D | (8) Số lô SAP |
| 8 | SOLO | ATWRT | (9) Số lô NSX: `Z_BATCH_NSX`, rồi `MCHA-LICHA`, rồi lô SAP |
| 9 | MEINS | MEINS | (11) ĐVT cơ sở (form hiển thị mã ngoài) |
| 10 | MENGE | MENGE_D | (10) Số lượng theo ĐVT cơ sở (WT đã xác nhận: SL thực tế) – Reference field: `ZWM_ST_LCVT-MEINS` |

Cột (2) Xác nhận, (12) SL thực chuyển, (13) Bin thực tế: ghi tay, để trống, không có field.

DDL gợi ý: `MENGE` cần `@Semantics.quantity.unitOfMeasure : 'zwm_st_lcvt.meins'` (giống `ZWM_ST_PCK`).
