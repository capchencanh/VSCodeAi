---
name: abap-fi-upload-fidoc
description: 'Khung "upload Excel → kiểm tra → staging ZTB_UPLOAD_HD/DT → ALV → BAPI_ACC_DOCUMENT_CHECK/POST/park" của ZFI_PG_UPLOAD_FIDOC (On-Premise) và cấu trúc tái dùng: ZST_UPLOAD_HD/DT, ZTT_UPLOAD_DT, FM ZFM_ACC_DOCUMENT_POST, Extension2 ZST_ACC_DOC_*, ZCORE_FM_SAVE_LONG_TEXT_1, message class ZMC_MAISON. TRIGGER — chỉ đọc khi (1) tạo chương trình MỚI upload-và-hạch toán chứng từ FI (bút toán, hóa đơn NCC/KH, tài sản, CPD) muốn dùng lại bảng/FM/structure có sẵn; (2) thêm/sửa 1 field (kể cả cột upload) hoặc 1 check trong ZFI_PG_UPLOAD_FIDOC/ZFM_ACC_DOCUMENT_POST; (3) gọi ZFM_ACC_DOCUMENT_POST từ chương trình/job khác hoặc debug lỗi post/scale amount/long text của chứng từ upload. SKIP — không đọc khi: chỉ đọc-giải thích code ZFI_PG_UPLOAD_FIDOC, upload Excel không tạo chứng từ FI (MM/SD/master data), chỉnh riêng template ZXLWB (dùng `zxlwb-workbench`), hoặc hỏi cú pháp BAPI chung.'
user-invocable: true
disable-model-invocation: false
---

# ZFI_PG_UPLOAD_FIDOC — khung upload & hạch toán chứng từ FI

Nguồn: `CodeABAP/zfi_pg_upload_fidoc/` (export 08.10.2026; On-Premise, extract ghi Release 753, header chương trình ghi ECC 6.0; gốc NamLG 29.05.2018, thêm "Download template" nguyen.ho 06.11.2025).

> **Mọi mô tả dưới đây rút ra từ ĐỌC source, chưa chạy thử trên hệ thống.** Chưa có trong export: PF-STATUS `STS0100`, form Excel `ZXLSX_TEMPLATE_ZUP`, BAdI `ACC_DOCUMENT` (đọc Extension2), customizing text ID `BELEG` 0001–0022, include `ZST_UPDATE_INFO`, package/T-code. Điểm nào dựa vào các thứ này đều ghi rõ cần xác nhận.

Tài liệu chi tiết (đọc đúng mục, không đọc cả file):
- `references/field-map.md` — 78 cột Excel ↔ GTY_UPLOAD ↔ ZST/ZTB ↔ đích BAPI, kèm check.
- `references/code-skeleton.md` — mẫu code: gọi FM từ nơi khác, check field mới, Extension2, long text.
- `references/known-issues.md` — lỗi/điểm nghi ngờ khi đọc code (đọc trước khi clone).

## 1. Chọn mức tái dùng

| Nhu cầu | Làm gì |
|---|---|
| Cần chức năng upload FI **mới** (khác template/validation/mapping) nhưng vẫn ra chứng từ qua BAPI_ACC_DOCUMENT | Clone chương trình (4 include + screen 0100 + PF-STATUS) → dùng chung FM + ZST + ZTB. Xem §6A |
| Chỉ thêm cột/field/check vào chương trình hiện có | Xem §6B (touch-list đầy đủ) |
| Không có giao diện (job, interface, BAdI) cần tạo chứng từ FI | Dựng `ZST_UPLOAD_HD` + `ZTT_UPLOAD_DT` rồi gọi thẳng `ZFM_ACC_DOCUMENT_POST` — §6C |
| Nghiệp vụ KHÔNG phải BAPI_ACC_DOCUMENT (MM/SD/master data) | Chỉ mượn pattern (upload → staging → ALV → post-loop), không dùng FM/ZST của FI |

## 2. Luồng chương trình

