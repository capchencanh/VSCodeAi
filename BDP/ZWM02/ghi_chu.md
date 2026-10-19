# ZWM02 – Biên bản kiểm nhận hàng hóa (chương trình ZWM_PG_BBKNHH)

FS: `FS/BIDIPHAR_FS_EWM_ZWM02_BienBanKiemNhan_v1.0.docx` (v1.0). Hệ: S/4 On-Premise, MCP `GUI_BDP_DEV_100` (từ 09/10/2026, trước đó dùng `GUI_BDP_DEV_200`; chỉ đọc, user tự dán code).

## 0. TRẠNG THÁI (09/10/2026) — ĐỌC TRƯỚC

**Cập nhật 12/10/2026 — ĐỌC ĐẦU TIÊN:** code ZWM02 (main + 2 include) **đã có trên SAP DEV client 100 và active**, TR `DEVK900207` / task `DEVK900208`. Hôm nay Claude (MCP `GUI_BDP_DEV_100`, vsp bản `vsp_tn_20261007`) đã: (1) tạo message class `ZWM02` (8 message); (2) sửa `GET_DATA_B` đọc `ZTWM_MVT_GRP` thay STVARV `ZWM02_BWART` (xem mục 2); (3) SyntaxCheck main: 0 lỗi, 1 cảnh báo `MARC has a replacement object`. Bảng `ZTWM_MVT_GRP` đã có TMG (`ZFG_WM_MVT_GRP`) + Log Data Changes; **chưa có data** (user nhập SM30). **Cập nhật 12/10/2026 (sau 09:30):** user đã làm xong GUI status `STANDARD` (4 nút `PREV`, `PRINT`, `SELALL`, `EXCEL`, icon `ICON_DISPLAY`/`ICON_PRINT`/`ICON_SELECT_ALL`/`ICON_XLS`, copy từ status của `ZWM_PG_PYCVT`) và upload SmartForm `ZWM_SF_BBKNHH` (09:26); Claude kiểm bằng MCP: interface form `/1BCDWB/SF00000021` có `GS_PARAMETER` + `IT_DATA`, không còn `GS_HEADER`; status và code nằm trong task `DEVK900208`. **Còn lại:** nhập data `ZTWM_MVT_GRP` qua SM30 (đang 0 dòng, nguồn B chưa ra dòng nào nếu chưa nhập), STVARV `ZWM02_LFART` (tuỳ chọn), chạy thử ZWM02 nguồn A/B. Không còn việc nào cần Claude trừ khi user báo lỗi khi chạy thử. Các đoạn bên dưới (mục 0 cũ) là lịch sử, đã làm xong trừ khi ghi khác.

*(Lịch sử)* Code viết lại theo FS ở local, SyntaxCheck bản gộp trên DEV: 0 lỗi, 1 cảnh báo `MARC has a replacement object` (chỉ đọc HERKL, bỏ qua được).

Bản ECC trước khi sửa lưu ở `Temp/zwm_pg_bbknhh_truoc_sua_09102026/`. Bản cũ lệch FS nhiều: chỉ có nguồn B; gọi `ZCORE_FM_GET_CRTRT_MULTIVAL` với tham số `EZ_*` không còn trên S/4 (sẽ dump); in mọi chứng từ chung 1 header; không có nhật ký in, nút In/Excel; MvT hard-code.

**Việc user cần làm trên SAP (thứ tự):**
1. SE91 tạo message class `ZWM02` (mục 1).
2. GUI status `STANDARD` cho `ZWM_PG_BBKNHH`: copy status `SALV_TABLE_STANDARD` của chương trình `SAPLSALV_METADATA_STATUS`, thêm 4 nút trên Application toolbar: `PREV` "Xem trước bản in", `PRINT` "In", `SELALL` "Chọn tất cả", `EXCEL` "Excel".
3. Dán `zwm_in_bbknhh_top` → `zwm_in_bbknhh_f01` → `zwm_pg_bbknhh`; cập nhật Text elements và Selection texts theo cuối file main.
4. SMARTFORMS: upload `Smartforms/FS_v1.0/ZWM_SF_BBKNHH.xml` đè lên `ZWM_SF_BBKNHH` rồi activate. **Interface form đổi** (bỏ `GS_HEADER`), nên phải upload form trước khi chạy chương trình mới.
5. (Tuỳ chọn) STVARV, loại Selection option: `ZWM02_LFART` (loại Delivery), `ZWM02_BWART` (MvT nguồn B). Để trống thì chương trình vẫn chạy (mục 2).

