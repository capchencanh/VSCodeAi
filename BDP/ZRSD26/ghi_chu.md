# Ghi chú dự án ZRSD26 — Báo cáo tổng hợp chi phí vận chuyển (Bidiphar)

FS: `FS/BIDIPHAR_FS_SD_ZRSD26_BaoCaoTongHopChiPhiVanChuyen_V1.0.docx` (V1.0, Nguyễn Thị Anh Thư)
Đọc & kiểm tra FS lần đầu: 01/10/2026. Cập nhật theo FS mới (V1.0 bản 3): 15/10/2026.

## Trạng thái cuối phiên 15/10/2026 (đọc mục này trước)

**Xong:** code theo FS mới đã nằm trên DEV (TR request `DEVK900205`, task `DEVK900206` mang tên "CS_DanhDH_01.10.2026_Create ZRSD26"). `SyntaxCheck` sạch, ATC 0 finding. User đã **chạy thử trên DEV/200 và thấy đúng dự kiến** (2 dòng, mỗi dòng doanh số hiển thị 350.000, tổng 700.000, (14)(15) = 0, tỷ lệ `0,000%`). Chi tiết thay đổi: mục "Cập nhật theo FS mới 15/10/2026"; dữ liệu test: mục "Dữ liệu test trên DEV/200".

**Đã sửa thêm khi user test trên SAP GUI (ngoài FS):**
- 2 thanh công cụ: status `STANDARD` copy từ status chuẩn ALV mang theo thanh nút ALV list → user xóa hết Application Toolbar ở SE41, giữ Function Keys.
- Nút Back không thoát: thêm dòng `MODULE EXIT_COMMAND_0100.` (không có `AT EXIT-COMMAND`) dưới dòng `AT EXIT-COMMAND` trong flow logic screen 0100. Mã `&F15` (Exit) đã được user thêm vào `ZIN_SD_THCPVC_PAI` trực tiếp trên SAP; local `zin_sd_thcpvc_pai.abap` có cùng nội dung (chỉ khác chữ hoa `OR`).
- Tiêu đề dài > 40 ký tự: chỉ có `REPTEXT`, trên ALV vẫn hiện (bị cắt `...` theo độ rộng cột, user kéo rộng được).

**Còn lại (không phải việc dev):**
- Tư vấn cấu hình `ZFR1`/`ZFR2` + thủ tục tính giá để `KZWI4` = (14)+(15), gán `MARC-MFRGR` cho vật tư; khi có hóa đơn mới thì test lại cột (14)(14.1)(15)(15.1)(16), chiều (7)(8) và dấu âm hóa đơn `VBTYP = O`.
- User release TR `DEVK900205` sau khi test xong.
- Điểm nên thông báo BA: xem mục "Điểm nên THÔNG BÁO BA" trong "Cập nhật theo FS mới" (chiết khấu sau, mâu thuẫn `VBTYP = O` với ví dụ (13), `VBKD-KVGR2`).
- Optional: tách tiêu đề cột dài hơn / `CWIDTH_OPT` nếu BA yêu cầu thấy đủ tiêu đề.

## Tóm tắt

Báo cáo **ALV Grid**, A4 ngang. Chỉ đọc, không ghi.
FS V1.0 bản đầu: 18 chỉ tiêu, 10 tham số. **FS mới (V1.0 bản 3, đã bàn với user): 19 cột (17 chỉ tiêu + 14.1 + 15.1), 9 tham số** — xem mục "Cập nhật theo FS mới 15/10/2026".
Nguồn: hoá đơn bán hàng (`VBRK` + `VBRP` + `PRCD_ELEMENTS`).

**Đặc điểm khác 2 báo cáo trước: đây là báo cáo CỘNG DỒN (aggregate).**
1 dòng báo cáo = 1 tổ hợp **5 chiều**: khu vực (`VBRP-VKGRP`), chi nhánh (`VBRP-VKBUR`),
vùng vận chuyển (`KVGR2`), loại hàng hoá vận chuyển (`MARC-MFRGR`), kênh bán hàng (`VBRK-VTWEG`).
Các dòng hoá đơn cùng tổ hợp được cộng dồn. Có dòng tổng cuối báo cáo.