```
START-OF-SELECTION → MAIN_PROC
  GET_DATA            ~29 SELECT bảng master → GT_* (SORT sẵn để BINARY SEARCH) — chạy cả khi Display/Download
  ├ RB_UPL  UPLOAD_EXCEL        TEXT_CONVERT_XLS_TO_SAP → GT_UPLOAD (dòng 1 = header, bị bỏ)
  │         CHECK_DATA_UPLOAD   length → GT_PROCESS; auth, required, tồn tại, ngày, số; DỪNG ở lỗi đầu tiên
  │         SPLIT_HEADER_DETAIL gom theo ID_DOC → GT_HEAD(+DETAIL); INSERT ZTB_UPLOAD_HD/DT; COMMIT
  ├ RB_DIS  GET_UPLOADED_DATA   đọc ZTB_* theo CRT_USER=sy-uname + P_FNAME + S_UPLDT
  └ RB_DOW  DOWNLOAD_EXCEL      ZXLWB_WORKBENCH(form ZXLSX_TEMPLATE_ZUP, action EXPORT) → RETURN
  CREATE_OBJECT → CALL SCREEN 0100   splitter 2 hàng: ALV GT_HEAD (trên) + ALV GT_DET (dưới)
PAI 0100
  POST / CHECK / PARK → POST_DOCUMENT
      mỗi header chưa có BELNR: đổi amount → external; CALL ZFM_ACC_DOCUMENT_POST (I_TEST_RUN / I_PARK)
      có lỗi A/E → ROLLBACK, xoá BELNR/GJAHR của mọi header (all-or-nothing)
      thành công thật → COMMIT WORK AND WAIT → SAVE_DATA (UPDATE ZTB_*) → CALL_SAVE_TEXT (long text)
  BACK / EXIT / CANC → EXIT_COMMAND_0100 (popup nếu GW_CHANGED_FLG, rồi LEAVE TO SCREEN 0) và/hoặc
                       SAVE_DATA trong USER_COMMAND_0100 — tuỳ function type trong STS0100 (chưa có trong export)
Double-click dòng header → DISPLAY_DETAIL nạp GT_DET (class CL_EVT_HEAD)
```

Ý nghĩa `OK_CODE`: `CHECK` = test run (BAPI_ACC_DOCUMENT_CHECK, không ghi); `POST` = hạch toán thật; `PARK` = vẫn gọi BAPI_ACC_DOCUMENT_POST nhưng `DOC_STATUS='2'` (chứng từ park). `STATUS` trên ALV (exception light): 1 đỏ = lỗi, 3 xanh = OK.

## 3. Bản đồ file (đọc chọn lọc)

`zfi_in_upload_fidoc_f01.abap` ~3100 dòng — KHÔNG đọc cả file: `grep -n -i '^form ' <file>` rồi đọc đúng FORM.

| File | Nội dung |
|---|---|
| `zfi_pg_upload_fidoc.abap` | Main: 5 include + event; text element 001–003, T01–T09; liệt kê message ZMC_MAISON 001–028 |
| `..._top.abap` | `GTY_UPLOAD` (78 cột Excel), `GTY_PROCESS` (độ dài thật), `GTY_T001…GTY_T012K` (cache check), `GT_*`, selection screen, `CL_EVT_HEAD/DET` |
| `..._f01.abap` | Toàn bộ FORM, nhóm: **màn hình** SH_FILE/SH_FNAME/UPD_SCREEN/CHECK_PROC · **upload+check** UPLOAD_EXCEL/CHECK_DATA_UPLOAD/CHECK_LENGTH/CHECK_DATE/CHECK_NUMERIC · **loader** GET_DATA + GET_T001…GET_T012K · **staging** SPLIT_HEADER_DETAIL/GET_UPLOADED_DATA/SAVE_DATA · **ALV** CREATE_OBJECT/DISPLAY_DETAIL/REFRESH_ALV/CALL_POPUP · **post** POST_DOCUMENT/CALL_SAVE_TEXT · **tiền tệ** CURRENCY_TO_INTERNAL/EXTERNAL · **template** DOWNLOAD_EXCEL |
| `..._i01.abap` / `..._o01.abap` | PAI `EXIT_COMMAND_0100` (AT EXIT-COMMAND), `USER_COMMAND_0100` · PBO `STATUS_0100` (STS0100/TTL0100) |
| `screens/screen_0100.txt` | Screen 0100: custom control `CC_CONTAINER` + `OK_CODE` |
| `zfm_acc_document_post/` | FM post (437 dòng) — lõi tái dùng |
| `dictionary/*.html` | ZST_UPLOAD_HD/DT, ZTB_UPLOAD_HD/DT, ZTT_UPLOAD_DT, ZST_ACC_DOC_* |