**TR ZWM02:** `DEVK900207` (task `DEVK900208` của CT.CSTECH), mô tả "DanhDH_WM_ZWM02_09.10.2026_Biên bản kiểm nhận hàng hóa". Task đã có: `ZWM_ST_BBKNHH`, `ZWM_PG_BBKNHH` + 2 include, Tcode `ZWM02`, `ZWM_SF_BBKNHH`, và các object `ZTWM_MVT_GRP` bên dưới. Từ 09/10/2026 làm trên client **100** (Dev & Config), không dùng client 200 nữa.

**Bảng `ZTWM_MVT_GRP` (09/10/2026): Claude đã tạo + activate qua MCP**, package `ZPK_BDP`, vào task trên. Gồm domain `ZDO_WM_GRP_CODE` và 6 data element `ZDE_WM_GRP_CODE`, `ZDE_WM_AUFNR_FLG`, `ZDE_WM_USE_FLG`, `ZDE_WM_MVT_TXT_VI`, `ZDE_WM_MVT_TXT_EN`, `ZDE_WM_REV_BWART`. Field: `CLIENT` (tool tự đặt tên, không phải MANDT), key `BWART`, `SEQNR`; `SOBKZ, AUFNR_FLG, BSART (ESART), PSTYP, WERKS, GRP_CODE, USE_FLG, TXT_VI, TXT_EN, REV_BWART`. Thiết kế + điểm lệch: mục 3a.

**Còn lại cho bảng (user làm tay SE11, chưa xác nhận đã làm):**
1. Technical Settings: data class `APPL2`, size `0`, tích Log Data Changes, Fully buffered (MCP không set được, hiện trống).
2. Enhancement category → *Can be enhanced (character-type)* (đang Not extensible).
3. Table Maintenance Generator: `&NC&`, FG `ZFG_WM_MVT_GRP`, one step, standard recording routine.
4. SM30 nhập data mẫu theo Excel.
5. Text DDIC đang lưu dưới ngôn ngữ EN (MCP đăng nhập EN) → cần bản VI thì SE63.
6. Bảng con `ZTWM_MVT_TCODE` **chưa tạo** (user mới nhờ bảng cha). Đề xuất key `BWART + SEQNR + TCODE`, không lưu mô tả T-code. Chờ user/BA chốt có thêm `SEQNR` không.

**Việc Claude làm tiếp phiên sau:** hỏi user đã xong 1–4 chưa → `GetTable ZTWM_MVT_GRP` + `RunQuery DD09L` (PROTOKOLL = X) + `TVDIR` (đã có TMG) + đọc data → sửa `GET_DATA_B` theo mục 3a (lọc MvT theo bảng con `TCODE = ZWM02` nếu đã có, chọn dòng cha khớp đầu tiên theo SEQNR, giữ `GRP_CODE` MH/TH; bỏ STVARV `ZWM02_BWART` + điều kiện `AUFNR = space`) → SyntaxCheck bản gộp.

## 1. Object

| Object | Ghi chú |
|---|---|
| `ZWM_PG_BBKNHH` + `ZWM_IN_BBKNHH_TOP`, `ZWM_IN_BBKNHH_F01` | `ZPK_WM`. Màn hình trung gian SALV toàn màn hình, status `STANDARD` |
| Structure `ZWM_ST_BBKNHH` | Giữ nguyên, không thêm field. `TXZ01` dùng chứa "Tình trạng niêm phong", `SGTXT` chứa "Hồ sơ đi kèm", `TABLE_HEADER` là dòng nhóm, `LEVEL` 1 = dòng nhóm / 2 = dòng chi tiết |
| Smart Form `ZWM_SF_BBKNHH` | Sinh bằng `Smartforms/gen_zwm_sf_bbknhh.py` → `Smartforms/FS_v1.0/ZWM_SF_BBKNHH.xml` (A4 ngang, 15 cột). Sửa form thì sửa script, sinh lại, chạy `sf_validate.py` trước khi upload. Interface: `GS_PARAMETER` (ZCORE_ST_PARAMETER), `IT_DATA` (ZWM_ST_BBKNHH) |
| Bảng `ZTWM_PRTLOG` | Có sẵn, dùng chung nhóm form kho. ZWM02 ghi `TCODE = ZWM02`, `FORMNAME = ZWM_SF_BBKNHH`, `OBJ_KEY = A/<VBELN>` hoặc `B/<MBLNR>/<MJAHR>`, `RPT_OPT = A/B`; mỗi chứng từ 1 dòng, cộng `PRT_COUNT` |
| Message class `ZWM02` | Claude tạo 12/10/2026 qua MCP (`ZPK_WM`, TR `DEVK900207`), 8 message. **Chỉ có bản tiếng Việt, lưu ở ngôn ngữ chính EN** (tool `WriteMessageClassTexts` bỏ qua tham số language, bản VI ghi đè bản EN). Text đã rút gọn ≤73 ký tự, bỏ dấu `"` (tool lỗi deserialize với dấu nháy kép) nên khác bảng bên dưới đôi chỗ |
| Bảng `ZTWM_MVT_GRP` (+ domain/DE `ZDO_/ZDE_WM_*`) | Đã tạo 09/10/2026 (`ZPK_BDP`), dùng chung FS kho; còn technical settings/TMG/data (mục 0). Bảng con `ZTWM_MVT_TCODE` chưa tạo |