→ Nên **push down GROUP BY xuống HANA** thay vì đọc hết rồi cộng bằng ABAP (skill `abap-performance-hana`).

## Kết quả kiểm tra object trên DEV/200 (01/10/2026)

**Có đủ:**

| Nhóm | Object |
|---|---|
| Field `VBRP` | `VKGRP`, `VKBUR`, `KZWI4`, `NETWR`, `WERKS`, `MATNR`, **`KVGR2`** |
| Field `VBRK` | `VBTYP`, `FKSTO`, `KUNAG`, `WAERK`, `KNUMV` |
| Bảng diễn giải | `TVGRT`, `TVKBT`, `TVV2T`, `TMFGT`, `TVTWT` |
| Khác | `MARC-MFRGR`, `MARA-MFRGR`, `PRCD_ELEMENTS` |
| Authorization object | `V_VBRK_VKO` (VKORG + ACTVT), `M_IS_VTWEG` (MCINF + VTWEG) |

**Lệch so với FS — phải xử lý khi code:**

1. **`VBKD-KVGR2` KHÔNG tồn tại** (FS chỉ tiêu (5) ghi *"[Table] VBKD đọc theo khoá VBELN và POSNR, với POSNR bằng '000000'"*).
   Trên hệ `KVGR2` có ở **`VBRP`**, `VBAK`, `KNVV` — không có ở `VBKD`. `VBKD` cũng rỗng (0 dòng).
   → **Dùng `VBRP-KVGR2`** (sẵn trên dòng hoá đơn, khỏi join thêm bảng). Cần báo FS sửa lại.
2. **`M_IS_VTWEG` KHÔNG có trường `ACTVT`** (chỉ `MCINF` + `VTWEG`) — y hệt bài học ZRSD08.
   → `AUTHORITY-CHECK ... ID 'MCINF' DUMMY ID 'VTWEG' FIELD ...`, **không** thêm `ACTVT`.
   Ngược lại `V_VBRK_VKO` **có** `ACTVT` → phải truyền.
3. **Condition type `ZFR1`, `ZFR2` chưa có ở client 200** (`T685` không có `ZF*` nào với KAPPL = V).
   Giống `ZRT1` của ZRSD08 — có thể chỉ có ở client 100 hoặc chưa transport.
   → Chỉ tiêu (14)(15) sẽ bằng 0 cho tới khi có customizing.
4. **Loại hoá đơn `ZF2`, `ZRE` (giá trị mặc định của tham số 2) chưa có ở client 200** — chỉ có `F2` chuẩn SAP.
   → ~~Để mặc định theo FS~~ **[15/10/2026] FS mới đã bỏ giá trị mặc định này**; client 100 cũng không có `ZF2`/`ZRE`.

## Điểm FS cần làm rõ

1. **Chỉ tiêu (16) nói `KZWI4` = (14) + (15), nhưng đó là giả định về cấu hình pricing procedure.**
   `KZWI4` (Subtotal 4) chỉ chứa đúng tổng đó nếu procedure được cấu hình gán ZFR1 + ZFR2 vào Subtotal 4.
   Chưa verify được vì chưa có `ZFR1`/`ZFR2` trên hệ. Khi có data phải đối chiếu `KZWI4` với `(14)+(15)`.
2. **Chỉ tiêu (13)(14) — quy tắc dấu âm:** FS nói dòng của hoá đơn `VBTYP = 'O'` lấy giá trị âm.
   Cần xác nhận: `KZWI4` ở chỉ tiêu (16) có đổi dấu theo không (FS không nói rõ, chỉ nói (14) theo dấu của (13)).
