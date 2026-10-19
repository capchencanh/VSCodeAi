# Ghi chú dự án ZRSD08 — Bảng kê bán lẻ hàng hoá dịch vụ (Bidiphar)

FS nguồn: `FS/BIDIPHAR_FS_SD_ZRSD08_BangKeBanLeHangHoaDichVu_V1.0 (1).docx` — **bản FS mới, đã bàn với user (14/10/2026)**.
Bản cũ `..._V1.0.docx` (09/09/2026) giữ lại để đối chiếu.
Người lập code: [CS]_DanhDH — 29/09/2026; cập nhật theo FS mới 14/10/2026

## Trạng thái cuối phiên 14/10/2026 (đọc mục này trước)

**Code + form theo FS mới đã xong và đã lên DEV/100 (TR `DEVK900197`, task `DEVK900198`); chỉ còn kiểm thử và bàn giao BA test.** User đã upload Smart Form bản lần 2 và báo OK.

**[16/10/2026] BA nhắn bổ sung 2 Item Category vào danh sách in: `ZP4A` ("B.Split (X Ky Gui)") và `ZP1A` ("B.Split (Ban)")** — danh sách trong `GC_PSTYV` nay có **38** loại (36 của FS + 2 này); FS chưa sửa theo. Đã sửa local và lên DEV/100 (`ZIN_SD_BKBLHHDV_TOP`, TR request `DEVK900197`); kiểm: `REPOSRC` mọi include `R3STATE = A`, ATC 0 lỗi. `ZP1B` ("B.Split (Tang, KoVAT)") vẫn **không** thuộc danh sách. Các hóa đơn test ở DEV/200 (`3060000000`, `3060000001`, `3060000003`; dòng 1 mỗi hóa đơn là `ZP1A`) nhờ vậy đã có dòng để in; chúng không có partner `SB` (Nhà thuốc) và không có điều kiện `ZRT1` nên Nhà thuốc / đơn giá sẽ trống.

**[16/10/2026] Dump khi BA/user chạy thật trên DEV/200: `CALL_FUNCTION_CONFLICT_TAB_TYP`** tại `PRINT_FORM` (dòng gọi `CALL FUNCTION lv_fmname`), điều kiện (3) "table keys do not match": `GT_ITEM` khai `WITH EMPTY KEY` còn tham số `IT_ITEM` của Smart Form là table type `ZTT_RSD08_ITEM` (default key). Đã sửa `GTT_ITEM TYPE ZTT_RSD08_ITEM`, `GTT_TAX TYPE ZTT_RSD08_TAX` trong `ZIN_SD_BKBLHHDV_TOP` (local + DEV/100, TR `DEVK900197`; active, ATC 0 lỗi). **Chưa chạy lại được qua MCP** (`RunReport` cần `ZADT_VSP`); user chạy lại để xác nhận. Lỗi này lộ vì lần đầu có hóa đơn thật: chương trình test `ZPG_SD_BKBLHHDV_TEST` truyền bảng typed `ZTT_*` nên không gặp.

**[16/10/2026] Chạy preview trên DEV/200 ra màn hình trắng, thông báo "Graphic cannot be displayed":** logo form lấy tên `ZLOGO_` + `BUKRS` (hóa đơn test `BUKRS = 1000` → `ZLOGO_1000`), hệ chỉ có `ZLOGO_0001` (`STXBITMAPS`) nên Smart Form báo lỗi và không hiển thị gì. Việc user: nạp `ZLOGO_1000` ở SE78 (xem mục 1 trong danh sách "Còn lại" bên dưới); không sửa code.
**Logo (16/10/2026):** MCP không có tool nạp ảnh vào SE78 (đồ họa `STXBITMAPS`), user tự nạp. File gốc user chỉ: `...\Citek Bidiphar Upgrade PCE - BIDIPHAR_ECC\LOGO\FES_LOGO.bmp` (đúng logo Bidiphar nhưng 505×505 px, 8 bit; ở 100 DPI sẽ ra 12,8 cm, tràn ô logo 6,3 cm của form). Đã cắt viền trắng và thu về **121×66 px, 24 bit, 100 DPI** (đúng cỡ form tính: 3,07 × 1,68 cm) lưu ở `Form/ZLOGO_1000.bmp`; nạp file này vào SE78 với tên `ZLOGO_1000`.
**Máy in:** user yêu cầu mặc định `LP01`. Code lấy máy in từ SU3 (`USR01-SPLD`), nếu trống dùng hằng số `GC_PRINTER` = `LP01`; luôn `NO_DIALOG = 'X'` nên không hiện hộp thoại chọn máy in khi Preview và PDF; riêng Direct Print vẫn mở hộp thoại in (code `P_PRNT` đặt lại `NO_DIALOG = SPACE`). Đã sửa local và DEV/100 (`ZIN_SD_BKBLHHDV_TOP`, `_F01`, TR `DEVK900197`, active, ATC 0 lỗi).

Còn lại (xem checklist ở mục "Trạng thái" cuối file):
1. **Nạp logo `ZLOGO_1000`** vào SE78 (hệ chỉ có `ZLOGO_0001`); GRAPHICS / BMAP / BCOL, ảnh khoảng 121×66 px, 100 DPI, TR `DEVK900197`.
2. **Xem preview** bằng `ZPG_SD_BKBLHHDV_TEST` (`P_ROWS` = 3 và 30): khối `Tổng cộng` và khối cuối (`OCOND FOOTER` + `PROTECT`) chỉ in ở trang cuối, cột `Thuế suất GTGT` có xuống dòng ở tiêu đề không.
3. **Test hoá đơn thật** — **[kiểm 16/10/2026 trên DEV/200]** client 200 có 4 hoá đơn (`3060000000`–`3060000003`, loại `ZFT3`/`ZST3`) nhưng item category của chúng chỉ là `ZP1A`, `ZP1B` ("B.Split") — **không nằm trong danh sách 36 item category của FS (`GC_PSTYV`: `ZT1A`, `ZT1P`, `ZT2A`… `ZN1A`)** nên chạy ZRSD08 với bất kỳ hoá đơn nào ở đó đều ra "Khong tim thay du lieu voi dieu kien da chon" (code đúng FS). Muốn test cần hoá đơn có item category thuộc danh sách (VD `ZT1A` "T1-Hang ban"), do BA/user lập. Ở client 100 DEV chưa có `VBRK`; client 200 còn thiếu customizing `ZRT1`/`ZRVA01`: kiểm `KBETR / 10` của MWST, nhánh Sold-to = nhà thuốc ("Bán cho người tiêu dùng", không in MST/địa chỉ), chọn lẫn hoá đơn người tiêu dùng với hoá đơn công ty phải báo lỗi.
4. Bật lại `PERFORM CHECK_AUTHORITY` trong chương trình chính (user đang comment trên hệ), release TR.

**Về BA (chốt 14/10/2026, theo bộ lọc ở `NOTE/note.md`): KHÔNG có câu hỏi bắt buộc nào.** Các chỗ lệch của FS chỉ là thông báo, code đã chạy đúng theo mẫu in: văn bản chỉ tiêu (21) còn công thức/ví dụ cũ; `LIKP-VKORG` (code dùng `VBRK-VKORG`); loại hoá đơn `ZF2` ở mẫu không có trên hệ; dòng ngày viết hoa ở mô tả (4)(5) nhưng mẫu in viết thường (code theo mẫu). `cau_hoi_fs_ZRSD08.md` là bản nháp cũ, không gửi nguyên văn.