Message `ZWM02` (VI / EN):

| Số | Loại dùng | Nội dung |
|---|---|---|
| 001 | E | Bạn không có quyền trên Plant &1. / You are not authorized for plant &1. |
| 002 | E | Vui lòng nhập Lệnh nhập kho/Ngày giao hàng (nguồn A) hoặc Chứng từ/Ngày nhập kho (nguồn B). / Please enter Inbound delivery/Delivery date (source A) or Material document/Posting date (source B). |
| 003 | S | Không có dữ liệu thỏa điều kiện. / No data found. |
| 004 | W | Chứng từ &1 có vật tư thuộc nhóm kiểm soát đặc biệt nhưng đang in bằng mẫu "Hàng hóa khác". / Document &1 contains controlled materials but is printed with the "Other goods" layout. (chưa dùng — FS chỉ là đề xuất, chưa có tiêu chí) |
| 005 | I | Chứng từ &1 đã in &2 lần. Bản in này được đánh dấu "Bản in lại". / Document &1 has been printed &2 times. This copy is marked "Reprint". |
| 006 | W | Dòng &1 chưa có Batch/thuộc tính lô – các cột lô sẽ để trống. / Item &1 has no batch – batch columns will be blank. |
| 007 | W | Đã loại &1 dòng thuộc Plant không có quyền (Plant &2). / &1 items of unauthorized plants removed (plant &2). — thêm ngoài FS để báo số dòng bị loại theo mục Phân quyền |
| 008 | E | Chưa chọn chứng từ để in. / No document selected for printing. — thêm ngoài FS |

## 2. Logic chính / giả định