3. ~~**Tham số (10) "Dạng hiển thị"**~~ **[ĐÃ XỬ LÝ 15/10/2026]** FS mới bỏ hẳn tham số này (cả hình 4); code đã bỏ `P_ALV`/`P_XLS`.
4. **Chỉ tiêu (18) Loại tiền:** FS ràng buộc *"các hoá đơn cộng dồn trên cùng một dòng báo cáo phải cùng một loại tiền"*
   nhưng không nói xử lý thế nào nếu khác nhau (báo lỗi, hay tách dòng, hay bỏ qua).

## Code đã viết (01/10/2026)

`Program/`: `zpg_sd_thcpvc.abap` (chính) + `zin_sd_thcpvc_top.abap` (types/tham số) +
`zin_sd_thcpvc_f01.abap` (logic) + `zin_sd_thcpvc_f02.abap` (ALV). Đủ 18 chỉ tiêu, 10 tham số.

**Cộng dồn đẩy xuống HANA (01/10/2026):** gộp thành **1 câu SQL** `WITH +FR AS (...) SELECT ... GROUP BY` trả thẳng
ra `GT_ALV`. Doanh số, chi phí vận chuyển ZFR1/ZFR2, diễn giải 5 chiều (LEFT JOIN `TVGRT/TVKBT/TVV2T/TMFGT/TVTWT`)
đều tính trên HANA. CTE `+FR` cộng ZFR1/ZFR2 theo từng dòng hoá đơn (KNUMV+KPOSN) trước khi nối vào VBRP —
nối thẳng `PRCD_ELEMENTS` sẽ nhân đôi doanh số khi 1 dòng có nhiều dòng điều kiện. Dấu âm hoá đơn trả hàng
(`VBTYP = 'O'`) xử lý bằng `CASE` trong SQL. ABAP chỉ còn 1 vòng LOOP gán Từ/Đến ngày và tỷ lệ.
Chưa chạy được câu SQL trên HANA (hệ chưa có hoá đơn, `RunQuery` không nhận `WITH`) — mới qua SyntaxCheck.

**ALV: `CL_GUI_ALV_GRID`** (user chốt 01/10/2026 — để sau này mở rộng được: thêm nút, cho sửa ô,
bắt sự kiện; `CL_SALV_TABLE` chỉ xem, đổi sau phải viết lại toàn bộ phần hiển thị).
Làm theo mẫu team trong `ZPK_BDP` (`ZCO_IN_PC_BCGTTT_A_D01/PBO/PAI`): screen 0100 + custom container
`CONTAINER`, PF-STATUS `GUI`, TITLEBAR `TITLE`, `SET_TABLE_FOR_FIRST_DISPLAY` + field catalog.
Dòng tổng (13)-(16) bằng `DO_SUM`. Toolbar chuẩn đã có xuất Excel; đã loại các nút sửa dòng vì báo cáo chỉ đọc.

File (5 include): `..._top` (types + tham số + khai báo ALV), `..._pbo`, `..._pai`,
`..._f01` (logic), `..._f02` (CREATE_OBJECT + ALV + field catalog).
Mẫu team có include `D01` riêng cho khai báo ALV — **user không muốn tách D01**, đã gộp vào TOP/F02.

**Chưa syntax check được** — chương trình chưa tạo ở SE38 nên cờ **Fixed point arithmetic đang TẮT**,
mọi câu SQL có `@` host variable bị chặn (đã gặp ở ZRSD25, xem `_ghichu_local.md`).
→ **Việc phía user:**
1. SE38: tạo `ZPG_SD_THCPVC` + **5 include**, BẬT Fixed point arithmetic (Attributes).
2. **SE51: tạo screen 0100** (Normal), kéo 1 **Custom Control** tên `CONTAINER` chiếm hết màn hình.
   Flow logic: `MODULE STATUS_0100` ở PBO, `MODULE EXIT_COMMAND_0100 AT EXIT-COMMAND` ở PAI.
3. **SE41: PF-STATUS `GUI`** (copy từ `ZSTANDARD_FULLSCREEN` hoặc status của `ZCO_PG_PC_BCGTTT_A`) + **TITLEBAR `TITLE`**.
4. Selection text 9 tham số (SE38 → Text Elements). **Tên cột / tiêu đề lưới / tiêu đề khối viết thẳng trong code**,
   không dùng text symbol (user chốt 01/10/2026 — chỉnh ở code tiện hơn). Tcode `ZRSD26` (SE93).
