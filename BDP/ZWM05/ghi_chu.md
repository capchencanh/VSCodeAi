# ZWM05 – Phiếu chuyển kho (chương trình ZWM_PG_PCK)

FS: `FS/BIDIPHAR_FS_EWM_ZWM05_PhieuChuyenKho_v1.0.docx` (v1.0, 16/09/2026). Source ECC: `CODE_FINAL/zwm_pg_pck` (OneDrive Citek Bidiphar: `C:\Users\DanhDangHoang\citek.vn\Citek Bidiphar Upgrade PCE - BIDIPHAR_ECC\CODE_FINAL\zwm_pg_pck`, có `dictionary/` html của `ZWM_ST_PCK`, `ZWM_ST_PCK_QUYDOI`). Hệ: S/4 On-Premise, MCP `GUI_BDP_DEV_100` (client 100). TR của ZWM05: `DanhDH_WM_ZWM05_13.10.2026_Phiếu chuyển kho`, TR cha `DEVK900566`, task `DEVK900567` (user gọi là `DEVK900567`). Qua MCP truyền **TR cha `DEVK900566`** (truyền task báo CTS_WBO_API020 "already locked in request DEVK900566"); object nằm trong task.

## 0. TRẠNG THÁI (14/10/2026) – ĐỌC TRƯỚC

**ZWM05 XONG phần phát triển (14/10/2026, kiểm lại bằng MCP).** Mọi object đã có và active trên DEV, nằm trong task `DEVK900567` (24 dòng: chương trình, 2 include, structure, 2 bảng + SM30, 3 data element, message class, T-code, 2 Smart Form). Source server khớp local, `SyntaxCheck` sạch (chỉ warning `MARC`). **CHƯA chạy thử lần nào**: `ZTWM_MVT_GRP` 0 dòng và DEV chưa có chứng từ chuyển kho (`MATDOC` 0 dòng). Việc còn lại: BA nhập `ZTWM_MVT_GRP` / `ZTWM_PCK_TITLE` / `ZTWM_PCK_SIGN`, có chứng từ chuyển kho để thử, sửa theo kết quả (mục 4); user xác nhận nút trên toolbar GUI status (mục 0.1, hàng 7).

Lịch sử (13/10/2026): code local viết xong; user tạo program + 2 include rồi dán source. Claude tạo qua MCP: structure `ZWM_ST_PCK`, 2 bảng `ZTWM_PCK_TITLE` / `ZTWM_PCK_SIGN` (delivery class A), message class `ZWM05` (10 message), text symbols + selection texts. User làm: log bảng, SM30, GUI status, T-code, upload 2 Smart Form. Đã kiểm bằng MCP: log bảng (`DD09L-PROTOKOLL = X`), SM30 (`TVDIR`, `TDDAT`), T-code (`TSTC`), Smart Form (`TADIR`, `STXFADM`), program + 2 include active (`R3STATE = A`). GUI status `STANDARD` có đủ mã `PREV`, `PRINT`, `SELALL`, `EXCEL` (còn `DETAIL`, không ảnh hưởng vì code không xử lý); MCP không đọc được nút nào nằm trên toolbar.

Local: `Program/zwm_pg_pck/` (`zwm_pg_pck.abap` main, `zwm_in_pck_top.abap`, `zwm_in_pck_f01.abap`, `dictionary/zwm_st_pck.md`, `ztwm_pck_title.md`, `ztwm_pck_sign.md`). Khung theo ZWM04 (`ZWM04/Program/zwm_pg_pxk`).

**Những điều cần nhớ:**
- Smart Form **đã xong**: 2 form `ZWM_SF_PCK`, `ZWM_SF_PCK_OP3` (XML ở `Smartforms/FS_v1.0/`), user đã upload và có trên DEV (mục 0.1 hàng 9, mục 0.3). Chưa in thử: cần user xác nhận form active và xem preview khi có chứng từ.
- **Mẫu in chỉ còn 3 mẫu (1, 2, 3)**: user chốt 14/10/2026 vì Hình 2 của FS chỉ có 3 radio (FS mục 1.3 ghi "4 option" nhưng không mô tả option 4). Đã bỏ mẫu 4 khỏi code và đẩy lên DEV. Text `P_OP4` còn lại trên server là mục rỗng (MCP không xóa được), tùy chọn xóa ở SE38 → Goto → Text elements → Selection texts.
- Câu hỏi cho BA: không còn câu nào. Mục 3 chỉ còn giả định và thông báo (thiếu data / chưa cấu hình).
- Cách làm việc: code ở local trước, chỉ đẩy lên SAP qua MCP khi user yêu cầu, gắn TR cha `DEVK900566`; GUI status, SM30, T-code, upload Smart Form do user tự làm; câu hỏi BA nói rõ FS ghi gì ở mục nào, viết ngắn 1 câu (theo `NOTE/note.md`).

### 0.1 Checklist object cần tạo trên DEV (kiểm bằng MCP 13/10/2026)