- **Nguồn A** (LIKP/LIPS): Delivery loại trong STVARV `ZWM02_LFART`; chưa khai báo thì lấy mọi Inbound (VBTYP 7) / Returns Delivery (T). Bỏ dòng không quản lý tồn (`WBSTA` trống) và dòng chính của batch split (`CHSPL`). In được cả khi chưa/đã GR; cột Trạng thái GR theo `LIKP-WBSTK`.
- **Nguồn B** (MATDOC): `RECORD_TYPE = MDOC`, `SHKZG = S`, `CANCELLED` trống (chưa bị hủy), `SMBLN` trống (không phải chứng từ hủy), `XAUTO` trống. **Lọc MvT theo `ZTWM_MVT_GRP` (từ 12/10/2026, thay STVARV `ZWM02_BWART` và điều kiện `AUFNR` trống):** đọc cả bảng vào `GT_MVT` (key BWART+SEQNR); MvT chọn ở SQL = MvT có ít nhất 1 dòng `GRP_CODE` MH/TH; sau đó mỗi dòng MATDOC xét các dòng bảng cùng BWART theo SEQNR tăng dần, **dòng khớp đầu tiên** (SOBKZ, AUFNR_FLG = X ⇔ MATDOC-AUFNR có giá trị, BSART/PSTYP của PO lấy từ EKKO/EKPO theo EBELN/EBELP, WERKS; trống = bất kỳ) quyết định nhóm; chỉ giữ nếu nhóm MH/TH (101 có lệnh SX khớp dòng SX ⇒ bị loại). **Bảng trống hoặc không có dòng MH/TH ⇒ nguồn B không ra dòng nào** (đúng FS: lọc theo bảng tham số). Chưa dùng bảng con `ZTWM_MVT_TCODE` (FS ZWM02 không nhắc; chốt BA sau nếu cần). Năm chứng từ chỉ áp dụng khi nhập Chứng từ nhập kho.
- **Bắt buộc**: Plant bắt buộc (`MEMORY ID WRK`); A cần Lệnh nhập kho hoặc Ngày GH, B cần Chứng từ hoặc Ngày nhập kho (ZWM02-002).
- **Quyền**: `M_MSEG_WWE` (03) theo Plant, dòng Plant không có quyền bị loại, báo ZWM02-007; loại hết thì báo ZWM02-001. `M_MSEG_LGO`: chưa kiểm (FS "nếu dự án bật").
- **Màn hình trung gian**: 1 dòng/chứng từ, mặc định tích chọn; ô Chọn bấm để tích/bỏ; nút Xem trước / In / Chọn tất cả (bấm lại để bỏ hết) / Excel (tải `.xlsx`). Số xe = `LIKP-TRAID` → text Delivery `ZLF6` → `MATDOC-XABLN`.
- **In**: mỗi chứng từ 1 biên bản trong 1 lần `SSF_OPEN`; ghi `ZTWM_PRTLOG` chỉ khi in ra máy in (kể cả in từ xem trước). Trước khi in hiện log ZWM02-005 (bản in lại) và ZWM02-006 (dòng nguồn A chưa có Batch). **`ZTWM_PRTLOG` không có cột máy in** (FS có nêu) — chưa thêm vì bảng dùng chung.
- **Header**: đơn vị theo Plant (`ZCORE_FM_GET_PROFILE` kind P); ngày kiểm nhận A = `WADAT_IST` nếu có, không thì `LFDAT`, B = `BUDAT`; người kiểm nhận = text `ZLF3`, B không có Delivery = `XBLNR`; người giao hàng = text `ZLF5` → `BOLNR` / `FRBNR`; nguồn B MvT 305 để trống 2 ô này; giấy phép NK = đặc tính `Z_GIAYPHEP_NK` các lô (chỉ mẫu gây nghiện).
- **Dòng chi tiết**: cộng dồn cùng vật tư + MPN + lô + ĐVT trong 1 chứng từ, STT đánh lại từ 1. Tên hàng: có `EMATN` (LIPS/MATDOC) thì lấy MAKT của mã MPN. NSX = `Z_NSX` lô (mã NCC → tên) → `MFRNR` của mã MPN; Nước = `LOBM_HERKL` → `MARC-HERKL` → nước của NSX (tên theo T005T). Số lô NSX = `Z_BATCH_NSX` → `MCHA-LICHA` → Batch SAP. Hạn dùng = `VFDAT`, mẫu Gây nghiện/Khác trống thì `QNDAT`. Quy cách = đặc tính `Z_QUY_CACH_BATCH` (tên ECC, FS không nêu) → `MARA-GROES`. Ghi chú = `Z_DIEUKIENBAOQUAN` của lô → của vật tư. SL thực tế nguồn A để trống.
- **Dòng nhóm**: `NCC/KH <mã> – <tên> | Lệnh nhập kho/Chứng từ nhập kho <số> [(Nhập kho GR blocked stock) nếu MvT 103] | HĐ <số> - <ngày>` (phần HĐ trống thì không in).
- **DEV chưa có**: đặc tính `Z_*` nào (CABN chỉ có `LOBM_HERKL`), Text ID Z nào cho VBBK/VBBP → các cột/ô này sẽ trống khi test trên DEV.

## 3. Câu hỏi còn mở cho BA

**User chốt 09/10/2026:** không hỏi thêm về `ZTWM_MVT_GRP`, chỉ báo BA "bảng chưa có trên DEV"; có bảng là đủ FS. Câu 1 dưới đây (loại Delivery) chỉ hỏi nếu bảng khi tạo ra không có loại Delivery.

Quy tắc (`CodeABAP/BDP/NOTE/note.md`): chỉ hỏi chỗ FS thiếu ở yêu cầu chính; chỗ chỉ là chưa cấu hình / chưa có data mà code đã có cách chạy tạm thì KHÔNG hỏi, chỉ thông báo BA.