**Code Inspector (user chạy 14/10/2026):** 0 lỗi, 4 cảnh báo `Buffered table ... in a JOIN` (`TVKO`, `T001` ở `GET_HEADER_DATA`; `T005U`, `T005T` ở `GET_ADRC_ADDRESS`) — bảng cấu hình nhỏ, mỗi `SELECT SINGLE` chạy 1 lần/lần in, không ảnh hưởng. Muốn sạch thì thêm `"#EC CI_BUFFJOIN` cuối 2 câu `SELECT` (chưa làm).

**Gotcha MCP đã gặp trong phiên** (chi tiết ở `_ghichu_mcp_gui.md`): ghi 2 include phụ thuộc nhau sau khi đổi DDIC thì `Activate` báo thành công nhưng còn `I` → ghi `F01` khung rỗng, activate `TOP`, ghi lại `F01` đầy đủ; `ExecuteABAP` bị chặn (`$TMP`), `RunQuery` có lúc bị bộ phân loại quyền của chế độ auto chặn (gọi lại bằng công cụ khác đúng mục đích như `RunATCCheck`, không đi vòng); xem Smart Form đã sinh bằng `STXFADM`/`STXFADMI` → FM `/1BCDWB/SF<8 số>`.

## Cập nhật theo FS mới (14/10/2026)

### FS mới khác FS cũ chỗ nào → code đã làm gì

| Chỉ tiêu | FS mới | Code (`Program/`) |
|---|---|---|
| (2.1) Địa chỉ công ty | **mới** — ADRC của công ty: HOUSE_NUM1 + STREET, CITY2, CITY1 | FORM `GET_COMPANY_ADDRESS` → `HEAD-CADDR` (nối bằng ` - ` theo mẫu) |
| (2.2) MST công ty | **mới** — OBY6 → Additional Data → VAT Registration No. | `T001-STCEG` → `HEAD-CTAXNO` |
| (3.1) Tên nhà thuốc | **mới** — tên partner SB | ADRC theo `KNA1-ADRNR` (ưu tiên) / `VBPA-ADRNR`, ghép NAME1..4 như (2) → `HEAD-NHATHUOCNM` |
| (8) Tên đơn vị mua hàng | Sold-to = nhà thuốc (3) → `Bán cho người tiêu dùng`; Sold-to ≠ nhà thuốc → tên Payer (RG) | `GET_HEADER_DATA`; Sold-to = `VBRK-KUNAG` |
| (8.1) MST đơn vị mua hàng | **mới** — Sold-to = nhà thuốc thì không in; ngược lại Tax Number 1 của Payer | `KNA1-STCD1` → `HEAD-PAYERTAX` |
| (9) Địa chỉ đơn vị mua hàng | Sold-to = nhà thuốc thì không in | `GET_HEADER_DATA` |
| (11) Item Category | chỉ lấy 36 Item Category liệt kê trong FS | hằng `GC_PSTYV` ở TOP → `GR_PSTYV` → `WHERE A~PSTYV IN @GR_PSTYV` |
| (16) | **đổi**: Ghi chú → **Thuế suất GTGT từng dòng** (condition `MWST`, hiển thị %) | join `PRCD_ELEMENTS` alias `TX` (KNUMV + KPOSN + `MWST`); `ITEM-TAXRATE = KBETR / 10` |
| (18) Chiết khấu sau | **bỏ** khỏi FS | bỏ code; `DISCOUNT` bỏ khỏi `HEAD` |
| (19.1)+(20) | **đổi**: 1 dòng cho mỗi mức thuế suất, tiền thuế = Σ `KWERT` (MWST) của các dòng cùng mức | FORM `GET_TAX_SUMMARY` → `GT_TAX` (truyền form qua `IT_TAX`), sắp xếp thuế suất tăng dần |
| (19) Tổng cộng tiền thuế | Σ (20) | `HEAD-TAXAMT` (`CALC_TOTAL`) |
| (21) Tổng thanh toán | theo mẫu: (17) + (19) | `CALC_TOTAL` |
| (21.1) Số tiền bằng chữ | **mới** | class có sẵn `ZCORE_CL_AMOUNT_IN_WORDS=>READ_AMOUNT` (package `ZPK_CORE_FUNCTION`, `I_IS_INTERNAL = X`) → `HEAD-AMTWORD` |
| Tham số (6) Nhà thuốc, (7) Đơn vị mua hàng | **đổi** Multiple → Single value | `NO-EXTENSION NO INTERVALS` |

Thay đổi kỹ thuật kèm theo:

- Thuế MWST lấy luôn trong `SELECT` chính của `GET_BILLING_DATA` → bỏ query `PRCD_ELEMENTS` riêng ở `GET_HEADER_DATA` (còn 1 query ít hơn; bỏ luôn `LR_VBELN`).
- Kiểm tra "cùng đơn vị mua hàng" nay xét theo khoá `*` (khách mua tại quầy, Sold-to = nhà thuốc) hoặc mã Payer. Chọn lẫn hoá đơn người tiêu dùng với hoá đơn công ty → báo lỗi (chỉ tiêu (8) khác nhau).
- `GET_ADRC_ADDRESS`: dấu ngăn `', '` đổi sang string literal `` `, ` `` để chắc chắn có dấu cách sau dấu phẩy (text literal `'...'` bỏ khoảng trắng cuối).
- `SELECT` chính dùng `INTO CORRESPONDING FIELDS OF TABLE` (khớp theo tên, không phụ thuộc thứ tự cột).
- Dọn marker `danhdh add` và code cũ bị comment trong 2 include (theo `NOTE/note.md`).
- `zpg_sd_bkblhhdv_test.abap` đổi sang interface mới, dùng số liệu mẫu FS mới (thuế 5% / 8% / 10%, tổng 1.112.500, thuế 90.210, thanh toán 1.202.710).

### Giả định đã chọn (có cách chạy hợp lý, không hỏi BA)

- (2.1) FS chỉ ghi dấu `+`, không nói ký tự ngăn → theo mẫu in dùng ` - ` (mẫu trộn ` - ` và ` – `, chọn ` - `).
- (16) FS ghi `CHAR 120` nhưng mẫu in `5%` → dùng `ZDE_TAXRATE` (DEC 5,2); form in kèm `%`.
- Dòng hàng không có condition MWST (hoặc MWST = 0) vẫn in, thuế suất 0 % → khối cộng có thêm dòng `Thuế suất GTGT 0 %` với tiền thuế 0.
- (8.1) đọc `KNA1-STCD1` (BP role FI Customer → Control → Tax Number 1); khách vãng lai không có → trống. Kiểu `STCD1` (CHAR 16) thay vì NUMC 10 của FS để giữ nguyên số 0 đầu.
- (21.1) VND in `... đồng`, không thêm `chẵn`; tiền tệ khác do class tự đổi đơn vị (không có trong bảng của class thì in mã tiền).
- Item Category: FS liệt kê cứng nên để thành hằng số tại `GC_PSTYV` (1 chỗ duy nhất). Nếu BA muốn đổi danh sách không cần transport → chuyển sang STVARV (`TVARVC`), đang chưa làm.