| # | Object | Trạng thái | Việc cần làm |
|---|---|---|---|
| 1 | Structure `ZWM_ST_PCK` | **Đã tạo**, active, `ZPK_WM`, task `DEVK900567` (13/10/2026, MCP); 16 field, `MENGE` có `@Semantics.quantity.unitOfMeasure` trỏ `MEINS` | — |
| 2 | Bảng `ZTWM_PCK_TITLE` | **Đã tạo**, active, `ZPK_BDP`, delivery class **A** (đổi từ C ngày 13/10/2026 để SM30 nhập được ở client 200; nhãn `OBJH` = `APPL`, dữ liệu không đi theo transport), key `MANDT, WERKS, LGORT, UMLGO`; `TITLE_VI` / `TITLE_EN` dùng data element mới `ZDE_WM_PCK_TITLE_VI` / `_EN` (CHAR 80, nhãn tiếng Việt, theo nguyên tắc ở `NOTE/note.md`) | User đã bật log và làm SM30 (kiểm 13/10/2026, mục 0.2 A, B). FS chỉ nêu tên bảng, **cấu trúc là giả định** |
| 3 | Bảng `ZTWM_PCK_SIGN` | **Đã tạo**, active, `ZPK_BDP`, delivery class **A** (đổi từ C ngày 13/10/2026, như hàng 2), key `MANDT, WERKS, BWART, LGORT, UMLGO`; `SIGN_QLCL` dùng data element mới `ZDE_WM_PCK_SIGN_QLCL` (domain `XFELD`) | Như hàng 2 (đã xong) |
| 4 | Message class `ZWM05` | **Đã tạo**, `ZPK_WM`, 10 message (ngôn ngữ EN, nội dung tiếng Việt như ZWM04; bỏ dấu `"` ở 006) | Bản tiếng Anh cần SE63 nếu muốn |
| 5 | Program `ZWM_PG_PCK` + include `ZWM_IN_PCK_TOP`, `ZWM_IN_PCK_F01` | **Đã tạo và activate** (user, package `ZPK_BDP`, task `DEVK900567`), source khớp local, `SyntaxCheck` sạch | — |
| 6 | Text symbols + Selection texts | **Đã ghi** (MCP 13/10/2026, TR `DEVK900566`): 3 text symbol, 14 selection text | Đã activate cùng program |
| 7 | GUI status `STANDARD` của `ZWM_PG_PCK` | **Đã có** (user, có bản ghi CUA); chưa kiểm được nút trên toolbar | Xác nhận đã xóa `DETAIL`, còn `PREV`, `PRINT`, `SELALL`, `EXCEL` |
| 8 | T-code `ZWM05` | **Đã có** (`TSTC`: `ZWM_PG_PCK`, 1000; "Phiếu chuyển kho"; 3 loại GUI như ZWM04) | — |
| 9 | Smart Form `ZWM_SF_PCK`, `ZWM_SF_PCK_OP3` | **Đã upload** (user, 13/10/2026): có trong `TADIR` (`SSFO`, `ZPK_BDP`), `STXFADM` (version 1, sửa lần cuối sau lúc tạo, nghĩa là đã lưu/activate) và TR `DEVK900567`. File XML ở `Smartforms/FS_v1.0/`, `sf_validate` PASS | **Chưa in thử** (chưa có chứng từ) |
| 10 | Data `ZTWM_MVT_GRP` | **0 dòng** ở mọi client | BA nhập MvT nhóm `DC` / `TT` kèm `REV_BWART` (xem mục 3) |
| 11 | Data `ZTWM_PCK_TITLE`, `ZTWM_PCK_SIGN` | Bảng đã tạo, chưa có data | BA/Key user nhập (mục 3) |
| 12 | STVARV `ZWM05_MATKL_KSDB` (nhóm vật tư kiểm soát đặc biệt), `ZWM05_MTART_KNL` (material type retest) — loại S | Chưa có, tùy chọn | `ZWM05_MATKL_KSDB` trống thì không kiểm mẫu 2; `ZWM05_MTART_KNL` trống thì mặc định `Z21` |
| 13 | Phân quyền role | Chưa kiểm | `S_TCODE` = `ZWM05`, `M_MSEG_WWA`, `M_MSEG_BWA`, `M_MSEG_LGO`, `S_SPO_DEV`, `S_TABU_NAM` (`ZTWM_PCK_TITLE`, `ZTWM_PCK_SIGN`) |

Đã có sẵn dùng chung: `ZTWM_MVT_GRP`, `ZTWM_PRTLOG`, `ZCORE_ST_PARAMETER` (có `PARAMETER01–60`, `SIGN01–12`, `FOOTER01–07`), FM `ZCORE_FM_GET_PROFILE`, `ZCORE_FM_GET_CRTRT_MULTIVAL`, logo `ZLOGO_0001`, style `ZCORE_STYLE_REPORT`.

**Dữ liệu thử:** DEV client 100 trống hoàn toàn (`MATDOC`, `MARA`, `LIKP` đều 0 dòng, kiểm 13/10/2026). Client 200 (Integration Test) có 4 chứng từ nhập kho (101/102) và 363 vật tư, chưa có chứng từ chuyển kho (301/311/313/321...). Cần BA/user tạo chứng từ chuyển kho thử.

### 0.2 Hướng dẫn việc user làm (đã xong 13/10/2026, giữ để tham khảo; giá trị lấy từ ZWM04 / `ZTWM_MVT_TCODE`)