Message class `ZMC_SD` đã có.

**Quyết định của user (01/10/2026):** FS còn đang hoàn thiện và hệ thiếu data → code đúng FS trước.
Chỉ tiêu (16) lấy thẳng `KZWI4` theo FS; (18) lấy `VBRK-WAERK` theo FS, không thêm xử lý khi khác loại tiền;
dạng hiển thị làm ALV trước (toolbar ALV đã có sẵn chức năng xuất bảng tính).
**Riêng `VBKD-KVGR2` của FS không tồn tại trên hệ → bắt buộc dùng `VBRP-KVGR2`.**

## Cập nhật theo FS mới 15/10/2026

FS cũ: `FS/..._V1.0.docx`; FS mới: `FS/..._V1.0 (3).docx` (bảng ghi nhận thay đổi trong file chưa cập nhật, vẫn chỉ dòng "Tạo mới" 09/09/2026).
Chỉ sửa **local** (`Program/`), **chưa ghi lên SAP**. Trên DEV/100 đang có bản cũ (program + 5 include `ZPK_BDP`, đã có từ lần trước).

**Khác biệt FS mới so với FS cũ, và việc đã làm ở code local:**

| # | FS mới | Code local |
|---|---|---|
| 1 | Thêm chỉ tiêu **(14.1)** Tỷ lệ chi phí vận chuyển theo tỷ lệ chuẩn = (14) / (13) × 100, trái/CHAR, kèm `%`, 3 số lẻ, (13) = 0 thì để trống | Thêm cột `RATE1` (CHAR 12) sau `FREIGHT1`; tính ở FORM `FORMAT_RATE` (`DECFLOAT34`, `\|{ … DECIMALS = 3 NUMBER = USER }%\|`) |
| 2 | Thêm chỉ tiêu **(15.1)** Tỷ lệ chi phí vận chuyển theo chi phí bổ sung = (15) / (13) × 100, cùng định dạng | Thêm cột `RATE2` sau `FREIGHT2` |
| 3 | **(17) Tỷ lệ chi phí được duyệt** bị gạch bỏ; **Loại tiền** thành (17) (cũ là (18)) | Bỏ field `RATE` (= KZWI4 / NETWR) và phép tính; `WAERK` giữ nguyên |
| 4 | Bỏ tham số **(10) Dạng hiển thị** (ALV / Bảng tính) và hình 4 | Bỏ `P_ALV`, `P_XLS`, khối `BL2` cũ; còn **9 tham số** |
| 5 | Tham số **Loại hóa đơn**: bỏ giá trị mặc định `ZF2`, `ZRE`; vẫn bắt buộc | Bỏ phần gán mặc định trong `SET_DEFAULT_DATE`; `S_FKART` vẫn `OBLIGATORY` |
| 6 | (13) Doanh số: thêm "hóa đơn điều chỉnh **tăng**/giảm giá" vào nhóm `VBTYP = 'O'` lấy âm, thêm dòng **"Loại trừ Chiết khấu sau"** và ví dụ 10.000.000 + 200.000 − 500.000 = 9.700.000; bỏ dòng nguồn `VBRK-FKSTO` trong bảng nguồn (ràng buộc loại FKSTO = 'X' vẫn còn ở mục *Những yêu cầu khác*) | **Không đổi code.** Xem giả định 1, 2 bên dưới |
| 7 | Mục đích: thêm 2 câu lưu ý (xin duyệt chi phí bổ sung không cài từ đầu trên Billing thì không lên báo cáo; duyệt chi phí bên ngoài không có trường để cập nhật chi phí được duyệt) | Không đổi code, chỉ là phạm vi |
| 8 | Bỏ câu "Dòng cuối báo cáo in tổng (13)–(16)…" | Giữ `DO_SUM` cho (13)(14)(15)(16): FS vẫn cho phép ALV cộng nhóm; cột tỷ lệ ở dòng tổng để trống. Xem giả định 3 |
| 9 | Hình 3 (màn hình tham số) 2 khối: **Hóa đơn bán hàng** (1)–(5), **Chiều phân tích** (6)–(9) — hình này không đổi so với FS cũ, nhưng code cũ gộp 1 khối | Tách `BL1` "Hóa đơn bán hàng" (Ngày hóa đơn, Loại hóa đơn, Tổ chức bán hàng, Kênh bán hàng, Mã khách hàng) và `BL2` "Chiều phân tích" (Khu vực, Chi nhánh, Vùng vận chuyển, Loại hàng hóa vận chuyển) |
| 10 | Mục tài liệu tham khảo: Bidiphar_SD_REPORT_SD 1.2 → 1.3 | Không liên quan code |

