# Form ZXLWB `ZXL_SD_DSNVBH` — Bản in ký duyệt ZRHR02

Dùng cho Option 1 của FS mục 2.3: *"Bản in ký duyệt form A4 ngang — Form in dạng Excel có thể chỉnh sửa (Có Header và Footer)"*.

## Cách tạo lại

```bash
cd "CodeABAP/BDP/ZRHR02/form zxlwb"
node build_form.js
```

Sinh ra `ZXL_SD_DSNVBH.xlsx`. Script tự đóng gói bằng `zipwriter.js` (KHÔNG dùng `Compress-Archive` — sẽ tạo entry sai chuẩn, SAP báo *"Error while reading template file"*).

Kiểm tra sau khi sinh:
```bash
node list_zip.js ZXL_SD_DSNVBH.xlsx
```

## Import vào SAP

1. **Copy file ra Desktop trước** — đường dẫn phải ≤ 128 ký tự, đường dẫn project này đã vượt (`RLGRAP-FILENAME` là CHAR 128, dài hơn sẽ mất đuôi `.xlsx` → lỗi *"No MIME type assigned to object"*).
2. Tcode `ZXLWB` → Import → chọn file.
3. Mở bằng Add-in Excel để kiểm tra cây node + chỉnh style/layout cho đẹp.

## Cấu trúc cây (25 node)

```
ZXL_SD_DSNVBH (R)          CB_RELPATH = ZST_SD_DSNVBH
└─ SHEET (S)               TB_SHEETNAME = Sheet1
   ├─ HEADER (P)           vùng dòng 1-7, 14 cột
   │  ├─ COMPANY (F)       [COMPANY]
   │  ├─ BRANCH  (F)       [BRANCH]
   │  ├─ TITLE   (F)       [TITLE]
   │  ├─ PERIOD  (F)       [PERIOD]
   │  └─ DECIDE  (F)       [DECIDE]
   ├─ ITEM (L)             CB_RELPATH = ZST_SD_DSNVBH-ITEM, LOOP_FROM = 1
   │  └─ LINE (P)          vùng dòng 8, 14 cột
   │     └─ 14 Field (F)   [STT] [PERNR] [PARVW] [ENAME] [ORGEH_TX] [ORGEH]
   │                       [VKBUR_TX] [VKBUR] [PLANS_TX] [PLANS] [PERIOD]
   │                       [SPGRP_TX] [SPGRP] [NETWR]
   └─ FOOTER (P)           vùng dòng 10-13 (phần ký duyệt 4 ô)
```

## Binding

- **Field header** (ngoài loop): `CB_VAL_RELPATH = ZST_SD_DSNVBH-<FIELD>`
- **Field trong loop**: `CB_VAL_RELPATH = LINE-<FIELD>` — chữ `LINE` là bắt buộc, hardcode trong runtime (`mk_shift_left cv_relpath: r_context->v_contextname , '-' , 'LINE-'`)
- Tất cả Field bind bằng **textmark** `[FIELD]` (`TB_AREA_TEXTMARK`), `TB_AREA_TOP/LEFT = 0` — không đặt theo tọa độ

Context bên ABAP là `GS_FORM TYPE GTY_FORM` (type local trong `zin_sd_dsnvbh_top.abap`), structure **phẳng**:

```abap
TYPES: BEGIN OF GTY_FORM,
         COMPANY TYPE C LENGTH 100,
         BRANCH  TYPE C LENGTH 100,
         TITLE   TYPE C LENGTH 100,
         PERIOD  TYPE C LENGTH 60,
         DECIDE  TYPE C LENGTH 150,
         ITEM    TYPE GTT_ALV,
       END OF GTY_FORM.
```

Binding so khớp **chuỗi tiền tố**, không tra tên type ABAP thật — nên `CONTEXTNAME = ZST_SD_DSNVBH` trong `head.xml` không bắt buộc phải là DDIC structure có thật. Nếu sau này tạo DDIC thật tên khác thì chỉ cần đổi `CONTEXTNAME` + tiền tố `CB_RELPATH`/`CB_VAL_RELPATH`, field name giữ nguyên.

## Bộ attribute — lấy từ hệ BDP

Tham chiếu form thật đang chạy: `ZXLSX_SD_ZUTGB02_TNTT.xlsx` (để ở `Program/`).

| File | Số attribute |
|---|---|
| `properties.xml` | **79** |
| `hierarchy.xml` | **122** |

Lưu ý: khác với skill mô tả cho hệ HPDQ (77 attribute) — hệ BDP có thêm `TB_RESPATTERN_PLACE` và `TB_KEEP_FORMULAS`. Luôn lấy bộ attribute từ form thật của đúng hệ đang làm.

## Style trong file

| Style | Dùng cho |
|---|---|
| 0 | Thường |
| 1 | Đậm, canh giữa (tên công ty, tiêu đề ký duyệt) |
| 2 | Đậm 16pt, canh giữa (tên báo cáo) |
| 3 | Header cột — đậm, viền, canh giữa, wrap text |
| 4 | Ô dữ liệu — viền, numFmtId 49 (chuỗi) |
| 5 | Ô số — viền, numFmtId 164 (`#,##0`), canh phải |

Font Times New Roman, cỡ 10 (tiêu đề 16) — theo FS mục 2.1.2. Khổ A4 ngang (`orientation="landscape"`).

## Còn phải làm

1. **Mở bằng Add-in Excel chỉnh lại layout cho đẹp** — script chỉ đảm bảo file import được và cây node đúng, không đảm bảo trình bày đẹp.
2. **Phần ký duyệt (FOOTER)**: hiện chỉ có 4 tiêu đề ở dòng 10. Cần thêm khoảng trống ký tên, ngày tháng theo mẫu FS Hình 1.
3. **2 field chờ BA**: `BRANCH` (tên chi nhánh — lấy theo tổ chức bán hàng hay địa chỉ Plant?) và `DECIDE` (số quyết định quy chế lương — FS ghi `"(Theo QĐ... /QĐ-DBD)"` nhưng không cho số cụ thể).
4. **Cột STT**: FS mục 2.4 ghi *"Không kết xuất chỉ tiêu này trong tệp import cho hệ thống HRM"* — bản in ký duyệt vẫn có STT nên giữ trong form.

## Tham chiếu

- Skill: `.claude/skills/zxlwb-workbench/SKILL.md`
- Form mẫu hệ BDP: `../Program/ZXLSX_SD_ZUTGB02_TNTT.xlsx`
- FM: `ZXLWB_CALLFORM` (function group `ZXLWB`, package `ZPK_CORE_GEN`) — **chỉ có 1 exception `PROCESS_TERMINATED`**
