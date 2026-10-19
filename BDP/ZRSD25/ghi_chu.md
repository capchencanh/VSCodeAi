# Ghi chú dự án ZRSD25 — Báo cáo theo dõi phê duyệt đơn hàng vượt hạn mức nợ (Bidiphar)

FS: `FS/BIDIPHAR_FS_SD_ZRSD25_BaoCaoTheoDoiPheDuyetDonHangVuotHanMucNo_V1.0.docx` (V1.0, 24/09/2026, Nguyễn Thị Anh Thư)
Đọc & kiểm tra FS: 30/09/2026, chưa viết code.

## Tóm tắt

Báo cáo **ALV** (khác ZRSD08 là form in), A4 ngang, 22 cột, 13 tham số chia 3 khối / 2 màn hình.
Mỗi dòng = 1 đơn hàng bán bị chặn tín dụng (`VBAK-CMGST` ∈ B/C/D). Chỉ đọc, không ghi.

Nguồn dữ liệu chính: `VBAK`/`VBAP` (đơn hàng), `CDHDR`/`CDPOS` (nhật ký thay đổi — người & ngày giải phóng),
`UKMBP_CMS_SGM` (hạn mức), `UKM_TOTALS` (số dư chiếm dụng), `BSID` (nợ quá hạn), `VBFA`+`VBRK` (hoá đơn),
`VBPA` (Sold-to `AG`, Sales employee), `PA0001` (tên TDV), `TVKBT`/`T151T` (diễn giải).

## Kết quả kiểm tra object trên DEV/200 (30.09.2026)

**Có đủ, không thiếu gì:**

| Nhóm | Object | Ghi chú |
|---|---|---|
| Field `VBAK` | `CMGST`, `CMFRE`, `AMTBL`, `KKBER`, `VKBUR`, `NETWR`, `WAERK`, `AUDAT` | đủ cả 8 |
| Bảng tín dụng | `UKM_KKBER2SGM`, `UKMBP_CMS_SGM`, `UKM_TOTALS` | đủ (S/4 Credit Management) |
| BP / khách hàng | `CVI_CUST_LINK`, `BUT000` | đủ |
| Nhật ký thay đổi | `CDHDR`, `CDPOS` | đủ |
| Khác | `BSID`, `PA0001`, `USR21`, `ADRP`, `TVKBT`, `T151T` | đủ |
| Authorization object | `V_VBAK_VKO` (VKORG, VTWEG, SPART, **ACTVT**), `F_UKM_SGMT` (ACTVT, UKM_SGMNT) | đủ |

**3 điểm cần lưu ý khi code:**

1. **`BSID` trên S/4HANA là VIEW, không phải bảng transparent** (`DD02L-TABCLASS = VIEW`, đọc `ACDOCA`/`BSEG`).
   Đọc được bằng ABAP SQL nhưng **chậm hơn bảng thật** và không dùng được vài kỹ thuật. Nếu chậm, cân nhắc CDS chuẩn
   (`I_OperationalAcctgDocItem`...) hoặc FM `FI_ITEMS_DISPLAY`. Cần đo khi có data.
2. **Vai trò Sales employee**: FS ghi *"mã SE… chuẩn SAP là 'VE'"*. Trên hệ **cả `SE` lẫn `VE` đều tồn tại** nhưng khác loại:
   `VE` = `PE` (Personnel — đúng, vì chỉ tiêu (13) lấy `VBPA-PERNR`), `SE` = `LI` (Vendor). → Dùng **`VE`**, FS đúng.
3. **`V_VBAK_VKO` có `ACTVT`** (trường thứ 4) — khác `M_IS_VTWEG` của ZRSD08 (không có `ACTVT`).
   → `AUTHORITY-CHECK` cho ZRSD25 phải có `ID 'ACTVT' FIELD '03'`.