Thứ tự cột ALV hiện tại bám hình 6: (9)(10)(11)(12)(13)(14)**(14.1)**(15)**(15.1)**(16)(17).

**Kết quả kiểm tra trên DEV/100 (15/10/2026, chỉ đọc):**
- `ZPG_SD_THCPVC` + 5 include đã tồn tại trong `ZPK_BDP` (bản cũ).
- `VBKD-KVGR2` vẫn **không có** (`DD03L`: chỉ `VBRP-KVGR2`) → vẫn dùng `VBRP-KVGR2`, FS vẫn ghi `VBKD` (chưa sửa).
- Condition type `ZFR1`, `ZFR2` **không có ở client 100** (`T685`/`T685T`); chỉ có `ZFRE` "CP Vận chuyển (UT)" → (14)(14.1)(15)(15.1) bằng 0 cho tới khi BA cấu hình. `VBRK` 0 dòng, `PRCD_ELEMENTS` không có `ZFR1/ZFR2`.
- Loại hóa đơn (`TVFK`/`TVFKT`): `ZF2`, `ZRE` **không tồn tại**. Có: `ZFL1` "HD DC tang CNo" (`VBTYP = P`), `ZFC1` "HD DC giam CNo", `ZFC3` "HD giam gia HB", `ZFR*` "HD tra…", `ZFW*` (đều `VBTYP = O`); nhóm có vẻ là chiết khấu sau: `ZFC2` CKTM, `ZFC4` CK bằng tiền, `ZFC6`/`ZFC7` trừ trước/ứng trước CKTM, `ZFC8` ứng trước CK tiền, `ZFC9` QT bổ sung CK (đều `VBTYP = O`). Condition type chiết khấu: `ZNCK`/`ZPCK` (CKTM), `ZNBT`/`ZPBT` (CK bằng tiền), `ZK01`, `ZK02`.
- `SyntaxCheck` (mượn URL `ZPG_SD_THCPVC`, nội dung ghép đủ 5 include local) trả **sạch** sau khi sửa lỗi `SCRTEXT` dài > 40 ký tự (xem `_ghichu_local.md`).

**Giả định (FS không nói rõ, code đã làm tạm):**
1. **Dấu của "hóa đơn điều chỉnh tăng giá":** FS ghi `VBTYP = 'O'` lấy âm cho cả "tăng/giảm giá", nhưng ví dụ (13) lại **cộng** 200.000 cho hóa đơn điều chỉnh tăng. Trên hệ, hóa đơn điều chỉnh tăng (`ZFL1`) là `VBTYP = 'P'`, điều chỉnh giảm (`ZFC1`, `ZFC3`) là `'O'` → code giữ nguyên quy tắc `'O'` âm, `'P'` dương, **khớp với ví dụ 9.700.000**.
2. **"Loại trừ Chiết khấu sau":** FS không nói cách nhận diện (theo loại hóa đơn, item category hay condition). Code **không tự lọc** chiết khấu sau; việc loại trừ do người dùng quyết định qua tham số **Loại hóa đơn** (không chọn nhóm `ZFC2/ZFC4/ZFC6–ZFC9`). Không hard-code danh sách loại hóa đơn vì chưa có danh sách chính thức từ BA. Đây là điểm nên báo BA (xem bên dưới), không phải câu hỏi chặn.
3. **Dòng tổng:** giữ tổng (13)(14)(15)(16) bằng `DO_SUM` của ALV (câu mô tả dòng tổng bị xóa khỏi FS, có thể chỉ vì (17) cũ đã bỏ). Tỷ lệ 14.1/15.1 ở dòng tổng để trống vì `DO_SUM` không tính được tỷ lệ.
4. **Định dạng tỷ lệ:** FS ghi "Trái / CHAR, 2" — "2" là độ dài không khớp với giá trị kiểu `1,000%`; code dùng CHAR 12, căn trái, định dạng số theo user (dấu thập phân của user), `%` dính liền sau số.

