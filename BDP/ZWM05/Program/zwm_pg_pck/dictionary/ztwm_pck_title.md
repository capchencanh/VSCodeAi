# Bảng ZTWM_PCK_TITLE – Tiêu đề phiếu chuyển kho theo Plant + SLoc xuất + SLoc nhận

Chưa có trên S/4 DEV (kiểm 13/10/2026). FS ZWM05 chỉ nêu tên bảng và mục đích ("tiêu đề theo Plant + SLoc xuất + SLoc nhận"), **không mô tả cấu trúc** → cấu trúc dưới đây là giả định, dùng cho mẫu 1, 3, 4.
Customizing, bảo trì SM30 (Key user/IT), bật table logging; delivery class **A** (đổi từ C ngày 13/10/2026 để SM30 nhập được ở client 200, dữ liệu không đi theo transport), package `ZPK_BDP`, field client `MANDT` (theo `_ghichu_mcp_gui.md`).

| # | Field | Data element | Key | Ý nghĩa |
|---|---|---|---|---|
| 1 | MANDT | MANDT | X | Client |
| 2 | WERKS | WERKS_D | X | Plant xuất |
| 3 | LGORT | LGORT_D | X | SLoc xuất |
| 4 | UMLGO | UMLGO | X | SLoc nhận |
| 5 | TITLE_VI | ZDE_WM_PCK_TITLE_VI (domain `TEXT80UEB`, CHAR 80, cho chữ thường) |  | Tiêu đề tiếng Việt (VD "PHIẾU NHẬP KHO") |
| 6 | TITLE_EN | ZDE_WM_PCK_TITLE_EN (domain `TEXT80UEB`, CHAR 80, cho chữ thường) |  | Tiêu đề phụ khi in song ngữ (trống thì mẫu 1 dùng "CERTIFICATE OF RELEASE", mẫu 3 dùng "MATERIAL TRANSFER SLIP") |

Đã tạo trên DEV 13/10/2026 (2 data element mới, package `ZPK_BDP`, nhãn tiếng Việt; `WERKS_D`, `LGORT_D`, `UMLGO` dùng data element chuẩn).

Không có dòng khớp thì chương trình dùng "PHIẾU CHUYỂN KHO".
Nguồn gốc: ECC hard-code cặp SLoc B004 → B001 và B005 → B002 thành "PHIẾU NHẬP KHO" ("PHIẾU CHỨNG NHẬN XUẤT XƯỞNG" khi song ngữ mẫu 1); S/4 chuyển thành data bảng này, BA/Key user nhập.