1. **Loại Delivery của nguồn A khai báo ở đâu** — FS mục 2.6.1: *"Nguồn A: Delivery thuộc loại trong bảng tham số (Inbound Delivery mua hàng, Returns Delivery, lệnh nhập hàng trả nội bộ)"*. BA nói bảng tham số là `ZTWM_MVT_GRP`, nhưng bảng này chỉ phân loại Movement Type, không có loại Delivery. Code tạm: STVARV `ZWM02_LFART`; chưa khai báo thì lấy mọi Inbound/Returns Delivery. Đề xuất: giữ STVARV `ZWM02_LFART` (key user tự bảo trì, không tạo bảng mới).

2. **(Không bắt buộc, chốt 12/10/2026) Công nghệ form: Adobe Form hay Smartform?** FS mục Form: *"Adobe Form (đề xuất) hoặc Smartform chuyển đổi – thống nhất chung nhóm form kho"*. Code đang dùng **Smartform** `ZWM_SF_BBKNHH` (form ECC có từ 2014, chuyển theo FS) — đây là lựa chọn của Claude, FS không bắt buộc. Nếu nhóm form kho chốt Adobe thì phải làm lại form + đổi lời gọi in trong `PRINT_DOCS`/`FILL_FORM`. Excel: nút `EXCEL` xuất **danh sách chứng từ ở màn hình trung gian** (`to_xml` xlsx của ALV), đúng FS dòng "Excel – Xuất danh sách", không xuất biên bản.

**Trạng thái 12/10/2026:** user chưa quyết hỏi BA câu 2; câu 1 chưa hỏi. Rà FS lại: ngoài 2 câu trên không còn chỗ FS thiếu ở yêu cầu chính.

### Chỉ thông báo BA (chưa cấu hình / chưa có data, code đã chạy tạm)

- ~~`ZTWM_MVT_GRP` chưa có trên DEV~~ (bảng đã tạo, code `GET_DATA_B` đã lọc theo bảng từ 12/10/2026, xem mục 0 và mục 2). **Việc BA còn lại: nhập data** (đang 0 dòng ⇒ nguồn B chưa ra dòng nào); data mẫu nằm ở `FS/BDP_ZTWM_MVT_GRP 2.xlsx` sheet `ZTWM_MVT_GRP`, ZWM02 chỉ cần các dòng nhóm MH/TH (và dòng SX/DC... để loại đúng, vì xét dòng khớp đầu tiên theo SEQNR).
- Text ID Delivery (FS ghi "Text ID dự án") chưa cấu hình → header tạm dùng ID ECC ZLF1 số HĐ, ZLF2 ngày HĐ, ZLF3 người kiểm nhận, ZLF5 người giao hàng, ZLF6 số xe; item text Hồ sơ đi kèm / Tình trạng niêm phong để trống. Đề xuất: giữ ID ECC cho header, tạo thêm 2 Text ID item (VBBP).
- Đặc tính lô `Z_NSX`, `Z_BATCH_NSX`, `Z_GIAYPHEP_NK`, `Z_DIEUKIENBAOQUAN`, quy cách lô (tạm tên ECC `Z_QUY_CACH_BATCH`) chưa có trên DEV → cột tương ứng trống.
- Mã biểu mẫu GMP / `ZTWM_FORM_LAYOUT` (FS: "chờ BIDIPHAR cung cấp") → để trống, 1 form chung.

### 3a. `ZTWM_MVT_GRP` (BA trả lời câu 1, 09/10/2026)

