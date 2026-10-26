# Mẫu code — tái dùng khung ZFI_PG_UPLOAD_FIDOC

**CÁCH ĐỌC FILE NÀY:** không đọc cả file. `grep -n '^## ' code-skeleton.md` rồi đọc đúng mẫu. Các mẫu là **khung đề xuất** dựng từ đọc source (chưa kích hoạt/chạy thử); khi dán vào chương trình thật vẫn phải thêm marker `add/modify begin-end` theo `CLAUDE.md` và hỏi xác nhận trước khi ghi vào hệ thống. Biến mới đặt theo `abap-naming-convention`.

## Mục lục
- S1. Gọi `ZFM_ACC_DOCUMENT_POST` từ chương trình/job khác
- S2. Check tồn tại cho field mới (loader + READ BINARY SEARCH)
- S3. Thêm Extension2 (structure mới)
- S4. Ghi long text sau khi post

## S1. Gọi `ZFM_ACC_DOCUMENT_POST` từ chương trình/job khác

Điều kiện: số tiền là **số thực (external/BAPI)**, `HKONT` ở dạng internal (ALPHA input), ngày dạng DATS, `KOART/SHKZG` lấy từ `TBSL`. FM không commit.

```abap
DATA:
  ls_head   TYPE zst_upload_hd,
  ls_det    TYPE zst_upload_dt,
  lt_det    TYPE ztt_upload_dt,
  lt_return TYPE bapiret2_t,
  lv_objkey TYPE bapiache09-obj_key,
  lv_belnr  TYPE belnr_d,
  lv_gjahr  TYPE gjahr,
  lv_error  TYPE c.

* Header (BAPI dùng BUKRS để suy ra CoA/local currency; WAERS áp cho mọi dòng)
ls_head-bukrs = '<BUKRS>'.
ls_head-bldat = sy-datum.
ls_head-budat = sy-datum.
ls_head-blart = '<BLART>'.
ls_head-waers = '<WAERS>'.
ls_head-bktxt = '<Header text, tối đa 25>'.
* ls_head-kursf / xblnr / xref1_hd / monat: tuỳ chọn

* Dòng 1 — KOART/SHKZG suy ra từ posting key
CLEAR ls_det.
ls_det-bschl = '<BSCHL>'.
SELECT SINGLE koart shkzg FROM tbsl
  INTO ( ls_det-koart, ls_det-shkzg )
  WHERE bschl = ls_det-bschl.
CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
  EXPORTING input  = '<HKONT>'
  IMPORTING output = ls_det-hkont.
ls_det-wrbtr = '<số tiền thực, dương>'.   "không phải giá trị BSEG-WRBTR
ls_det-sgtxt = '<Item text>'.
APPEND ls_det TO lt_det.
* Dòng 2... (lặp lại; tổng Nợ = tổng Có theo SHKZG)

* Test run trước
CALL FUNCTION 'ZFM_ACC_DOCUMENT_POST'
  EXPORTING i_header = ls_head i_detail = lt_det i_test_run = 'X' i_park = space
  IMPORTING e_return = lt_return e_objkey = lv_objkey.
LOOP AT lt_return TRANSPORTING NO FIELDS WHERE type = 'A' OR type = 'E'.
  lv_error = 'X'. EXIT.
ENDLOOP.

IF lv_error IS INITIAL.
* Post thật (i_park = 'X' để park)
  CLEAR lt_return.
  CALL FUNCTION 'ZFM_ACC_DOCUMENT_POST'
    EXPORTING i_header = ls_head i_detail = lt_det i_test_run = space i_park = space
    IMPORTING e_return = lt_return e_objkey = lv_objkey.
  LOOP AT lt_return TRANSPORTING NO FIELDS WHERE type = 'A' OR type = 'E'.
    lv_error = 'X'. EXIT.
  ENDLOOP.
  IF lv_error IS INITIAL.
    COMMIT WORK AND WAIT.
    lv_belnr = lv_objkey(10).
    lv_gjahr = lv_objkey+14(4).
  ELSE.
    ROLLBACK WORK.
  ENDIF.
ENDIF.
```

Nếu có nhiều chứng từ cần all-or-nothing (như `POST_DOCUMENT`): gọi hết, chỉ `COMMIT WORK AND WAIT` khi không header nào lỗi, ngược lại `ROLLBACK WORK`. Muốn kèm dòng thuế/tài sản/khách vãng lai/CO-PA: xem SKILL.md §5.6–5.7 (KOART `S` + TK `133*/3331*`, `A` + `ANLN1/ANLN2/BWASL/BZDAT`, `NAME/CITY/COUNTRY/STCEG`, `WW14…`).

## S2. Check tồn tại cho field mới

