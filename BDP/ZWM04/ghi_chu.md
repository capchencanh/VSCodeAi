# ZWM04 – Phiếu xuất kho (chương trình ZWM_PG_PXK)

FS: `FS/BIDIPHAR_FS_EWM_ZWM04_PhieuXuatKho_v1.0.docx` (v1.0, 16/09/2026). Source ECC: `CODE_FINAL/zwm_pg_pxk` (ZWM04), `zwm_pg_pxk_new` (ZWM041), `zwm_pg_pxkqi` (ZWM20) trong OneDrive Citek Bidiphar. Hệ: S/4 On-Premise, MCP `GUI_BDP_DEV_100` (client 100).

## 0. TRẠNG THÁI (13/10/2026) – ĐỌC TRƯỚC

**ZWM04 XONG phần phát triển (user xác nhận 13/10/2026).** Mọi object kỹ thuật đã có đủ trên DEV (kiểm bằng MCP, TR `DEVK900552`), `SyntaxCheck` sạch, đã activate. **CHƯA chạy thử lần nào** vì `ZTWM_MVT_GRP` 0 dòng và `MATDOC` của DEV client 100 đang trống (không có chứng từ vật tư nào để in). Việc còn lại chỉ là chạy thử khi có data và sửa theo kết quả. Xem checklist mục 0.1.

**Những điều cần nhớ (chốt trong phiên 13/10/2026):**
- **BA đã trả lời câu hỏi duy nhất:** mẫu 4 in cho MvT xuất mẫu **331 / 333 / 335**; **551 là xuất khác**. FS mục 2.3 (dòng STT 11 "Mẫu in") còn ghi "551" là ghi nhầm, chờ tác giả FS sửa. Hiện không còn câu hỏi mở cho BA.
- **Thứ tự ưu tiên khi chạy thử gặp lỗi:** (1) data `ZTWM_MVT_GRP` (kèm cột `REV_BWART`) và chứng từ xuất kho; (2) đặc tính lô `Z_*` chưa có nên các cột tương ứng trống là bình thường; (3) kiểm WT (ZWM04-005) dựa giả định `/SCDL/DB_PROCH_O-DOCNO` = số delivery, cần thử với delivery thật.
- **Cách user làm việc ở dự án BDP:** code tạo ở local trước, chỉ đẩy lên SAP qua MCP khi user yêu cầu; object tạo qua MCP phải gắn vào TR user chỉ định (TR cha `DEVK900552`; truyền TR cha, object vào task `DEVK900553`); GUI status, SM30, T-code, upload Smart Form do user tự làm trong GUI; câu hỏi cho BA phải nói rõ FS đang ghi gì ở mục nào rồi mới hỏi, viết ngắn 1 câu.
- **Smart Form:** sinh bằng `Smartforms/gen_zwm_sf_pxk.py` (theo skill `smartforms-xml`); máy không có Python thật, tải bản embeddable (xem memory `no-python-smartforms-generator`). Sửa form thì sinh lại rồi nhờ user Upload lại, không sửa tay file XML.
- **Phát hiện kỹ thuật đã ghi vào `_ghichu_mcp_gui.md`:** field client của bảng tạo bằng `CreateTableAtomic` là `MANDT`; `CreateStructureAtomic` báo lỗi chung nhưng vỏ vẫn tạo, xử lý bằng `UpdateObjectAtomic`; `EditSource` sửa include đang active được (multi-line vẫn chạy).

- Local: `Program/zwm_pg_pxk/` (`zwm_pg_pxk.abap` main, `zwm_in_pxk_top.abap`, `zwm_in_pxk_f01.abap`, `dictionary/zwm_st_pxk.md`). Khung và cách làm theo `ZWM03/Program/zwm_pg_pnk`.
- Kiểm trên DEV ngày 13/10: `ZTWM_MVT_GRP` 0 dòng; `ZTWM_PRTLOG` đã có; bảng EWM `/SCDL/DB_PROCH_O`, `/SCWM/ORDIM_O` có (EWM nhúng).
- **Đã tạo trên DEV (13/10/2026, theo yêu cầu user): bảng `ZTWM_MVT_TCODE`** (package `ZPK_BDP`, TR `DEVK900552` / task `DEVK900553` "DanhDH_WM_ZWM04_13.10.2026_Phiếu xuất kho"), active. Khóa: `MANDT`, `BWART`, `TCODE`; không có cột mô tả T-code (file mẫu ghi mô tả lấy từ `TSTCT` để hiển thị, không lưu). SM30 đã tạo (function group `ZFG_WM_MVT_TCODE`, `TVDIR` kiểm 13/10: one step, overview 0001, `ZPK_BDP`); chưa có foreign key sang `TSTC`, chưa có data. Code ZWM04 chưa dùng bảng này.

