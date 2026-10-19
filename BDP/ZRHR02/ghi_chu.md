# ZRHR02 — Báo cáo doanh số nhân viên bán hàng

## Bối cảnh

- Loại phát triển: **Tạo mới** (đã xác nhận qua MCP: `ZRHR02`, `ZRHR02B` chưa tồn tại trên hệ).
- FS: `FS/BIDIPHAR_FS_SD_ZRHR02_BaoCaoDoanhSoNhanVienBanHang_V1.0.docx` (v1.0, ngày 24/09/2026, người tạo: Trần Đoàn Kim Ngân).
- Chủ trương user (06/10/2026): **code phần đã rõ trước, phần chưa biết để trống/TODO**, khi có thông tin từ BA thì bổ sung sau.
- User tự copy code lên SE38, không tạo object qua MCP.

## Object đã tạo (local)

| File | Nội dung |
|---|---|
| `Program/zpg_sd_dsnvbh.abap` | Report chính, header chuẩn Citek, 3 INCLUDE |
| `Program/zin_sd_dsnvbh_top.abap` | TYPES (GTY_ALV 16 field, GTY_BILL, GTY_PARTNER, GTY_PFTEXT, GTY_ORG), CONSTANTS, selection-screen 3 block |
| `Program/zin_sd_dsnvbh_f01.abap` | SET_DEFAULT_DATE, CHECK_AUTHORITY, GET_DATA, GET_BILLING, BUILD_ALV, GET_HR_INFO (TODO), GET_PRODUCT_GROUP (TODO), SUM_BY_KEY |
| `Program/zin_sd_dsnvbh_f02.abap` | DISPLAY_ALV, SET_COLUMNS (14 cột), EXPORT_FILE |

Naming theo chuẩn dự án (giống ZRSD25/ZRSD26): `ZPG_SD_<viết tắt>` + include `ZIN_SD_<viết tắt>_TOP/F01/F02`. Package đích: `ZPK_BDP`. Message class: `ZMC_SD` (đã có sẵn trên hệ).

## Đã làm được (theo FS)

- **Selection screen**: 7 tham số Billing (VKORG bắt buộc, FKDAT bắt buộc mặc định tháng hiện tại), 2 tham số nhân sự (PERNR, PARVW), 1 checkbox xuất file.
- **Phân quyền**: `AUTHORITY-CHECK OBJECT 'V_VBRK_VKO'` trên VBRK-VKORG (FS mục 2.5).
- **Đọc dữ liệu**: VBRP INNER JOIN VBRK, LEFT JOIN TVKBT (tên Sales Office), LEFT JOIN KNVV (Customer Group) — lọc WAERK='VND', FKSTO<>'X' theo ràng buộc FS chỉ tiêu (14).
- **4 Partner Function**: SE, KM, ER, VW (FS mục 2.1.1) — mỗi PF trên chứng từ sinh 1 dòng báo cáo.
- **Đổi dấu hàng trả**: `VBTYP = 'O'` → nhân -1.
- **Tháng áp dụng**: format mm/yyyy từ FKDAT (FS chỉ tiêu 11).
- **Cộng dồn**: theo PERNR + PARVW + PERIOD + SPGRP + VKBUR.
- **ALV**: CL_SALV_TABLE, 14 cột theo FS mục 2.4, currency column, lưu layout.
- **Xuất file**: tab-delimited, codepage 4110 (UTF-8), bỏ cột STT theo FS chỉ tiêu (1).

## Lỗi đã gặp và cách xử lý (kinh nghiệm cho lần sau)

1. **`VBRK-VKBUR` không tồn tại** — Sales Office chỉ có ở `VBRP`, không có ở header `VBRK`. Đã sửa type thành `VBRP-VKBUR`.
2. **Tên internal table `LT_PARVW_TX` bị đụng select-option `S_PARVW`** — ABAP parse nhầm thành `S_PARVW-TX`. Đã đổi tên thành `LT_PFTEXT`. **Lưu ý: không đặt tên biến bắt đầu trùng prefix của select-option đã khai.**
3. **Lỗi "fixed point arithmetic flag"** khi SyntaxCheck trên program chưa tồn tại — đây là **lỗi giả**, do SyntaxCheck chạy trên source rời chưa có thuộc tính program. Đã kiểm chứng: cùng cú pháp đó check trên `ZPG_SD_THCPVC` (program đã tồn tại) thì không báo lỗi. **Khi tạo program mới trên SE38 nhớ bật "Fixed point arithmetic" trong Attributes.**
4. **Inline declaration `DATA(...)` trong SQL/CALL METHOD** gây lỗi khi chưa có fixed point — đã khai báo tường minh hết cho an toàn.

## TODO — chờ BA (đã đánh dấu rõ trong code)

### 1. Nguồn dữ liệu HRM — FORM `GET_HR_INFO` (f01) đang rỗng

