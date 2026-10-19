# Bảng ZTWM_WT_OPT – Ánh xạ Option ↔ Warehouse Process Type (WPT)

Đã tạo và active trên S/4 DEV bằng MCP (14/10/2026, TR `DEVK900602`, package `ZPK_BDP`, delivery class `A`); còn bật Log data changes và SM30 (user làm, `ghi_chu.md` mục 6B). FS ZWM07 chỉ nêu tên bảng và khóa ("Warehouse, Option, Loại (Bin-to-Bin/Putaway/Picking), WPT, loại chứng từ tham chiếu"), **không mô tả field cụ thể** → cấu trúc dưới đây là giả định theo khóa FS nêu.
Customizing, bảo trì SM30 (Key user/IT; FS: `S_TABU_NAM` ZTWM_WT_OPT chỉ Key user/IT), bật table logging; delivery class **A** (như `ZTWM_PCK_TITLE`, để SM30 nhập được ở client 200 và dữ liệu không đi theo transport), package `ZPK_BDP`, field client `MANDT`.

| # | Field | Data element | Key | Ý nghĩa |
|---|---|---|---|---|
| 1 | MANDT | MANDT | X | Client |
| 2 | LGNUM | /SCWM/LGNUM | X | Warehouse |
| 3 | OPT | ZDE_WM_WT_OPTION (domain `CHAR1`, nhãn "Option ZWM07") | X | Option của màn hình chọn: 1, 2, 3 |
| 4 | LOAI | ZDE_WM_WT_LOAI (domain `CHAR1`, nhãn "Loại điều chuyển") | X | Chỉ dùng cho Option 1: `B` = Bin-to-Bin, `P` = Putaway, `K` = Picking; Option 2, 3 để trống |
| 5 | PROCTY | /SCWM/DE_PROCTY | X | Warehouse Process Type |
| 6 | RDOCCAT | /SCWM/DE_DOCCAT | X | Loại chứng từ tham chiếu của WT (`PDO` Outbound Delivery, `PDI` Inbound Delivery, `PMR`…); để trống = bất kỳ |

Cần tạo 2 data element mới (package `ZPK_BDP`, nhãn tiếng Việt, theo nguyên tắc ở `NOTE/note.md`):

| Data element | Domain | Short / Medium / Long / Heading |
|---|---|---|
| ZDE_WM_WT_OPTION | CHAR1 | Option / Option ZWM07 / Option lệnh chuyển vị trí / Option |
| ZDE_WM_WT_LOAI | CHAR1 | Loại ĐC / Loại điều chuyển / Loại: Bin-to-Bin/Putaway/Picking / Loại ĐC |

Cách chương trình dùng:
- Chỉ đọc WT có WPT khớp cấu hình của Option đang chọn (Option 1: chỉ các loại được tick).
- Dòng cấu hình để trống `RDOCCAT` áp cho mọi loại chứng từ; có `RDOCCAT` thì WT phải khớp cả WPT và loại chứng từ.
- WT có WPT chưa khai báo ở bất kỳ Option nào của Warehouse: bị loại và báo ZWM07-005.
- Option 2, 3 phân biệt nhau bằng WPT (VD ví dụ ở hình 3 của FS: `Z311` cấp phát, `Z312` bổ sung; mã WPT thật theo cấu hình EWM) và `RDOCCAT = PMR`.

Ví dụ dòng theo FS (chỉ để BA tham khảo, chưa nhập): Option 1 / `B` / `/SCWM/ADPROD`, `/SCWM/ADHU`; Option 1 / `P` / WPT nhập của Inbound Delivery; Option 1 / `K` / WPT xuất của Outbound Delivery; Option 2, 3 / WPT cấp phát và bổ sung cho sản xuất.