### 0.1 Checklist object trên DEV (kiểm bằng MCP 13/10/2026)

FS không yêu cầu view SM30, GUI status hay T-code cụ thể ngoài: T-code `ZWM04`, message class `ZWM04` (SE91), 2 biểu mẫu (Smartform/Adobe), bảng `ZTWM_MVT_GRP`, `ZTWM_PRTLOG` dùng chung. GUI status và SM30 là việc kỹ thuật phát sinh từ code.

| # | Object | Trạng thái | Việc cần làm |
|---|---|---|---|
| 1 | Program `ZWM_PG_PXK` + include `ZWM_IN_PXK_TOP`, `ZWM_IN_PXK_F01` | Đã tạo, package `ZPK_BDP`, TR `DEVK900552`; **SyntaxCheck sạch** (chỉ còn warning `MARC has a replacement object`, giống ZWM03), đã activate (13/10/2026) | Đã sửa 1 lỗi cú pháp ở `CHECK_OPEN_WT` (`FIELDS DISTINCT`), local và server cùng sửa |
| 2 | Structure `ZWM_ST_PXK` | **Đã tạo**, active, package `ZPK_WM`, TR `DEVK900552` (13/10/2026, qua MCP) | `ERFMG` có `@Semantics.quantity.unitOfMeasure` trỏ `ERFME` |
| 3 | Message class `ZWM04` | **Đã tạo**, package `ZPK_WM`, TR `DEVK900552`, 11 message (ngôn ngữ EN, nội dung tiếng Việt như ZWM03) | Bản tiếng Anh cần SE63 nếu muốn |
| 4 | Text symbols + Selection texts | **Đã ghi** (13/10/2026, qua MCP, ngôn ngữ EN): 3 text symbol, 16 selection text, kiểm lại bằng `GetTextElements` | Program đã activate lại sau khi ghi |
| 5 | GUI status `STANDARD` của `ZWM_PG_PXK` | **Đã có** (user tạo, `RSMPTEXTS` có `STANDARD`, 13/10) | Chưa kiểm nút nào còn / thừa; cách làm ở mục 0.2 |
| 6 | T-code `ZWM04` | **Đã có**, trỏ `ZWM_PG_PXK`, màn hình 1000, package `ZPK_BDP` | FS đề xuất tên chương trình `ZWM_R_ZWM04_PXK`, code dùng `ZWM_PG_PXK` như ECC và ZWM03 |
| 7 | Smart Form `ZWM_SF_PXK`, `ZWM_SF_PXK_OP2`, `ZWM_SF_PXK_OP4` | **Đã upload** (có trong TADIR và TR); file XML ở `Smartforms/FS_v1.0/` | Chưa in bằng chứng từ thật. Xem thử bằng dữ liệu mẫu qua `ZWM_PG_PXK_TEST` (hàng 13) |
| 8 | Bảng `ZTWM_MVT_TCODE` + SM30 | Đã tạo, SM30 đã tạo (`ZFG_WM_MVT_TCODE`, TOBJ `ZTWM_MVT_TCODES`) | `ZTWM_MVT_GRP` có SM30 riêng (`ZFG_WM_MVT_GRP`); view cluster `ZTWM_MVT_GRP` có trong TADIR nhưng `VCLSTRUC` trống, chưa rõ có dùng không |
| 9 | Data `ZTWM_MVT_GRP` | **0 dòng** | BA nhập qua SM30: MvT xuất (601, 631, 122, 124, 161, 261, Z11–Z17, 331, 333, 335, 543, 201, 551…) + `REV_BWART`; rỗng thì ZWM04-010 |
| 10 | Data `ZTWM_MVT_TCODE` | 0 dòng (code chưa dùng) | BA nhập theo sheet 2 file `FS/BDP_ZTWM_MVT_GRP 2.xlsx` |
| 11 | STVARV `ZWM04_MATKL_KSDB` (nhóm vật tư kiểm soát đặc biệt, mẫu 3) và `ZWM04_BWART_MAU` (MvT mẫu 4) — loại S | Chưa có, tùy chọn | `ZWM04_MATKL_KSDB`: khai báo khi BA chốt tiêu chí. `ZWM04_BWART_MAU`: không khai báo cũng chạy, mặc định 331, 333, 335 |
| 12 | Phân quyền role | Chưa kiểm | `S_TCODE` = `ZWM04`, `M_MSEG_WWA`, `M_MSEG_BWA`, `M_MSEG_LGO`, `S_SPO_DEV` (FS mục Phân quyền) |
| 13 | Program test form `ZWM_PG_PXK_TEST` (không có T-code, chạy SE38) | **Đã tạo** 13/10/2026 theo yêu cầu user: `ZPK_BDP`, TR `DEVK900552` (task `DEVK900553`), active, SyntaxCheck sạch, text elements đã ghi. Local: `Program/zwm_pg_pxk_test/zwm_pg_pxk_test.abap` | Dựng `GS_PARAMETER` + `IT_DATA` giống `ZWM_PG_PXK` bằng 8 dòng hàng mẫu (dòng cuối cố ý thiếu data lô), gọi đúng Smart Form theo mẫu 1–4. Không đọc chứng từ, không ghi `ZTWM_PRTLOG`. Tham số: mẫu in, song ngữ, cột ĐK bảo quản, dòng "đã trừ CT điều chỉnh", xem trước, số dòng (1–200), số phiếu (1–20), số lần đã in (>0 = bản in lại), Plant lấy header thật từ `ZCORE_FM_GET_PROFILE` (mặc định 1000, trống = chữ mẫu). **User chạy thử 13/10/2026: form hiện đúng, rồi nhờ xóa; đã xóa khỏi DEV qua MCP (`DeleteObjectAtomic`, TR `DEVK900552`), kiểm lại: `REPOSRC` trống, `TADIR` `DELFLAG = X`, `E071` vẫn còn dòng của task `DEVK900553` (bản ghi xóa, bình thường), nên không còn trên server.** File local giữ lại để tạo lại khi cần (cần user yêu cầu, gắn TR `DEVK900552`) |