FORM legacy KHÔNG dùng/không copy khi clone: CHECK_STATUS, DEL_DATA, OVERWRITE_DATA, SET_SELECT, USER_COMMAND, EDIT_TOOLBAR, GET_NEXT_NUMBER, LIST_TO_PRINT, CHECK_NET_PRICE, GET_T043, CALL_WS_E_INVOICE (thân comment, tham chiếu object không có trong package).

## 4. Thành phần tái dùng

| Object | Loại | Vai trò / lưu ý khi dùng |
|---|---|---|
| `ZTB_UPLOAD_HD` | Bảng | Staging header. Key `MANDT+FILENAME+ID_DOC`. Có BELNR, `.INCLUDE ZST_UPDATE_INFO` (CRT/UPD/PST/DEL user-date-time, ISDEL, ISPOST). **Không có cột phân loại chức năng** |
| `ZTB_UPLOAD_DT` | Bảng | Staging dòng. Key `+ID_LINE` (NUMC6). WRBTR/DMBTR/FWBAS lưu **internal** (CURR) |
| `ZST_UPLOAD_HD` | Structure | Header runtime = field HD + `BELNR/GJAHR/ERROR/STATUS/STYLE/COLOR` + `DETAIL` (`ZTT_UPLOAD_DT`, bảng lồng). Line type `GT_HEAD`, tham số `I_HEADER` |
| `ZST_UPLOAD_DT` | Structure | Dòng chi tiết (+`KOART/SHKZG/LWAER`, `KDGRP/LAND1/KUNNR/WERKS` mà Excel chưa có cột). Line type `GT_DET` |
| `ZTT_UPLOAD_DT` | Table type | `TABLE OF ZST_UPLOAD_DT` — tham số `I_DETAIL` |
| `ZFM_ACC_DOCUMENT_POST` | FM (FUGR `ZFG_ACC_DOCUMENT_POST`) | `I_HEADER, I_DETAIL, I_TEST_RUN(CHAR01), I_PARK(CHAR01)` → `E_RETURN(BAPIRET2_T), E_OBJKEY`. **Không commit** — caller commit/rollback. Chi tiết §5 |
| `ZST_ACC_DOC_PKEY / _TAX_FIELDS / _VEND_FIELDS / _CUST_FIELDS / _ASSET_FIELDS` | Structure | Payload `EXTENSION2` (BAPIPAREX-STRUCTURE = tên structure, `POSNR` đầu tiên, nhét vào `VALUEPART1`). Cần BAdI `ACC_DOCUMENT` đọc lại — **chưa thấy implementation trong export** |
| `ZCORE_FM_SAVE_LONG_TEXT_1` (FUGR `ZCORE_FG_GLOBAL_FUNCTION`) | FM | `I_TDOBJECT/I_TDNAME/I_TDID/I_TDSPRAS/I_LONGTEXT(CHAR255)` → `SAVE_TEXT`+`COMMIT_TEXT`+`COMMIT WORK AND WAIT` (**commit ngay trong FM**) |
| `ZCH_SPLIT_FILENAME` | FM | `NAME` = tên file **không đuôi** (`a.xlsx`/`a.xls` cùng khoá) |
| `ZXLWB_WORKBENCH` + form `ZXLSX_TEMPLATE_ZUP` | FM + form | Tải template; cần `INCLUDE zxlwb_include` (~40k dòng) để dùng `LCL_WORKBENCH=>C_ACTION-EXPORT`. Sửa form: skill `zxlwb-workbench` |
| `ZMC_MAISON` | Message class | 001 Please input &1 · 002 &1 &2 does not exist · 003 not authorized CoCode · 004 exceeded max length · 005 does not support · 006 PstKey/SGL invalid · 007 PstKey/PayTerm invalid · 008 PayMethod · 009 wrong format · 010 insert table failed · 011 upload OK · 012 file name invalid · 013 file posted · 014 execute FM failed · 015 file của user khác · 016 input excel · 017 No data · 018 File was posted · 019 saved · 020 checking finished · 021 post OK · 022 post failed · 023 Account/Tax code · 024 Asset · 025 park OK · 026 House bank · 027 Bank account · 028 numeric |
| DE | | `ZDE_FILE_NAME` (CHAR255, lowercase) · `ZDE_ID_DOC` (domain BELNR, CHAR10) · `ZDE_ID_LINE` (POSNR, NUMC6) · `ZDE_LIGHT`/`ZDO_LIGHT` (CHAR1) |