5 chỉ tiêu FS mục 2.4 chỉ ghi "theo dữ liệu HRM", không cho tên bảng/field (khác với chỉ tiêu (8)(11) ghi rõ `[Tcode] VF03 / [Field] Sales Office, Billing Date`):
- (4) Tên nhân viên → `GT_ALV-ENAME`
- (5) Tên phòng ban HRM → `GT_ALV-ORGEH_TX`
- (6) Mã phòng ban HRM → `GT_ALV-ORGEH`
- (9) Tên vị trí công việc → `GT_ALV-PLANS_TX`
- (10) Mã vị trí công việc → `GT_ALV-PLANS`

Đã check MCP: **`PA0001` có 0 bản ghi** trên DEV client 200 → không tự dò ra được nguồn.

Khi có thông tin: đọc theo `GT_ALV-PERNR`, gán 5 field trên. Đồng thời bổ sung 2 select-option `S_ORGEH`, `S_PLANS` vào BLOCK BL2 (FS tham số 10, 11).

### 2. Công thức doanh số — FORM `BUILD_ALV` (f01) đang dùng tạm `VBRP-NETWR`

FS chỉ tiêu (14): *"Doanh số tính lương = doanh số bán hàng đã trừ chiết khấu ngay (chưa VAT) − hàng bán trả lại − giảm giá của giá bán + tăng giá của giá bán"*

Thiếu để code chính xác:
- Billing Type nào là "hóa đơn bán" (cộng), "giấy báo có hàng trả lại" (trừ), "giảm giá", "tăng giá" → mã `FKART`?
- "chiết khấu ngay", "giảm giá", "tăng giá" là condition type `KSCHL` nào?
- Lấy field giá trị nào: `VBRP-NETWR` hay `KZWI1..KZWI6` hay cộng/trừ từ `PRCD_ELEMENTS`?
- "Không lấy chứng từ đã huỷ" → hiện dùng `FKSTO <> 'X'`, cần BA xác nhận đúng chưa.

**Hiện code dùng `VBRP-NETWR` (giá trị thuần chưa VAT — đúng ràng buộc FS) và đổi dấu theo `VBTYP='O'`.** Khi có condition type thì sửa lại trong `GET_BILLING`/`BUILD_ALV`.

### 3. Nhóm sản phẩm — FORM `GET_PRODUCT_GROUP` (f01) đang rỗng

FS mục 3.1: *"Mã nhóm sản phẩm = Nhóm sản phẩm phân tích (lấy từ field Z_SPCL trong Basic Data3) + Distribution Channel + Customer Group"*, khai báo tại màn hình `ZRHR02B`.

Hai điểm chặn:
- **Field `Z_SPCL` không tồn tại trên DEV client 200.** Đã check kỹ qua MCP: `MARA` chỉ có `ZZBRAND, ZZSUB_BRAND, ZZGROUP, ZZSUB_GROUP, ZZMVCHINH, ZZMVQUYDOI, ZZMARKET, ZZDKBH, ZZTHBH, ZZTHBHDP, ZZPREFIX, ZZSUFFIX, ZZKT_RELEASE, ZZBRANDCHIP`; `CABN` có 4.146 characteristic nhưng **không có cái nào bắt đầu bằng Z**; `MVKE`/`MARC` không có field `ZZ*` nào. **Chính BA cũng đã comment trong FS: "Update lại tên Field trên Master data của Mã" / "Cập nhật tên field là Sản phẩm chủ lực"** → tên trong FS là tạm, chưa chốt.
- **Bảng Z của màn hình `ZRHR02B` chưa được tạo** (khóa: DChl + CGrp + Z_SPCL + Từ ngày hiệu lực; FS mục 3.2.4).

### 4. Màn hình ZRHR02B — chưa làm

FS mục 3.2 mô tả đầy đủ 10 field + 5 tham số tìm kiếm, là maintenance view SM30 chuẩn. Chưa làm vì phụ thuộc điểm chặn #3 (chưa biết field `Z_SPCL` thật).

### 5. Màn hình ZRHR02A — FS chưa thiết kế

FS mục 3 viết *"Hai màn hình dưới đây"* nhưng chỉ mô tả ZRHR02B. `ZRHR02A - Khai báo nhân sự bán hàng theo kênh bán hàng` được nêu tên ở bảng Quy định chung nhưng **không có mục thiết kế nào**. BA đã comment: *"Citek cập nhật tài liệu"*.

### 6. Option 1 "Bản in ký duyệt" — chưa làm

FS mục 2.3 mô tả *"Form in dạng Excel có thể chỉnh sửa (Có Header và Footer)"* nhưng mục 2.1.2 lại ghi `Output = ALV`. Chưa rõ làm bằng Smart Form, XLSX Workbench (ZXLWB) hay ALV + template Excel → chờ BA chốt.

### 7. Tham số còn thiếu/mâu thuẫn trong FS

- Dòng **"Mã sản phẩm chủ lực"** trong bảng tham số FS mục 2.2.1 **trống toàn bộ** (không mô tả/loại/điều kiện lọc/mặc định/bắt buộc). BA comment: *"Bổ sung tham số Mã sản phẩm chủ lực"*.
- BA comment **"Xoá 2 tham số 4,5"** nhưng cột STT trong bảng tham số FS **để trống hết** → không xác định được xóa tham số nào.
- FS mục 2.3 ghi *"Kết xuất khi đánh dấu tham số (12)"* nhưng đếm theo thứ tự dòng thì (12) là "Mã sản phẩm chủ lực", checkbox lại là dòng 13.