**A. Bật log thay đổi dữ liệu (làm lần lượt `ZTWM_PCK_TITLE`, rồi `ZTWM_PCK_SIGN`)**

1. SE11 → Database table = `ZTWM_PCK_TITLE` → **Change**.
2. Menu **Goto → Technical Settings**. Đang là: Data class `APPL0`, Size category `0`, Buffering not allowed (giữ nguyên, giống `ZTWM_MVT_GRP`).
3. Tick **Log data changes** (hiện đang trống) → Save → chọn TR/task `DEVK900567`.
4. Back → **Activate** (Ctrl+F3). Lặp lại cho `ZTWM_PCK_SIGN`.

**B. SM30 (Table Maintenance Generator) – mỗi bảng 1 function group mới**

Giống `ZTWM_MVT_TCODE` (`TVDIR`: one step, màn hình tổng quan 1, package `ZPK_BDP`; `TDDAT`: nhóm quyền `&NC&`).

| Ô trong màn hình | `ZTWM_PCK_TITLE` | `ZTWM_PCK_SIGN` |
|---|---|---|
| Authorization Group | `&NC&` | `&NC&` |
| Function group | `ZFG_WM_PCK_TITLE` | `ZFG_WM_PCK_SIGN` |
| Package | `ZPK_BDP` | `ZPK_BDP` |
| Maintenance type | One step | One step |
| Overview screen | `1` | `1` |
| Single screen | để trống | để trống |

1. SE11 → bảng → **Change** → menu **Utilities → Table Maintenance Generator**.
2. Điền theo bảng trên → bấm **Create** (biểu tượng) → chọn TR/task `DEVK900567` → thoát.
3. Kiểm tra: SM30 → nhập tên bảng → **Maintain** → thêm thử 1 dòng. `ZTWM_PCK_TITLE`: `WERKS` 1000, `LGORT` B004, `UMLGO` B001, `TITLE_VI` PHIẾU NHẬP KHO, `TITLE_EN` để trống. `ZTWM_PCK_SIGN`: `WERKS` 1000, `BWART` 313, `LGORT` B101, `UMLGO` BX01, `SIGN_QLCL` X. Dòng thử là ví dụ theo ECC; bảng đang class A (đổi từ C ngày 13/10/2026) nên SM30 không hỏi TR customizing khi Save và dữ liệu không đi theo transport; xóa dòng thử sau nếu không dùng. Xem `_ghichu_local.md` mục 2 (SM30 báo client 200 not modifiable).

**C. GUI status `STANDARD`** (SE41)

1. SE41 → Program `ZWM_PG_PNK`, Status `STANDARD` → **Copy** (menu Status → Copy hoặc Ctrl+F5).
2. Hộp thoại: To Program = `ZWM_PG_PCK`, To Status = `STANDARD` → OK → chọn TR/task `DEVK900567`.
3. Mở `ZWM_PG_PCK` / `STANDARD` → **Change** → mục **Application toolbar**: xóa nút `DETAIL` ("Chi tiết điều chỉnh"). **Giữ** `PREV`, `PRINT`, `SELALL`, `EXCEL` (khác ZWM04: ZWM05 cần `EXCEL`).
4. **Activate**. Code xử lý đúng 4 mã `PREV`, `PRINT`, `SELALL`, `EXCEL` (`LCL_HANDLER=>ON_FUNCTION`).

**D. T-code `ZWM05`** (SE93; theo `TSTC`/`TSTCT`/`TSTCC` của ZWM04)

1. SE93 → Transaction code = `ZWM05` → **Create**.
2. Short text = `Phiếu chuyển kho` → chọn **Program and selection screen (report transaction)**.
3. Program = `ZWM_PG_PCK`, Screen number = `1000`.
4. GUI support: tick **SAPGUI for HTML**, **SAPGUI for Java**, **SAPGUI for Windows** (như ZWM04).
5. Save → Package `ZPK_BDP`, TR/task `DEVK900567`.

**E. Sau khi xong A–D**: báo Claude để kiểm lại bằng MCP. *(Đã xong và kiểm lại 13/10/2026, xem mục 0.)*

### 0.3 Smart Form: upload 2 file XML (đã xong 13/10/2026, giữ để tham khảo)

Các file ở `Smartforms/FS_v1.0/`: `ZWM_SF_PCK.xml` (mẫu 1, 2 và phiếu chuyển trạng thái), `ZWM_SF_PCK_OP3.xml` (mẫu 3). Mỗi file làm lần lượt:

1. Copy file ra đường dẫn ngắn (VD `C:\temp\`).
2. SMARTFORMS → nhập **Form** = đúng tên file (`ZWM_SF_PCK`, rồi `ZWM_SF_PCK_OP3`) → menu **Utilities → Upload Form...** → chọn file.
3. Kiểm tra **Global Definitions → Form Interface**: Import `GS_PARAMETER` (Type `ZCORE_ST_PARAMETER`), Tables `IT_DATA` (Like `ZWM_ST_PCK`); Global Data `GS_DATA` (Type `ZWM_ST_PCK`).
4. **Activate**. Package `ZPK_BDP`, TR/task `DEVK900567`.
5. Logo `ZLOGO_0001` và style `ZCORE_STYLE_REPORT` đã có từ ZWM03/04.
6. Xong báo Claude: kiểm `TADIR` (`SSFO`) bằng MCP; lỗi gặp khi in thử thì chụp màn hình preview.

Tạo lại file: `PYTHONUTF8=1 python gen_zwm_sf_pck.py FS_v1.0` (máy không có Python thật, xem memory `no-python-smartforms-generator`).

## 1. Đối chiếu source ECC với FS – những gì đã làm

Source ECC không đáp ứng FS (không Plant, không ALV, MvT hard-code, SLoc hard-code), viết lại toàn bộ, giữ tên chương trình, tách include theo kiểu ZWM04.

| # | ECC (`zwm_pg_pck`) | S/4 theo FS |
|---|---|---|
| 1 | Selection chỉ Chứng từ kho + Năm + 3 radio + song ngữ | Thêm Plant (bắt buộc), Ngày hạch toán, MvT, SLoc xuất, SLoc nhận, Reservation, Người tạo; 4 mẫu in; bắt buộc Chứng từ kho hoặc Ngày hạch toán (tối đa 31 ngày) |
| 2 | Đọc `MSEG` dòng nhận (`XAUTO = X`) | Đọc `MATDOC`: dòng xuất (`XAUTO` trống) ghép dòng nhận (`XAUTO = X`) qua `LINE_ID` / `PARENT_ID` |
| 3 | 31 MvT hard-code trong `SELECT` | MvT trong `ZTWM_MVT_GRP` nhóm `DC` (chuyển kho) và `TT` (chuyển trạng thái) |
| 4 | In thẳng Preview | Luôn qua màn hình trung gian ALV (mỗi dòng = 1 phiếu: chứng từ + SLoc xuất + SLoc nhận), nút Xem trước / In / Excel |
| 5 | Tiêu đề hard-code theo cặp SLoc `B004→B001`, `B005→B002` ("PHIẾU NHẬP KHO") | Bảng `ZTWM_PCK_TITLE` (Plant + SLoc xuất + SLoc nhận), không có thì "PHIẾU CHUYỂN KHO" |
| 6 | Chữ ký QLCL (`FLAG14`) hard-code: MvT 313, SLoc xuất `B101…C003`, SLoc nhận `BX*`/`C0*` | Bảng `ZTWM_PCK_SIGN` |
| 7 | Cộng dồn SL các dòng cùng vật tư + lô | Mỗi dòng xuất 1 dòng in (FS: STT tăng dần theo dòng xuất, không nêu cộng dồn) |
| 8 | SL = `MSEG-MENGE` (đặt tên `ERFMG`), ĐVT = `ERFME` | SL (10) = `MENGE` theo ĐVT cơ sở `MEINS` (FS); SL quy đổi (11) theo `MARM` |
| 9 | Có cột Nồng độ – Hàm lượng, Độ ẩm | FS không có 2 cột này → bỏ |
| 10 | Tên hàng theo text lô (`CHARGE/VERM`) cho `Z51`, `Z41`; Dạng bào chế từ text `GRUN` | FS (3) = `MAKT-MAKTX` → bỏ text lô. Dạng bào chế (15): FS ghi "Technical xác nhận" → để trống |
| 11 | Hạn dùng = đặc tính `LOBM_VFDAT`, `QNDAT` cho `Z21/Z22/Z41` | `MCHA-VFDAT`; material type retest thêm "KNL dd/mm/yyyy" (`MCHA-QNDAT`) |
| 12 | Quy đổi SL: 3 khối gần giống nhau ~500 dòng, hard-code BOX/CAR/KAR | Viết lại 1 FORM `CONVERT_QTY` (mục 2) |
| 13 | Logo `FES_LOGO_<Plant>` | `ZLOGO_0001` (như ZWM03/04) |
| 14 | Không ghi nhật ký in | Ghi `ZTWM_PRTLOG` mỗi phiếu khi In thật; in lại có "Bản in lại – lần n" |
| 15 | `BREAK ABAPLEADER` còn trong code | Bỏ |

## 2. Logic chính / giả định

- **Ghi chú từ tài liệu khác (user cung cấp 13/10/2026): "Không gộp nghiệp vụ chuyển kho/SLoc với chuyển Bin; form thể hiện SAP Batch + Manufacturer Batch".** Không tìm thấy câu này trong FS ZWM05 (không có comment trong file Word; chỉ mục 1.1 loại trừ chuyển Bin ZWM07). Code đã đúng cả hai: (1) chỉ đọc `MATDOC` theo MvT `DC` / `TT` của `ZTWM_MVT_GRP`, không đọc WT/Bin EWM, không có logic chuyển Bin; (2) form có 2 cột riêng: (5) Số lô NSX = Manufacturer Batch (`Z_BATCH_NSX`, rồi `LICHA`, rồi lô SAP) và (6) Số lô SAP = SAP Batch (`MATDOC-CHARG`, đổi lô thì "lô xuất → lô nhận").
- **Phạm vi MvT**: MvT trong `ZTWM_MVT_GRP` có `GRP_CODE` = `DC` hoặc `TT`; khớp dòng theo `SEQNR` (điều kiện `SOBKZ`, có lệnh SX, Plant; trống = bất kỳ); dòng không khớp bị bỏ. Bảng rỗng → ZWM05-009 và dừng. **Chứng từ hủy (302, 312, 322…) chỉ in nếu BA khai các MvT này trong bảng** (FS: "vẫn in").
- **Dòng xuất / dòng nhận**: dòng xuất = `XAUTO` trống (lấy STT, vật tư, lô, SL, Plant/SLoc xuất). Dòng nhận = `XAUTO = X` có `PARENT_ID` = `LINE_ID` của dòng xuất. Đơn vị nhận = dòng nhận; không có (chuyển 2 bước 313/303) thì `UMWRK` / `UMLGO` của dòng xuất; không có nữa thì chính Plant/SLoc xuất. Mã vật tư nhận = dòng nhận, rồi `UMMAT`; khác mã xuất thì in "mã xuất → mã nhận" (không hard-code 309/310). Lô nhận = dòng nhận, rồi `UMCHA`.
- **Chưa kiểm với data thật**: hướng xuất/nhận của MvT 305 (bước nhận chuyển 2 bước) và của chứng từ hủy; cách MATDOC lưu 321 (có dòng `XAUTO = X` hay không).
- **Mẫu in**: 1 Thành phẩm/hàng hóa; 2 Thuốc gây nghiện; 3 Nguyên liệu/bao bì (thêm cột (13) Ngày cấp/Thủ kho, (14) Người nhận, để trống ký tay). Không có mẫu 4: FS mục 1.3 ghi "4 option" nhưng Hình 2 chỉ có 3 radio và FS không mô tả option 4, user chốt bỏ (14/10/2026).
- **Chuyển trạng thái (nhóm `TT`)**: không phụ thuộc mẫu in chọn; tiêu đề "PHIẾU CHUYỂN TRẠNG THÁI", bỏ "Mã/tên đơn vị nhận", thêm "Chuyển trạng thái: loại tồn nguồn → đích", nhãn "Kho:" thay "Kho xuất:", chữ ký chỉ "Người lập phiếu" (hình 6 của FS). Tên loại tồn từ domain `MB_INSMK` (`DD07T`, tiếng Việt, thiếu thì Anh) của dòng xuất và dòng nhận; kèm số lô kiểm tra từ `QAMB` (`PRUEFLOS`) nếu có.
- **Tiêu đề chuyển kho (nhóm `DC`)**: mẫu 2 = "PHIẾU CHUYỂN KHO THUỐC GÂY NGHIỆN, THUỐC HƯỚNG THẦN, TIỀN CHẤT DÙNG LÀM THUỐC"; mẫu 1, 3 theo `ZTWM_PCK_TITLE` (FS), không có thì "PHIẾU CHUYỂN KHO". Song ngữ: tiêu đề phụ lấy `TITLE_EN`; trống thì mẫu 1 "CERTIFICATE OF RELEASE", mẫu 3 "MATERIAL TRANSFER SLIP" (theo ECC); mẫu 2 không có bản EN.
- **Mẫu 2 và vật tư kiểm soát đặc biệt**: kiểm theo từng phiếu bằng Material Group trong STVARV `ZWM05_MATKL_KSDB`. Có vật tư kiểm soát mà chọn mẫu khác 2 → **không in phiếu đó** + ZWM05-007 (FS ghi loại W nhưng nội dung "bị chặn"; code giữ loại W, chặn in). Chọn mẫu 2 mà không có vật tư kiểm soát → ZWM05-005, vẫn in. STVARV chưa khai báo → bỏ qua cả hai kiểm.
- **Khối chữ ký (DC)**: mặc định "Người nhận hàng | Thủ kho | Trưởng bộ phận", chỉ hiện khi SLoc xuất ≠ SLoc nhận (hoặc khác Plant); thêm "Trưởng phòng QLCL" (trước Trưởng bộ phận) khi `ZTWM_PCK_SIGN` có dòng khớp.
- **Diễn giải (H6)**: chứng từ hủy "Hủy chứng từ <SMBLN>"; MvT 321 lấy từ `ZTWM_MVT_GRP`, thiếu thì "Đạt yêu cầu sử dụng"; còn lại `BKTXT`; trống thì `ZTWM_MVT_GRP` (VI/EN).
- **Số yêu cầu (H5)**: các `RSNUM` khác nhau của cả chứng từ, cách nhau "; ", giữ nguyên số 0 đầu (theo hình mẫu FS; ECC bỏ số 0).
- **Đơn vị nhận/kho xuất**: "SLoc - tên (T001L)"; thêm "Plant - tên (T001W) /" phía trước khi dòng nhận khác Plant xuất.
- **Header**: Plant (`ZCORE_FM_GET_PROFILE`, loại P; bản quốc tế loại Q cho song ngữ), MST theo Company Code (như ZWM04; FS ghi "bảng tham số theo Plant", chưa có bảng).
- **NSX, nước SX, quy cách, bảo quản**: như ZWM04 (đặc tính lô `Z_NSX`, `Z_NUOC_SX`, `Z_BATCH_NSX`, `Z_QUY_CACH_BATCH`, `Z_BAO_QUAN_BATCH` qua `ZCORE_FM_GET_CRTRT_MULTIVAL`; NSX theo MPN và `MARC-HERKL` khi lô trống; bảo quản thiếu thì `MARA-RAUBE` / `T142T`). Số lô NSX: `Z_BATCH_NSX`, rồi `MCHA-LICHA`, rồi lô SAP. Mẫu 1 song ngữ: cột (7) ghép "Ngày SX (`MCHA-HSDAT`) - Hạn dùng".
- **SL quy đổi (11)**: lấy `MARM` của vật tư; BOX in là HOP, CAR/KAR in là THU (như ECC); gộp các đơn vị cùng hệ số (ưu tiên HOP/THU); xếp từ lớn đến nhỏ rồi chia dần (đơn vị khối lượng `DIMID = MASS` giữ phần lẻ, đơn vị khác lấy phần nguyên), VD "3 THÙNG 65 HỘP 2 VỈ"; tên đơn vị = `T006A-MSEH6` (E) viết hoa. Vật tư chỉ có 1 đơn vị → "ERFMG ERFME" (theo ĐVT nhập liệu, FS). Không dùng FM chuẩn vì FS cần chuỗi nhiều đơn vị theo mẫu ECC.
- **Hủy**: cột "Hủy bởi" = `MBLNR` của chứng từ có `SMBLN` = chứng từ này (`SJAHR` = năm); in phiếu thêm ZWM05-004 và footer "Chứng từ đã bị hủy bởi <số>" (`FOOTER04`). Không trừ SL.
- **Nhật ký in**: `ZTWM_PRTLOG` (`TCODE`/`FORMNAME` = `ZWM05`), mỗi phiếu 1 bản ghi, `OBJ_KEY` = `<MBLNR>/<MJAHR>/<Plant><SLoc xuất>/<Plant><SLoc nhận>`, `LGORT` = SLoc xuất; chỉ ghi khi In thật. Máy in: máy mặc định của user (`USR01-SPLD`), không có thì hộp thoại.
- **Phân quyền**: `M_MSEG_WWA`, `M_MSEG_BWA`, `M_MSEG_LGO` theo Plant/SLoc/MvT của dòng xuất (như ZWM04); dòng không quyền bị loại, báo ZWM05-010; hết dòng thì ZWM05-001. FS còn ghi `M_MSEG_WMB`, `M_MRES_BWA` (dạng "A / B"): chưa dùng.
- **F4 chứng từ kho**: gọi MB51 (như ZWM03/04), cần thử lại trên DEV.
- **Performance**: không dùng `FOR ALL ENTRIES`; 1 `SELECT` tự nối `MATDOC` cho dòng xuất + dòng nhận; master data bằng `INNER JOIN @itab`; đặc tính lô gọi FM 1 lần/lô.

## 3. Câu hỏi còn mở cho BA

Chỉ giữ chỗ FS thiếu / mâu thuẫn ở yêu cầu chính (theo `NOTE/note.md`); các chỗ thiếu data / chưa cấu hình nằm ở mục thông báo bên dưới.

Hiện **không còn câu hỏi nào** cho BA.

### Giả định đã chọn (FS thiếu hoặc mâu thuẫn nhẹ, đoán được ý đồ, không hỏi BA)

- **Cấu trúc `ZTWM_PCK_TITLE`, `ZTWM_PCK_SIGN`**: FS không mô tả field → giả định như `dictionary/ztwm_pck_title.md`, `ztwm_pck_sign.md`.
- **Mẫu 2 bị chặn bằng ZWM05-007**: FS ghi loại W nhưng "bị chặn" ở mục 2.5 (T1) → chặn in.
- **Không có cột Trạng thái WT ở màn hình trung gian**: FS mục 2.4 có câu "Trạng thái WT phải hiển thị riêng theo nguồn EWM" (gắn với "mẫu trả nguyên liệu theo WT") nhưng bảng cột và Hình 3 không có cột WT, mục 1.1 loại trừ chuyển Bin, và FS chỉ còn 3 mẫu in → code chỉ đọc `MATDOC`, không làm cột WT. BA muốn thêm thì mới làm.

### Chỉ thông báo BA (chưa cấu hình / chưa có data, code đã chạy tạm)

- `ZTWM_MVT_GRP` 0 dòng → ZWM05 chưa chạy được. File mẫu BA mới có nhóm DC (301, 311, 313, 305, 309) và TT (321, 322, 343). FS còn nhắc 303 (2 bước), 344, 349, 350 (chuyển trạng thái) và các MvT hủy 302, 312, 322…; **thiếu trong bảng thì ZWM05 không in** các MvT đó. Cột `REV_BWART` để BA nhập.
- `ZTWM_PCK_TITLE`, `ZTWM_PCK_SIGN` chưa có (FS chỉ nêu tên) → chưa có tiêu đề riêng ("PHIẾU NHẬP KHO" của ECC cho `B004→B001`, `B005→B002`) và chưa có ô Trưởng phòng QLCL. BA cần nhập data theo cặp SLoc thực tế.
- Nhóm vật tư kiểm soát đặc biệt (mẫu 2): FS không nêu tiêu chí → code đọc Material Group từ STVARV `ZWM05_MATKL_KSDB`, trống thì không kiểm, không chặn. Nên dùng chung tiêu chí với ZWM04 (`ZWM04_MATKL_KSDB`).
- Rule tự nhận diện "trả nguyên liệu từ xưởng" (FS: "chốt sau") → chưa làm (mẫu 4 đã bỏ).
- **"Các mẫu in được phép" của từng MvT** (FS 2.6.2): `ZTWM_MVT_GRP` không có cột mẫu in → code không giới hạn mẫu theo MvT, chỉ kiểm vật tư kiểm soát đặc biệt cho mẫu 2.
- Phân quyền: FS ghi `M_MSEG_WMB`, `M_MRES_BWA` (dạng "A / B") → code chỉ dùng `M_MSEG_WWA`, `M_MSEG_BWA`, `M_MSEG_LGO`.
- Vật tư retest in "KNL": FS ghi "nhóm retest (ECC Z21)" → mặc định `Z21` khi STVARV `ZWM05_MTART_KNL` chưa khai báo; ECC còn dùng `Z22`, `Z41`.
- Dạng bào chế (15): FS ghi "BP MATERIAL, Technical xác nhận" → để trống.
- Tên loại tồn ở phiếu chuyển trạng thái (H8): FS ghi nguồn "ZTWM_MVT_GRP" nhưng bảng không có cột loại tồn → code lấy theo domain `MB_INSMK` (VD "Quality inspection → Unrestricted-use" nếu chưa có text tiếng Việt, FS ví dụ "Chờ kiểm nghiệm → Được phép sử dụng"). Muốn nhãn riêng thì cần thêm bảng/cột.
- Đặc tính lô `Z_NSX`, `Z_NUOC_SX`, `Z_BATCH_NSX`, `Z_QUY_CACH_BATCH`, `Z_BAO_QUAN_BATCH` chưa có trên DEV (kiểm ZWM04) → cột tương ứng trống.
- MST theo Plant: FS ghi bảng tham số theo Plant nhưng chưa có bảng → tạm MST theo Company Code.
- Chữ ký "Người lập phiếu" (chuyển trạng thái) và nhãn song ngữ ("Prepared by", "QC Manager") do code đặt, FS không nêu bản dịch.

## 4. Khi BA trả lời / khi có dữ liệu

- Đổi nhóm MvT: sửa `GC_GRP_DC`, `GC_GRP_TT` trong TOP (hoặc cấu hình `ZTWM_MVT_GRP`).
- BA chốt rule nhận diện trả nguyên liệu (nếu có làm): sửa `RESOLVE_SHEET` (chữ ký, tiêu đề).
- BA chốt tiêu chí thuốc kiểm soát đặc biệt: sửa đọc STVARV trong `GET_MASTER_DATA` và kiểm tra trong `RESOLVE_SHEET`.
- Có chứng từ thật: thử 301, 311, 313 + 305 (2 bước), 309 (đổi mã), 321/322/343 (chuyển trạng thái, có UD), chứng từ hủy 302; kiểm hướng xuất/nhận, cột "Hủy bởi", footer hủy, in lại.
- BA chốt nguồn Dạng bào chế: điền `DANGBC` trong `FILL_FORM_LINES`.

## 5. Message class ZWM05 (VI / EN)

| Số | Loại | Nội dung |
|---|---|---|
| 001 | E | Bạn không có quyền trên Plant &1 / SLoc &2 / Movement Type &3. / You are not authorized for plant &1 / storage location &2 / movement type &3. |
| 002 | E | Vui lòng nhập Chứng từ kho hoặc Ngày hạch toán (tối đa 31 ngày). / Enter material document or posting date (max. 31 days). |
| 003 | S | Không có dữ liệu thỏa điều kiện. / No data found. |
| 004 | I | Chứng từ &1 đã bị hủy bởi chứng từ &2. / Document &1 has been cancelled by document &2. |
| 005 | W | Chứng từ &1 có vật tư không thuộc nhóm kiểm soát đặc biệt nhưng in bằng mẫu 2. / Document &1 has materials outside the special-control group but is printed with layout 2. |
| 006 | I | Chứng từ &1 đã in &2 lần. Bản in này được đánh dấu "Bản in lại". / Document &1 printed &2 times. This copy is marked "Reprint". |
| 007 | W | Chứng từ &1 có vật tư kiểm soát đặc biệt; phải chọn Mẫu 2. / Document &1 has special-control materials; layout 2 is required. |
| 008 | E | Chưa chọn chứng từ. / No document selected. — thêm ngoài FS |
| 009 | S | Bảng ZTWM_MVT_GRP chưa khai báo Movement Type nhóm chuyển kho / chuyển trạng thái. / No transfer movement type maintained in ZTWM_MVT_GRP. — thêm ngoài FS |
| 010 | W | Đã loại &1 dòng không có quyền (Plant &2 / Movement Type &3). / &1 items removed – no authorization (plant &2 / mvt &3). — thêm ngoài FS (mục Phân quyền yêu cầu báo số dòng bị loại) |

Lưu ý: câu 006 chứa dấu `"` — khi ghi qua MCP phải bỏ dấu nháy kép (xem `_ghichu_mcp_gui.md`), VD viết Bản in lại không có nháy.

## 6. Interface Smart Form (2 form – đã upload lên DEV)

Import `GS_PARAMETER TYPE ZCORE_ST_PARAMETER`; Tables `IT_DATA LIKE ZWM_ST_PCK`. Mỗi lần gọi form = 1 phiếu; trong 1 lần In có thể gọi cả 2 form (chương trình dùng `SSF_OPEN` 1 lần, gọi từng form với `NO_OPEN` / `NO_CLOSE`). Form `ZWM_SF_PCK`: mẫu 1, 2 và phiếu chuyển trạng thái; form `ZWM_SF_PCK_OP3`: mẫu 3 (thêm 2 cột ký tay).

| Field GS_PARAMETER | Nội dung |
|---|---|
| LOGO | `ZLOGO_0001` |
| HEADER01–06 | Tên Plant (in hoa), địa chỉ, "Điện thoại: …", "Fax: …", "MST: …" (theo Company Code), "Website: …" |
| HEADER39 / 40 | Tên / địa chỉ quốc tế của Plant (chỉ song ngữ) |
| TITLE_REPORT / TITLE_REPORT_EN | Tiêu đề VI / EN (EN chỉ khi song ngữ) |
| HEADER08 | (H3) "Ngày dd tháng mm năm yyyy" |
| HEADER22 / 23 | Nhãn / (H2) Số chứng từ |
| HEADER09 / 10 | Nhãn / (H4) Mã - tên đơn vị nhận (trống ở chuyển trạng thái) |
| HEADER20 / 21 | Nhãn / (H5) Số yêu cầu (reservation) |
| HEADER18 / 19 | Nhãn / (H6) Diễn giải |
| HEADER16 / 17 | Nhãn ("Kho xuất:" hoặc "Kho:") / (H7) Kho xuất |
| HEADER11 / 12 | Nhãn / (H8) Chuyển trạng thái (chỉ phiếu chuyển trạng thái) |
| PARAMETER01–15 | Tiêu đề cột: (1) STT, (2) Mã hàng, (3) Tên hàng, (4) NSX – Nước SX, (5) Số lô NSX, (6) Số lô SAP, (7) Hạn dùng / KNL (mẫu 1 song ngữ: Ngày SX - Hạn dùng), (8) Quy cách, (9) ĐVT, (10) Số lượng, (11) SL quy đổi, (12) ĐK bảo quản, (13) Ngày cấp/ Thủ kho và (14) Người nhận (chỉ mẫu 3), (15) Dạng bào chế (chỉ mẫu 1 song ngữ) |
| SIGN01–04 | Nhãn các ô chữ ký (1 ô: "Người lập phiếu"; 3 ô: Người nhận hàng / Thủ kho / Trưởng bộ phận; 4 ô: thêm Trưởng phòng QLCL trước Trưởng bộ phận; ô trống = không in; không có ô nào thì không in khối ký) |
| SIGN06 | "(Ký, ghi rõ họ tên)" |
| FOOTER03 | "In lúc: dd/mm/yyyy hh:mm:ss – User: …" |
| FOOTER04 | "Chứng từ đã bị hủy bởi <số>" (chứng từ đã bị hủy) |
| FOOTER05 / 06 / 07 | "Ngày ….. tháng ….. năm ……..", "Trang" (form tự in x/y), "Bản in lại – lần n" |
| ISO_LINE01 | "Lần in: 1" / "Bản in lại – lần n" |

Dòng `IT_DATA` (`ZWM_ST_PCK`): `STT, MATNR (đã ghép mã xuất → mã nhận), MAKTX, NSXNS, SOLO, CHARG, HANDUNG, GROES, MEINS, MENGE, QUYDOI, BAOQUAN, DANGBC`. Cột (13) hiện khi `PARAMETER13` có giá trị, (15) khi `PARAMETER15` có giá trị.

Thiết kế form (FS 2.5): A4 ngang, lề trái 2 cm, còn lại 1,5 cm; Times New Roman, tiêu đề 16, nội dung 10; ngắt trang theo chứng từ + SLoc xuất + SLoc nhận. Mẫu hình: FS Hình 4 (mẫu 1), Hình 5 (mẫu 3 có QLCL), Hình 6 (chuyển trạng thái).

## 7. Bắt đầu phiên mới

1. Đọc `CodeABAP/BDP/NOTE/note.md` rồi file này (mục 0).
2. Hỏi user đã có chứng từ chuyển kho và data `ZTWM_MVT_GRP` để chạy thử chưa, form in có lỗi gì không (nếu có thì xin ảnh chụp).
3. Object đã đủ trên DEV (mục 0.1). Sửa code: sửa local trước, rồi `EditSource` lên DEV (TR cha `DEVK900566`, `syntax_check=false` vì warning `MARC` chặn lưu), kiểm `SyntaxCheck` chương trình thật `/sap/bc/adt/programs/programs/zwm_pg_pck`; `SetTextElements` (selection text ≤ 30 ký tự).
4. Comment tiếng Việt ngắn, không marker tên/ngày, không comment lại code cũ (theo `NOTE/note.md`).
5. Sửa Smart Form: sửa `Smartforms/gen_zwm_sf_pck.py` rồi chạy lại (máy không có Python thật, xem memory `no-python-smartforms-generator`), chạy `sf_validate.py`, nhờ user upload lại.