## 5. Hợp đồng dữ liệu — phải giữ khi tạo chức năng mới

1. **Excel đọc theo VỊ TRÍ cột**: `TEXT_CONVERT_XLS_TO_SAP` đổ cột 1..N vào `GTY_UPLOAD` đúng thứ tự khai báo → thứ tự cột template = thứ tự field trong `GTY_UPLOAD`. Thêm field = chèn đúng vị trí + sửa template (§6B). Giá trị đến dạng CHAR255 thô; chuyển đổi/kiểm tra ở `CHECK_DATA_UPLOAD`.
2. **`ID_DOC` là khoá gom dòng thành chứng từ** (không phải BELNR). `GTY_PROCESS-ID_DOC` là `N(10)` → nên dùng số. Sau `SORT BY ID_DOC STT`, `AT NEW ID_DOC` lấy **header từ dòng đầu của nhóm**, nhưng `CHECK_DATA_UPLOAD` bắt các cột header (BLDAT, BUDAT, BLART, BUKRS, WAERS) **phải có ở mọi dòng**.
3. **Tiền tệ — 2 biên chuyển đổi, mỗi biên 1 lần**: Excel (số thực) → `BAPI_CURRENCY_CONV_TO_INTERNAL` khi `SPLIT_HEADER_DETAIL` → staging lưu internal; staging → `BAPI_CURRENCY_CONV_TO_EXTERNAL` trên **bản copy** `LT_DETAIL` trong `POST_DOCUMENT` → FM nhận **external** (số thực). Gọi FM từ nơi khác: truyền số thực, KHÔNG truyền giá trị BSEG-WRBTR. Nhập số dương; FM đảo dấu khi `SHKZG='H'`.
4. **`KOART`/`SHKZG` suy ra từ `TBSL` theo `BSCHL`** (không có trong Excel) và quyết định bảng BAPI: `S/A` → ACCOUNTGL (hoặc ACCOUNTTAX), `K` → ACCOUNTPAYABLE, `D` → ACCOUNTRECEIVABLE. `HKONT` phải ở dạng **internal** (ALPHA input).
5. **FM không commit**. `I_TEST_RUN='X'` → `BAPI_ACC_DOCUMENT_CHECK`; ngược lại `BAPI_ACC_DOCUMENT_POST`. Lỗi = có dòng `E_RETURN-TYPE` A hoặc E. `E_OBJKEY` = BELNR(10)+BUKRS(4)+GJAHR(4) → `BELNR = objkey(10)`, `GJAHR = objkey+14(4)`.
6. **Dòng thuế**: `KOART='S'` và TK dạng `133*`/`3331*` → `ACCOUNTTAX` (`DIRECT_TAX='X'`) + Extension2 `TAX_FIELDS`; TK khác → `ACCOUNTGL`. `KOART='A'` → ACCOUNTGL `ACCT_TYPE='A'` + TK clearing tài sản từ `T095_ACI` + Extension2 `ASSET_FIELDS`. **Hard-code theo khách hàng VN**: `133*`/`3331*`, tax code `IN/IX/NA` miễn check, `GET_T030K` cứng `KTOPL='COAO'`, `ALAND='VN'`, `KALSM='TAXVN'`, `T007A` lọc `TAXVN`.
7. **Currency line**: dòng 1 `CURRENCY=I_HEADER-WAERS`, `EXCH_RATE=KURSF`, `AMT_BASE=FWBAS`; dòng 2 (`CURR_TYPE='10'`, `LWAER`) chỉ khi `DMBTR` khác rỗng và ≠ `WRBTR`. CO-PA: `PRCTR, WW14, VKBUR→KMVKBU, VKGRP→KMVKGR, VTWEG, WW12, KDGRP, LAND1, KUNNR→KNDNR, WERKS` đẩy vào `CRITERIA`. Khách vãng lai (`XCPDK` của LFA1/KNA1 từ dòng K/D đầu) → `CUSTOMERCPD` từ `NAME, NAME_2, CITY, COUNTRY, STCEG`.
8. **Long text sau khi post**: header `OBJECT='BELEG'`, `TDNAME=BUKRS+BELNR+GJAHR`, ID theo cột (xem field-map); dòng `OBJECT='DOC_ITEM'`, `ID='0001'`, `TDNAME=BUKRS+BELNR+GJAHR+BUZEI` với `BUZEI` = thứ tự dòng detail (giả định khớp BSEG-BUZEI, chưa kiểm chứng).
9. **Validation kiểu "dừng ở lỗi đầu"**: `MESSAGE Snnn WITH … DISPLAY LIKE 'E'.` + `LEAVE LIST-PROCESSING.` (class `ZMC_MAISON`). Muốn liệt kê mọi lỗi → thiết kế khác (cột `ERROR`/`STATUS` ALV), đừng nhái pattern này.
10. **Khoá file**: `ZTB_UPLOAD_*` khoá theo tên file không đuôi, không có user/chức năng. Upload lại cùng tên: chỉ cho phép khi cùng `CRT_USER` và header chưa có BELNR (hỏi popup rồi DELETE + INSERT lại); khác user → S015; đã post → S013.