**Điểm nên THÔNG BÁO BA (không bắt buộc trả lời):**
- "Loại trừ Chiết khấu sau" ở chỉ tiêu (13): hiện loại trừ bằng cách người dùng không chọn các loại hóa đơn chiết khấu ở tham số Loại hóa đơn. Nếu BA muốn báo cáo **tự** loại trừ thì cần chốt danh sách loại hóa đơn (hệ có `ZFC2/ZFC4/ZFC6/ZFC7/ZFC8/ZFC9`).
- Câu mô tả (13) vẫn ghi `VBTYP = 'O'` gồm cả hóa đơn điều chỉnh tăng giá, mâu thuẫn ví dụ ngay bên dưới (xem giả định 1).
- (5) FS vẫn ghi `VBKD-KVGR2` (không tồn tại, code dùng `VBRP-KVGR2`).
- `ZFR1`/`ZFR2` chưa có trên hệ là do **chưa cấu hình**, việc của tư vấn cấu hình, không phải của dev. Code đọc theo hằng số `GC_KSCHL_FR1`/`GC_KSCHL_FR2`, khi có customizing + hóa đơn thì chạy đúng, không phải sửa code. Cột có data mới test được.
- Bảng ghi nhận thay đổi của FS chưa ghi các thay đổi lần này (14.1, 15.1, bỏ (17) cũ, bỏ tham số Dạng hiển thị, bỏ mặc định loại hóa đơn).

**Đã đẩy lên SAP DEV/100 ngày 15/10/2026 theo lệnh user:** `ZIN_SD_THCPVC_TOP`, `_F01`, `_F02` bằng `EditSource` (từng include, đi theo thứ tự thêm `RATE1`/`RATE2` → sửa F01/F02 → xóa `RATE` ở TOP). `ZPG_SD_THCPVC`, `_PBO`, `_PAI` không đổi.
TR: user gọi là "CS_DanhDH_01.10.2026_Create ZRSD26" — đó là tên **task `DEVK900206`**, nằm trong **request `DEVK900205`** ("DanhDH_SD_ZRSD26_01.10.2026_Create Bao cao tong hop chi phi", owner `CT.CSTECH`, đang Modifiable). Truyền `transport = DEVK900205`. Request đã chứa sẵn 6 `PROG` + Tcode `ZRSD26`.
Kiểm sau khi ghi: 6 object `R3STATE = A` (`REPOSRC`), chương trình chính `FIXPT = X`, `SyntaxCheck` `null`, `RunATCCheck` 0 finding.
Mọi `EditSource` khớp đúng chuỗi cũ của bản local cũ nên đoạn sửa trên hệ giống local (không đọc lại toàn bộ source để so từng dòng). Chưa test chạy thật vì chưa có hóa đơn.

Việc phía user (SAP GUI): screen 0100, PF-STATUS, TITLEBAR và Tcode `ZRSD26` làm từ lần trước (Tcode đã nằm trong TR; ATC không báo thiếu GUI status). Lần này chỉ cần **xóa selection text `P_ALV`, `P_XLS`** ở SE38 → Text Elements nếu đã nhập, kiểm lại selection text 9 tham số theo `Program/huong_dan_tao.md`. Release TR `DEVK900205` khi đã test.

