# Các bước tạo ZRSD26 trên hệ

Copy code xong **chưa chạy được ngay**. Phải tạo thêm screen, PF-STATUS, text elements, Tcode.
Làm theo đúng thứ tự dưới đây. Mẫu tham khảo của team: `ZCO_PG_PC_BCGTTT_A` (cùng package `ZPK_BDP`).

---

## 1. SE38 — Chương trình + 5 include

Tạo `ZPG_SD_THCPVC`:
- **Type**: Executable program
- **Attributes → tick `Fixed point arithmetic`** (bắt buộc; không tick thì mọi câu SQL báo lỗi)
- Package `ZPK_BDP`

Dán code [zpg_sd_thcpvc.abap](zpg_sd_thcpvc.abap). Khi save, hệ hỏi tạo từng include thì bấm Yes,
hoặc tự tạo trước 5 include (Type = Include):

| Include | File |
|---|---|
| `ZIN_SD_THCPVC_TOP` | [zin_sd_thcpvc_top.abap](zin_sd_thcpvc_top.abap) |
| `ZIN_SD_THCPVC_PBO` | [zin_sd_thcpvc_pbo.abap](zin_sd_thcpvc_pbo.abap) |
| `ZIN_SD_THCPVC_PAI` | [zin_sd_thcpvc_pai.abap](zin_sd_thcpvc_pai.abap) |
| `ZIN_SD_THCPVC_F01` | [zin_sd_thcpvc_f01.abap](zin_sd_thcpvc_f01.abap) |
| `ZIN_SD_THCPVC_F02` | [zin_sd_thcpvc_f02.abap](zin_sd_thcpvc_f02.abap) |

Chưa activate được ngay — còn thiếu screen 0100 và text elements. Làm tiếp bước 2.

---

## 2. SE51 — Screen 0100 (bắt buộc, nếu không thì dump lúc chạy)

- **Program** `ZPG_SD_THCPVC`, **Screen number** `0100` → Create
- Tab **Attributes**: Screen type = **Normal**, Next screen = `0`
- Tab **Element list** / Layout: vào **Layout**, kéo **Custom Control** (biểu tượng hình chữ nhật
  trong thanh công cụ bên trái), đặt **Name = `CONTAINER`**, kéo chiếm gần hết màn hình.
  Tên này phải đúng chữ `CONTAINER` vì code khai `GC_SCRFNAME VALUE 'CONTAINER'`.
- Tab **Flow logic**, sửa thành:

```
PROCESS BEFORE OUTPUT.
  MODULE STATUS_0100.

PROCESS AFTER INPUT.
  MODULE EXIT_COMMAND_0100 AT EXIT-COMMAND.
  MODULE EXIT_COMMAND_0100.
```

Save + Activate screen.

---

## 3. SE41 — PF-STATUS `GUI` và TITLEBAR `TITLE`

Code gọi `SET PF-STATUS 'STANDARD'` và `SET TITLEBAR 'TITLE'`.
(01/10/2026: user đã copy status chuẩn tên `STANDARD` → code sửa theo cho khớp.)

**Cách nhanh — copy từ chương trình mẫu của team:**
SE41 → Menu **GUI status → Copy** (hoặc Utilities → Copy status):
- From program `ZCO_PG_PC_BCGTTT_A`, status `GUI` → To program `ZPG_SD_THCPVC`, status `STANDARD`
- Tương tự với Titlebar `TITLE`

**Sau khi copy status chuẩn (15/10/2026, đã test):** màn hình hiện 2 thanh công cụ vì status mang theo thanh nút ALV dạng danh sách. SE41 → Change → nhánh **Application Toolbar** → xóa hết các nút, **giữ** Function Keys (`&F03` Back, `&F15` Exit, `&F12` Cancel) → Activate. Thanh còn lại là thanh của ALV Grid.
Nếu Back/Exit/Cancel không thoát: kiểm flow logic screen 0100 ở mục 2 (phải có cả 2 dòng `MODULE EXIT_COMMAND_0100`).

**Cách tự tạo:**
- SE41 → Program `ZPG_SD_THCPVC`, Status `STANDARD` → Create → Status type **Normal screen**
- Trong Function keys, bật tối thiểu: `BACK` (F3), `EXIT` (Shift+F3), `CANCEL` (F12)
- SE41 → Title `TITLE` → Create → nhập `Bao cao tong hop chi phi van chuyen`

---

## 4. Text elements — KHÔNG CẦN

Tên 19 cột ALV (17 chỉ tiêu + 14.1, 15.1), tiêu đề lưới và tiêu đề 2 khối tham số đã viết thẳng trong code
(user chốt 01/10/2026: chỉnh ở code tiện hơn). Đổi tên cột chỉ cần sửa `BUILD_FIELDCAT`
trong `zin_sd_thcpvc_f02.abap`, không phải mở SE38 → Text Elements.

**Selection text của 9 tham số** vẫn nên nhập (SE38 → Goto → Text Elements → tab Selection Texts),
nếu không màn hình chọn hiện tên kỹ thuật `S_FKDAT`, `S_VKORG`...:

| Name | Text |
|---|---|
| S_FKDAT | Ngày Hóa Đơn |
| S_FKART | Loại Hóa Đơn |
| S_VKORG | Tổ Chức Bán Hàng |
| S_VTWEG | Kênh Bán Hàng |
| S_KUNAG | Mã Khách Hàng |
| S_VKGRP | Khu Vực |
| S_VKBUR | Chi Nhánh |
| S_KVGR2 | Vùng Vận Chuyển |
| S_MFRGR | Loại Hàng Hóa Vận Chuyển |

FS mới (V1.0 bản 3) bỏ tham số "Dạng hiển thị" nên không còn `P_ALV` / `P_XLS` — nếu đã nhập 2 selection text này thì xoá đi.

---

## 5. Activate

Activate toàn bộ: chương trình, 5 include, screen 0100, PF-STATUS, TITLEBAR.

---

## 6. SE93 — Tcode `ZRSD26`

- Transaction code `ZRSD26` → Create
- Chọn **Program and selection screen (report transaction)**
- Program `ZPG_SD_THCPVC`, Selection screen `1000`
- Tick **SAPGUI for Windows**

---

## Đã có sẵn, không cần tạo

- Message class `ZMC_SD` (đã tạo cho ZRSD08/ZRSD25), message `001`
- Authorization object `V_VBRK_VKO`, `M_IS_VTWEG` (chuẩn SAP)
- Các bảng diễn giải `TVGRT`, `TVKBT`, `TVV2T`, `TMFGT`, `TVTWT`
- View `NSDM_E_MARC` (view thay thế bắt buộc của `MARC` trên S/4HANA — chuẩn SAP, dùng để hết
  warning ATC `MARC has a replacement object`; `MFRGR` đọc từ view này)
- Không cần tạo DDIC (structure / data element) — báo cáo ALV dùng kiểu nội bộ

## Chưa có trên hệ (không chặn activate, nhưng số liệu sẽ bằng 0)

Kiểm lại 15/10/2026 trên DEV client 100:
- Condition type `ZFR1`, `ZFR2` chưa có (`T685`) → chỉ tiêu (14)(14.1)(15)(15.1) bằng 0.
  Trên hệ chỉ có `ZFRE` "CP Vận chuyển (UT)" liên quan vận chuyển.
- Loại hóa đơn `ZF2`, `ZRE` không có — FS mới đã bỏ giá trị mặc định này, tham số Loại hóa đơn để trống và bắt buộc nhập
- Chưa có hóa đơn nào trong hệ (`VBRK` 0 dòng)