- BA: "bảng tham số" MvT trong FS ZWM02 là `ZTWM_MVT_GRP`; khai báo gì thì đội check rồi gửi.
- Bảng được mô tả ở **FS khác** (ảnh user gửi, mục *"2.5.2 Diễn giải nghiệp vụ (bảng ZTWM_MVT_GRP)"*, chưa có file FS đó trong repo): *"Khóa: MvT, special stock, có lệnh SX (X/trống), loại PO, item category PO, Plant. Kết quả: nhóm nghiệp vụ (Mua hàng / Sản xuất / Hàng trả / Điều chuyển / Khác), diễn giải (VI, EN), MvT đảo"*; *"Bảng là customizing, bảo trì qua SM30 bởi Key user/IT, có transport và table logging"*. Giá trị khởi tạo theo ECC: 101/105 thường → Mua hàng; 101 có lệnh SX, 131, 531 → Sản xuất; 653, 657, Z18, Z19, Z20 → Hàng trả; 101 + PO điều chuyển, STO → Điều chuyển…
- **Kiểm tra 09/10/2026 (đã cũ — sau đó Claude đã tạo bảng ở client 100, xem mục 0):** `ZTWM_MVT_GRP` **chưa có trên DEV 200** (SearchObject `ZTWM_MVT*` rỗng, DD02L không có), không có trong code/FS nào trong repo. Bảng tên gần giống `ZTB_ZBC05_BWART` là của Barcode ZBC06 (cờ nhập/xuất), không liên quan.
- **Liên quan ZWM02:** khớp đúng yêu cầu nguồn B — *"Khi một MvT được sử dụng cho nhiều nghiệp vụ, kiểm tra thêm chứng từ tham chiếu để loại nghiệp vụ ngoài phạm vi, bao gồm nhập thành phẩm từ sản xuất"*: tra `ZTWM_MVT_GRP` theo MvT + SOBKZ + có AUFNR + loại PO (EKKO-BSART) + item category (EKPO-PSTYP) + Plant, chỉ lấy dòng nhóm **Mua hàng** và **Hàng trả**. Bảng **không có loại Delivery** → nguồn A vẫn cần danh sách LFART riêng.
- **Trong lúc chờ bảng:** theo giá trị khởi tạo ở ảnh, có thể khai STVARV `ZWM02_BWART` = 101, 105 (mua hàng) + 653, 657, Z18, Z19, Z20 (hàng trả) để test sát hơn. Vẫn còn lẫn 101 ký gửi (SOBKZ K), 101 PO điều chuyển, 101 gia công — chỉ bảng mới loại được.
- **(Đã cũ — 12/10/2026 code đã đổi sang đọc `ZTWM_MVT_GRP`, xem mục 2)** Code hiện tại chưa đổi (vẫn STVARV `ZWM02_BWART` + loại dòng có AUFNR): bảng chưa tồn tại, chưa biết tên field / mã nhóm → đọc vào sẽ không activate được.
- **Khi bảng được tạo:** sửa `GET_DATA_B` — lấy thêm `SOBKZ`, `AUFNR`, `EBELN/EBELP` (join EKKO-BSART, EKPO-PSTYP), đọc `ZTWM_MVT_GRP`, giữ dòng có nhóm Mua hàng/Hàng trả (ưu tiên khóa cụ thể hơn, khóa trống = mọi giá trị — xác nhận khi có thiết kế); bỏ STVARV `ZWM02_BWART` và điều kiện `AUFNR = space`.
- Không hỏi thêm: chờ đội gửi khai báo/thiết kế bảng (BA đã nói). Khi có thì cần biết tên field + mã nhóm "Mua hàng"/"Hàng trả".
- **09/10/2026 BA gửi thiết kế** `FS/BDP_ZTWM_MVT_GRP 2.xlsx` (2 sheet): cha `ZTWM_MVT_GRP` key `BWART + SEQNR`, điều kiện `SOBKZ, AUFNR_FLG, BSART, PSTYP, WERKS` (trống = bất kỳ, xét theo SEQNR tăng dần, dòng chung 900 cuối), `GRP_CODE` (MH/SX/BH/TH/DC/TT/VT/KH), `TXT_VI/EN`, `REV_BWART`; data mẫu có thêm cột `USE_FLG` (Có tiêu thụ, ZWM09) không có trong danh sách field. Con `ZTWM_MVT_TCODE` (T-code được phép, giống OMJJ) key `BWART + TCODE`. Với ZWM02: có dòng con 101, 103, 653, Z20.
- Điểm lệch trong thiết kế (đã báo user): (1) con chỉ khóa theo `BWART` nhưng ghi chú mẫu "101 có lệnh SX: ZWM02 không có dòng con → loại" ⇒ con phải theo dòng cha `BWART + SEQNR`; (2) cột "T-code - Des" đánh Key nhưng ghi chú "lấy từ TSTCT, không lưu" ⇒ không tạo field; (3) dòng 101/ZWM02 lặp 2 lần; (4) `PSTYP` lưu nội bộ (gia công = 3) — SM30 sẽ hiện 3, không hiện L.
- **09/10/2026 đã tạo qua MCP (client 100, task `DEVK900208` / TR `DEVK900207`, package `ZPK_BDP`)**: domain `ZDO_WM_GRP_CODE`, 6 data element dưới đây, bảng `ZTWM_MVT_GRP` (active, field khóa client tên `CLIENT`). **Chưa làm**: technical settings (Log Data Changes, data class, buffering), enhancement category (đang Not extensible), Table Maintenance Generator, bảng con `ZTWM_MVT_TCODE`, nhập data mẫu. Text tạo dưới ngôn ngữ EN (MCP đăng nhập EN).
- Thiết kế (đã hướng dẫn user, giữ để tham chiếu) (package `ZPK_BDP` như `ZTWM_PRTLOG`), data element mới `ZDE_WM_AUFNR_FLG`, `ZDE_WM_GRP_CODE` (+ domain `ZDO_WM_GRP_CODE` fixed values), `ZDE_WM_USE_FLG`, `ZDE_WM_MVT_TXT_VI/_EN`, `ZDE_WM_REV_BWART`; chuẩn dùng `BWART, SEQNR, SOBKZ, ESART, PSTYP, WERKS_D, TCODE`. Khi user báo đã activate → `GetTable` kiểm field thật rồi sửa `GET_DATA_B`: lọc MvT có dòng con `TCODE = ZWM02`, chọn dòng cha khớp đầu tiên theo SEQNR, giữ `GRP_CODE` MH/TH.