### 8. Mâu thuẫn định dạng số

FS mục 2.1.2: *"Doanh số hiển thị dạng số có phân cách hàng nghìn, **không lấy phần thập phân**"* nhưng mục 2.4 chỉ tiêu (14) ghi `CURR, (15,2)` (2 số lẻ). Hiện code để `VBRP-NETWR` (2 decimal), file xuất dùng `NO-GROUPING DECIMALS 0`.

### 9. FS thiếu hẳn các mục

- **Message** (mã/loại E-W-I-S/nội dung): FS không có mục nào. Hiện code dùng message hard-code + `ZMC_SD` cho authority.
- **Quy tắc sort**: không đề cập. Hiện sort theo PERNR + PARVW + PERIOD + SPGRP + VKBUR.
- **Dòng tổng cộng**: không đề cập, mẫu in cũng không vẽ → hiện không làm.
- **Quy tắc group/sum**: không đề cập. Hiện gom theo tổ hợp trên, cần BA xác nhận.
- **1 billing có cả 4 PF → ra 4 dòng hay 1 dòng?** FS nói "thể hiện đồng thời 4 Partner Function". Hiện code sinh 4 dòng (mỗi PF 1 dòng, cùng doanh số) → **tổng doanh số sẽ bị nhân 4 nếu cộng hết**. Cần BA xác nhận cách hiểu này đúng không.

## Comment của BA trong file FS (10 cái, đều ngày 02/10/2026, tác giả Ngan Tran Doan Kim)

| Neo vào | Nội dung |
|---|---|
| ZRHR02A | Citek cập nhật tài liệu |
| Billing Document (bảng tham số) | **Xoá 2 tham số 4,5** |
| Mã sản phẩm chủ lực | **Bổ sung tham số Mã sản phẩm chủ lực** |
| "ALV hoặc Form in" | Màn hình tham số bổ sung 2 option ALV: Xuất file import cho HRM / Form in: Ký duyệt |
| Z_SPCL (thuật ngữ) | Citek update thông tin |
| Z_SPCL (mục 3.1) | **Update lại tên Field trên Master data của Mã** |
| SPCL (thuật ngữ) | **Cập nhật tên field là Sản phẩm chủ lực** |
| ZRHR02B (tiêu đề 3.1) | Điều chỉnh tên của chỉ tiêu 7 trong hình thành "Mã nhóm sản phẩm" |
| Màn hình danh sách khai báo | Anh Toà trao đổi và thống nhất nội bộ về cách thức khai báo Mapping, **gửi lại Citek 03.10.2026** |
| Màn hình danh sách khai báo | Quy chế lương của kênh dịch vụ Anh Toà **gửi lại 03.10.2026** |

→ 2 comment cuối hẹn gửi lại ngày 03.10.2026, hôm nay đã 06/10 — cần hỏi đã nhận chưa.

## Trạng thái dữ liệu trên DEV client 200 (check 06/10/2026)

| Bảng | Số bản ghi |
|---|---|
| `VBRK` (hóa đơn) | **0** |
| `VBPA` (partner chứng từ) | **0** |
| `PA0001` (HR master) | **0** |
| `CABN` (characteristic) | 4.146 (nhưng không có `Z*`) |

→ Chưa test được bằng dữ liệu thật trên client 200.

## Text Elements cần tạo khi copy lên SE38

- `TEXT-B01` = Điều kiện lọc
- `TEXT-B02` = Nhân sự bán hàng
- `TEXT-B03` = Dạng kết xuất
- `TEXT-H01` = Báo cáo doanh số nhân viên bán hàng

Selection texts: S_VKORG (Tổ chức bán hàng), S_VTWEG (Kênh bán hàng), S_FKDAT (Ngày hóa đơn), S_FKART (Loại hóa đơn), S_VBELN (Số hóa đơn), S_KUNAG (Mã khách hàng), S_MATNR (Mã hàng), S_PERNR (Mã nhân viên), S_PARVW (Vai trò nhân sự bán hàng), P_EXPORT (Xuất tệp import cho hệ thống nhân sự tiền lương).

## Tham chiếu

- FS: `CodeABAP/BDP/ZRHR02/FS/BIDIPHAR_FS_SD_ZRHR02_BaoCaoDoanhSoNhanVienBanHang_V1.0.docx`
- Code mẫu cùng chuẩn: `CodeABAP/BDP/ZRSD25/Program/` (CL_SALV_TABLE), `CodeABAP/BDP/ZRSD26/Program/` (header chuẩn Citek)
- Quy tắc chung: `CodeABAP/BDP/NOTE/note.md`
- MCP server: `GUI_BDP_DEV_200` (user CT.CSTECH, client 200), package `ZPK_BDP`