## 6. Công thức

### A. Clone thành chương trình upload FI mới
1. Quyết định với user **staging dùng chung hay riêng**. Dùng chung `ZTB_UPLOAD_*`: 2 chương trình đụng tên file và Display lẫn dữ liệu nhau (không có cột phân loại) → đề xuất thêm cột loại chức năng vào ZTB/ZST và lọc theo nó, hoặc quy ước prefix tên file. Đổi bảng dùng chung = hỏi xác nhận.
2. Tên mới theo họ hiện hữu `ZFI_PG_UPLOAD_<X>` + `ZFI_IN_UPLOAD_<X>_TOP/F01/I01/O01` (On-Premise — KHÔNG dùng `abap-cloud-naming`). Copy screen 0100 + PF-STATUS (`STS0100`, `TTL0100`) + text element + message class.
3. Giữ nguyên khung: TOP (types/event class), MAIN_PROC, SPLIT_HEADER_DETAIL, POST_DOCUMENT, SAVE_DATA, CREATE_OBJECT, GET_UPLOADED_DATA, tiền tệ/ALPHA helpers. Sửa: `GTY_UPLOAD/GTY_PROCESS`, `CHECK_DATA_UPLOAD`, danh sách loader theo check cần, form template.
4. Bỏ FORM legacy (§3), bỏ `INCLUDE zxlwb_include` nếu không cần nút tải template.
5. Mọi thay đổi ZST/ZTB/FM → làm theo touch-list §6B; template Excel mới copy từ `ZXLSX_TEMPLATE_ZUP` (xem `zxlwb-workbench`).
6. Đọc `references/known-issues.md` trước khi copy `SPLIT_HEADER_DETAIL`/`CHECK_LENGTH`.

