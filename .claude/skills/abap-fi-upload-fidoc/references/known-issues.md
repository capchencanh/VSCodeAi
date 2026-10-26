# Known issues — điểm nghi ngờ khi đọc ZFI_PG_UPLOAD_FIDOC

**CÁCH ĐỌC FILE NÀY:** không đọc cả file. `grep -n '^## ' known-issues.md` rồi đọc đúng mục. **Tất cả là `[ĐỌC CODE]` — suy ra từ source/dictionary export 08.10.2026, CHƯA tái hiện trên hệ thống.** Mục đích: không copy nguyên lỗi khi clone; không tự sửa chương trình đang chạy khi chưa được user cho phép. Mức: 🔴 ảnh hưởng dữ liệu/tiền, 🟡 hành vi lạ, ⚪ dọn dẹp.

## Mục lục
1. 🟡 CHECK_LENGTH không dừng
2. 🔴 Payment term mặc định: Customer/Vendor đảo bảng + READ sai key
3. 🔴 Lệch ZST ↔ ZTB — Display rồi Post mất field
4. 🟡 Long text/commit sau khi post, `ERROR` chỉ giữ lỗi đầu
5. 🟡 Khoá file (tên không đuôi, SELECT SINGLE)
6. 🟡 `ACCT_KEY` dòng thuế luôn rỗng
7. 🟡 Hard-code theo cấu hình VN
8. ⚪ Message S028 sai chữ, check MONAT bị comment
9. ⚪ ALV thực chất chỉ-đọc, nút SAVE chưa nối
10. ⚪ GET_DATA luôn nạp 29 bảng kể cả Download
11. ⚪ Code legacy/chết, tên REPORT lệch
12. 🟡 ID_DOC là N(10)
13. 🟡 LEAVE TO SCREEN 0100 trong FORM dùng chung nhiều pha
14. ⚪ Authorization chỉ F_BKPF_BUK ở pha Upload

## 1. CHECK_LENGTH không dừng
- **Vị trí:** `FORM CHECK_LENGTH` (F01) — chỉ `MESSAGE S004 … DISPLAY LIKE 'E'`, không `LEAVE LIST-PROCESSING`; sau đó `MOVE-CORRESPONDING LS_UPLOAD TO LS_PROCESS` (field `GTY_PROCESS` ngắn hơn `GTY_UPLOAD`).
- **Hệ quả:** giá trị quá dài bị **cắt im lặng** (vd HKONT > 10 ký tự thành mã khác rồi mới check tồn tại). Các check khác đều dừng ở lỗi đầu.
- **Khi clone:** thêm dừng sau MESSAGE (sau khi user đồng ý đổi hành vi) hoặc check độ dài trên `GTY_PROCESS`.

## 2. Payment term mặc định: Customer/Vendor đảo bảng + READ sai key
- **Vị trí:** `SPLIT_HEADER_DETAIL` — `IF KOART = 'D'` đọc `GT_LFB1` (vendor) theo `LIFNR = HKONT`; `KOART = 'K'` đọc `GT_KNB1` (customer) theo `KUNNR = HKONT`.
- **Thêm:** `GT_LFB1/KNB1` sort `BUKRS, LIFNR/KUNNR, ZTERM` nhưng READ chỉ theo `LIFNR/KUNNR` với `BINARY SEARCH` (không có BUKRS, key không là tiền tố của key sort) → kết quả không tin cậy; `GET_LFB1/KNB1` đọc mọi company code.
- **Hệ quả:** khi cột ZTERM trống, `PMNTTRMS` mặc định có thể sai/trống ở dòng Customer/Vendor.
- **Khi clone:** sửa D→KNB1, K→LFB1, READ theo `BUKRS + KUNNR/LIFNR` (sửa chương trình đang chạy → hỏi xác nhận).

## 3. Lệch ZST ↔ ZTB — Display rồi Post mất field
Chi tiết bảng ở `field-map.md` §4. Tóm tắt: `ZTB_UPLOAD_DT` thiếu `BZDAT, XREF2, PARGB, WW14, VKBUR, VKGRP, VTWEG, WW12`; `ZTB_UPLOAD_HD` thiếu `TEN_NGUOINHAN, MONAT, ANLN1/2, GJAHR`. **Upload→Post ngay** dùng bản trong bộ nhớ (đủ field); **Upload → thoát → Display → Post** dùng bản đọc lại từ DB (thiếu field, CO-PA trống). Muốn xác nhận: so sánh 2 chứng từ cùng file post theo 2 đường (Dev).

## 4. Long text/commit sau khi post, `ERROR` chỉ giữ lỗi đầu
- **Trình tự `POST_DOCUMENT`:** `COMMIT WORK AND WAIT` → `SAVE_DATA` → `CALL_SAVE_TEXT` (mỗi lần FM lại `COMMIT WORK AND WAIT`). Nếu `CALL_SAVE_TEXT` lỗi: `ROLLBACK WORK` + `LEAVE TO SCREEN 0100` — chứng từ đã commit rồi, rollback vô tác dụng.
- **Hệ quả:** chứng từ có thể tồn tại mà thiếu long text; không post lại được vì `BELNR` đã có (S018) → phải bổ sung text thủ công (SO10/FB03).
- `ERROR` của header chỉ là message của **dòng A/E đầu tiên** (`FORMAT_MESSAGE`), các lỗi sau bị bỏ — debug cần xem `E_RETURN` đầy đủ.
- `GT_HEAD` có `STATUS=3` cả khi test-run thành công (không có BELNR).