## Dữ liệu test trên DEV/200 (kiểm 15/10/2026, `GUI_BDP_DEV_200`, chỉ đọc)

Client 200 **có** 4 hóa đơn (client 100 không có hóa đơn nào). **Số tiền dưới đây là giá trị lưu trong DB (3.500,00); VND không có số lẻ nên SAP hiển thị nhân 100 = 350.000.** Tất cả lập 14.10.2026, Sales org `1108`, kênh `11`, khách `0018000001`, VND, mã hàng `5100457` (+ `5100465` dòng 0 đồng), `VKGRP 300` "Miền Nam", `VKBUR 1108` "Chi nhánh TPHCM":

| Hóa đơn | FKART | VBTYP | FKSTO | KVGR2 | Doanh số | Ghi chú |
|---|---|---|---|---|---|---|
| 3060000000 | ZFT3 | M | | (trống) | 3.500 | tính |
| 3060000001 | ZFT3 | M | **X** | N03 | 3.500 | đã hủy, báo cáo loại |
| 3060000002 | ZST3 | N | | N03 | 3.500 | hóa đơn hủy, dương; chỉ lên báo cáo nếu chọn `ZST3` ở Loại hóa đơn |
| 3060000003 | ZFT3 | M | | N03 | 3.500 | tính |

**Chạy thử với:** Ngày hóa đơn 14.10.2026 – 14.10.2026, Loại hóa đơn `ZFT3`, Tổ chức bán hàng `1108`, **đăng nhập tiếng EN** (diễn giải `TVGRT/TVKBT/TVV2T/TMFGT/TVTWT` ở client này lưu dưới ngôn ngữ `E`, bằng tiếng Việt; ngôn ngữ khác sẽ để trống tên). **Kết quả dự kiến: 2 dòng** (khác nhau ở `KVGR2` trống / `N03`), mỗi dòng doanh số 3.500, (14) = (15) = 0, (14.1) = (15.1) = `0,000%`, loại tiền VND.

**Test được:** cộng dồn theo chiều, loại hóa đơn hủy `FKSTO = X`, lọc theo tham số, diễn giải 5 chiều, định dạng tỷ lệ, dòng tổng.
**Chưa test được (thiếu data / cấu hình):**
- `ZFR1`/`ZFR2` không có trong `PRCD_ELEMENTS` (và không có trong `T685`) → (14)(15)(14.1)(15.1) luôn 0.
- `KZWI4` của dòng = 3.500 (bằng doanh số), **không** phải chi phí vận chuyển → (16) in 3.500 trong khi (14)+(15) = 0. Giả định "KZWI4 = (14)+(15)" của FS chưa đúng với thủ tục tính giá hiện tại, chờ tư vấn cấu hình.
- `MARC-MFRGR` trống ở mọi vật tư (2 plant 1000, 2000) → chiều (7)(8) trống; `TMFGT` đã có `FG01`–`FG05`.
- Chưa có hóa đơn `VBTYP = O` (trả hàng, giảm giá) hay `P` (điều chỉnh tăng) → chưa kiểm được dấu âm.
- Điều kiện giá của hóa đơn chỉ có `ZRWR`, `ZNET`, `MWST`, `VPRS`.
Quyền: người test cần `V_VBRK_VKO` (VKORG 1108, ACTVT 03) và `M_IS_VTWEG` (VTWEG 11), nếu thiếu báo cáo báo lỗi thiếu quyền ở màn hình chọn.

## Việc tiếp theo

Test với hóa đơn thật khi tư vấn cấu hình xong `ZFR1`/`ZFR2` và có dữ liệu: đối chiếu `KZWI4` với (14) + (15); kiểm dấu hóa đơn `VBTYP = O` / `P`; kiểm 14.1/15.1 hiển thị `x,xxx%`; kiểm hiển thị tiêu đề dài của 2 cột tỷ lệ trên ALV (chỉ có `REPTEXT`).
Báo cáo này **cộng dồn** nên giữ `SUM( ) ... GROUP BY` đẩy xuống HANA (đã làm, 1 câu SQL).
