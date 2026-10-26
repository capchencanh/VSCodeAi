# Chương trình ABAP gọi Adobe Form (On-Premise)

Nguồn: API chuẩn SAP Forms by Adobe (`FP_JOB_OPEN`, `FP_FUNCTION_MODULE_NAME`, FM sinh từ form, `FP_JOB_CLOSE`). **Chưa có chương trình gọi form nào trong repo để đối chiếu** — có MCP server `GUI_*` thì kiểm tham số bằng tool đọc FM trước khi bàn giao. Khi chèn vào chương trình của user: header + marker `"<UserName> add begin/end ...` theo `CLAUDE.md`, tên biến theo skill `abap-naming-convention`.

## Mục lục
1. FM sinh từ form
2. Khung gọi form (preview / in / lấy PDF)
3. Chuẩn bị dữ liệu
4. Logo SE78

## 1. FM sinh từ form

Activate form → SAP sinh FM tên dạng `/1BCDWB/SM000000nn`, **khác nhau giữa các hệ thống** → luôn lấy tên qua `FP_FUNCTION_MODULE_NAME`. Tham số FM:

| Tham số | Kiểu | Ghi chú |
|---|---|---|
| `/1BCDWB/DOCPARAMS` (import) | `SFPDOCPARAMS` | `LANGU` = ngôn ngữ gốc của form (thẻ `LANGUAGE` trong SFPF, 3 mẫu đều `E`), `COUNTRY` |
| tham số import của interface | đúng tên + kiểu khai trong SFPI | VD `GT_DATA = gt_data` |
| `/1BCDWB/FORMOUTPUT` (export) | `FPFORMOUTPUT` | `-PDF` (XSTRING) khi `GETPDF = 'X'` |
| exception | `USAGE_ERROR`, `SYSTEM_ERROR`, `INTERNAL_ERROR` | |

## 2. Khung gọi form

1 job (`FP_JOB_OPEN` … `FP_JOB_CLOSE`) gọi FM form bao nhiêu lần cũng được → 1 spool / 1 lần xem trước. Kiểu "1 lần gọi = 1 chứng từ" (header + item): `LOOP` qua chứng từ, dựng `GT_HDR` (1 dòng) + `GT_ITEM` rồi gọi FM trong vòng lặp.

```abap
FORM print_adobe.
  CONSTANTS: lc_form TYPE fpname VALUE 'ZAF_DEMO_PXK'.
  DATA: ls_outparams TYPE sfpoutputparams,
        ls_docparams TYPE sfpdocparams,
        ls_output    TYPE fpformoutput,
        lv_fm_name   TYPE funcname,
        lo_error     TYPE REF TO cx_root,
        lv_text      TYPE string.

  ls_outparams-preview  = abap_true.             " xem trước
* ls_outparams-nodialog = abap_true.             " không hiện hộp chọn máy in
* ls_outparams-dest     = 'LP01'.                " máy in
* ls_outparams-reqimm   = abap_true.             " in ngay
* ls_outparams-getpdf   = abap_true.             " không in, trả PDF vào ls_output-pdf
  CALL FUNCTION 'FP_JOB_OPEN'
    CHANGING
      ie_outputparams = ls_outparams
    EXCEPTIONS
      cancel          = 1
      usage_error     = 2
      system_error    = 3
      internal_error  = 4
      OTHERS          = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  TRY.
      CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
        EXPORTING
          i_name     = lc_form
        IMPORTING
          e_funcname = lv_fm_name.
    CATCH cx_fp_api_repository cx_fp_api_usage cx_fp_api_internal INTO lo_error.
      lv_text = lo_error->get_text( ).
      MESSAGE lv_text TYPE 'S' DISPLAY LIKE 'E'.
      CALL FUNCTION 'FP_JOB_CLOSE'
        EXCEPTIONS
          OTHERS = 1.
      RETURN.
  ENDTRY.

  ls_docparams-langu   = 'E'.                    " ngôn ngữ gốc của form
  ls_docparams-country = 'VN'.
  CALL FUNCTION lv_fm_name
    EXPORTING
      /1bcdwb/docparams  = ls_docparams
      gt_hdr             = gt_hdr                " = tên tham số import trong interface
      gt_item            = gt_item
    IMPORTING
      /1bcdwb/formoutput = ls_output
    EXCEPTIONS
      usage_error        = 1
      system_error       = 2
      internal_error     = 3
      OTHERS             = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
  ENDIF.

  CALL FUNCTION 'FP_JOB_CLOSE'
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.
ENDFORM.
```

Lưu PDF (khi `GETPDF = abap_true`, gọi FM 1 lần):

```abap
  DATA: lt_solix TYPE solix_tab,
        lv_size  TYPE i.
  lv_size  = xstrlen( ls_output-pdf ).
  lt_solix = cl_bcs_convert=>xstring_to_solix( iv_xstring = ls_output-pdf ).
  cl_gui_frontend_services=>gui_download(
    EXPORTING
      bin_filesize = lv_size
      filename     = lv_file
      filetype     = 'BIN'
    CHANGING
      data_tab     = lt_solix
    EXCEPTIONS
      OTHERS       = 1 ).
```

Lỗi xem trước/in báo "ADS ..." mà form activate được → thường do cấu hình ADS (RFC destination `ADS`), chuyển Basis kiểm.

## 3. Chuẩn bị dữ liệu

- Mỗi tham số interface cần structure (line type) + table type trong SE11, active **trước** khi activate interface. Danh sách field truyền vào `Form.loop()` = đúng structure này, đúng thứ tự.
- Field in ra nên là CHAR/STRING đã định dạng (3 mẫu đều vậy, layout không dùng display pattern):
  - Số tiền/số lượng: `WRITE lv_amt TO lv_txt CURRENCY lv_waers.` / `WRITE lv_qty TO lv_txt UNIT lv_meins.` rồi `CONDENSE`. Dấu thập phân theo cài đặt user (SU01) — cần cố định thì `SET COUNTRY 'VN'.` trước `WRITE`, trả lại `SET COUNTRY space.` sau đó.
  - Ngày: `|Ngày { lv_d+6(2) } tháng { lv_d+4(2) } năm { lv_d(4) }|` hoặc `WRITE lv_d TO lv_txt DD/MM/YYYY.`
  - Bỏ số 0 đầu: `CONVERSION_EXIT_ALPHA_OUTPUT` (MATNR: `CONVERSION_EXIT_MATN1_OUTPUT`).
- Tổng cộng, số tiền bằng chữ, STT: tính sẵn trong ABAP, đưa vào field của dòng header.

## 4. Logo SE78

1. SE78: Graphics → General Graphics → tên (VD `ZLOGO_CTY`) → Import ảnh BMP, kiểu màu (`BCOL`).
2. Interface: `Interface.logo_bds('ZLOGO_CTY')` sinh global `LOGO TYPE XSTRING` + code Initialization (y mẫu LSX).
3. Context: `Form.graphic('GRAPHIC', 'LOGO')`; layout: `image_field('$.GRAPHIC', ...)` khi đặt ngoài khung lặp, `image_field('$record.GRAPHIC', ...)` khi đặt trong `repeat()` — **chưa có mẫu dùng thật trên layout**, kiểm bản in.

Logo không đổi theo dữ liệu → đơn giản hơn: nhúng file ảnh tĩnh bằng `image('logo.png', ...)` (đã có mẫu), không cần bước 1-3.