1. TOP: `gty_xxx` (chỉ field cần), `gt_xxx TYPE TABLE OF gty_xxx`.
2. F01: loader + gọi trong `GET_DATA` + `REFRESH` trong `INIT_PROC` (`SORT` theo đúng key sẽ `READ … BINARY SEARCH`; key READ phải là **tiền tố** của key SORT).

```abap
FORM get_xxx.
  SELECT <key> FROM <bảng> INTO TABLE gt_xxx.
  IF sy-subrc = 0.
    SORT gt_xxx BY <key> ASCENDING.
  ENDIF.
ENDFORM.
```

3. `CHECK_DATA_UPLOAD` (trong `LOOP AT GT_PROCESS ASSIGNING <LF_PROCESS>`):

```abap
*   Check existence of <Tên hiển thị>
    IF <lf_process>-xxx IS NOT INITIAL.
      lw_temp = <lf_process>-xxx.                       "giữ giá trị gốc cho message
      PERFORM convert_alpha_input USING <lf_process>-xxx CHANGING <lf_process>-xxx.
      READ TABLE gt_xxx TRANSPORTING NO FIELDS
        WITH KEY <key> = <lf_process>-xxx BINARY SEARCH.
      IF sy-subrc <> 0.
        MESSAGE s002 WITH '<Tên hiển thị>' lw_temp DISPLAY LIKE 'E'.
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDIF.
```

4. Độ dài: thêm `PERFORM check_length USING ls_upload-xxx '<Tên>' <len>.` vào vòng lặp đầu (lưu ý known-issues #1: không dừng). Ngày: `PERFORM check_date CHANGING <lf_process>-xxx lw_subrc` + `MESSAGE s009`. Số: `PERFORM check_numeric …`.

## S3. Thêm Extension2 (structure mới)

1. Tạo `ZST_ACC_DOC_<X>` — field đầu `POSNR` (kiểu POSNR NUMC6), tổng độ dài ≤ 240 (vừa `BAPIPAREX-VALUEPART1`; nếu dài hơn dùng VALUEPART2…). Structure hiện hữu dài 3–132 ký tự.
2. `ZFM_ACC_DOCUMENT_POST` — trong LOOP dòng detail, đúng nhánh KOART:

```abap
CLEAR: ls_acc_doc_<x>, ls_bapiparex.
ls_bapiparex-structure   = 'ZST_ACC_DOC_<X>'.
ls_acc_doc_<x>-posnr     = lw_itemno.
ls_acc_doc_<x>-<field>   = ls_det-<field>.
ls_bapiparex-valuepart1  = ls_acc_doc_<x>.
APPEND ls_bapiparex TO lt_bapiparex.
```

3. Implement BAdI `ACC_DOCUMENT` (method `CHANGE`, đọc `EXTENSION2`, khớp `STRUCTURE` + `POSNR` với `ACCIT-POSNR`, gán field vào ACCIT). **Implementation hiện hữu chưa nằm trong export** → tìm trong SE19 (filter theo structure `ZST_ACC_DOC_*`) và kiểm tra tên tham số ở SE18 trước khi sửa. Xem skill `badi-enhancement`.
4. Field đi qua Extension2 còn cần có cột trên `ZST_UPLOAD_*` (+`ZTB_*`) — xem SKILL.md §6B.

## S4. Ghi long text sau khi post

`POST_DOCUMENT` gọi `CALL_SAVE_TEXT` **sau** `COMMIT WORK AND WAIT` + `SAVE_DATA`, với `GT_HEAD` đã có `BELNR/GJAHR`:

```abap
CONCATENATE ls_head-bukrs ls_head-belnr ls_head-gjahr INTO lw_tdname.
IF ls_head-<field> IS NOT INITIAL.
  PERFORM call_save_text
    USING 'BELEG' '<text id>' lw_tdname ls_head-<field>.   "<= CHAR255
ENDIF.
* Item: OBJECT 'DOC_ITEM', ID '0001', TDNAME = BUKRS+BELNR+GJAHR+BUZEI
CONCATENATE ls_head-bukrs ls_head-belnr ls_head-gjahr lw_buzei INTO lw_tdname.
PERFORM call_save_text USING 'DOC_ITEM' '0001' lw_tdname ls_detail-ltext.
```

Text ID đang dùng cho `BELEG`: 0001–0007, 0009, 0010, 0012, 0017, 0020–0022 (bảng field-map). Chọn ID mới phải kiểm tra customizing object `BELEG` trên hệ thống (chưa kiểm chứng ID nào còn trống). `ZCORE_FM_SAVE_LONG_TEXT_1` **tự `COMMIT WORK AND WAIT`** mỗi lần gọi.
