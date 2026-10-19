# Bảng ZTWM_PCK_SIGN – Khối chữ ký Trưởng phòng QLCL của phiếu chuyển kho

Chưa có trên S/4 DEV (kiểm 13/10/2026). FS ZWM05 chỉ nêu tên bảng (và sơ đồ ghi "chữ ký QLCL theo bảng tham số"), **không mô tả cấu trúc** → cấu trúc dưới đây là giả định.
Customizing, bảo trì SM30 (Key user/IT), bật table logging; delivery class **A** (đổi từ C ngày 13/10/2026, như `ZTWM_PCK_TITLE`), package `ZPK_BDP`, field client `MANDT`.

| # | Field | Data element | Key | Ý nghĩa |
|---|---|---|---|---|
| 1 | MANDT | MANDT | X | Client |
| 2 | WERKS | WERKS_D | X | Plant xuất (trống = mọi Plant) |
| 3 | BWART | BWART | X | Movement Type (trống = mọi MvT) |
| 4 | LGORT | LGORT_D | X | SLoc xuất (trống = mọi SLoc) |
| 5 | UMLGO | UMLGO | X | SLoc nhận (trống = mọi SLoc) |
| 6 | SIGN_QLCL | ZDE_WM_PCK_SIGN_QLCL (domain `XFELD`, CHAR 1) |  | X = có ô ký Trưởng phòng QLCL |

Đã tạo trên DEV 13/10/2026 (data element mới, package `ZPK_BDP`, nhãn tiếng Việt; `WERKS_D`, `BWART`, `LGORT_D`, `UMLGO` dùng data element chuẩn).

Dòng khớp (mọi cột key khác trống đều khớp) và `SIGN_QLCL = X` thì phiếu chuyển kho (mẫu 1–3) có thêm ô "Trưởng phòng QLCL".
Nguồn gốc: ECC hard-code MvT 313, SLoc xuất B101/B102/B105/B106/B111/B112/C002/C003 và SLoc nhận bắt đầu `BX` hoặc `C0`; FS S/4 ghi "rule tự động nhận diện nghiệp vụ trả nguyên liệu được chốt sau" nên chỉ dựng bảng, không hard-code.