**Chưa có customizing tín dụng:** `UKM_KKBER2SGM` = 0 dòng ở client 200 → chưa map Credit Control Area sang Credit Segment.
Chỉ tiêu (16)(17) sẽ trống cho tới khi cấu hình xong (giống `ZRT1` ở ZRSD08 — có thể chỉ có ở client 100).
DEV vẫn chưa có đơn hàng/khách hàng nào (`VBAK` = 0 mọi client).

## Điểm FS cần làm rõ trước/trong khi code

1. **(10) Số chứng từ & (20)(21) người/ngày duyệt — điều kiện lọc `CDPOS` chưa cụ thể.** FS ghi *"Chọn bản ghi có CDPOS
   thay đổi trường trạng thái kiểm tra tín dụng"* nhưng **không nêu `TABNAME`/`FNAME` cụ thể**. Thực tế VKM1 giải phóng
   có thể ghi `CDPOS` với `TABNAME = 'VBUK'`/`VBAK` và `FNAME = 'CMGST'` hoặc `CMPSA`/`CMPS_CM`… **Phải xem `CDPOS` thật
   của 1 đơn đã giải phóng mới chốt được.** Trên S/4HANA `VBUK` đã gộp vào `VBAK` → khả năng cao là `TABNAME = 'VBAK'`.
2. **(15) Lý do chặn — chỉ là suy luận lại, không phải lý do thật của SAP.** FS tự định nghĩa công thức
   ((17)+(12) > (16) → vượt hạn mức; (18) > 0 → nợ quá hạn) và ghi rõ *"tính lại tại thời điểm chạy báo cáo"*.
   → Lý do in ra **có thể khác** lý do SAP chặn lúc lập đơn (vì số dư/nợ đã đổi). Đây là ý đồ của FS, không phải lỗi,
   nhưng cần user nghiệp vụ biết.
3. **(18) Nợ quá hạn — chưa nêu lọc Company Code.** `BSID` theo `KUNNR` + `BUKRS`; FS chỉ nói `KUNNR`.
   Khách hàng phát sinh nợ ở nhiều company code sẽ bị cộng dồn. Cần hỏi: lọc theo company code của tổ chức bán hàng?
4. **(9) Hoá đơn — "VBTYP_N thuộc nhóm hoá đơn" chưa liệt kê giá trị.** Cần chốt danh sách (thường `M`, `O`, `P`, `N`…).
5. **(2)(3) Chi nhánh = Sales Office** — tham số (3) lọc theo chỉ tiêu (2). OK, không vướng.

## Code đã viết (30.09.2026)

`Program/`: `zpg_sd_pdvhmn.abap` (chính) + `zin_sd_pdvhmn_top.abap` (types/tham số) +
`zin_sd_pdvhmn_f01.abap` (logic) + `zin_sd_pdvhmn_f02.abap` (ALV). Đủ 22 chỉ tiêu, 13 tham số, ALV `CL_SALV_TABLE`.
Không dùng `FOR ALL ENTRIES` (theo skill): mỗi FORM gom key thành `RANGE` rồi `IN @range`; đọc đơn hàng bằng 1 SELECT JOIN
(VBAK + TVKBT + VBPA×2 + KNA1 + KNVV + T151T).

**Chưa syntax check được trên hệ.** Chương trình chưa tạo ở SE38 nên cờ **Fixed point arithmetic đang TẮT** → mọi câu SQL có
`@` host variable báo lỗi, kéo theo hàng chục lỗi giả "field unknown". Xem bài học ở `_ghichu_local.md`.
→ **Việc phía user: tạo `ZPG_SD_PDVHMN` + 3 include ở SE38, BẬT Fixed point arithmetic (Attributes), rồi báo để check lại.**

**Data element (30.09.2026):** bản đầu khai `ZDE_*_RSD25` → user activate báo `Type "ZDE_STT_RSD25" is unknown` vì chưa tạo.
Đã đổi sang khai độ dài trực tiếp trong TOP (`TYPE N LENGTH 6`, `TYPE C LENGTH 160`...) để chạy ngay, **không cần tạo DDIC**.
Nếu sau này muốn theo convention `ZDE_` của `.claude/CLAUDE.md` thì tạo 7 data element rồi thay lại ở `GTY_ALV`/bảng phụ trợ:
STT (NUMC 6), NAME (CHAR 160), BILLLIST (CHAR 60), PERNR (CHAR 8), REASON (CHAR 30), APPSTAT (CHAR 20), APPROVER (CHAR 60).