### FS mới còn chỗ lệch nội bộ (thông báo BA, không chặn code)

- Chỉ tiêu (21): văn bản vẫn ghi *"(17) cộng (20) trừ (18)"* và ví dụ *"1.112.500 cộng 55.625 trừ 0 bằng 1.168.125"* (số của bản cũ). Mẫu in ghi **1.202.710 = 1.112.500 + 90.210**. Code làm theo mẫu: (21) = (17) + (19).
- Chỉ tiêu (1): FS vẫn ghi `LIKP-VKORG` (bảng Delivery) — code dùng `VBRK-VKORG`.
- Đầu FS vẫn ghi *"Nội dung bôi vàng là điểm cần Bidiphar xác nhận"*, nhưng FS mới không có chỗ nào bôi vàng (đã quét XML) → coi như không còn điểm chờ xác nhận.
- Mẫu in dùng loại hoá đơn `ZF2` — không tồn tại trên hệ (xem mục lệch customizing bên dưới).
- Search help của tham số (1), (6), (7) theo FS ("theo Billing Date + Sales organization", "cột mã và cột tên") — chưa làm, đang dùng F4 chuẩn (giống FS cũ).

### Đã kiểm bằng MCP `GUI_BDP_DEV_100` (chỉ đọc, 14/10/2026)

- 36/36 Item Category trong FS tồn tại trong `TVAP`.
- `T001`: BUKRS `1000` có `ADRNR = 0000000055`, `STCEG = 4100259564` (đúng MST ở mẫu FS).
- `ZMC_SD` đã có (message `001`); Tcode `ZRSD08` đã có (package `ZPK_BDP`).
- `ZCORE_CL_AMOUNT_IN_WORDS` có sẵn; `TCURX`: VND `CURRDEC = 0` → tiền lưu ×100, khớp `I_IS_INTERNAL = X`. Mẫu 1.202.710 → *"Một triệu hai trăm lẻ hai nghìn bảy trăm mười đồng"* (đọc source class, khớp mẫu FS).
- `MWST`: T685A có (`KAPPL V`, `KRECH A` = phần trăm). `KONP` có bản ghi MWST giá trị `150.00` / `70.00` → thuế suất lưu nhân 10 (15,0 % / 7,0 %), hướng chia 10 là đúng. **Chưa kiểm trên `PRCD_ELEMENTS`** vì chưa có hoá đơn nào (0 dòng MWST).
- *(Lúc kiểm, trước khi ghi lên hệ)* hệ là bản cũ của 2 include + main: còn `MWAS`, `M_IS_VTWEG` có `ACTVT`, và `PERFORM CHECK_AUTHORITY` đang bị comment ở `AT SELECTION-SCREEN`; DDIC chưa có field mới. **Đã xử lý — xem mục "Đã ghi lên hệ DEV/100 qua MCP" ở trên** (riêng `CHECK_AUTHORITY` ở chương trình chính vẫn đang comment).
- Syntax check qua `SyntaxCheck` (không lưu): nguồn main + TOP + F01 ghép, DDIC mới thay bằng type cục bộ tương đương → **sạch**; `zpg_sd_bkblhhdv_test` → **sạch**. Chưa chạy được với hoá đơn thật.

### Đã ghi lên hệ DEV/100 qua MCP (14/10/2026) — TR `DEVK900197`, task `DEVK900198` (CS_DanhDH_29.09.2026_Create ZRSD08)

| Object | Việc đã làm | Kiểm lại |
|---|---|---|
| `ZDE_CADDR`, `ZDE_NHATHUOCNM` (CHAR 120, domain `CHAR120`) | tạo mới, đủ 4 nhãn | `DD04L` có dòng `A` |
| `ZST_RSD08_TAX`, `ZTT_RSD08_TAX` | tạo mới | `DD03L` đủ 3 field; `DD40L` dòng `A` |
| `ZST_RSD08_ITEM` | thêm `TAXRATE`, bỏ `GHICHU` | `DD03L` 11 field |
| `ZST_RSD08_HEAD` | thêm `CADDR CTAXNO NHATHUOCNM PAYERTAX AMTWORD`; bỏ `DISCOUNT TAXRATE` | `DD03L` 20 field |
| `ZIN_SD_BKBLHHDV_TOP`, `ZIN_SD_BKBLHHDV_F01` | ghi bản mới | `SyntaxCheck` chương trình chính = `null`; ATC 0 lỗi, không có SLIN 0033 (inactive) |
| `ZPG_SD_BKBLHHDV_TEST` | ghi bản mới (interface `IT_TAX`) | `SyntaxCheck` = `null` |
| Text symbol `B01`, `B02` của `ZPG_SD_BKBLHHDV` | thêm (`Điều Kiện Chọn`, `Chế Độ Đầu Ra`) + activate | ATC hết finding 1701 |

- Chương trình chính `ZPG_SD_BKBLHHDV` **không sửa trên hệ**: bản trên hệ có header CITEK và `PERFORM CHECK_AUTHORITY` đang bị comment (user tự comment). Include mới đã sửa lỗi `M_IS_VTWEG`; muốn bật lại phân quyền thì bỏ dấu `*` ở dòng đó trong SE38.
- Hai include phụ thuộc lẫn nhau + DDIC vừa đổi → `UpdateObjectAtomic`/`Activate` báo `success` nhưng REPOSRC còn dòng `I`. Đã xử lý bằng cách đưa `F01` về khung compile được, activate `TOP`, rồi ghi lại `F01` đầy đủ (xem `_ghichu_mcp_gui.md`). Không đọc lại được `REPOSRC` ở bước cuối (RunQuery bị chặn quyền) nên xác nhận bằng ATC; **nên mở SE38 xem 2 include đã active chưa**.

### Smart Form — đã sinh lại theo FS mới (14/10/2026), chờ user upload

`Form/gen_zsf_sd_bkblhhdv.py` → `Form/zsf_sd_bkblhhdv.xml` (191 KB). `sf_validate.py` **PASS** khi đối chiếu `CodeABAP/BDP/ZWM01/Smartforms/FS_v1.0/ZWM_SF_PYCVT.xml` (mẫu duy nhất trong BDP có cả điều kiện so sánh lẫn code node; so với mẫu thiếu 1 trong 2 thì FAIL vì thiếu thẻ, không phải lỗi cấu trúc).