Còn lại để chạy thử: mục 9 (data `ZTWM_MVT_GRP`) và dữ liệu thử: `MATDOC` DEV client 100 đang 0 dòng (kiểm 13/10), cần có chứng từ xuất kho (VD MvT 601, 261, 122) hoặc chạy ở hệ/client có data.

### 0.2 GUI status `STANDARD` (SE41)

1. SE41 → Program `ZWM_PG_PNK`, Status `STANDARD` → **Copy** (Ctrl+F5 hoặc nút Copy Status).
2. Hộp thoại: From = `ZWM_PG_PNK` / `STANDARD`; To = `ZWM_PG_PXK` / `STANDARD` → OK (chọn TR `DEVK900552` khi hỏi).
3. Mở `ZWM_PG_PXK` / `STANDARD` → Change → mục **Application toolbar**: xóa hai nút `DETAIL` ("Chi tiết điều chỉnh") và `EXCEL`; giữ `PREV` (Xem trước), `PRINT` (In), `SELALL` (Chọn tất cả).
4. Activate. Code ZWM04 xử lý đúng 3 mã `PREV`, `PRINT`, `SELALL` (xem `LCL_HANDLER=>ON_FUNCTION`).

### 0.3 Smart Form: upload 3 file XML

Các file ở `Smartforms/FS_v1.0/`: `ZWM_SF_PXK.xml` (mẫu 1 và 3), `ZWM_SF_PXK_OP2.xml` (mẫu 2), `ZWM_SF_PXK_OP4.xml` (mẫu 4). Mỗi file làm lần lượt:

1. Copy file ra đường dẫn ngắn (VD `C:\temp\`).
2. SMARTFORMS → nhập tên form (đúng tên file, VD `ZWM_SF_PXK`) → menu **Utilities → Upload form** → chọn file.
3. Kiểm tra Global Definitions → Form Interface: `GS_PARAMETER` (Type `ZCORE_ST_PARAMETER`), tables `IT_DATA` (Like `ZWM_ST_PXK`) → **Activate**. Package `ZPK_BDP`, TR `DEVK900552`.
4. Logo `ZLOGO_0001` đã nạp SE78 ở 100 dpi (như ZWM03). Style `ZCORE_STYLE_REPORT` đã có.

Thiết kế form (FS 2.5): A4 ngang; cột (14) ĐK bảo quản chỉ hiện khi `PARAMETER14` có giá trị (chương trình để trống khi bỏ chọn hoặc mẫu 4); hàng chữ ký mẫu 1, 2, 4 có 3 ô, mẫu 3 có 5 ô (khi `SIGN04` có giá trị) — chọn bằng điều kiện trong cùng form `ZWM_SF_PXK`. Mẫu 4 (layout ZWM20) dựng theo mô tả FS (không cột STT, Nồng độ, Độ ẩm, ĐK bảo quản; chữ ký Người lấy mẫu | Người kiểm tra | Thủ kho), **chưa đối chiếu với form ZWM20 gốc** (`ZWM_SF_PXKQI_EN` trên ECC). Tạo lại file: `PYTHONUTF8=1 python gen_zwm_sf_pxk.py FS_v1.0` (máy này không có Python thật, xem memory hoặc tải bản embeddable).

### 0.4 SM30 cho `ZTWM_MVT_TCODE`

1. SE11 → bảng `ZTWM_MVT_TCODE` → Change → menu **Utilities → Table Maintenance Generator**.
2. Điền giống cách `ZTWM_MVT_GRP` đã làm (đối chiếu `TVDIR`/`TDDAT` 13/10/2026): Authorization Group `&NC&`; Function group **mới** `ZFG_WM_MVT_TCODE` (không dùng chung `ZFG_WM_MVT_GRP` vì nhóm đó đã có màn hình `0001`); Package `ZPK_BDP`; Maintenance Type **One step**; Overview screen `1`; Single screen để trống.
3. **Create** → chọn TR `DEVK900552` (hoặc task `DEVK900553`) khi hỏi. Bảng này delivery class A nên dữ liệu SM30 nhập tay từng hệ, không tự vào TR (giống `ZTWM_MVT_GRP`).
5. Kiểm tra: SM30 → `ZTWM_MVT_TCODE` → Maintain, thêm thử 1 dòng (BWART `601`, TCODE `ZWM04`).
6. Mô tả T-code (từ `TSTCT`) không lưu trong bảng; nếu muốn hiển thị trong SM30 thì phải thêm vào maintenance view (không bắt buộc).

## 1. Đối chiếu source ECC với FS – những gì đã làm

Source ECC không đáp ứng FS, viết lại toàn bộ (giữ tên chương trình, include đặt theo kiểu ZWM03).

| # | ECC | FS yêu cầu / đã làm |
|---|---|---|
| 1 | 3 chương trình (ZWM04, ZWM041, ZWM20); ZWM04 chỉ có Chứng từ kho (bắt buộc) + 3 radio + song ngữ | 1 T-code, 4 mẫu in (radio). Màn hình chọn thêm Plant (bắt buộc), Năm, Ngày HT, MvT, SLoc, Lệnh xuất kho, Lệnh SX, Cost Center, Người tạo, cột ĐK bảo quản; bắt buộc Chứng từ kho **hoặc** Ngày HT ≤ 31 ngày (ZWM04-002) |
| 2 | In thẳng | ALV trung gian 1 dòng/chứng từ: Chọn, Chứng từ, Năm, MvT, SLoc, Đơn vị nhận, Diễn giải, Số lần in, User in lần cuối; nút Xem trước / In / Chọn tất cả |
| 3 | Đọc MSEG/MKPF + FOR ALL ENTRIES | Đọc `MATDOC` (`RECORD_TYPE = MDOC`), join `LIPS`/`LIKP` trong 1 câu; master data đọc 1 lần bằng `INNER JOIN @itab` |
| 4 | Mọi dòng Credit | Credit (`SHKZG = H`), MvT thuộc `ZTWM_MVT_GRP` trừ nhóm DC / TT / VT (chuyển kho – ZWM05), `XAUTO` trống, `SMBLN` trống (bỏ chứng từ đảo) |
| 5 | Không trừ SL đảo | SL thực xuất = SL dòng gốc − SL dòng đảo (SMBLN/SJAHR/SMBLP, hoặc MvT đảo của bảng qua LFBNR/LFBJA/LFPOS). = 0 → bỏ dòng; cả chứng từ = 0 → ZWM04-003. Chú thích số chứng từ đảo cuối bảng |
| 6 | Không kiểm quyền (code bị comment) | `M_MSEG_WWA` (Plant), `M_MSEG_BWA` (MvT), `M_MSEG_LGO` (Plant, SLoc, MvT); báo số dòng bị loại; loại hết → ZWM04-001 |
| 7 | Không kiểm WT | Delivery còn Warehouse Task mở (`/SCWM/ORDIM_O`) → không in chứng từ, ZWM04-005 |
| 8 | Header theo Company Code, gọi `ZCORE_FM_GET_PROFILE` với `E_NAME_N_TITLE`, `E_ADDRESS_EN` (**S/4 không còn 2 tham số này → dump**), `ZCORE_FM_GET_CRTRT_MULTIVAL` với tham số `EZ_*` (**cũng không còn → dump**) | Tên, địa chỉ, ĐT, Fax, Website theo Plant; MST theo Company Code; song ngữ đọc địa chỉ quốc tế (`I_NATION = 'I'`); đặc tính lô đọc qua `IT_CHARACT` |
| 9 | Đơn vị nhận: SMBLN → KUNNR → LIFNR → KOSTL → AUFNR → ANLN1; tên qua `ZCORE_FM_GET_PROFILE_SD` / hard-code theo MvT (331, Z40, Z12) | Thứ tự FS: Order (qua LIPS) → Ship-to (LIKP) → Cost Center → Asset; tên: BP (Name2+3+4), CSKT, ANLT, lệnh SX. Bỏ các nhánh hard-code theo MvT |
| 10 | Nồng độ = ghép 12 đặc tính `ZQC_HAMLUONG_A1..B6` + đơn vị | Đặc tính lô `Z_NONG_DO_HL` |
| 11 | Hạn dùng gộp với ngày KNL theo MTART Z21/Z41 | 2 cột riêng: (9) `MCHA-VFDAT`, (10) `MCHA-QNDAT` |
| 12 | Quy cách: `Z_QUY_CACH_BATCH` → `Z_QUYCACH` → `MARA-GROES` | `Z_QUYCACH_TPHH` → `Z_QUY_CACH_BATCH` → `MARA-GROES` |
| 13 | Lô NSX không có thì lấy số lô SAP | Bỏ nhánh này (đã có cột Số lô SAP) |
| 14 | ĐK bảo quản: đặc tính `Z_BAO_QUAN` | Tùy chọn; `Z_BAO_QUAN_BATCH` của lô → `MARA-RAUBE` → `T142T` |
| 15 | Diễn giải: Header text, rồi CASE hard-code MvT | `TXT_VI`/`TXT_EN` của `ZTWM_MVT_GRP`; không có thì `T156T`; không có nữa thì Header text |
| 16 | Không có nhật ký in | `ZTWM_PRTLOG` (TCODE = FORMNAME = `ZWM04`, OBJ_KEY = `<MBLNR>/<MJAHR>`, RPT_OPT = mẫu 1–4); chỉ ghi khi bấm **In** (Xem trước không ghi); lần in ≥ 2 in "Bản in lại – lần n" |
| 17 | Mẫu 4 (ZWM20) lấy MvT `Z40` + `TCODE2 = QA11` | Theo BA (13/10/2026): MvT xuất mẫu `331`, `333`, `335` (551 là xuất khác) |
| 18 | Form riêng `ZWM_SF_PXK_N2` cho kho B103 – Plant 2000 | FS không nêu → bỏ |
| 19 | 4 Smart Form VI + EN riêng | 3 form (mẫu 1 và 3 chung), song ngữ qua nhãn |

## 2. Logic chính / giả định

- **Phạm vi MvT**: chỉ MvT có trong `ZTWM_MVT_GRP` ngoài nhóm DC / TT / VT. Mã nhóm DC, TT, VT lấy theo file mẫu BA (`ZWM02/FS/BDP_ZTWM_MVT_GRP 2.xlsx`). Bảng rỗng → ZWM04-010 và dừng.
- **Khớp dòng bảng MvT**: dòng khớp đầu tiên theo `SEQNR` (điều kiện SOBKZ, có lệnh SX, Plant; trống = bất kỳ). Dùng `TXT_VI`/`TXT_EN` và `REV_BWART`. Điều kiện loại PO / Item Category của bảng không dùng cho xuất.
- **Đơn vị nhận (H3)**: Order = `LIPS-AUFNR` của delivery, không có thì `MATDOC-AUFNR` (xuất 261/Z11/Z12 không qua delivery; giả định). Rồi `LIKP-KUNNR` (Ship-to). **Thêm** `MATDOC-KUNNR` / `LIFNR` sau Ship-to (FS không nêu, cần cho xuất trả NCC 122/124/161 vốn không có delivery; giả định). Rồi Cost Center, rồi Asset.
- **Tên đơn vị nhận (H4)**: Ship-to/KH/NCC = `BUT000` `NAME_ORG2` + `3` + `4` (đúng chữ FS, thiếu thì lấy tên từ `ZCORE_FM_GET_PROFILE`); Cost Center = `CSKT-LTEXT`; Asset = `ANLT-TXT50`; Order = "Phân xưởng " + tên SLoc của thành phần đầu tiên trong lệnh (`RESB`, bỏ "NVL"; cách làm của ZWM03), thiếu thì `AUFK-KTEXT`. Địa chỉ (H5) chỉ có với KH/NCC, qua `ZCORE_FM_GET_PROFILE`.
- **Ngắt trang / gom dòng**: mỗi phiếu = chứng từ + SLoc + lệnh xuất kho + đơn vị nhận (FS: chỉ lấy dòng cùng Mã đơn vị nhận, Kho xuất, Lệnh xuất kho với header). Không cộng dồn dòng (ECC không cộng, FS không nêu). STT theo thứ tự dòng in.
- **Mẫu 4**: chỉ dòng MvT xuất mẫu (STVARV `ZWM04_BWART_MAU` loại S; chưa khai báo thì mặc định 331, 333, 335 theo BA); chứng từ không có dòng nào thuộc nhóm này → ZWM04-004, bỏ. MvT 551 là "xuất khác", in bằng mẫu 1–3. Luôn song ngữ, không cột STT/Nồng độ/Độ ẩm/ĐK bảo quản (FS 2.5: cột (2),(3),(6)–(13)).
- **Mẫu 2**: không cột Nồng độ, Độ ẩm (FS: (1)–(3), (6)–(13) + (14) nếu chọn).
- **Mẫu 3**: cảnh báo ZWM04-006 nếu chứng từ có vật tư ngoài nhóm kiểm soát đặc biệt; tiêu chí = Material Group trong STVARV `ZWM04_MATKL_KSDB` (loại S). STVARV chưa khai báo thì không cảnh báo. Tiêu đề không có bản EN (FS không nêu bản dịch). ECC chặn in song ngữ cho thuốc gây nghiện, FS không nêu nên code không chặn.
- **Độ ẩm**: `Z_DO_AM_PKN` (FS), thiếu thì `ZQC_DOAM1` (có trong mục Nguồn dữ liệu của FS).
- **Kiểm WT (ZWM04-005)**: FS để "Technical xác nhận ở TS". Code: `/SCDL/DB_PROCH_O` (`DOCNO` = số delivery ERP) nối `/SCWM/ORDIM_O` (`RDOCID = DOCID`, bảng WT chưa xác nhận). Giả định `DOCNO` chính là số delivery; cần thử trên DEV khi có data. Chứng từ có delivery như vậy bị bỏ khỏi ALV.
- **Chữ ký**: mẫu 1, 2: Người nhận | Thủ kho | Trưởng bộ phận; mẫu 3: 1 hàng 5 ô (Người giao | Người nhận | Thủ kho | Trưởng bộ phận | Giám đốc); mẫu 4: Người lấy mẫu | Người kiểm tra | Thủ kho.
- **Máy in**: máy mặc định của user (`USR01-SPLD`), không có thì hộp thoại chọn máy in. FS có cột máy in trong log nhưng `ZTWM_PRTLOG` không có → không ghi (bảng dùng chung).
- **F4 chứng từ kho**: giữ cách ECC/ZWM03 (gọi MB51, lấy PID MBN/MJA); cần thử lại trên DEV.
- **Performance**: không dùng FOR ALL ENTRIES; đọc 1 câu cho chứng từ + delivery; master data bằng `INNER JOIN @itab`; đặc tính lô gọi FM 1 lần/lô.

## 3. Câu hỏi còn mở cho BA

**Hiện không còn câu hỏi mở.**

- **Đã chốt (BA trả lời 13/10/2026): mẫu 4 in cho MvT xuất mẫu 331 / 333 / 335; 551 là xuất khác.** Câu hỏi trước đó: FS mục 2.3 (dòng STT 11 "Mẫu in") ghi *"Option 4 chỉ nhận MvT 551 – GI Scrapping"*, còn mục 2.6.3 ghi *"chỉ nhận MvT nhóm 'Xuất mẫu'"* và mục 2.6.1 ghi *"xuất mẫu 331, 333, 335"*. Code đã sửa theo BA: nhận 331/333/335 (STVARV `ZWM04_BWART_MAU`, chưa khai báo thì mặc định 3 mã này). FS mục 2.3 dòng STT 11 cần BA/tác giả FS sửa lại chữ "551" cho khớp.

Chỉ giữ câu hỏi mà FS tự mâu thuẫn ở yêu cầu chính và code xử lý khác nhau tùy câu trả lời. Các điểm còn lại (nguồn diễn giải, "Xưởng yêu cầu", nhóm vật tư kiểm soát đặc biệt, bảng nhật ký in) nằm ở mục giả định / thông báo theo `NOTE/note.md`.

### Giả định đã chọn (FS thiếu hoặc mâu thuẫn nhẹ, đoán được ý đồ, không hỏi BA)

- **Nguồn diễn giải (H7)**: FS H7 ghi *"Lấy MSEG-Movement Type tham chiếu vào T156T-Movement Type Text"*, mục Diễn giải nghiệp vụ ghi dùng `ZTWM_MVT_GRP` (*"khác: Header text"*). Code ưu tiên `ZTWM_MVT_GRP`, rồi `T156T`, rồi Header text; đổi thứ tự trong `RESOLVE_HEADER` nếu BA muốn khác.
- **"Xưởng yêu cầu" của Lệnh sản xuất (H4)**: FS ghi *"tham chiếu vào Lệnh sản xuất để lấy thông tin Xưởng yêu cầu"*, không nêu field. Code dùng "Phân xưởng " + tên SLoc của thành phần đầu tiên trong lệnh (đúng cách FS ZWM03 mô tả), thiếu thì tên lệnh (`AUFK-KTEXT`).
- **Bảng nhật ký in**: FS mục nút "In" ghi `ZTB_ZWM04`, còn mục Nhật ký in và Nguồn dữ liệu ghi `ZTWM_PRTLOG`. Code dùng `ZTWM_PRTLOG` (bảng đã có, dùng chung ZWM02/03).

### Chỉ thông báo BA (chưa cấu hình / chưa có data, code đã chạy tạm)

- Nhóm vật tư kiểm soát đặc biệt (cảnh báo ZWM04-006, mẫu 3): FS ghi *"tiêu chí dùng chung với ZWM02"*, FS ZWM02 mới ghi *"characteristic/Material Group theo BP MATERIAL"* chưa chốt → code đọc Material Group từ STVARV `ZWM04_MATKL_KSDB`, để trống thì không cảnh báo.

- `ZTWM_MVT_GRP` đang 0 dòng trên DEV → ZWM04 chưa chạy được; cần thêm các MvT xuất và cột MvT đảo. File mẫu của BA mới có dòng 331; mẫu 4 cần thêm 333 và 335 (cùng 551 là xuất khác).
- `ZTWM_MVT_TCODE` (bảng con theo file mẫu của BA) đã tạo kèm SM30 nhưng chưa có data; code chưa dùng bảng này, chỉ loại nhóm DC / TT / VT. Khi có data, có thể đổi cách lọc sang "MvT có T-code ZWM04".
- Đặc tính lô `Z_NONG_DO_HL`, `Z_DO_AM_PKN`, `ZQC_DOAM1`, `Z_NSX`, `Z_NUOC_SX`, `Z_BATCH_NSX`, `Z_QUYCACH_TPHH`, `Z_QUY_CACH_BATCH`, `Z_BAO_QUAN_BATCH` chưa có trên DEV → các cột tương ứng trống.
- MST theo Plant: FS ghi *"bảng tham số theo Plant"* nhưng chưa có bảng → tạm lấy MST theo Company Code (như ZWM03).
- Đơn vị nhận cho xuất trả NCC (122/124/161): code thêm `MATDOC-KUNNR`/`LIFNR` sau Ship-to vì FS không có nhánh NCC.
- MvT 541 (gia công, *"chờ xác nhận"*) và 643/645: không code riêng, chạy theo data `ZTWM_MVT_GRP` mà BA nhập.
- Chữ ký mẫu 3: FS ghi *"hợp nhất thành 1 hàng, chờ BIDIPHAR xác nhận"* → code in 1 hàng.
- STVARV `ZWM04_MATKL_KSDB` chưa khai báo → bỏ qua cảnh báo mẫu 3.
- `ZTWM_PRTLOG` không có cột máy in → chưa ghi máy in.

## 4. Khi BA trả lời / khi có dữ liệu

- Đổi MvT của mẫu 4: khai báo STVARV `ZWM04_BWART_MAU` (loại S) hoặc sửa 3 hằng số `GC_BWART_XM1..3`.
- BA chốt T156T trước ZTWM_MVT_GRP: đổi thứ tự trong `RESOLVE_HEADER`.
- BA chốt field "Xưởng yêu cầu": sửa nhánh Order trong `SET_RECIPIENTS`.
- BA chốt tiêu chí nhóm vật tư kiểm soát đặc biệt: sửa đọc STVARV trong `GET_MASTER_DATA` và kiểm tra trong `PRINT_DOCS`.
- Kiểm WT: thử với 1 chứng từ còn WT mở và 1 chứng từ đã xong trên DEV để xác nhận `DOCNO`.

## 5. Message class ZWM04 (VI / EN)

| Số | Loại | Nội dung |
|---|---|---|
| 001 | E | Bạn không có quyền trên Plant &1 / Movement Type &2. / You are not authorized for plant &1 / movement type &2. |
| 002 | E | Vui lòng nhập Chứng từ kho hoặc Ngày hạch toán (tối đa 31 ngày). / Enter material document or posting date (max. 31 days). |
| 003 | W | Chứng từ &1 đã được hủy/điều chỉnh toàn bộ, không in. / Document &1 fully reversed/adjusted, not printed. |
| 004 | E | Chứng từ &1 không phải nghiệp vụ xuất lấy mẫu – không in bằng mẫu 4. / Document &1 is not a sampling issue – cannot be printed with layout 4. |
| 005 | W | Chứng từ &1 còn Warehouse Task chưa xác nhận, chưa được in. / Document &1 has unconfirmed warehouse tasks, not printed. |
| 006 | W | Chứng từ &1 có vật tư không thuộc nhóm kiểm soát đặc biệt nhưng in bằng mẫu 3. / Document &1 has materials outside the special-control group but is printed with layout 3. |
| 007 | I | Chứng từ &1 đã in &2 lần. Bản in này được đánh dấu "Bản in lại". / Document &1 printed &2 times. This copy is marked "Reprint". |
| 008 | S | Không có dữ liệu thỏa điều kiện. / No data found. |
| 009 | E | Chưa chọn chứng từ. / No document selected. — thêm ngoài FS |
| 010 | S | Bảng ZTWM_MVT_GRP chưa khai báo Movement Type nào. / No movement type maintained in ZTWM_MVT_GRP. — thêm ngoài FS |
| 011 | W | Đã loại &1 dòng không có quyền (Plant &2 / Movement Type &3). / &1 items removed – no authorization (plant &2 / mvt &3). — thêm ngoài FS (mục Phân quyền yêu cầu báo số dòng bị loại) |

## 6. Interface Smart Form (3 form)

Import `GS_PARAMETER TYPE ZCORE_ST_PARAMETER`; Tables `IT_DATA LIKE ZWM_ST_PXK`. Nhãn song ngữ đã ghép sẵn dạng "Việt/ Anh" khi chọn In song ngữ (mẫu 4 luôn song ngữ). Mỗi lần gọi form = 1 phiếu.

| Field GS_PARAMETER | Nội dung |
|---|---|
| LOGO | `ZLOGO_0001` |
| HEADER01–06 | Tên Plant (in hoa), địa chỉ, "Điện thoại: …", "Fax: …", "MST: …" (theo Company Code), "Website: …" |
| HEADER39 / HEADER40 | Tên / địa chỉ quốc tế của Plant (chỉ song ngữ) |
| TITLE_REPORT / TITLE_REPORT_EN | Tiêu đề VI / EN (EN trống ở mẫu 3 và khi không song ngữ) |
| HEADER08 | (H2) "Ngày dd tháng mm năm yyyy" |
| HEADER09 / 10 | Nhãn / (H3) Mã đơn vị nhận |
| HEADER11 / 12 | Nhãn / (H4) Tên đơn vị nhận |
| HEADER13 / 14 | Nhãn / (H5) Địa chỉ |
| HEADER16 / 17 | Nhãn / (H6) Kho xuất "mã - tên SLoc" |
| HEADER18 / 19 | Nhãn / (H7) Diễn giải |
| HEADER20 / 21 | Nhãn / (H8) Lệnh xuất kho |
| HEADER22 / 23 | Nhãn / (H9) Số chứng từ kho |
| HEADER24 / 25 | Nhãn / (H10) Số chứng từ kế toán |
| PARAMETER01–14 | Tiêu đề cột (1) STT, (2) Mã hàng, (3) Tên hàng, (4) Nồng độ - Hàm lượng, (5) Độ ẩm, (6) NSX – Nước SX, (7) Số lô NSX, (8) Số lô SAP, (9) Hạn dùng, (10) Ngày KNL, (11) Quy cách, (12) ĐVT, (13) Số lượng, (14) ĐK bảo quản (trống khi không hiển thị hoặc mẫu 4) |
| SIGN01–05 | Nhãn các ô chữ ký (xem mục 2; ô trống = không in) |
| SIGN06 | "(Ký, ghi rõ họ tên)" |
| FOOTER03 | "In lúc: dd/mm/yyyy hh:mm:ss – User: …" |
| FOOTER05 | "Ngày ….. tháng ….. năm …….." |
| FOOTER06 | "Trang" (form tự in x/y) |
| FOOTER07 | "Bản in lại – lần n" (lần đầu trống) |
| ISO_LINE01 | "Lần in: 1" / "Bản in lại – lần n" |
| LONG_TEXT1 | Chú thích cuối bảng: "Số lượng đã trừ chứng từ điều chỉnh: …" (khi có chứng từ đảo) |

Cột theo mẫu (FS 2.5): mẫu 1 và 3 (1)–(13) + (14) nếu chọn; mẫu 2 (1)–(3), (6)–(13) + (14) nếu chọn; mẫu 4 (2), (3), (6)–(13), không STT. A4 ngang, lề trái 2 cm, còn lại 1,5 cm; Times New Roman, tiêu đề 16, nội dung 10.

## 7. Bắt đầu phiên mới

1. Đọc `CodeABAP/BDP/NOTE/note.md` rồi file này (mục 0).
2. Hỏi user đã chạy thử `ZWM04` chưa, kết quả/lỗi thế nào, BA đã nhập `ZTWM_MVT_GRP` và đã có chứng từ xuất kho để thử chưa.
3. Sửa code: sửa file local trước, rồi đẩy lên DEV bằng `EditSource` (include `/sap/bc/adt/programs/includes/zwm_in_pxk_top` hoặc `_f01`, `transport` = `DEVK900552`), `SyntaxCheck` chương trình thật `/sap/bc/adt/programs/programs/zwm_pg_pxk`, `Activate`; kiểm lại bằng `GrepObject` số dòng với bản local. SAP khóa object nếu user đang mở trong SE38 (lỗi EU510) → nhờ user thoát. Comment code tiếng Việt ngắn (theo `NOTE/note.md`); text elements ≤ 30 ký tự.
4. Nếu phải sửa form in: sửa `Smartforms/gen_zwm_sf_pxk.py`, sinh lại, chạy `sf_validate.py` so với `ZWM03/Smartforms/FS_v1.0/ZWM_SF_PNK.xml`, nhờ user upload lại.