## 5. Khoá file (tên không đuôi, SELECT SINGLE)
- `ZCH_SPLIT_FILENAME-NAME` bỏ đuôi → `a.xlsx` và `a.xls` trùng khoá; cùng tên trong 2 thư mục cũng trùng.
- Kiểm tra trùng chỉ `SELECT SINGLE *` 1 header của file rồi xét `BELNR` của header đó → nếu file có header đã post và header khác chưa post, kết quả phụ thuộc dòng nào được chọn.
- Khoá toàn cục theo tên file (không theo user): user khác dùng lại tên → S015.

## 6. `ACCT_KEY` dòng thuế luôn rỗng
- `ZFM_ACC_DOCUMENT_POST`: `ls_accounttax-acct_key = ls_t030k-ktosl` nhưng `READ TABLE lt_t030k INTO ls_t030k …` đã bị comment → `LS_T030K` luôn initial. `LT_T030K` được SELECT nhưng không dùng. BAPI tự suy transaction key từ tax code/`GL_ACCOUNT` hay không → chưa kiểm chứng.

## 7. Hard-code theo cấu hình VN
`COAO`/`VN`/`TAXVN` (`GET_T030K`, `GET_T007A`), `133*`/`3331*` (CHECK_DATA_UPLOAD + FM), tax code `IN/IX/NA`, `T095_ACI` với `KTOGR=''`/`SYMBTR=''` (TK clearing mua tài sản), cột nghiệp vụ VN (hóa đơn điện tử). Dùng cho khách hàng/CoA khác → tham số hoá hoặc đọc customizing.

## 8. Message S028 sai chữ, check MONAT bị comment
- `ZMC_MAISON 028` = `"Period" &1 must be a numeric value` nhưng đang dùng để báo lỗi `Quantity` (MENGE). Check MONAT là số (block comment ở cuối CHECK_DATA_UPLOAD) chưa bật → MONAT chỉ qua `CHECK_LENGTH`.

## 9. ALV thực chất chỉ-đọc, nút SAVE chưa nối
- Field catalog không set `EDIT`; `STYLE`/`COLOR`/`CHECK_CHANGED_DATA`/`GW_CHANGED_FLG` có sẵn nhưng không có đường nào bật ô editable. `USER_COMMAND_0100` chỉ xử lý `POST/CHECK/PARK` và `BACK/EXIT/CANC`; `SAVE_DATA` có nhánh `GW_OK_CODE='SAVE'` nhưng không được gọi từ `CASE` (cần xem PF-STATUS `STS0100` có nút SAVE không — chưa có trong export).
- ALV tạo trong `MAIN_PROC` **trước** `CALL SCREEN 0100` (không phải trong PBO). Đang chạy thật theo cách này; khi clone giữ nguyên, đừng đổi chỗ khi chưa test.

## 10. GET_DATA luôn nạp 29 bảng kể cả Download
`MAIN_PROC` gọi `GET_DATA` trước khi rẽ nhánh `RB_UPL/RB_DOW/RB_DIS` → chế độ Download template cũng đọc toàn bộ KNA1, LFA1, MARA, SKA1, AUFK, ANLA, CSKS, CEPC, KNB1, LFB1… Clone: đưa `GET_DATA` vào nhánh cần dùng (Upload) hoặc giới hạn theo dữ liệu file.

## 11. Code legacy/chết, tên REPORT lệch
- FORM thân comment hoặc không ai gọi: xem SKILL.md §3. Comment tham chiếu `ZST_HD_EXCEL(_H)`, `ZTB_HD_EXCEL(_H)`, `GT_MAPPING_NVU`, `ZTB_MAP_POSTKEY`, `ZHD10`, `ZFM_EINV_INVOICE_ZUP` — **không có trong package export**. `TEXT-M35` (GET_NEXT_NUMBER) không có text element.
- TOP include khai `REPORT zfi_pg_upload_f01 MESSAGE-ID zmc_maison …` (tên REPORT khác tên chương trình `ZFI_PG_UPLOAD_FIDOC`) — di sản từ bản cũ; clone: đặt đúng tên chương trình mới.

## 12. ID_DOC là N(10)
`GTY_PROCESS-ID_DOC` kiểu `N(10)` nhận từ CHAR255 qua `MOVE-CORRESPONDING`: ký tự không phải số bị bỏ khi chuyển C→N (theo quy tắc chuyển đổi ABAP, chưa chạy thử) → `INV-001` và `A001` có thể gom thành cùng `ID_DOC`. Quy ước: cột ID_DOC trong Excel chỉ chứa số.

## 13. LEAVE TO SCREEN 0100 trong FORM dùng chung nhiều pha
`CURRENCY_TO_INTERNAL`, `POPUP_TO_CONFIRM` lỗi trong `SPLIT_HEADER_DETAIL`, `READ_DYNP_VALUE`… dùng `LEAVE TO SCREEN 0100` — ở pha upload (trước `CREATE_OBJECT`) nhảy sang screen 0100 khi ALV chưa tạo; hành vi chưa kiểm chứng. Clone: dùng `LEAVE LIST-PROCESSING` ở pha upload, `LEAVE TO SCREEN 0100` ở pha PAI.

## 14. Authorization chỉ F_BKPF_BUK ở pha Upload
`AUTHORITY-CHECK OBJECT 'F_BKPF_BUK' ID 'BUKRS'` (không `ACTVT`) chỉ chạy trong `CHECK_DATA_UPLOAD` — không chạy ở chế độ Display/Post (BAPI tự kiểm tra quyền hạch toán). Nếu cần chặn Display theo company code → thêm check. Xem skill `authorization-iam`.