- Interface: `IS_HEAD ZST_RSD08_HEAD`, `IT_ITEM ZTT_RSD08_ITEM`, **`IT_TAX ZTT_RSD08_TAX` (mới)**.
- 1 window `MAIN` gồm 2 table: `IT_ITEM` (đầu form, dòng hàng, dòng Tổng cộng) và `IT_TAX` (mỗi mức thuế suất 1 dòng, rồi Tổng cộng tiền thuế, Tổng cộng tiền thanh toán, Số tiền bằng chữ, ngày lập, 3 ô ký).
- Đầu form: logo | tên công ty + địa chỉ + `Mã số thuế`; `Nhà thuốc: mã – tên`; tiêu đề 2 dòng; loại hoá đơn; `Tên đơn vị mua hàng` + `MST` (chỉ in khi có MST); `Địa chỉ`.
- Cột 7 bảng hàng: `Thuế suất GTGT`, in `5%` (số nguyên) hoặc `8,5%` (có lẻ). Cột 1–6 rộng lại: `1,1 / 4,9 / 1,3 / 2,0 / 2,3 / 3,0 / 2,9` cm (tổng 17,5).
- Dòng ngày `Từ ngày dd tháng mm năm yyyy đến ngày ...` theo **mẫu in** (chữ thường, dòng thứ 2 dưới tiêu đề); bảng mô tả chỉ tiêu (4)(5) vẫn ghi `TỪ NGÀY ... THÁNG ...` viết hoa — mẫu in được chọn. Đổi lại viết hoa: sửa 1 dòng `row_title` trong script.
- **Chưa test hiển thị**: cần xem preview với `P_ROWS` = 3 và = 30 để xác nhận khối `Tổng cộng` / khối cuối (`OCOND FOOTER`, `PROTECT`) chỉ in ở cuối và không bị ngắt trang giữa chừng; xem cột `Thuế suất GTGT` có xuống dòng 2 dòng ở tiêu đề không.

#### Kết quả upload lần 1 (14/10/2026 17:30) và bản sinh lại lần 2

- Form `Active`; function module sinh ra `/1BCDWB/SF00000020` có đủ `IS_HEAD`, `IT_ITEM`, `IT_TAX` (khớp `PRINT_FORM`), các include sinh ra đều `R3STATE = A`. Chỉ có **4 cảnh báo vàng**, không có lỗi: `GV_QTY`, `GV_TAX`, `GV_TAXR`, `GS_TAX-TAXAMT` "has no defined value".
- Nguyên nhân (suy từ vị trí các node, chưa xác nhận với SAP): 3 biến `GV_*` được gán trong code node nằm trong ô bảng nên Form Builder không theo dõi được (biến `GV_FD`... gán ở code node cấp event thì không bị cảnh báo). `GS_TAX-TAXAMT` là symbol trực tiếp của work area table thứ 2, chưa rõ vì sao bị báo trong khi `GS_ITEM-*` không bị.
- **Bản sinh lại lần 2** (`gen_zsf_sd_bkblhhdv.py`): 4 biến `GV_QTY`, `GV_TAX`, `GV_TAXR`, `GV_TAXA` có Default Value `' '`; tiền thuế mỗi mức in qua biến `GV_TAXA` (`WRITE gs_tax-taxamt TO gv_taxa CURRENCY gs_tax-waerk` + `CONDENSE`) thay cho symbol `&GS_TAX-TAXAMT(C)&`. Cảnh báo không chặn nên bản upload lần 1 vẫn dùng được; bản lần 2 **chưa upload để xác nhận hết cảnh báo**.
- `sfgen.py` (skill `smartforms-xml`) đã thêm `DEFAULTVAL` cho `gdata` (phần tử thứ 4). `sf_validate.py` đối chiếu `ZWM_SF_PYCVT.xml` (FS_v1.0) chỉ còn báo thứ tự con của `GDATA` vì mẫu đó không có biến nào có Default Value; mẫu `ZWM_SF_PYCVT_EN.xml` (có `DEFAULTVAL`) cho thấy thứ tự `NAME, TYPING, TYPENAME, DEFAULTVAL` là đúng.

### Việc user phải làm — theo thứ tự