Còn cần tạo: message class `ZMC_SD` (dùng chung với ZRSD08); text symbol `B01`-`B03` (tiêu đề khối), `C01`-`C22` (tên cột),
`R01`-`R03` (lý do chặn), `S01`-`S03` (trạng thái), `H01` (tiêu đề báo cáo).

**Chỗ FS thiếu — đã code sẵn, đánh dấu trong source, sửa 1 chỗ khi có câu trả lời:**
- `GET_CHANGELOG`: hằng số `LC_TABNAME = 'VBAK'`, `LC_FNAME = 'CMGST'` (giả định).
- `GET_OVERDUE`: chưa lọc company code (FS không nêu).
- `GET_BILLING`: `VBTYP_N IN ( 'M', 'O', 'P' )` (FS chỉ ghi "thuộc nhóm hoá đơn").

## Rà performance (30.09.2026)

Đã kiểm toàn bộ 4 file: **0 `FOR ALL ENTRIES`**, **0 SELECT trong LOOP**, **0 LOOP lồng LOOP**.
12 câu SELECT đều chạy 1 lần, lọc bằng `IN @range`, `SELECT` chỉ field cần.

**Sửa thêm 2 chỗ O(n² log n):** `GET_BILLING` và `GET_OVERDUE` có `SORT` **bên trong** `LOOP`
(mỗi lần thêm dòng mới lại sort cả bảng). Đổi sang `SORTED TABLE ... WITH UNIQUE KEY` +
`READ ... WITH TABLE KEY` + `INSERT ... INTO TABLE`, gán sang tham số trả về sau khi loop xong.

Còn lại đều là `READ TABLE ... BINARY SEARCH` trên bảng đã `SORT` sẵn trước LOOP — đúng chuẩn.

## Kiểm tra object trên hệ (30.09.2026)

| Object | ZRSD08 | ZRSD25 |
|---|---|---|
| Chương trình + include, `FIXPT = X` | có | có (đã tạo) |
| Syntax check trên hệ | sạch | sạch |
| Tcode | `ZRSD08` có | **`ZRSD25` chưa có** (SE93) |
| Message class `ZMC_SD` | **chưa có** | **chưa có** |
| Text elements | chưa kiểm được (tool `GetTextElements` lỗi WebSocket 500) | chưa kiểm được — danh sách ở `Program/text_elements.md` |

Sửa thêm: tham số **Lý do chặn tín dụng** (FS có yêu cầu) trước bị giấu `NO-DISPLAY` và khai kiểu 1 ký tự nên bộ lọc không bao giờ khớp.
Đã sửa: `S_REASON FOR GV_REASON` (30 ký tự), hiện lên màn hình, có F4 3 giá trị (`FORM F4_REASON`).

## Review + tối ưu lại (01/10/2026) — thay cho mục "Rà performance" ở trên

Check bằng MCP (`RunATCCheck` + đọc source hệ). Phát hiện và đã sửa trong code local:

| # | Vấn đề | Cách sửa |
|---|---|---|
| 1 | **`RS_CHANGEDOCUMENT_SHOW` không tồn tại** (TFDIR rỗng) → bấm cột "Số chứng từ" dump `CALL_FUNCTION_NOT_FOUND` | `SUBMIT RSSCD100 WITH OBJEKT/OBJEKTID/CALLSUB AND RETURN` (report chuẩn, đã đọc tham số) |
| 2 | Lọc `S_CMGST`/`S_KDGRP`/`S_PERNR` bằng `DELETE` trong `LOOP` (O(n²)) + 1 câu SELECT VBAP riêng cho "từ chối toàn bộ" | Đẩy vào `WHERE` + `EXISTS` (VBAP có ≥1 dòng chưa từ chối) |
| 3 | Hạn mức/số dư: `JOIN UKM_KKBER2SGM ON S~KKBER = S~KKBER` (tự so sánh → cross join), 2 câu SELECT lặp JOIN | Nối thẳng vào câu đơn hàng: `S~KKBER = A~KKBER`; số dư gộp bằng CTE `+EXPO` |
| 4 | Tên KH (ADRC), tên TDV (PA0001), tên người duyệt (USR21→ADRP): mỗi thứ 1 câu SELECT + range | ADRC, CTE `+TDV` nối vào câu đơn hàng; USR21/ADRP nối vào câu CDHDR |
| 5 | Nợ quá hạn: kéo **toàn bộ** dòng BSID về ABAP rồi cộng trong LOOP | `SUM ... GROUP BY KUNNR` + `DATS_ADD_DAYS( ZFBDT, ZBD1T )` ngay trên HANA |
| 6 | Hoá đơn: LOOP nối chuỗi trong ABAP | CTE `+FLOW` (DISTINCT) + `STRING_AGG` |
| 7 | `CHECK_AUTHORITY` quét VBAK mỗi lần Enter/F4 trên màn hình chọn | Chỉ chạy khi `SY-UCOMM = 'ONLI'` |
| 8 | ALV rỗng khi không có dữ liệu (`RETURN` rồi `END-OF-SELECTION` vẫn gọi ALV) | Gọi `DISPLAY_ALV` ngay trong START-OF-SELECTION |
| 9 | ATC warning "Buffered table in a JOIN" (TVKBT, T151T, UKM_KKBER2SGM) | `"#EC CI_BUFFJOIN` — bảng nhỏ, JOIN trên HANA không đáng ngại |

Còn **2 câu SQL phụ** (hoá đơn, nhật ký) + **1 câu nợ quá hạn** chạy theo range key lấy từ đơn hàng (`IN @range`) vì
bảng nguồn lớn (VBFA, CDPOS, BSID) — đọc theo key nhanh hơn gom cả bảng. Nếu 1 lần chạy ra hàng chục nghìn đơn,
range quá dài có thể gây `DBSQL_STMNT_TOO_LARGE` → khi đó phải chia nhỏ theo khoảng ngày.

Đổi hành vi nhỏ: đơn **không có dòng hàng nào** trước đây vẫn hiện, nay bị loại (vì `EXISTS`). Đơn không có dòng hàng
là trạng thái không hợp lệ nên không ảnh hưởng báo cáo.

**Câu hỏi còn treo cho tư vấn:**
- `UKM_TOTALS` có key `COMM_TYP` + `CURRENCY`; `SUM( AMOUNT )` đang cộng **mọi loại cam kết và mọi tiền tệ**. Số dư công nợ
  (chỉ tiêu 17) có đúng là tổng tất cả `COMM_TYP` không, và có cần lọc `CURRENCY = 'VND'` không?
- Nợ quá hạn chưa lọc Company Code (FS không nêu) — mục 3 phần "Điểm FS cần làm rõ".
- ALV: ZRSD25 đang dùng `CL_SALV_TABLE`, ZRSD26 dùng `CL_GUI_ALV_GRID`. Có muốn đổi ZRSD25 cho giống ZRSD26 không?

## Việc user cần tạo trên hệ (DEV)

1. Tcode `ZRSD25` (SE93) — hiện chưa có.
2. Text elements của `ZPG_SD_PDVHMN` — **chưa tạo** (ATC báo thiếu `B01-B03`, `C01-C22`, `R01-R03`, `S01-S03`, `H01`).
   Danh sách đầy đủ + selection texts: `Program/text_elements.md`.
3. Cập nhật 4 file lên hệ rồi activate: `ZPG_SD_PDVHMN`, `ZIN_SD_PDVHMN_TOP`, `_F01`, `_F02`
   (bản trên hệ đang lệch bản local vài dòng).
