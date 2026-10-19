# Các bước tạo ZRSD27 trên hệ

Copy code xong **chưa chạy được ngay**. Phải tạo thêm screen, PF-STATUS, Tcode.
Làm đúng thứ tự dưới đây. Làm tương tự ZRSD26 (cùng package `ZPK_BDP`, cùng màn hình ALV `CL_GUI_ALV_GRID`).

> MCP trên DEV/200 chỉ đọc/kiểm (ghi source bị chặn `TK 730`), nên code dán tay vào SE38.

---

## 1. SE38 — Chương trình + 5 include

Tạo `ZPG_SD_TDTHGT`:
- **Type**: Executable program
- **Attributes → tick `Fixed point arithmetic`** (bắt buộc; không tick thì mọi câu SQL báo lỗi)
- Package `ZPK_BDP`

Dán code [zpg_sd_tdthgt.abap](zpg_sd_tdthgt.abap). Khi save, hệ hỏi tạo từng include thì bấm Yes,
hoặc tự tạo trước 5 include (Type = Include):

| Include | File |
|---|---|
| `ZIN_SD_TDTHGT_TOP` | [zin_sd_tdthgt_top.abap](zin_sd_tdthgt_top.abap) |
| `ZIN_SD_TDTHGT_PBO` | [zin_sd_tdthgt_pbo.abap](zin_sd_tdthgt_pbo.abap) |
| `ZIN_SD_TDTHGT_PAI` | [zin_sd_tdthgt_pai.abap](zin_sd_tdthgt_pai.abap) |
| `ZIN_SD_TDTHGT_F01` | [zin_sd_tdthgt_f01.abap](zin_sd_tdthgt_f01.abap) |
| `ZIN_SD_TDTHGT_F02` | [zin_sd_tdthgt_f02.abap](zin_sd_tdthgt_f02.abap) |

Chưa activate được ngay — còn thiếu screen 0100. Làm tiếp bước 2.

---

## 2. SE51 — Screen 0100 (bắt buộc, nếu không thì dump lúc chạy)

**Cách nhanh:** SE51 → Utilities → Copy: From program `ZPG_SD_THCPVC` screen `0100` → To `ZPG_SD_TDTHGT` screen `0100`.

**Cách tự tạo:**
- **Program** `ZPG_SD_TDTHGT`, **Screen number** `0100` → Create
- Tab **Attributes**: Screen type = **Normal**, Next screen = `0`
- Vào **Layout**, kéo 1 **Custom Control** đặt **Name = `CONTAINER`**, chiếm gần hết màn hình
  (tên đúng chữ `CONTAINER` vì code khai `GC_SCRFNAME VALUE 'CONTAINER'`)
- Tab **Flow logic**:

```
PROCESS BEFORE OUTPUT.
  MODULE STATUS_0100.

PROCESS AFTER INPUT.
  MODULE EXIT_COMMAND_0100 AT EXIT-COMMAND.
```

Save + Activate screen.

---

## 3. SE41 — PF-STATUS `STANDARD` và TITLEBAR `TITLE`

Code gọi `SET PF-STATUS 'STANDARD'` và `SET TITLEBAR 'TITLE'`.

**Cách nhanh:** SE41 → GUI status → Copy: From program `ZPG_SD_THCPVC` status `STANDARD` → To program `ZPG_SD_TDTHGT`.
Tương tự Titlebar `TITLE` (nhập tiêu đề `Báo cáo theo dõi thực hiện gói thầu`).

**Cách tự tạo:** status type **Normal screen**, bật tối thiểu `BACK` (F3), `EXIT` (Shift+F3), `CANCEL` (F12).

---

## 4. Text elements — KHÔNG CẦN

Nhãn 5 khối tham số, nhãn từng tham số và tên 100+ cột ALV đều viết thẳng trong code
(`INIT_SCREEN` ở `zin_sd_tdthgt_f01.abap`, `BUILD_FIELDCAT` ở `zin_sd_tdthgt_f02.abap`).
Đổi nhãn/tên cột chỉ cần sửa code, không phải mở SE38 → Text Elements.

---

## 5. Activate

Activate toàn bộ: chương trình, 5 include, screen 0100, PF-STATUS, TITLEBAR.

---

## 6. SE93 — Tcode `ZRSD27`

- Transaction code `ZRSD27` → Create
- Chọn **Program and selection screen (report transaction)**
- Program `ZPG_SD_TDTHGT`, Selection screen `1000`
- Tick **SAPGUI for Windows**

---

## 7. Transport

Tên TR theo quy ước `NOTE/note.md`: `<Tên><mã Module><TCode><DD.MM.YYYY><Mô tả>`, ví dụ
`<TênViếtTắt>_SD_ZRSD27_08.10.2026_Bao cao theo doi thuc hien goi thau`
(mô tả không chứa chữ "move", "copy" hay tên dự án khác).

---

## Đã có sẵn, không cần tạo

- Message class `ZMC_SD`, message `001`
- Authorization object `V_VBAK_VKO` (VKORG, VTWEG, SPART, ACTVT), `V_VBAK_AAT` (AUART, ACTVT) — chuẩn SAP
- FM chuẩn `MD_CONVERT_MATERIAL_UNIT`, `F4IF_INT_TABLE_VALUE_REQUEST`
- Không cần tạo DDIC (structure / data element) — báo cáo dùng kiểu nội bộ

## Chưa có trên client 200 (không chặn activate, nhưng số liệu rỗng/không test được)

- Chưa có hợp đồng, hóa đơn nào (`VBAK` rỗng) → chưa chạy thử được kết quả thật
- Loại hợp đồng `ZCQ1` (hợp đồng cấp 1) — hệ chỉ có `AD1 GCQ GVC JSDQ KM MV PHAM VBOS WK1 WK2 WV`
- Đặc tính `Z_SPCL` (cột SPCL), bảng nhân sự `PA0001` rỗng (cột tên TDV / ASM)
- Xem chi tiết các điểm lệch FS trong [../ghi_chu.md](../ghi_chu.md)