1. **SMARTFORMS**: nhập `ZSF_SD_BKBLHHDV` → Utilities → Upload form → chọn `Form/zsf_sd_bkblhhdv.xml` (copy ra đường dẫn ngắn như `C:\temp\` trước) → Activate. Chưa upload thì `PRINT_FORM` dump vì form trên hệ chưa có tham số `IT_TAX` và DDIC đã đổi.
2. Chạy `ZPG_SD_BKBLHHDV_TEST` xem preview, đối chiếu mẫu in trong FS (số: tổng 1.112.500, thuế 90.210, thanh toán 1.202.710, bằng chữ *Một triệu hai trăm lẻ hai nghìn bảy trăm mười đồng*).
3. Mở SE38 kiểm `ZIN_SD_BKBLHHDV_TOP` / `_F01` đã active (xem ghi chú trên).
4. Chạy `ZRSD08` với hoá đơn thật khi có data (DEV chưa có `VBRK`).

## Điểm FS còn thiếu / cần Bidiphar xác nhận

### (16) Ghi chú và (18) Chiết khấu sau — BA XÁC NHẬN BỎ (05/10/2026)

> **Cập nhật 14/10/2026 (FS mới):** (18) đã bị bỏ khỏi văn bản FS; cột (16) nay là **Thuế suất GTGT**, không còn là Ghi chú.
> Phần "KHÔNG xoá `GHICHU`/`DISCOUNT` khỏi DDIC, KHÔNG sửa layout Smart Form" bên dưới **hết hiệu lực** —
> vì form phải sinh lại theo FS mới, `GHICHU` và `DISCOUNT` bỏ khỏi DDIC cùng đợt sửa DDIC (`ddic_structures.md`).
> Giữ nguyên đoạn dưới để lưu vết.

- **Quyết định (BA, 05/10/2026, xác nhận miệng qua chat — FS V1.0 CHƯA cập nhật lại văn bản):**
  bỏ hẳn 2 chỉ tiêu (16) Ghi chú và (18) Chiết khấu sau khỏi phạm vi báo cáo. Không cần tìm
  nguồn `VBRP-ZZGHICHU` hay danh sách Item Category chiết khấu/hàng tặng nữa (2 câu hỏi 2, 3
  trong `cau_hoi_fs_ZRSD08.md` coi như đã trả lời — đánh dấu RESOLVED, không gửi nữa).
- **Phạm vi áp dụng (user chốt 05/10/2026):** chỉ dọn code/comment đang chờ nguồn dữ liệu.
  **KHÔNG xoá field `GHICHU`/`DISCOUNT` khỏi DDIC `ZST_RSD08_ITEM`/`ZST_RSD08_HEAD`** (đã activate
  trên hệ) và **KHÔNG sửa layout Smart Form** — 2 cột này tiếp tục tồn tại trên form, luôn in
  ra rỗng (16) / 0 (18), y như trạng thái trước đây, chỉ khác là không còn ghi "đang chờ chốt".
- Code liên quan: `Program/zin_sd_bkblhhdv_f01.abap` — `GET_BILLING_DATA` (16) không gán `GHICHU`
  nữa; `CALC_TOTAL` (18) vẫn `CLEAR GS_HEAD-DISCOUNT.`, công thức (21) = (17) + (20) − 0.
- Nếu sau này cần dọn dứt điểm (bỏ hẳn khỏi report, không chỉ để trống): phải xoá 2 component
  khỏi DDIC + sinh lại Smart Form XML + upload lại — **chưa làm, đợi user yêu cầu riêng.**

### Các điểm khác chưa xác nhận trên hệ thống

**Đã verify qua MCP `GUI_BDP_DEV_200` ngày 30.09.2026** (hệ DEV client 200,
`sapRelease=816`, `databaseSystem=HDB`, package Z của tổ chức là **`ZPK_BDP`**):

| Object | Dùng ở | Kết quả |
|---|---|---|
| `VBRP-ZZGHICHU` | (16) Ghi chú | ❌ **KHÔNG tồn tại** — `DD03L` không có field `ZZ*`/`*GHICHU*` nào trên VBRP |
| Condition type `ZRT1` | (14) Đơn giá | ✅ **có ở client 100** (`KAPPL = V`, verify 30.09.2026 bằng `USING CLIENT '100'`); ❌ không có ở client 200 (client 200 chỉ có customizing tối thiểu) |
| Condition type `MWAS` | (19)(20) Thuế GTGT | ✅ có, `KAPPL = 'V'` (Sales) — đúng cái cần |
| Message class `ZMC_SD` | `MESSAGE-ID ZMC_SD` | ❌ chưa có (hệ đang có `ZMC_VIETQR`, `ZMC_CTK` → convention `ZMC_` đúng) |
| Style `ZCORE_STYLE_REPORT` | Smart Form | ❌ **KHÔNG tồn tại** — đúng như nghi ngờ, đó là style của hệ HPDQ. Hệ BDP **không có style Z nào** (`STXSADM` rỗng với `Z%`) |
| Ký tự `B0`, `B5`, `N0` | Smart Form | ❌ phụ thuộc style trên → phải đổi |
| `ZST_RSD08_HEAD` / `_ITEM` | DDIC | ✅ đã tạo trong `ZPK_BDP` (tên CŨ, trước khi đổi sang `ZST_RSD08_*`) |
| 7 data element `ZDE_*` | DDIC | ✅ đã tạo đủ. **Lưu ý 2 cái lệch độ dài so với thiết kế:** `ZDE_GHICHU` = CHAR **255** (thiết kế 120), `ZDE_STT` = CHAR **4** (thiết kế 3); `ZDE_LOGO` = CHAR **3** (thiết kế 30 — **quá ngắn**, không chứa nổi `ZLOGO_<BUKRS>` dài 10 ký tự) |
| Đồ hoạ `ZLOGO_<BUKRS>` | (1) Logo | Chưa kiểm tra — cần nạp qua SE78 |

### Lỗi activate lần 1 (30.09.2026) — 12 lỗi, đã sửa hết

User activate `ZPG_SD_BKBLHHDV` trên DEV/200 báo 12 lỗi. Gom thành 4 nguyên nhân:

1. **`VBRP-ZZGHICHU` không tồn tại** (4 lỗi: dòng 161, 167, 232, 236) → đã **comment lại**
   khối `SELECT ... LT_NOTE` và khối `READ TABLE LT_NOTE`, cột (16) Ghi chú tạm để trống.
2. **`FILTER_BY_PARTNER CHANGING CT_VBRP TYPE STANDARD TABLE`** (6 lỗi: 258–280) —
   **bảng generic KHÔNG truy cập được component** (`CT_VBRP-VBELN` báo *"The specified type
   does not have a structure"*), kéo theo `LT_VBPA`/`LS_SB`/`LS_RG` cũng unknown vì câu
   `SELECT` chứa nó fail. → Khai `GTY_VBRP`/`GTT_VBRP` ở TOP, FORM nhận `TYPE GTT_VBRP`.
   Bỏ luôn `ASSIGN COMPONENT` và `FIELD-SYMBOLS <LFS_VBELN>` không còn cần.
3. **`PRCD_ELEMENTS-KBETR` KHÔNG phải kiểu `KBETR` cổ điển** (lỗi dòng 405) —
   trên S/4HANA nó là data element **`VFPRC_ELEMENT_AMOUNT` = DEC(24,9)**, còn `KBETR`
   truyền thống là P(6,2) → *"type P(13.9) is not compatible with line type P(6.2)"*.
   Đã đổi mọi khai báo sang `TYPE PRCD_ELEMENTS-KBETR`.
   **Bài học chung: trên S/4HANA không khai `TYPE KBETR` cho giá trị đọc từ
   `PRCD_ELEMENTS` — luôn tham chiếu trực tiếp `PRCD_ELEMENTS-<field>`.**
4. **`GET_ADRC_NAME` tham số `CV_NAME TYPE CHAR120`** (lỗi 488) — được gọi với
   `GS_HEAD-PAYERNM` (CHAR 100) → không tương thích. Đã đổi `CV_NAME`/`CV_ADDR`
   sang `TYPE CLIKE` (generic) để nhận mọi độ dài.

Ngoài ra đồng bộ code với data element thật user đã tạo: `STT TYPE ZDE_STT` (CHAR 4,
bộ đếm `LV_STT` nới lên `N LENGTH 4`), `GHICHU TYPE ZDE_GHICHU`, `LOGO TYPE ZDE_LOGO`,
`CNAME/NHATHUOC/PAYERNM/PAYERAD` theo `ZDE_*` tương ứng.

**Trạng thái:** include `ZIN_SD_BKBLHHDV_TOP` đã syntax check **sạch** trên DEV/200
(30.09.2026). `ZIN_SD_BKBLHHDV_F01` sửa xong ở local nhưng **chưa syntax check** vì
bản trên hệ còn là bản cũ — user cập nhật 2 include rồi check lại.

### Viết lại theo skill `abap-performance-hana` (30.09.2026)

Bản đầu dùng 7 câu `FOR ALL ENTRIES` (skill cấm trên HANA) + nhiều SELECT tách rời.
Đã viết lại `ZIN_SD_BKBLHHDV_F01`:

- `GET_BILLING_DATA`: **1 câu SELECT JOIN** VBRP, VBRK, MARA, MAKT, PRCD_ELEMENTS (ZRT1),
  MARM (2 lần: ĐVT bán, ĐVT điều kiện giá), VBPA (SB, RG), KNA1 → bảng `GT_VBRP` (global).
  Lọc nhà thuốc / payer nằm luôn trong WHERE → **bỏ FORM `FILTER_BY_PARTNER`**.
- `GET_HEADER_DATA`: rút header từ `GT_VBRP`, không đọc lại VBRK/VBPA. Thuế MWAS lấy bằng
  1 JOIN VBRK↔PRCD_ELEMENTS, lọc hoá đơn bằng `IN @LR_VBELN` (range). Công ty: JOIN TVKO↔T001.
- `GET_ADRC_ADDRESS`: JOIN ADRC↔T005U↔T005T thay 3 SELECT. ADRC thêm `DATE_TO >= sy-datum`.
- `CHECK_AUTHORITY`: 2 SELECT gộp thành 1 (`VKORG, VTWEG`).
- `CALC_TOTAL` chỉ còn (17), (18), (21); thuế (19)(20) tính ở `GET_HEADER_DATA`.

**Syntax check trên DEV/200 (nguồn ghép TOP + F01): sạch, không lỗi.**
Điểm cần test với data thật: nhà thuốc / payer NULL trong LEFT JOIN khi user để trống
select-option (range rỗng → không lọc, hoá đơn thiếu partner vẫn ra).

### Data test (30.09.2026)

**Toàn hệ DEV không có hoá đơn nào**: `VBRK` = 0 ở cả 4 client 050 / 100 / 300 / 500 (và 200);
`MARA`, `KNA1` cũng = 0 ở client 200 và 100. Hệ mới, chỉ có customizing.
Muốn test bằng data thật phải tạo master data (vật tư, khách hàng, partner SB/RG, giá `ZRT1`)
rồi VA01 → VF01 — chưa làm. Hướng thay thế: chương trình test đổ data mẫu từ FS vào form.
Program, Smart Form, DDIC, style là cross-client nên chạy được ở client 100.

### Test ở DEV/200 (client user đang làm) — customizing 30.09.2026

Client 200 (`Intergration Test`, `CCCORACTIV = 2` = **khoá customizing, chỉ nhận qua transport**) chỉ có
customizing chuẩn SAP, **thiếu toàn bộ customizing riêng của client 100**:

| Mục | Client 200 | Client 100 |
|---|---|---|
| Sales area | `0001/01/01`, `0002/01/01`, `0003/01/01` | `1000/10/99`... |
| Company code | `0001`, `0003` | `1000`... |
| `ZRT1`, pricing procedure `ZRVA01` | ❌ không có | ✅ |
| Loại đơn / loại hoá đơn `ZD01` / `ZFD1` | ❌ không có (chỉ `TA` → `F2`, chuẩn SAP) | ✅ |
| Plant | `0001`, `0003` | `1000`, `2000` |

Không tạo được `ZRT1` trực tiếp ở client 200 (customizing bị khoá). Test hoá đơn thật ở 200 thì
đơn giá (14) trống vì join `ZRT1` không ra; phải xin transport customizing từ client 100 sang.
Hướng không phụ thuộc data/customizing: chương trình test đổ data mẫu FS vào Smart Form.

### Bộ data test — chỉ áp dụng CLIENT 100 (tra customizing 30.09.2026)

| Mục | Giá trị | Nguồn |
|---|---|---|
| Sales area | VKORG `1000` / VTWEG `10` / SPART `99` | `ZRVA01` chỉ gán cho SPART 99 (`T683V`) |
| Company code / tiền | `1000` / VND | `TVKO` + `T001` |
| Plant | `1000` (hoặc `2000`) | `TVKWZ` |
| Loại đơn hàng | `ZD01` (KALVG `0` → pricing procedure `ZRVA01`) | `TVAK` |
| Loại hoá đơn | `ZFD1` "Invoice (DMS01)" — **không có `ZF2` và `F2` không dùng ZRVA01** | `TVFK`, `TVAK-FKARV` |
| Pricing procedure | `ZRVA01`: `ZRT1` ở step 130 | `T683S` |
| Partner | `SB`, `RG` đều có (partner type `KU`) | `TPAR` |
| Access sequence `ZRT1` | `PR02` | `T685` |

Chưa có sẵn: khách hàng, vật tư, bản ghi giá `ZRT1` (`KONP` = 0). Cần tạo: 1–2 khách hàng
(SB nhà thuốc, RG payer), 3 vật tư (có view Sales, plant 1000, ĐVT quy đổi `MARM`), giá `ZRT1` bằng VK11.
Số liệu theo mẫu FS: Biragan 500 H/16 (base `VNS`, bán `HOP` = 16 VNS, giá 35.200/HOP, 10 HOP → 160 × 2.200 = 352.000),
Bidicorbic 500 L/100 (`VNA`, 430, 400 → 172.000), Biracin E H/1 (`LO`, 11.770, 50 → 588.500); tổng 1.112.500.

**Điểm lệch FS ↔ customizing (ĐÃ GIẢI QUYẾT 14/10/2026):** `ZRVA01` tính thuế bằng **`MWST`** (step 450), không có `MWAS`.
FS mới đã đổi sang `MWST` cho cả (16) và (20) → code đọc `MWST`, hết lệch. (Bản cũ của FS ghi `MWAS`.)
Chưa rõ `ZD01` lập hoá đơn theo order hay theo delivery — nếu theo delivery phải VL01N + xuất kho (cần tồn kho).

### Test Smart Form bằng data mẫu — `ZPG_SD_BKBLHHDV_TEST` (30.09.2026)

`Program/zpg_sd_bkblhhdv_test.abap`: đổ 3 dòng mẫu FS (tổng 1.112.500, thuế 5%, thanh toán 1.168.125) vào form,
xem preview; `P_ROWS` > 3 để thêm dòng test xuống trang. Không đọc SD nên chạy được ở client 200. Syntax check sạch.
Tiền VND lưu ×100 (`TCURX-CURRDEC = 0`: 352.000 VND = `3520.00`) — chương trình test nạp đúng dạng đó.

Cần soi trên preview:
- **Tiền VND**: dòng Biragan phải ra `352.000`, không phải `3.520`. Item khai `@Semantics.amount.currencyCode = 'zst_rsd08_head.waerk'`
  (tham chiếu sang structure khác) — Smart Form có thể **không tìm được currency** cho dòng bảng → sai 100 lần.
- **`ZST_RSD08_HEAD-TAXRATE` là CURR có currency reference** nhưng thuế suất là phần trăm, không phải tiền →
  với VND (0 số lẻ) `5` có thể in thành `0` hoặc `0,05`. **Nên đổi sang kiểu DEC (vd DEC 5,2, bỏ currency reference).**
- Logo `ZLOGO_<BUKRS>`: chưa thấy đồ hoạ nào trên hệ (`STXBITMAPS` không có `ZLOGO%`) → form sẽ báo thiếu đồ hoạ.
- Ngày `TỪ NGÀY dd THÁNG mm NĂM yyyy`, tên hàng dài xuống dòng, khối 3 ô ký không bị ngắt trang.

### Lỗi test Smart Form: "Reference field GS_ITEM-KBETR unknown in form" (30.09.2026)

Smart Form tìm trường tham chiếu currency/quantity **trong cùng structure của work area**. `ZST_RSD08_ITEM-KBETR`/`NETWR`
đang trỏ `ZST_RSD08_HEAD-WAERK` (structure khác) → form không biết. **Sửa DDIC:**

1. `ZST_RSD08_ITEM`: thêm component **`WAERK`** (type `WAERK`, desc `Currency Key`) ở cuối.
2. Tab Currency/quantity fields của `ZST_RSD08_ITEM`: `KBETR` và `NETWR` → Ref table `ZST_RSD08_ITEM`, Ref field `WAERK`
   (`MENGE` giữ `ZST_RSD08_ITEM-MEINS`).
3. `ZST_RSD08_HEAD`: **`TAXRATE` bỏ currency reference**, đổi sang kiểu DEC (tạo `ZDE_TAXRATE` = DEC 5,2)
   vì thuế suất là %, không phải tiền. 4 field tiền còn lại (`TOTAL`, `DISCOUNT`, `TAXAMT`, `AMTPAY`) giữ ref `ZST_RSD08_HEAD-WAERK`.
4. Activate 2 structure rồi activate lại table type `ZTT_RSD08_ITEM` và form.

Code đã gán `WAERK` từng dòng (`GET_BILLING_DATA`, chương trình test). Thứ tự: sửa DDIC **trước**, rồi mới cập nhật code trên hệ.

### Preview lần 1 vs mẫu FS (30.09.2026) — đã sinh lại form V2

Tiền VND in **đúng** (352.000 / 2.200 / 1.112.500) → sửa DDIC `WAERK` ở dòng hàng có hiệu quả. Các khác biệt tìm thấy và cách xử lý:

| Vấn đề trên preview | Nguyên nhân | Xử lý |
|---|---|---|
| Ngày "TU NGAY 20 THANG 8. NAM 01.0" | `&DATE+6(2)&` cắt trên chuỗi **đã format** dd.mm.yyyy | code node tách `GV_FD/FM/FY...` từ giá trị thô |
| Logo rất nhỏ | node `RESOLUTION 600` mà ảnh 100 DPI | sinh `RESOLUTION 100` (3,07 × 1,68 cm) |
| Header không có khung, tiêu đề rời bảng | header là window riêng, không viền | gộp vào **cùng 1 table**: Header event (folder `FPAGE`) — bố cục 2 cột logo/tên như mẫu |
| Dòng cộng: số tiền rơi vào cột Đơn giá | ô số tiền đặt sai cột | line type `S1`/`S2` chia cột đúng (nhãn cột 1-3, số tiền cột Thành tiền) |
| `***` ở cột ĐVT | `T006A` không có đơn vị `VNS`/`VNA`/`LO` cho ngôn ngữ EN | chương trình test dùng `ST`/`KG`/`L`; **dữ liệu thật cần `T006A` có đơn vị đúng ngôn ngữ đăng nhập** |
| Số/tiền ở ô căn phải nằm dòng dưới, dòng cao gấp đôi | **KHÔNG phải do đoạn `R`** (đã đọc style XML: `R` = RIGHT, không có khoảng cách). Symbol kiểu tiền/số lượng xuất kèm **khoảng trắng đệm** bằng độ rộng field → vượt bề rộng ô nên xuống dòng | thêm tuỳ chọn `(C)` cho mọi symbol số: `&GS_ITEM-NETWR(C)&` |
| Chữ `TH##NG`, `C#`, `PH#N` | thiết bị `LP01` (HP LaserJet III) không có font tiếng Việt | không phải lỗi form; test bằng PDF / thiết bị có font Unicode |
| `500 %` | `TAXRATE` vẫn là kiểu tiền có currency reference | đổi DEC 5,2 (xem mục lỗi Reference field) |

Số lượng: nguyên → bỏ phần thập phân (`160`), lẻ → 3 số lẻ (code node `GV_QTY`). STT bỏ số 0 đầu (`(Z)`).
Khối cộng + ngày + chữ ký nằm trong Footer event (folder `PROTECT` + điều kiện `FOOTER` theo mẫu team) — **cần test `P_ROWS` = 30** để xác nhận không lặp ở mỗi trang.

### Đối chiếu với style `ZCORE_STYLE_REPORT` thật (file `Form/sfstyle-zcore_style_report.xml`, 30.09.2026)

Ký tự: `B0` = đậm **10**, `B1` = đậm **11**, `B2` = đậm **12**, `B5` = đậm **15**, `N0` = thường 10, `N1` = thường 11. FS yêu cầu cỡ 11, tiêu đề 12
→ form V3 dùng `N1` (thường), `B1` (đậm), `B2` (tiêu đề); V1/V2 dùng nhầm `B0` (10) và `B5` (15).
Đoạn: `C` CENTER, `L` LEFT, `R` RIGHT (đều 1 dòng, không space before/after).

### Kiểm tra toàn chương trình sau khi form in đúng (30.09.2026)

Form `ZSF_SD_BKBLHHDV` in đúng (bố cục, tiền VND, tiếng Việt sau khi sửa `LP01` → `SWINCF`/`G`/`__DEFAULT`). `ZPG_SD_BKBLHHDV` (+ 2 include trên hệ) syntax check **sạch**,
nhưng **chưa chạy với hoá đơn thật** (không client nào có `VBRK`).

Lỗi tìm thêm khi rà (syntax check không bắt được):
- **`M_IS_VTWEG` không có trường `ACTVT`** (chỉ `MCINF` + `VTWEG`, tra `TOBJ`) → `AUTHORITY-CHECK ... ID 'ACTVT'` cho `SY-SUBRC = 12` với MỌI user, chặn không ai in được. Đã sửa: `ID 'MCINF' DUMMY ID 'VTWEG' FIELD ...`. **Cập nhật `ZIN_SD_BKBLHHDV_F01` lên hệ.**
- **Message class `ZMC_SD` chưa tạo** (`T100A`, `T100` không có) — code dùng `MESSAGE E001(ZMC_SD)`. Tạo ở SE91: message `001` = `&1 &2 &3 &4`.
- **Tcode `ZRSD08` chưa tạo** (`TSTC` không có) — SE93, chương trình `ZPG_SD_BKBLHHDV`.

Còn treo theo FS (cần Bidiphar / consultant SD): `ZRT1` chưa có ở client 200, loại hoá đơn `ZF2` (FS) không tồn tại,
search help tham số theo FS. (Thuế `MWAS` vs `MWST` đã hết treo — FS mới dùng `MWST`.)
Chỉ tiêu (16) Ghi chú và (18) Chiết khấu sau: **đã chốt bỏ (05/10/2026)**, không còn treo — xem mục đầu file.

### Việc phải xử lý trước khi activate

1. **`ZDE_LOGO` CHAR 3 là lỗi chặn** — chuỗi `ZLOGO_1000` dài 10 ký tự sẽ bị cắt cụt,
   Smartform không tìm được đồ hoạ. Sửa thành CHAR 30 trong SE11.
2. **Chỉ tiêu (16) Ghi chú không có nguồn dữ liệu** — FS nói lấy `VBRP-ZZGHICHU`
   ("custom field trên bảng chứng từ, không lấy theo Text ID") nhưng field đó chưa tồn tại.
   Phải hỏi Bidiphar: tạo append structure cho VBRP, hay đổi sang đọc Text ID?
3. **Chỉ tiêu (14) Đơn giá không có nguồn** — condition type `ZRT1` chưa có trên DEV200.
   Hỏi Bidiphar tên condition type thật của giá bán lẻ (hoặc `ZRT1` mới chỉ có trên hệ khác).
4. **Smart Form phải đổi style** — `ZCORE_STYLE_REPORT` không có trên BDP, và hệ này
   không có style Z nào. Hai hướng: dùng style chuẩn SAP (`SYSTEM`), hoặc lấy style thật
   từ 1 trong 19 form `ZFI_SF_*` đang chạy trong `ZPK_BDP` (style nằm trong XML nội dung
   form, phải đọc form chứ không query bảng được).
5. Tạo message class `ZMC_SD` (SE91) với message 001.

### Lỗi trong FS đã tự sửa khi code

- **Chỉ tiêu (1) Logo:** FS viết *"đọc TVKO với VKORG bằng **LIKP**-VKORG"* — sai,
  `LIKP` là bảng Delivery. Báo cáo này chạy trên Billing Document nên code dùng
  **`VBRK-VKORG`**. Xem `GET_HEADER_DATA`.

### Thuế suất (16)/(19.1) — cách quy đổi cần kiểm chứng

`PRCD_ELEMENTS-KBETR` lưu thuế suất dạng phần trăm nhân 10 (5% → 50).
Code chia 10 ở 2 chỗ: `GET_BILLING_DATA` (`ITEM-TAXRATE`) và `GET_TAX_SUMMARY` (`LV_RATE`). Bằng chứng gián tiếp:
`KONP` của MWST trên DEV/100 có `150.00` / `70.00` (15 % / 7 %). **Cần xác nhận trên hoá đơn thật của BDP** —
nếu hệ thống lưu khác thì sửa đúng 2 chỗ trên.

## Quy ước đặt tên đang áp dụng

Theo bảng "Naming Convention ABAP Cloud" trong `.claude/CLAUDE.md` — user chốt 29/09/2026
áp dụng **cho cả project On-Premise này**, không riêng ABAP Cloud.

**Tên object mô tả CHỨC NĂNG, không dùng Tcode** (user chốt 29/09/2026).
`BKBLHHDV` = **B**ảng **K**ê **B**án **L**ẻ **H**àng **H**oá **D**ịch **V**ụ.
Lý do: nhìn `ZSD_PG_RSD08` không biết chương trình làm gì, phải tra Tcode mới hiểu.

| Object | Tên | Prefix |
|---|---|---|
| Report | `ZPG_SD_BKBLHHDV` | `ZPG_<module>_` |
| Include TOP | `ZIN_SD_BKBLHHDV_TOP` | `ZIN_<module>_` |
| Include F01 | `ZIN_SD_BKBLHHDV_F01` | `ZIN_<module>_` |
| Smart Form | `ZSF_SD_BKBLHHDV` | `ZSF_<module>_` |
| Structure header | `ZST_RSD08_HEAD` | `ZST_` |
| Structure item | `ZST_RSD08_ITEM` | `ZST_` |
| Table type | `ZTT_RSD08_ITEM` | `ZTT_` |
| Data element | `ZDE_*` | `ZDE_` |
| Message class | `ZMC_SD` | `ZMC_` |
| Tcode | `ZRSD08` | *(theo danh mục Bidiphar)* |

`ZST_`/`ZTT_`/`ZDE_`/`ZMC_` lấy từ bảng "Naming Convention ABAP Cloud" trong
`.claude/CLAUDE.md` — user chốt áp dụng cho cả project On-Premise này.
`ZPG_`/`ZIN_`/`ZSF_` không có trong bảng đó (object chỉ có ở On-Premise) nên đặt theo
cùng logic: `Z<loại>_<module>_<viết tắt chức năng>`.

> **Lưu ý:** Data element đã tạo trên DEV/100 là `ZDE_STT` và `ZDE_GHICHU` — tên chung,
> không gắn BKBLHHDV, để dùng lại được ở report khác. Giữ nguyên.

## Danh sách file đã tạo

```
CodeABAP/BDP/ZRSD08/
├── FS/BIDIPHAR_FS_SD_ZRSD08_...V1.0.docx       (FS cũ 09/09/2026)
├── FS/BIDIPHAR_FS_SD_ZRSD08_...V1.0 (1).docx   (FS MỚI, đã bàn với user — bản đang theo)
├── ghi_chu.md                           (file này)
├── cau_hoi_fs_ZRSD08.md                 Câu hỏi/thông báo cho BA
├── Program/
│   ├── zpg_sd_bkblhhdv.abap                Report chính (Tcode ZRSD08)
│   ├── zpg_sd_bkblhhdv_test.abap           Test Smart Form bằng data mẫu FS
│   ├── zin_sd_bkblhhdv_top.abap            TABLES, TYPES, global data, selection screen
│   ├── zin_sd_bkblhhdv_f01.abap            Toàn bộ logic xử lý
│   └── ddic_structures.md               DDIC cần tạo/sửa (HEAD, ITEM, TAX + data element)
└── Form/
    ├── gen_zsf_sd_bkblhhdv.py              Script sinh form
    └── zsf_sd_bkblhhdv.xml                 File upload SMARTFORMS
```

## Thứ tự triển khai

1. SE11: tạo/sửa `ZST_RSD08_HEAD`, `ZST_RSD08_ITEM`, `ZST_RSD08_TAX`, `ZTT_RSD08_TAX` + 2 data element mới (xem `Program/ddic_structures.md`)
2. SE91: `ZMC_SD` (message 001) — đã có trên DEV/100
3. SE78: nạp logo `ZLOGO_<mã công ty>`, nhóm GRAPHICS / BMAP / BCOL
4. SMARTFORMS: nhập `ZSF_SD_BKBLHHDV` → Utilities → Upload form → chọn `Form/zsf_sd_bkblhhdv.xml` → Activate
   - Copy file ra đường dẫn ngắn (VD `C:\temp\`) trước khi upload
5. SE38: tạo `ZPG_SD_BKBLHHDV` + 2 include, syntax check, activate
6. SE93: gán Tcode `ZRSD08`
7. Chạy thử, đối chiếu với mẫu in ở mục "Mẫu báo cáo/chứng từ" của FS

## Trạng thái

- [x] Đọc FS cũ, bóc tách 22 chỉ tiêu
- [x] Viết chương trình (3 file ABAP)
- [x] Sinh Smart Form XML (theo FS cũ)
- [x] Đối chiếu FS mới ↔ FS cũ, sửa `TOP` + `F01` + `zpg_sd_bkblhhdv_test` theo FS mới (14/10/2026)
- [x] Syntax check bản local mới (DDIC mới giả bằng type cục bộ): sạch
- [x] DDIC (HEAD, ITEM, TAX, 2 data element, 2 table type) tạo/sửa + activate trên DEV/100, TR `DEVK900197` (14/10/2026)
- [x] Include TOP/F01 + chương trình test ghi lên DEV/100; ATC 0 lỗi (14/10/2026)
- [x] Smart Form sinh lại theo FS mới, `sf_validate` PASS (14/10/2026)
- [x] User upload `Form/zsf_sd_bkblhhdv.xml` (bản lần 2, có Default Value) lên SMARTFORMS + activate — user báo OK (14/10/2026)
- [ ] **Code xong theo FS mới, còn kiểm thử**: xem preview bằng `ZPG_SD_BKBLHHDV_TEST` (`P_ROWS` = 3 và 30) và chạy `ZRSD08` với hoá đơn thật (DEV chưa có `VBRK`); kiểm `KBETR / 10` của MWST trên `PRCD_ELEMENTS` thật
- [ ] **Nạp logo `ZLOGO_1000` (SE78)** — `STXBITMAPS` trên DEV/100 chỉ có `ZLOGO_0001` (14/10/2026); công ty thật là `1000` nên form in ra thiếu logo. Hướng dẫn từng bước: xem câu trả lời ngày 14/10/2026 / mục "Thứ tự triển khai" bước 3
- [ ] Bật lại `PERFORM CHECK_AUTHORITY` ở `AT SELECTION-SCREEN` của chương trình chính (đang comment trên hệ) khi test xong
- [ ] Release TR `DEVK900197` (user làm)
- [x] ~~Chờ Bidiphar chốt Item Category cho chỉ tiêu (18)~~ — BA bỏ (18); FS mới đã bỏ khỏi văn bản

Sau lần upload/test đầu tiên: cập nhật mục này và ghi lỗi/kết quả thật vào
`_ghichu_local.md` (mục On-Premise).