### B. Thêm 1 field/cột (touch-list theo chiều đi của dữ liệu)
1. `GTY_UPLOAD` — **đúng vị trí cột** (TOP). 2. `GTY_PROCESS` — độ dài thật (TOP).
3. `CHECK_DATA_UPLOAD`: `CHECK_LENGTH`, required/format/tồn tại (loader `GET_xxx` + `GT_xxx` + `GTY_xxx` + REFRESH ở `INIT_PROC`). Mẫu: code-skeleton §S2.
4. `ZST_UPLOAD_DT` hoặc `_HD` — thêm field; **và `ZTB_UPLOAD_DT/HD` nếu muốn lưu & hiển thị lại** (`MOVE-CORRESPONDING` âm thầm bỏ field không có ở ZTB — xem known-issues #3). Sửa bảng DB = hỏi xác nhận, kích hoạt + điều chỉnh DB.
5. `ZFM_ACC_DOCUMENT_POST`: gán vào field BAPI chuẩn hoặc Extension2 (§S3; phải sửa BAdI `ACC_DOCUMENT` đọc structure mới).
6. `CREATE_OBJECT`: tiêu đề cột (`CASE fieldname` COLTEXT/SCRTEXT_*), ẩn `NO_OUT` nếu cần.
7. Template `ZXLSX_TEMPLATE_ZUP`: thêm cột đúng vị trí, import lại (làm tay trên GUI). 8. Cập nhật TS/FS (`sap-ts-document`).
`SPLIT_HEADER_DETAIL`/`SAVE_DATA` dùng `MOVE-CORRESPONDING`/`UPDATE … FROM TABLE` nên **không cần sửa** nếu tên field trùng.

### C. Gọi `ZFM_ACC_DOCUMENT_POST` từ nơi khác
Dựng `ZST_UPLOAD_HD` + `ZTT_UPLOAD_DT` (tối thiểu: header `BUKRS BLDAT BUDAT BLART WAERS`; dòng `BSCHL KOART SHKZG HKONT WRBTR` + `WAERS/LWAER` nếu có DMBTR), gọi test run trước rồi post thật; COMMIT/ROLLBACK ở caller. Mẫu đầy đủ: code-skeleton §S1.

### D. Thêm long text header mới
Thêm cột `…` vào GTY_UPLOAD/ZST_UPLOAD_HD (+ZTB_UPLOAD_HD), thêm khối `IF ls_head-xxx IS NOT INITIAL. PERFORM call_save_text USING 'BELEG' '<id>' lw_tdname ls_head-xxx.` trong `POST_DOCUMENT`; **text ID phải tồn tại trong customizing object `BELEG`** (chưa kiểm chứng ID nào còn trống). Mẫu: §S4. Giới hạn 255 ký tự (CHAR255, FM tự cắt dòng 132).

## 7. Quy ước khi sửa/clone

- Code mới trong file cũ: marker `add/modify/comment begin-end` + `<UserName>` theo `CLAUDE.md`; không xoá code, chỉ comment.
- Biến/field-symbol **mới** theo `abap-naming-convention` (`LV_/LT_/LS_`, `<LFS_*>`); file cũ dùng `LW_/LPW_/GW_` — **không đổi tên hàng loạt**.
- Nền tảng On-Premise → `abap-platform-constraints` (BAPI cho thay đổi dữ liệu, ATC khuyến nghị, transport SE09/STMS).
- `GET_DATA` đọc nguyên bảng master (KNA1, LFA1, MARA, SKA1, AUFK, ANLA, CSKS, CEPC, KNB1, LFB1…) mỗi lần chạy kể cả Display/Download — chấp nhận được với dữ liệu vừa; nếu clone cho hệ thống lớn, giới hạn theo giá trị có trong file (`abap-performance-hana`).

## 8. Skill liên quan

`zxlwb-workbench` (template Excel) · `abap-naming-convention` · `abap-platform-constraints` · `badi-enhancement` (BAdI `ACC_DOCUMENT`) · `sap-ts-document` (viết TS cho chức năng mới) · `abap-performance-hana`.