**Tự xử lý, không báo cũng được:**
- Cảnh báo ZWM02-004: FS ghi *"Đề xuất bổ sung kiểm tra"*, chưa có tiêu chí → chưa làm.
- `ZTWM_PRTLOG` không có cột máy in → chưa thêm (bảng dùng chung).
- `M_MSEG_LGO`: FS ghi "nếu dự án bật" → chưa kiểm.

## 4. Khi BA trả lời / khi có dữ liệu

- Câu 2 (Adobe hay Smartform): giữ Smartform nếu BA đồng ý; nếu chốt Adobe thì làm lại form theo FS hình 4, 5.
- Khi BA nhập xong data `ZTWM_MVT_GRP`: chạy thử ZWM02 nguồn B (chứng từ 101/103/653/Z20...), kiểm dòng bị loại đúng (101 có lệnh SX, ký gửi, PO điều chuyển) rồi báo lỗi nếu có.

- Câu 1 (loại Delivery): khai báo STVARV `ZWM02_LFART`; nếu BA chỉ định chỗ khác thì sửa FORM `GET_PARAMETER`.
- Khi có `ZTWM_MVT_GRP` trên DEV: sửa `GET_DATA_B` theo mục 3a.
- Khi có Text ID: sửa hằng số `GC_TXT_*` trong TOP.
- Khi có `ZTWM_FORM_LAYOUT`: đọc trong `FILL_FORM`, mã biểu mẫu gán `GS_PARAMETER-HEADER02` (form đã có chỗ in, chỉ in khi có giá trị).
- Khi có tiêu chí ZWM02-004: thêm kiểm tra trong `PRINT_DOCS`.

## 5. Bắt đầu phiên mới — làm theo thứ tự

1. Đọc `CodeABAP/BDP/NOTE/note.md` (quy tắc chung) rồi đọc file này.
2. Hỏi user đã làm tới bước nào của mục 0 (message class, GUI status, dán code, upload form). Nếu user báo đã xong → MCP kiểm lại: `SearchObject ZWM_PG_BBKNHH`, `GetInclude` 2 include so với file local, `GetMessageClassTexts ZWM02`, form qua `STXFADM` (ngày sửa) + `FUPARAREF` (interface phải còn `GS_PARAMETER`, `IT_DATA`, không còn `GS_HEADER`).
3. Sửa code xong thì SyntaxCheck: gộp main + TOP + F01 thành 1 file rồi check với URL `/sap/bc/adt/programs/programs/zwm_pg_bbknhh` (check include riêng sẽ dùng bản cũ trên server). File gộp dài ~1.700 dòng → giao subagent dán vào SyntaxCheck.
4. Khi BA trả lời → mục 4.

**Quy tắc đã áp dụng cho code này (từ note.md), giữ khi sửa tiếp:** code move coi như tạo mới, không đánh marker tên/ngày; comment chỉ ý chính, không ghi số mục FS, không để code cũ bị comment; chỗ FS ghi "chờ" thì để trống, không hard-code; chỗ đoán được thì code và ghi giả định ở mục 2; FS ghi rõ mà code lệch thì sửa theo FS, không hỏi BA.
