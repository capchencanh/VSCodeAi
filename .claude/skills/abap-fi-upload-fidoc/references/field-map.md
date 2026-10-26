# Field map — Excel ↔ GTY_UPLOAD ↔ ZST/ZTB ↔ BAPI (ZFI_PG_UPLOAD_FIDOC)

**CÁCH ĐỌC FILE NÀY:** không đọc cả file. `grep -n '^## ' field-map.md` rồi đọc đúng mục. Nguồn: đọc `zfi_in_upload_fidoc_top.abap`, `_f01.abap` (CHECK_DATA_UPLOAD), `zfm_acc_document_post.abap`, `dictionary/*.html` (export 08.10.2026) — chưa chạy thử.

## Mục lục
1. Chú giải
2. Bảng 78 cột Excel (thứ tự = thứ tự cột template)
3. Field có trong ZST nhưng chưa có cột Excel
4. Lệch ZST ↔ ZTB (field mất khi nạp lại từ staging)

## 1. Chú giải

- **#** = vị trí cột Excel (cột 1 = `ID_DOC`). Thứ tự này lấy từ `GTY_UPLOAD`; template `ZXLSX_TEMPLATE_ZUP` nằm trên SAP, **chưa đối chiếu được** — phải khớp thứ tự này.
- **Len** = độ dài trong `GTY_PROCESS` (độ dài hợp lệ; `CHECK_LENGTH` chỉ báo, không dừng — known-issues #1). Thực tế các field header long text (12–25) giữ 255.
- **HD/DT** = field có trong `ZST_UPLOAD_HD` / `ZST_UPLOAD_DT`; **TB-HD/TB-DT** = có trong bảng DB `ZTB_UPLOAD_HD` / `ZTB_UPLOAD_DT` (ô trống = không lưu vào staging).
- **Check**: `R` bắt buộc (S001) · `L` check độ dài (S004, không dừng) · `E:<bảng>` tồn tại (S002, dừng) · `A` ALPHA input · `D` ngày (CONVERT_DATE_TO_INTERNAL, S009) · `N` số (CATS_NUMERIC_INPUT_CHECK, S009) · `AUTH` AUTHORITY-CHECK `F_BKPF_BUK`.
- **Đích**: `HEADER` = BAPIACHE09; `GL/ITEM` = BAPIACGL09/ACAP09/ACAR09; `Ext2` = BAPIPAREX (structure ZST_ACC_DOC_*); header long text = `ZCORE_FM_SAVE_LONG_TEXT_1` (object `BELEG`).
- `KOART`, `SHKZG`, `STT`, `LWAER`, `ID_LINE`, `FILENAME` **không có cột Excel** — chương trình tự gán (KOART/SHKZG từ TBSL theo BSCHL, LWAER từ T001-WAERS, ID_LINE đếm theo nhóm ID_DOC).

## 2. Bảng 78 cột Excel

| # | Field | Mô tả | Len | HD | DT | TB-HD | TB-DT | Check | Đích (BAPI / khác) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | ID_DOC | Document ID | 10 | x | x | x | x | R L | Khóa gom dòng thành 1 chứng từ (không vào BAPI) |
| 2 | BLDAT | Document date | 10 | x |  | x |  | R L D | HEADER DOC_DATE |
| 3 | MONAT |  | 2 | x |  |  | x | L | HEADER FIS_PERIOD (check số đang comment) |
| 4 | BUDAT | Posting date | 10 | x |  | x |  | R L D | HEADER PSTNG_DATE |
| 5 | BLART | Document Type | 2 | x |  | x |  | R L E:T003 | HEADER DOC_TYPE |
| 6 | BUKRS | Company Code | 4 | x |  | x |  | R L E:T001 AUTH | HEADER COMP_CODE; AUTHORITY-CHECK F_BKPF_BUK |
| 7 | WAERS | Currency | 5 | x | x | x | x | R L E:TCURC | CURRENCYAMOUNT-CURRENCY (lấy từ header cho mọi dòng) |
| 8 | KURSF | Exchange rate | 10 | x |  | x |  | N | CURRENCYAMOUNT-EXCH_RATE |
| 9 | BKTXT | Document header text | 25 | x |  | x |  | L | HEADER HEADER_TXT |
| 10 | XBLNR | Reference Document Number | 16 | x |  | x |  | L | HEADER REF_DOC_NO |
| 11 | XREF1_HD | Header Reference key 1 | 20 | x |  | x |  | L | Ext2 ZST_ACC_DOC_PKEY-XREF1_HD (mọi dòng) |
| 12 | NH_NHANTIEN | Ngân hàng nhận tiền | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0001 (sau khi post) |
| 13 | STK_NHANTIEN | Số tài khoản nhận tiền | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0002 (sau khi post) |
| 14 | HOTEN_NOPTIEN | Họ tên người nộp tiền | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0003 (sau khi post) |
| 15 | HOTEN_NHANTIEN | Họ tên người nhận tiền | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0004 (sau khi post) |
| 16 | CT_KEMTHEO | Chứng từ kèm theo | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0005 (sau khi post) |
| 17 | TEN_NGUOIBAN | Tên người bán | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0006 (sau khi post) |
| 18 | MST_NGUOIBAN | Mã số thuế người bán | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0007 (sau khi post) |
| 19 | TEN_NGUOINHAN | ten nguoi nhan hang | 255 | x |  |  |  | — | Long text header: SAVE_TEXT BELEG/0020 (sau khi post) |
| 20 | MAU_HD | Mẫu hóa đơn | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0012 (sau khi post) |
| 21 | DIACHI | Địa chỉ | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0009 (sau khi post) |
| 22 | EMAIL | Email | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0017 (sau khi post) |
| 23 | MATHANG | Mặt hàng | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0010 (sau khi post) |
| 24 | LINK_HDDT | link hóa đơn điện tử | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0021 (sau khi post) |
| 25 | MA_HDDT | mã hóa đơn điện tử | 255 | x |  | x |  | — | Long text header: SAVE_TEXT BELEG/0022 (sau khi post) |
| 26 | BSCHL | Posting Key | 2 |  | x |  | x | R L E:TBSL | Ext2 PKEY-BSCHL; suy ra KOART+SHKZG |
| 27 | HKONT | Vendor Account / Customer account / GL account | 10 |  | x |  | x | R* L A E:SKA1/KNA1/LFA1 | GL_ACCOUNT / VENDOR_NO / CUSTOMER theo KOART (*bắt buộc có HKONT hoặc ANLN1 hoặc ANLN2) |
| 28 | ANLN1 | Main Asset Number | 12 | x | x |  | x | L A E:ANLA | ACCOUNTGL-ASSET_NO (KOART=A) |
| 29 | ANLN2 | Sub Asset Number | 4 | x | x |  | x | L A E:ANLA | ACCOUNTGL-SUB_NUMBER (KOART=A) |
| 30 | UMSKZ | Special G/L indicator | 1 |  | x |  | x | L E:T074U | SP_GL_IND (K/D) |
| 31 | BWASL | Asset transaction type | 3 |  | x |  | x | L E:TABW | Ext2 ASSET_FIELDS-ANBWA |
| 32 | WRBTR | Amount in document currency | 30 |  | x |  | x | R N | CURRENCYAMOUNT-AMT_DOCCUR (đảo dấu nếu SHKZG=H) |
| 33 | DMBTR | Amount in local currency | 30 |  | x |  | x | N | Dòng tiền tệ 2 (CURR_TYPE 10, LWAER) — chỉ khi ≠ WRBTR |
| 34 | FWBAS | Base amount in document currency | 30 |  | x |  | x | N | CURRENCYAMOUNT-AMT_BASE (tax base) |
| 35 | ZUONR | Assignment | 18 |  | x |  | x | L | ALLOC_NMBR (dòng thuế: Ext2 TAX_FIELDS) |
| 36 | GSBER | Business Area | 4 |  | x |  | x | L E:TGSB | BUS_AREA |
| 37 | PARGB | Trading partner's business area | 4 |  | x |  |  | — | GL TR_PART_BA; Ext2 VEND/CUST_FIELDS-PARGB (không check L/E) |
| 38 | KOSTL | Cost center | 10 |  | x |  | x | L A E:CSKS | GL COSTCENTER (dòng thuế: Ext2) |
| 39 | PRCTR | Profit center | 10 |  | x |  | x | L A E:CEPC | PROFIT_CTR + CO-PA criteria PRCTR |
| 40 | AUFNR | Internal order | 12 |  | x |  | x | L A E:AUFK | GL ORDERID |
| 41 | BZDAT | Asset Value Date | 10 |  | x |  |  | L D | Ext2 ASSET_FIELDS-BZDAT |
| 42 | SGTXT | Item text | 50 |  | x |  | x | L | ITEM_TEXT |
| 43 | HKONT_OVERRIDE | Override GL account | 10 |  | x |  | x | L A E:SKA1 | GL_ACCOUNT của dòng K/D (đổi TK đối ứng/recon) |
| 44 | MWSKZ | Tax code | 2 |  | x |  | x | L E:T007A(TAXVN) | TAX_CODE; GL 133*/3331* → ACCOUNTTAX |
| 45 | SEGMENT | Segment | 10 |  | x |  | x | L A E:FAGL_SEGM | GL SEGMENT |
| 46 | ZTERM | Payment term | 4 |  | x |  | x | L E:T052 | PMNTTRMS; trống → mặc định từ LFB1/KNB1 (xem known-issues #2) |
| 47 | ZLSPR | Payment Block | 1 |  | x |  | x | L E:T008 | PMNT_BLOCK |
| 48 | ZLSCH | Payment Method | 1 |  | x |  | x | L E:T042Z | PYMT_METH (theo LAND1 của BUKRS) |
| 49 | ZFBDT | Baseline date | 10 |  | x |  | x | L D | BLINE_DATE |
| 50 | VALUT | Value date | 10 |  | x |  | x | L D | GL VALUE_DATE |
| 51 | VERTN | Contract number | 13 |  | x |  | x | L | Ext2 VEND/CUST_FIELDS-VERTN |
| 52 | VERTT | Contract type | 1 |  | x |  | x | L | Ext2 VEND/CUST_FIELDS-VERTT |
| 53 | HBKID | House bank | 5 |  | x |  | x | L E:T012 | BANK_ID (K/D) / HOUSEBANKID (GL) |
| 54 | HKTID | Bank Account ID | 5 |  | x |  | x | L E:T012K | HOUSEBANKACCTID |
| 55 | REBZG | Invoice Ref. Number | 10 |  | x |  | x | L | Ext2 VEND/CUST_FIELDS-REBZG |
| 56 | REBZJ | Invoice Ref. Fiscal Year | 4 |  | x |  | x | L | Ext2 VEND/CUST_FIELDS-REBZJ |
| 57 | REBZZ | Invoice Ref. Line Item | 3 |  | x |  | x | L | Ext2 VEND/CUST_FIELDS-REBZZ |
| 58 | EBELN | Purchasing Doc. No. | 10 |  | x |  | x | L | GL PO_NUMBER |
| 59 | EBELP | Purchasing Doc. Item | 5 |  | x |  | x | L | GL PO_ITEM |
| 60 | KDAUF | Sales Order Number | 10 |  | x |  | x | L | GL SALES_ORD |
| 61 | KDPOS | Sales Order Item | 6 |  | x |  | x | L | GL S_ORD_ITEM |
| 62 | XREF1 | Reference Key 1 | 12 |  | x |  | x | L | REF_KEY_1 (dòng thuế: Ext2) |
| 63 | XREF2 | Reference Key 2 | 12 |  | x |  |  | L | REF_KEY_2 (dòng thuế: Ext2) |
| 64 | XREF3 | Reference Key 3 | 20 |  | x |  | x | L | REF_KEY_3 (dòng thuế: Ext2) |
| 65 | LTEXT | Long text | 255 |  | x |  | x | — | Long text dòng: SAVE_TEXT DOC_ITEM/0001 (sau khi post) |
| 66 | MATNR | Article | 18 |  | x |  | x | L A E:MARA | GL MATERIAL |
| 67 | MENGE | Quantity | 17 |  | x |  | x | N (S028) | GL QUANTITY |
| 68 | MEINS | Unit | 3 |  | x |  | x | L E:CUNIT | GL BASE_UOM |
| 69 | NAME | Name 1 | 35 |  | x |  | x | L | BAPIACPA09-NAME (CPD) |
| 70 | NAME_2 | Name 2 | 35 |  | x |  | x | L | BAPIACPA09-NAME_2 (CPD) |
| 71 | CITY | City | 35 |  | x |  | x | L | BAPIACPA09-CITY (CPD) |
| 72 | COUNTRY | Country Key | 3 |  | x |  | x | L E:T005 | BAPIACPA09-COUNTRY (CPD) |
| 73 | STCEG | VAT Reg. No. | 20 |  | x |  | x | L | BAPIACPA09-TAX_NO_1 (CPD) |
| 74 | WW14 |  | 255 |  | x |  |  | — | CO-PA criteria WW14 |
| 75 | VKBUR |  | 255 |  | x |  |  | — | CO-PA criteria KMVKBU |
| 76 | VKGRP |  | 255 |  | x |  |  | — | CO-PA criteria KMVKGR |
| 77 | VTWEG |  | 255 |  | x |  |  | — | CO-PA criteria VTWEG |
| 78 | WW12 |  | 255 |  | x |  |  | — | CO-PA criteria WW12 |

## 3. Field có trong ZST nhưng chưa có cột Excel

- `ZST_UPLOAD_DT`: `KDGRP, LAND1, KUNNR, WERKS` — `ZFM_ACC_DOCUMENT_POST` đã đẩy vào CO-PA `CRITERIA` (`KDGRP, LAND1, KNDNR, WERKS`) nhưng `GTY_UPLOAD` chưa có cột nên luôn trống khi upload từ Excel. Muốn dùng: thêm cột theo recipe B (SKILL.md §6B).
- `ZST_UPLOAD_HD`: `FISCYEARPER`, `ANLN1`, `ANLN2` (HD nhận giá trị dòng đầu qua MOVE-CORRESPONDING, không dùng trong FM).
- Runtime: `BELNR, GJAHR, ERROR, STATUS, STYLE, COLOR, DETAIL` (HD); `ID_LINE, LWAER, KOART, SHKZG` (DT).
- Extension2 `VEND_FIELDS/CUST_FIELDS` còn các field `AUFNR, EBELN, EBELP, ZEKKN, VBEL2, POSN2, ANLN1, ANLN2, FISTL, FIPOS` mà `ZFM_ACC_DOCUMENT_POST` **chưa gán** (chỉ gán REBZG/J/Z, VERTN, VERTT, PARGB).

## 4. Lệch ZST ↔ ZTB (field mất khi nạp lại từ staging)

`SPLIT_HEADER_DETAIL`/`SAVE_DATA`/`GET_UPLOADED_DATA` copy bằng `MOVE-CORRESPONDING`/`INTO CORRESPONDING FIELDS` → field có ở ZST mà không có ở ZTB bị bỏ **không báo lỗi**. Hệ quả: chế độ **Display (RB_DIS) rồi Post** dùng dữ liệu đã mất các field sau (so với Upload rồi Post ngay):

| Staging | Field có ở ZST nhưng KHÔNG có ở ZTB | Ảnh hưởng khi post từ Display |
|---|---|---|
| `ZTB_UPLOAD_DT` | `BZDAT, XREF2, PARGB, WW14, VKBUR, VKGRP, VTWEG, WW12` (+`KDGRP, LAND1, KUNNR, WERKS` chưa có cột Excel) | mất Asset Value Date, Ref Key 2, Trading partner BA, **toàn bộ CO-PA criteria WW14/VKBUR/VKGRP/VTWEG/WW12** |
| `ZTB_UPLOAD_HD` | `TEN_NGUOINHAN, MONAT, ANLN1, ANLN2, FISCYEARPER, GJAHR` | mất text BELEG/0020, kỳ kế toán `FIS_PERIOD` (BAPI tự suy từ ngày), GJAHR không lưu cùng BELNR |
| Thừa bên ZTB | `ZTB_UPLOAD_DT-MONAT` (ZST_UPLOAD_DT không có), `ZTB_UPLOAD_HD-ZZSTATUS` (ZST dùng `STATUS`) | không bao giờ được điền |

Khi thêm field mới muốn "Display rồi Post" đúng → thêm vào cả ZST **và** ZTB.
