# ZWM11 – Báo cáo tồn kho theo thuộc tính lô (chương trình ZWM_PG_TONTHUOCTINH)

FS: `FS/BIDIPHAR_FS_EWM_ZWM11_TonKhoTheoThuocTinh_v1.0.docx` (v1.0, 17/09/2026, người tạo Võ Hoàng Tuyên). Hệ: S/4 On-Premise, MCP `GUI_BDP_DEV_200` (client 200, release 816, HDB). Đẩy lên DEV qua MCP `GUI_BDP_DEV_100` (client 100) khi user cho phép, TR `DEVK900647` (task `DEVK900648`).

## 0. TRẠNG THÁI (15/10/2026) – ĐỌC TRƯỚC

**Tình trạng cuối ngày 15/10/2026: code xong, đã có trên DEV_100 và active, CHƯA CHẠY THỬ lần nào** (chưa mở ZWM11 trên SAP GUI; DEV client 100 gần như không có dữ liệu, chạy thử ở client 200 theo kịch bản mục 4). Chương trình `ZWM_PG_TONTHUOCTINH` + 2 include do user tạo và dán, Claude kiểm / sửa / tạo phần còn thiếu (mục 0.3). Kiểm lần cuối bằng MCP (15/10/2026): `REPOSRC` chỉ còn dòng `A`; `SyntaxCheck` chương trình thật (main + `INCLUDE`) không lỗi, chỉ warning `ATWRT / ATFLV may contain NULL values` và `MARC replacement object`; ATC 0 lỗi, 0 warning (còn info "chuỗi chưa đưa vào text element", giống ZWM05); bản local khớp bản trên server.

**Kiểm lại bằng MCP `GUI_BDP_DEV_200` ngày 16/10/2026 (đối chiếu FS v1.0 từng mục):** code khớp FS (2.3 màn hình chọn, 2.4–2.5 cột / nút, 2.6.1–2.6.4, 2.7 sắp xếp, 2.8 message 001–008); `REPOSRC` 3 dòng `A` (`UDAT` 15/10, không đổi), không có object ZWM11 nào inactive, message class `ZWM11` có 11 message (`T100` chỉ ngôn ngữ `E`, nội dung tiếng Việt, FS ghi "song ngữ Việt – Anh" chưa làm), `ZTWM_CHAR_PARAM` trống ở client 200. MCP không chạy được report (`RunReport` / `ExecuteABAP` bị chặn), nên chưa có lần chạy thật nào; chỉ kiểm bằng `RunQuery` các bước dữ liệu tương đương (kịch bản mục 4). Chỗ còn lệch FS: không kiểm `M_MATE_STA`, `C_KLAH_BKL`, `S_GUI` (mục 3), chưa dùng chung routine với ZMM60, `ZWM11-004` chỉ kiểm định dạng số / ngày (không kiểm giá trị CHAR theo `CAWN`), cột "HSD còn lại" hiện 0 khi lô chưa có HSD.

**Việc còn lại của dev (đọc cái này đầu tiên):**
1. **User: thử event 01 của SM30** theo mục 0.2 E bước 5 (nhập `ATNAM` sai phải báo ZWM11-011 và không lưu; nhập đúng thì `ATBEZ` tự có). Event đã tạo và active (kiểm 16/10/2026: `TVIMF` `01` → `CHECK_CHAR_PARAM`, `LZFG_CHAR_PARAMF01` và `SAPLZFG_CHAR_PARAM` đều `A`, không còn object inactive), chưa thử chạy.
2. **Chạy thử ZWM11 ở client 200 (16/10/2026 10:27): màn hình chọn và ALV chạy được, nhưng ALV báo "Object Column CH01 not found" (`GET_COLUMN`)** nên 15 cột thuộc tính hiện nhãn mặc định, không ẩn. Đã sửa ở local (`DISPLAY_ALV`: lấy cột động theo vị trí sau cột `STATUS` thay vì theo tên `CHnn`; thêm `set_zero( abap_false )` cho `HSDCL` để lô chưa có HSD không hiện 0), `SyntaxCheck` sạch. **Đã đẩy lên DEV_100 lúc 10:37 ngày 16/10/2026** qua `EditSource` vào TR `DEVK900647` (3 lần sửa include F01, đều activate thành công; `REPOSRC` 3 dòng `A`; ATC 0 lỗi, 0 warning, 31 info). **User: chạy lại ZWM11** để kiểm lỗi cột đã hết chưa, rồi thử tiếp theo mục 4, báo kết quả / chụp ảnh lỗi. Các chỗ chưa thể kiểm bằng MCP: hiển thị ALV, nút `MSC3N`, double-click, sinh khối lọc khi đổi Batch Class, F4 giá trị thuộc tính.
3. Release TR `DEVK900647` sau khi test xong.
4. Bản tiếng Anh message class `ZWM11` (FS ghi song ngữ Việt – Anh), qua SE63 hoặc `WriteMessageClassTexts`; dùng chung routine với ZMM60 khi ZMM60 làm xong (hiện chưa có routine, mục 0).

**Không phải việc dev (data / cấu hình, chỉ thông báo cho BA / Key user / Basis, theo `NOTE/note.md`):**
- Nhập data `ZTWM_CHAR_PARAM` qua SM30 (bảng trống mọi client; code vẫn chạy: tick tất cả, tối đa 15 thuộc tính; thử với class `B_BATCH`, mục 0.2 B bước 3).
- Gán quyền role (`S_TCODE` = `ZWM11`, `M_MSEG_WMB`, `M_MSEG_LGO`, `M_MATE_MAR`, `M_MATE_CHG`, `S_TABU_NAM` cho `ZTWM_CHAR_PARAM`; có kiểm thêm `M_MATE_STA`, `C_KLAH_BKL`, `S_GUI` hay không thì Basis / BA quyết, mục 3).
- Dữ liệu thử thiếu trên DEV: Batch Class `Z_*` như hình FS, HSD của lô (đang trống), `MARM` đầy đủ.

**Đã xong (không cần làm lại):** 2 data element, bảng `ZTWM_CHAR_PARAM` (+ log bảng + SM30 `ZFG_CHAR_PARAM`), message class `ZWM11` (11 message), text elements, program + 2 include, GUI status `STANDARD`, T-code `ZWM11`; tất cả nằm trong task `DEVK900648` (TR cha `DEVK900647`).

**Cách làm việc khi sửa tiếp (rút từ phiên 15/10/2026):**
- Sửa local trước, chỉ đẩy lên DEV khi user bảo. Ghi lên DEV qua MCP `GUI_BDP_DEV_100` (client 100, truyền TR cha `DEVK900647`); `GUI_BDP_DEV_200` chỉ đọc dữ liệu (client 200 có lô, vật tư, class `B_BATCH`).
- Sửa include bằng `EditSource` (`/sap/bc/adt/programs/includes/<tên thường>`); nhớ `CLASS LCL_HANDLER DEFINITION` đang nằm trong F01 (không để trong TOP, nếu không activate riêng từng include bị lỗi ngầm). Sau mỗi lần sửa: `SyntaxCheck` chương trình thật, `RunQuery` `REPOSRC` chỉ còn `A`, `RunATCCheck`.
- Đổi field trong TOP khi F01 còn dùng: thêm field mới, sửa F01, rồi mới bỏ field cũ.
- Không đưa biểu thức (`COND`, `VALUE`, `|...|`) trực tiếp vào tham số `PERFORM`; gán biến trước (xem `_ghichu_local.md`).
- `CreateTableAtomic` tạo field client sai (`CLIENT` không data element): luôn kiểm `DD03L` và sửa bằng `UpdateObjectAtomic` (xem `_ghichu_mcp_gui.md`).

Local: `Program/zwm_pg_tonthuoctinh/` (`zwm_pg_tonthuoctinh.abap` main, `zwm_in_tonthuoctinh_top.abap`, `zwm_in_tonthuoctinh_f01.abap`, `dictionary/ztwm_char_param.md`). Khung theo ZWM05 (`ZWM05/Program/zwm_pg_pck`).

**Source ECC user đưa (`CODE_FINAL/zwm_pg_bcsdnlcccgn`) không dùng lại được**: đó là báo cáo sử dụng nguyên liệu chứa chất gây nghiện (ZWM11/11A/12 cũ, đã gộp về ZWM10); không có đọc classification. FS mục 1.1 ghi rõ ZWM11 trên S/4 là báo cáo mới, không liên quan chức năng cũ → viết mới hoàn toàn.

**Phát hiện khi đối chiếu FS với DEV (client 200):**
- FS ghi `KLART = 022` nhưng DEV dùng class type **023** cho lô (INOB `MCH1`, bảng `TCLA`). Code **không hard-code**: lấy cấp lô bằng `VB_BATCH_DEFINITION`, class type bằng `CLOB_GET_CLASSTYPE_FOR_BATCH` (cùng cách `QMSP_MATERIAL_BATCH_CLASS_READ`); lỗi thì dùng 022 / `MCHA` theo FS.
- DEV chỉ có 2 class loại 023: `B_BATCH` (37 characteristic, gồm `Z_NSX`, `Z_NUOC_SX`, `Z_BATCH_NSX`, `Z_QUYCACH_TPHH`, `ZQC_POTENCY`...) và `SAP_EWM_LOBM`. Chưa có `Z_NVL` như hình mẫu FS. Chỉ 8 lô được phân loại (`INOB`), 44 lô `MCHA` / 40 dòng `MCHB`, `VFDAT` / `HSDAT` đều trống.
- `B_BATCH` có 37 thuộc tính, FS giới hạn 15 dòng lọc → dùng `ZTWM_CHAR_PARAM` để chọn thuộc tính hiển thị trên ALV (bảng đã tạo, mục 0.1; data cần BA nhập, mục 3).
- FS yêu cầu "dùng chung routine sinh cột characteristic với ZMM60": routine đọc characteristic của ZMM60 trên DEV (`f_enrich_batch_class`, ZMM_PG_ZMM60) mới là khung rỗng → chưa có gì để dùng chung. Logic sinh khối lọc / đọc giá trị nằm trong các FORM `BUILD_CHAR_LIST`, `GET_CHAR_VALUES`, `FMT_VALUE` của F01, tách sang include / class dùng chung được khi ZMM60 làm xong; khi đó phải kiểm thử hồi quy cả hai báo cáo (FS 2.6.1).
- FS mục 3 ghi nguồn tồn là `MCHB` / `MARD`, nhưng trên S/4 hai bảng này bị `SyntaxCheck` cảnh báo "replacement object" → code đọc từ CDS entity `NSDM_E_MCHB` / `NSDM_E_MARD` (cùng tên field `CLABS`, `CINSM`, `CSPEM`, `LABST`, `INSME`, `SPEME`, `LVORM`; kiểm `RunQuery` + `SyntaxCheck` 15/10/2026, hết cảnh báo, số liệu khớp bảng cũ trên DEV). `MARC` (chỉ đọc cờ `XCHPF`) vẫn còn warning như ZWM05. Cần đối chiếu tổng tồn với MB52 / MMBE khi có data thật.
- `MCHA` có đủ `VFDAT`, `HSDAT`, `QNDAT`, `ZUSTD`, `LVORM` (FS ghi đúng `MCHA-QNDAT`).

### 0.1 Checklist object trên DEV (kiểm bằng MCP 15/10/2026)

| # | Object | Trạng thái | Việc cần làm |
|---|---|---|---|
| 1 | 2 data element `ZDE_WM_CHAR_DESC` (domain `TEXT40`), `ZDE_WM_CHAR_SHOW` (domain `XFELD`) | **Đã tạo** (15/10/2026), `ZPK_BDP`, task `DEVK900648`, đủ nhãn tiếng Việt | Field Class / Characteristic dùng data element chuẩn `KLASSE_D`, `ATNAM` |
| 2 | Bảng `ZTWM_CHAR_PARAM` | **Đã tạo**, active, `ZPK_BDP`, delivery class A; tool tạo field client thành `CLIENT` không data element, đã sửa lại `MANDT` / `MANDT` (kiểm `DD03L`) | Cấu trúc ở `dictionary/ztwm_char_param.md`; đã nối vào FORM `READ_CHAR_CONFIG` |
| 3 | Message class `ZWM11` (11 message, mục 5) | **Đã tạo**, `ZPK_WM`, task `DEVK900648`; `T100` có đủ 11 dòng (011 thêm 15/10/2026) | Bản tiếng Anh cần SE63 nếu muốn |
| 4 | Program `ZWM_PG_TONTHUOCTINH` + include `ZWM_IN_TONTHUOCTINH_TOP`, `ZWM_IN_TONTHUOCTINH_F01` | **Đã có và active** (15/10/2026), `ZPK_BDP`, task `DEVK900648`; `CLASS DEFINITION` nằm trong F01 | Xem mục 0.3 |
| 5 | Text elements + selection texts | **Đã ghi và activate**: 7 text symbol, 46 selection text (gồm `P_H01–15`, `S_C01–15`) | — |
| 6 | GUI status `STANDARD` của program | **Đã xong** (user làm lại 16/10/2026 09:30, `D342L` `UDAT` 16/10, version 49). Ảnh SE41 user chụp: toolbar chỉ còn các nút ALV chuẩn (`&ETA`, `&EB9`, `&ALL`, `&SAL`, `&OUP`, `&ODN`, `&ILT`, `&UMC`, `&SUM`, `&XPA`, `&OMP`, `&XXL`, `&AQW`, `%PC`, `%SL`, `&ABC`, `&OLO`, `&OAD`, `&AVE`, `&LFO`, `&NFO`) và `MSC3N` ở ô 29; mô tả "Standard for General List Output", function key "Standard Maximum Interaction". Không còn `EXCEL`, `PREV`, `PRINT`, `SELALL` trên toolbar | Không cần làm gì. `RSMPTEXTS` còn text cũ của `DETAIL`, `EXCEL`, `PREV`, `PRINT`, `SELALL` (không hại); danh sách function của status còn mã `DETAIL`, `PRINT` nhưng không nằm trên toolbar, code bỏ qua mã lạ. Menu bar và function key chưa thấy chi tiết (ảnh chỉ có toolbar) |
| 7 | T-code `ZWM11` | **Đã có** (kiểm 15/10/2026: `TSTC` `ZWM_PG_TONTHUOCTINH`, screen 1000, `CINFO` 80 như ZWM05; text "Báo cáo tồn kho theo thuộc tính"; `ZPK_BDP`, task `DEVK900648`) | — |
| 8 | Log bảng + SM30 + event kiểm Characteristic cho `ZTWM_CHAR_PARAM` | **Log đã bật** (`DD09L-PROTOKOLL = X`, `APPL0`). **SM30 đã tạo** (`TVDIR`: function group `ZFG_CHAR_PARAM`, one step, màn hình 1; `TDDAT` nhóm quyền `&NC&`; TR có `FUGR`, `SVIM`, `TOBJ ZTWM_CHAR_PARAMS`). **Event 01 đã tạo và active** (16/10/2026: `TVIMF` `01` → `CHECK_CHAR_PARAM`, include `LZFG_CHAR_PARAMF01` + `SAPLZFG_CHAR_PARAM` đều `A`) | User thử SM30 theo mục 0.2 E bước 5 |
| 9 | Phân quyền role | Chưa kiểm | `S_TCODE` = `ZWM11`, `M_MSEG_WMB`, `M_MSEG_LGO`, `M_MATE_MAR`, `M_MATE_CHG` (ACTVT 03), `S_TABU_NAM` (`ZTWM_CHAR_PARAM`) |
| 10 | Data `ZTWM_CHAR_PARAM` | Trống | BA / Key user nhập qua SM30 (dữ liệu mẫu BA ở mục 0.2 B bước 3) |

### 0.3 Việc đã làm trên DEV_100 ngày 15/10/2026 (user tạo program + include, lưu vào TR `DEVK900647`)

- **Kiểm**: 3 object nằm trong task `DEVK900648`, package `ZPK_BDP`, source trên server khớp local. `SyntaxCheck` chương trình thật báo **1 lỗi**: không được đưa `COND string( ... )` trực tiếp vào tham số `PERFORM` (`DISPLAY_ALV`, đặt biểu thức ra biến `LV_LABEL` trước). Đã sửa cả local và server.
- **Activate**: 3 object còn dòng `I` treo (`REPOSRC`) vì TOP chứa `CLASS DEFINITION`, F01 chứa `IMPLEMENTATION` nên không activate riêng được (xem `_ghichu_mcp_gui.md`, case ZWM07). Cách làm: ghi chương trình chính khung `REPORT` + 2 `INCLUDE`, chuyển `CLASS LCL_HANDLER DEFINITION` từ TOP sang ngay trên `IMPLEMENTATION` trong F01 (local cũng đã đổi), activate TOP rồi F01, cuối cùng ghi lại chương trình chính đầy đủ. `REPOSRC` còn đúng 3 dòng `R3STATE = A`.
- **Tạo**: message class `ZWM11` (`ZPK_WM`, 10 message ban đầu, thêm 011 sau; task `DEVK900648`); text elements (7 text symbol, 46 selection text) rồi activate text pool.
- **Sửa nhỏ theo ATC** (đã vào cả local): `MESSAGES_INITIALIZE` thêm `EXCEPTIONS OTHERS = 1`; `CATCH` của SALV có xử lý (`MESSAGE ... TYPE 'S' DISPLAY LIKE 'E'`). ATC trước khi sửa: 0 lỗi, 3 warning mức 2, 30 info (chuỗi chưa đưa vào text element, `MARC` replacement object).
- **Bảng cấu hình (BA gửi cấu trúc 15/10/2026, file `FS/BDP_ZWM11_ZTWM_CHAR_PARAM.xlsx`)**: đã tạo `ZTWM_CHAR_PARAM` + 2 data element (mục 0.1), nối vào code: `READ_CHAR_CONFIG` đọc bảng, `ATBEZ` làm nhãn, `SHOW_ALV` làm tick "Hiển thị" mặc định (mục 2). Thêm message `ZWM11-011` cho event kiểm Characteristic. Sửa `ZWM_IN_TONTHUOCTINH_TOP` / `_F01` trên server theo thứ tự tương thích, ATC sau khi sửa 0 lỗi, 0 warning, `REPOSRC` toàn `A`.
- **Sau đó user đã tự làm** (kiểm lại bằng MCP cuối ngày 15/10/2026): GUI status `STANDARD`, T-code `ZWM11`, log bảng + SM30 `ZFG_CHAR_PARAM`. Riêng event 01 của SM30 chưa làm (xem "Việc còn lại" ở đầu mục 0).
- **Dữ liệu thử**: DEV client 100 gần như trống (xem `ZWM05/ghi_chu.md`); client 200 mới có lô, vật tư, class `B_BATCH` (mục 4). Chạy thử ở client 200.

### 0.2 Hướng dẫn việc user làm (A–D đã xong; E chưa làm, giữ làm tham khảo / tạo lại ở hệ khác)

Giá trị lấy theo ZWM05 đã làm và kiểm bằng MCP (`TVDIR`, `TDDAT`, `TSTC`: `ZWM05` → `ZWM_PG_PCK`, screen 1000, `CINFO` 80); `SAPLSALV_METADATA_STATUS` kiểm có trong `TRDIR` ngày 15/10/2026.

**A. Bật log thay đổi dữ liệu `ZTWM_CHAR_PARAM`** (làm trước B)

1. SE11 → Database table = `ZTWM_CHAR_PARAM` → **Change**.
2. Menu **Goto → Technical Settings**. Data class `APPL0`, Size category `0`, Buffering not allowed (giữ nguyên, giống `ZTWM_MVT_GRP`).
3. Tick **Log data changes** → Save → chọn TR / task.
4. Back → **Activate** (Ctrl+F3).

**B. SM30 (Table Maintenance Generator)**

| Ô trong màn hình | Giá trị |
|---|---|
| Authorization Group | `&NC&` |
| Function group | `ZFG_CHAR_PARAM` (user đã tạo đúng tên này, 15/10/2026) |
| Package | `ZPK_BDP` |
| Maintenance type | One step |
| Overview screen | `1` |
| Single screen | để trống |

1. SE11 → `ZTWM_CHAR_PARAM` → **Change** → menu **Utilities → Table Maintenance Generator**.
2. Điền theo bảng trên → bấm **Create** → chọn TR / task → thoát.
3. Kiểm tra: SM30 → `ZTWM_CHAR_PARAM` → **Maintain** → thêm thử dòng. Dữ liệu mẫu BA (file `FS/BDP_ZWM11_ZTWM_CHAR_PARAM.xlsx`): `CLASS` = `B_BATCH`, `ATNAM` = `ZQC_POTENCY`, `ATBEZ` = `QC API`, `SHOW_ALV` = `X`; `B_BATCH` / `Z_BAO_QUAN` / `Điều kiện bảo quản_Mã` / (trống); `Z_BATCH` / `Z_BATCH_NSX` / `Lô NSX` / `X`. Trên DEV chỉ có class `B_BATCH` (và `SAP_EWM_LOBM`), không có `Z_BATCH`; `Z_BATCH_NSX` thuộc `B_BATCH`, nên để thử chương trình hãy nhập với class `B_BATCH`.

**E. Event kiểm tra Characteristic và điền mô tả** (BA: "Characteristic phải có trong `CABN-ATNAM`; mô tả lấy từ hệ thống"). Làm sau B.

1. SE11 → `ZTWM_CHAR_PARAM` → **Change** → **Utilities → Table Maintenance Generator** → menu **Environment → Modification → Events**.
2. Bấm **New Entries**: cột `T` = `01` (Before saving the data in the database), cột Form routine = `CHECK_CHAR_PARAM`.
3. Bấm biểu tượng editor (cây bút) ở dòng đó → SAP hỏi include để chứa form (đề xuất sẵn tên dạng `LZFG_CHAR_PARAMF01`; hiện chưa có include nào tên này, kiểm `TRDIR` 16/10/2026) → nhận đề xuất, Create, chọn TR / task `DEVK900647`.
4. Trong editor, xóa khung `FORM check_char_param. ... ENDFORM.` SAP tự sinh, dán FORM `CHECK_CHAR_PARAM` từ file `Program/zwm_pg_tonthuoctinh/dictionary/ztwm_char_param_tmg_event01.abap` → Save → Activate (Ctrl+F3, tick cả function group `ZFG_CHAR_PARAM` nếu hỏi). Quay lại màn hình Events, bấm **Save** để ghi dòng event (`TVIMF`) vào TR.
5. Thử: SM30 nhập Characteristic sai (VD `ABC`) rồi Save → báo ZWM11-011 và không lưu; nhập `ZQC_POTENCY` rồi Save → cột mô tả tự có (lấy từ `CABNT`, ngôn ngữ đăng nhập).

Lưu ý: BA ghi lấy mô tả từ `CABN-ATBEZ` nhưng `CABN` không có field này, mô tả nằm ở `CABNT-ATBEZ`. Đoạn code event chưa chạy thử (MCP không tạo được TMG). Ngày 16/10/2026 kiểm cú pháp trong ngữ cảnh function group `ZFG_CHAR_PARAM` (`SyntaxCheck` trên chương trình chính của function group, xem `_ghichu_mcp_gui.md`): bản đầu dùng `<vim_total_struc>-atnam` bị lỗi "does not have a structure" (field symbol này khai báo `TYPE any`), đã sửa thành `ASSIGN COMPONENT` và kiểm lại không lỗi. Nếu activate báo lỗi khác thì gửi lại thông báo lỗi.

**C. GUI status `STANDARD` (SE41)**

1. SE41 → Program `SAPLSALV_METADATA_STATUS`, Status `SALV_TABLE_STANDARD` → **Copy** (menu Status → Copy hoặc Ctrl+F5). Status này có thật trên DEV (kiểm `D342L` 15/10/2026, cùng `SALV_TABLE_STDPOPUP`). Cách thay thế: copy `STANDARD` của `ZWM_PG_PCK` (ZWM05), nhưng phải xóa nút `PREV`, `PRINT`, `SELALL`, `EXCEL` vì ZWM11 không xử lý; các chương trình ZWM khác có `STANDARD`: `ZWM_PG_PXK`, `ZWM_PG_PNK`, `ZWM_PG_TKBIN`, `ZWM_PG_PYCVT`, `ZWM_PG_LCVT`, `ZWM_PG_BBKNHH` (MCP không đọc được nội dung status, nhưng `RSMPTEXTS` cho xem danh sách function code, đối chiếu 15/10/2026: `SAPLSALV_METADATA_STATUS` có đủ function chuẩn của SALV — `&UMC` Total, `&ILT` Set Filter, `&OL0` Change Layout, `&XXL` Spreadsheet, `&ODN`/`&OUP` sắp xếp...; `STANDARD` của `ZWM_PG_PCK` = bộ function chuẩn tương tự + 5 function riêng `DETAIL` "Chi tiết điều chỉnh", `EXCEL`, `PREV`, `PRINT`, `SELALL`. Nếu copy từ `ZWM_PG_PCK` thì đổi luôn nút `DETAIL` thành `MSC3N` / "Chi tiết lô (MSC3N)" và xóa 4 nút còn lại). Đã kiểm `RSMPTEXTS` các Tcode ZWM làm bằng SALV (15/10/2026): `ZWM_PG_BBKNHH` (ZWM02) có 4 nút riêng `PREV`, `PRINT`, `SELALL`, `EXCEL`; `ZWM_PG_PNK` (ZWM03), `ZWM_PG_PXK` (ZWM04), `ZWM_PG_PCK` (ZWM05), `ZWM_PG_LCVT` (ZWM07) có 5 nút (thêm `DETAIL` "Chi tiết điều chỉnh"); **không status nào có sẵn `MSC3N`** và không cái nào chỉ có 1 nút riêng. ZWM01, ZWM2D, ZRSD26, ZRSD27 dùng `SET PF-STATUS` trong dynpro nên không dùng lại được.
2. Hộp thoại: To Program = `ZWM_PG_TONTHUOCTINH`, To Status = `STANDARD` → OK → chọn TR / task.
3. Mở `ZWM_PG_TONTHUOCTINH` / `STANDARD` → **Change** → **Application toolbar**: thêm 1 nút, Function code `MSC3N`, Function text `Chi tiết lô (MSC3N)`, icon `ICON_DISPLAY` (hoặc bất kỳ icon xem chi tiết).
4. **Activate**. Code xử lý mã `MSC3N` (`LCL_HANDLER=>ON_FUNCTION`); các nút chuẩn (Σ, filter, layout, Export) do SALV tự xử lý. Chưa tạo status thì chương trình dump khi hiển thị ALV, nên làm trước khi chạy thử.

**D. T-code `ZWM11` (SE93)**

1. SE93 → Transaction code = `ZWM11` → **Create**.
2. Short text = `Tồn kho theo thuộc tính lô` → chọn **Program and selection screen (report transaction)**.
3. Program = `ZWM_PG_TONTHUOCTINH`, Screen number = `1000`.
4. GUI support: tick **SAPGUI for HTML**, **SAPGUI for Java**, **SAPGUI for Windows** (như ZWM05).
5. Save → Package `ZPK_BDP`, TR / task.

**F. Xong thì báo Claude để kiểm lại bằng MCP** (đã kiểm A–D ngày 15/10/2026; E chưa làm).

## 1. Đối chiếu FS – những gì đã làm

| FS | Code |
|---|---|
| 2.3 tham số 1–2 (Plant bắt buộc, SLoc / Vật tư / Material Type / Nhóm vật tư / Lô) | `P_WERKS` (mặc định 1000), `S_LGORT`, `S_MATNR`, `S_MTART`, `S_MATKL`, `S_CHARG` |
| 3 Batch Class | `P_CLASS` (F4 liệt kê class của class type lô), `P_AUTO` "Sinh khối lọc thuộc tính" (hình 2 FS): tick thì đổi class sẽ tự sinh khối lọc |
| 4 Điều kiện thuộc tính, tối đa 15 dòng | 15 dòng sinh sẵn trên màn hình chọn (tick Hiển thị + nhãn + khoảng từ–đến, chọn nhiều giá trị bằng nút mũi tên); dòng thừa ẩn bằng `LOOP AT SCREEN`. CHAR: nhập giá trị / pattern / danh sách, F4 lấy từ `CAWN`; NUM / DATE: nhập theo định dạng người dùng, đổi sang float (`C14W_CHAR_NUMBER_CONVERSION`, `CONVERT_DATE_TO_INTERNAL`) |
| Nút "Lấy thuộc tính theo Batch Class" | Function key 1 của màn hình chọn (`FC01`): sinh lại khối lọc; không chọn class thì lấy hợp thuộc tính của các vật tư trong phạm vi |
| 5–9 Loại tồn, chỉ lô còn tồn, bao gồm lô khóa / hết hạn, ĐVT quy đổi, ngày tham chiếu, Layout | `P_UNR`, `P_QI`, `P_BLK`, `P_ONLY`, `P_INCL`, `P_MEINH`, `P_DATE`, `P_LAYO` |
| 2.6.2 Lọc thuộc tính trên DB trước khi lấy tồn; AND giữa thuộc tính, OR trong 1 thuộc tính | `GET_BATCH_FILTER`: giao dần từng điều kiện trên `AUSP` (mỗi điều kiện 1 `SELECT` join với tập kết quả trước), đổi đối tượng phân loại (`INOB`) sang khóa lô, rồi `GET_STOCK` join `NSDM_E_MCHB` với tập lô đó |
| Lô không có giá trị thuộc tính đang lọc → loại | Tự đúng do join `AUSP` |
| Vật tư không quản lý lô: hiện khi không có điều kiện thuộc tính | `GET_STOCK` đọc `NSDM_E_MARD` (vật tư `XCHPF` trống ở `MARA` và `MARC`); bỏ qua phần không lô khi có điều kiện thuộc tính hoặc lọc theo lô |
| 2.5 Cột (1)–(10) | `BUILD_ALV_DATA`: Plant / SLoc, vật tư + mô tả, lô SAP, Lô NSX (`Z_BATCH_NSX` → `MCHA-LICHA` → lô SAP), ĐVT cơ sở, 3 loại tồn + tổng tồn (cộng loại được tick), SL / ĐVT theo ĐVT chọn, Ngày SX / HSD / Retest, HSD còn lại, cột thuộc tính động `CH01–CH15` (nhãn theo `ZTWM_CHAR_PARAM`) |
| Quy đổi ĐVT | `CONVERT_QTY`: FM chuẩn `MD_CONVERT_MATERIAL_UNIT` (theo MARM), làm tròn theo số lẻ ĐVT đích (`T006-ANDEC`); chưa khai báo quy đổi thì để trống + ZWM11-005, mỗi vật tư báo 1 lần; không dùng hệ số vật tư khác |
| Loại trừ và cảnh báo | Lô đánh dấu xóa (`NSDM_E_MCHB-LVORM` / `MCHA-LVORM`) không hiện. Lô hết hạn (`VFDAT` < ngày tham chiếu) hoặc hạn chế sử dụng (`MCHA-ZUSTD = X`) chỉ hiện khi tick `P_INCL`, đánh dấu ở cột "Trạng thái"; HSD còn lại âm tô đỏ (HSD còn lại, HSD, Trạng thái) |
| Cộng tổng chỉ cộng cùng ĐVT | Các cột số lượng gắn cột đơn vị (`set_quantity_column`), nút Σ chuẩn của ALV tự tách theo ĐVT |
| Double-click lô / vật tư; nút Chi tiết lô (MSC3N) | `MSC3N` (`SET PARAMETER ID MAT / CHA / WRK`), `MM03`; nút lấy dòng đang chọn, không có thì dòng ô đang đứng |
| 2.7 Sắp xếp | `SORT gt_alv BY matnr vfdat lgort charg` (FEFO) |
| 2.8 Message ZWM11-001…008 | Có đủ (mục 5); thêm 009, 010, 011 ngoài FS |
| 4 Phân quyền | `M_MSEG_WMB` (Plant, kiểm ở màn hình chọn → ZWM11-001), `M_MSEG_LGO` (từng SLoc, loại dòng không quyền), `M_MATE_MAR` + `M_MATE_CHG` (theo nhóm quyền `MARA-BEGRU`, bỏ qua vật tư không có nhóm quyền). Chưa dùng `M_MATE_STA`, `C_KLAH_BKL`, `S_GUI` (xem mục 3) |

## 2. Logic chính / giả định

- **Class type, bảng đối tượng**: xem mục 0. Khóa đối tượng phân loại của lô: `MCH1` = vật tư + lô; `MCHA` = vật tư + Plant + lô (gán struct vào `INOB-OBJEK`, như `QMSP_MATERIAL_BATCH_CLASS_READ`). `AUSP-OBJEK` = `INOB-CUOBJ`.
- **Batch Class chỉ quyết định danh sách thuộc tính** của khối lọc / cột ALV (FS: "Quyết định danh sách thuộc tính sinh ra ở khối lọc"), **không lọc** tồn theo class; muốn chỉ thấy lô của class đó thì dùng điều kiện thuộc tính.
- **Danh sách thuộc tính**: lấy từ `KSML` của Batch Class (bỏ dòng xóa), xếp theo `ZTWM_CHAR_PARAM`: thuộc tính có `SHOW_ALV = X` trước, rồi thuộc tính có dòng cấu hình nhưng `SHOW_ALV` trống, rồi thuộc tính chưa khai báo; trong mỗi nhóm giữ thứ tự trong class (bảng BA không có cột thứ tự). Nhãn: `ATBEZ` của bảng, trống thì mô tả `CABNT`. Quá 15 thì cắt (nhóm `X` luôn nằm trong 15 đầu) và báo ZWM11-003 (FS: "vượt giới hạn – hãy chọn Batch Class cụ thể"). Tick "Hiển thị" mặc định: dòng cấu hình `SHOW_ALV = X`; thuộc tính không `X` hoặc chưa khai báo thì không tick; nếu bảng chưa có dòng nào cho class thì tick tất cả (FS không nêu, giả định). Khi không chọn Batch Class, thuộc tính trùng tên ở nhiều class lấy dòng `SHOW_ALV = X` nếu có.
- **Không chọn Batch Class**: hợp thuộc tính của Batch Class (class type lô) gán cho các vật tư có tồn trong phạm vi (đọc `INOB` object `MARA` → `KSSK` → `KSML`). Khi chạy mà chưa sinh khối lọc (chạy nền, chạy thẳng) thì code tự sinh theo class / phạm vi, giữ nguyên giá trị đã lưu trong variant.
- **Giá trị thuộc tính**: CHAR đọc `AUSP-ATWRT` (nhiều giá trị nối ", "), NUM đọc `ATFLV` hiển thị theo số lẻ `CABN-ANZDZ`, DATE đổi float `YYYYMMDD` về ngày theo định dạng người dùng. Thuộc tính không phân biệt hoa thường (`CABN-ATKLE` trống) thì giá trị nhập được đổi sang chữ hoa trước khi so. Không hỗ trợ pattern (`CP` / `NP`) cho NUM / DATE → ZWM11-004.
- **Cột thuộc tính tự ẩn** khi không tick hoặc không có giá trị ở mọi dòng (FS ghi "tùy chọn", làm luôn).
- **Loại tồn không tick**: không hiện cột, không cộng vào tổng tồn, không tham gia điều kiện "chỉ lô còn tồn" (SQL so ngưỡng `GC_QTY_NONE`).
- **ZWM11-006** (vật tư không quản lý lô): chỉ báo khi người dùng có điều kiện thuộc tính (vật tư không lô bị bỏ qua); báo tối đa 50 vật tư (`GC_MAX_MSG`). ZWM11-005, 007, 008 cũng giới hạn 50 dòng mỗi loại để cửa sổ message không quá dài.
- **Message ngoài FS**: 009 (số dòng bị loại do không quyền SLoc / nhóm quyền vật tư), 010 (nút Chi tiết lô khi chưa chọn dòng), 011 (Characteristic không có trong CABN, dùng ở SM30).
- **Cột "Trạng thái"**: "Hết hạn", "Hạn chế sử dụng" hoặc cả hai (FS chỉ nói "đánh dấu trong cột trạng thái", không nêu nội dung).
- **Performance**: không `FOR ALL ENTRIES`; lọc thuộc tính bằng join itab trên DB; `SELECT` tồn gộp `NSDM_E_MCHB` + `MCHA` + `MARA` + `MAKT`; giá trị thuộc tính đọc 1 lần cho tất cả lô trong kết quả; FM chỉ gọi theo dòng ở bước quy đổi ĐVT (1 lần mỗi dòng, có nhớ vật tư lỗi để khỏi gọi lại).

## 3. Câu hỏi còn mở cho BA

Hiện **không còn câu hỏi nào** cho BA (theo `NOTE/note.md`: chỉ hỏi chỗ FS thiếu / đang bàn ở yêu cầu chính; các chỗ dưới đây code đã chạy tạm theo cách hợp lý).

### Giả định đã chọn (FS thiếu, tự đặt – không hỏi BA)

- **Cấu trúc `ZTWM_CHAR_PARAM`**: FS chỉ nêu tên bảng; BA đã gửi cấu trúc (15/10/2026, file `FS/BDP_ZWM11_ZTWM_CHAR_PARAM.xlsx`, 4 field: Class, Characteristic, Char. Description, Hiển thị). BA không đặt tên kỹ thuật nên tự đặt `CLASS`, `ATNAM`, `ATBEZ`, `SHOW_ALV` (theo `KLAH` / `CABN` / `CABNT`). Hai chỗ khác chữ BA: `CLASS` dùng `KLASSE_D` (CHAR 18) thay vì CHAR 10 vì class `SAP_EWM_LOBM` trên DEV đã dài 12 ký tự; mô tả lấy từ `CABNT-ATBEZ` (BA ghi `CABN-ATBEZ`, bảng `CABN` không có field này). Delivery class A như `ZTWM_PCK_TITLE`.
- **Class type**: FS ghi 022, DEV dùng 023 → theo cấu hình hệ thống (mục 0).
- **Số cột tối đa 15**: theo FS; class có nhiều thuộc tính hơn thì cắt theo thứ tự cấu hình.
- **Bảng nguồn tồn**: FS ghi `MCHB` / `MARD`, code đọc CDS `NSDM_E_MCHB` / `NSDM_E_MARD` (mục 0), cùng field và ý nghĩa.

### Chỉ thông báo BA (chưa cấu hình / chưa có data, code đã chạy tạm)

- `ZTWM_CHAR_PARAM` đã có bảng nhưng chưa có data → code lấy tối đa 15 thuộc tính đầu của class theo thứ tự trong class, tick tất cả, nhãn lấy từ mô tả characteristic (`CABNT`). Class `B_BATCH` trên DEV có 37 thuộc tính nên cần BA / Key user nhập bảng qua SM30 để chọn đúng thuộc tính hiển thị (đánh dấu `X`).
- Dữ liệu mẫu BA có class `Z_BATCH` (characteristic `Z_BATCH_NSX`), trên DEV không có class này; `Z_BATCH_NSX` đang thuộc `B_BATCH`. Bảng không kiểm class có tồn tại hay characteristic có thuộc class đó (BA chỉ yêu cầu kiểm Characteristic có trong `CABN`).
- Batch Class trên DEV chỉ có `B_BATCH` (class type 023), chưa có các class như hình mẫu FS (`Z_NVL`...). Các characteristic trong hình mẫu (`Z_HSD`, `Z_TIEU_CHUAN`, `Z_BAO_QUAN`, `Z_HAM_LUONG`) không có đúng tên trên DEV (có `Z_TIEU_CHUAN_BATCH`, `Z_BAO_QUAN_BATCH`, `Z_HAM_LUONG_PKN`...).
- Hạn dùng (`MCHA-VFDAT`) trên DEV đang trống ở mọi lô → cột HSD, HSD còn lại, trạng thái hết hạn chỉ kiểm thử được khi có lô nhập HSD.
- Hạn dùng cũng có thể lọc như thuộc tính ngày nếu BA đưa `LOBM_VFDAT` (class `SAP_EWM_LOBM`) vào class lô; hiện FS không yêu cầu lọc theo HSD ngoài thuộc tính.
- Phân quyền `M_MATE_STA`, `C_KLAH_BKL`, `S_GUI`: FS có liệt kê nhưng chưa dùng (đọc classification trực tiếp bằng SQL không qua API chuẩn nên `C_KLAH_BKL` không tự kiểm; `S_GUI` do ALV export tự kiểm). BA / Basis cần quyết có kiểm thêm không.

## 4. Khi BA trả lời / khi có dữ liệu

- **Đổi cấu trúc `ZTWM_CHAR_PARAM` về sau** (BA đã gửi bản đầu 15/10/2026, đã nối code): sửa bảng, `dictionary/ztwm_char_param.md`, kiểu `GTY_CFG` (TOP), FORM `READ_CHAR_CONFIG` và đoạn dùng `LT_CFG` trong `BUILD_CHAR_LIST` (F01). Sửa field trong TOP đi theo thứ tự tương thích: thêm field mới, sửa F01, rồi bỏ field cũ.

- Có Batch Class thật (`Z_*`): kiểm `GET_BATCH_FILTER` với cả 3 kiểu thuộc tính (CHAR, NUM, DATE) và `MCHA` / `MCH1`.
- Có lô nhập HSD: kiểm "Bao gồm lô đã khóa / hết hạn", HSD còn lại âm (tô đỏ), message 007, 008.
- Có data `MARM`: kiểm quy đổi (DEV: vật tư `2100281` có `BAO` = 1000 G, `KG` = 1000 G, ĐVT cơ sở `G`).
- Đối chiếu tổng tồn với MB52 / MMBE (nguồn `NSDM_E_MCHB` / `NSDM_E_MARD`, mục 0).
- BA chốt cách dùng chung routine với ZMM60: tách `BUILD_CHAR_LIST`, `GET_CHAR_VALUES`, `FMT_VALUE` sang include dùng chung.

### Kịch bản thử trên DEV client 200 (số liệu đọc lại ngày 16/10/2026, data đổi theo ngày)

`B_BATCH` có 37 thuộc tính; `ZTWM_CHAR_PARAM` trống nên khối lọc chỉ sinh 15 thuộc tính đầu theo thứ tự trong class (`ZQC_POTENCY`, `Z_BAO_QUAN`, `Z_BAO_QUAN_BATCH`, `Z_BAO_QUAN_TPHH`, `Z_BATCH_NSX`, `Z_DO_AM_PKN`, `Z_DO_DEM_PKN`, `Z_HAM_LUONG_PKN`, `Z_HAM_LUONG_PKN1`, `Z_HAM_LUONG_PKN2`, `Z_HOAT_CHAT`, `Z_NGAY_DK`, `Z_NLVO_TRUNG`, `Z_NONG_DO_HL`, `Z_NSX`) và báo ZWM11-003 (37 > 15). `Z_QUYCACH_TPHH` (16 giá trị, nhiều nhất) đứng thứ 19 nên chưa có trong khối lọc trừ khi khai báo `SHOW_ALV = X` trong `ZTWM_CHAR_PARAM`. Trong 15 thuộc tính đầu chỉ `Z_DO_AM_PKN` và `Z_HAM_LUONG_PKN` có giá trị ở cấp lô (`NL10-003` của `2100281`: `0,3%` / `99,5%`; `261015_02` của `2200160`: `0,3 %` / `99,2 %`). `MCHA-VFDAT` trống mọi lô.

| Bước | Điều kiện | Kết quả mong đợi |
|---|---|---|
| 1 | Plant 1000, Batch Class `B_BATCH`, không lọc | ZWM11-003, khối lọc 15 dòng; ALV liệt kê mọi lô có tồn của Plant 1000 (79 dòng `MCHB` có tồn) kèm dòng vật tư không quản lý lô nếu có; chỉ hiện cột thuộc tính `Z_DO_AM_PKN`, `Z_HAM_LUONG_PKN` (cột trống ẩn); Lô NSX = số lô SAP |
| 2 | Lọc `Z_DO_AM_PKN` = `0,3%` | 1 dòng: `NL10-003` (`2100281`, SLoc 1100, Unrestricted 101.000 G). Thêm giá trị thứ hai `0,3 %` (nhiều giá trị, OR): thêm `261015_02` của `2200160` (Unrestricted 19, QI 11) |
| 3 | Lọc `Z_DO_AM_PKN` = `0,3%` và `Z_HAM_LUONG_PKN` = `99,2 %` (AND) | Không có lô nào thỏa, báo ZWM11-002 |
| 4 | Vật tư `2100281`, ĐVT quy đổi `KG` | 9 dòng (`AA6100`, `AA6101`, `AA6102`, `NL10-001`, `-003`, `-004`, `-005`, `-006`, `-007`), SL theo ĐVT chọn = tổng tồn / 1.000 (VD `NL10-001` 1 KG, `NL10-003` 101 KG, `NL10-004` 116 KG); bỏ không chọn vật tư thì vật tư thiếu `KG` trong MARM để trống + ZWM11-005 |
| 5 | Vật tư `2100277`, bỏ tick "Chỉ hiển thị lô còn tồn" | Có thêm lô tồn 0 (`AA6001` ở SLoc 1100) so với khi tick |
| 6 | (Thử thêm) SM30 `ZTWM_CHAR_PARAM`: `B_BATCH` / `Z_QUYCACH_TPHH` / `SHOW_ALV` = `X`; chạy ZWM11, Batch Class `B_BATCH`, lọc `Z_QUYCACH_TPHH` = `25KG/BAO` | `Z_QUYCACH_TPHH` lên đầu khối lọc, tick sẵn; ALV 7 dòng của `2100281`, SLoc 1100: `AA6100`, `AA6101`, `AA6102`, `NL10-001`, `-003`, `-004`, `-007` (`NL10-005`, `-006` chưa có giá trị đặc tính; `25KG/THÙNG` bị loại) |
| 7 | Chọn 1 dòng, bấm "Chi tiết lô"; double-click ô Lô và ô Vật tư | Mở `MSC3N` đúng lô; double-click Lô mở `MSC3N`, double-click Vật tư mở `MM03` |

## 5. Message class ZWM11 (VI / EN)

| Số | Loại | Nội dung |
|---|---|---|
| 001 | E | Bạn không có quyền với Plant &1 / Storage Location &2. / You are not authorized for plant &1 / storage location &2. |
| 002 | I | Không có dữ liệu theo điều kiện chọn. / No data found for the selection. |
| 003 | W | Phạm vi chọn có &1 thuộc tính, vượt giới hạn &2 – hãy chọn Batch Class cụ thể. / Selection has &1 characteristics, exceeding limit &2 – choose a specific batch class. |
| 004 | E | Giá trị &1 không hợp lệ cho thuộc tính &2. / Value &1 is not valid for characteristic &2. |
| 005 | W | Vật tư &1 chưa khai báo quy đổi sang đơn vị &2. / Material &1 has no conversion to unit &2. |
| 006 | W | Vật tư &1 không quản lý lô – không có thuộc tính để lọc. / Material &1 is not batch-managed – no characteristics to filter. |
| 007 | W | Lô &1 đã hết hạn ngày &2. / Batch &1 expired on &2. |
| 008 | W | Lô &1 đang ở trạng thái hạn chế sử dụng. / Batch &1 is in restricted-use status. |
| 009 | W | Đã loại &1 dòng không có quyền (Plant &2). / &1 items removed – no authorization (plant &2). — thêm ngoài FS |
| 010 | S | Chưa chọn dòng lô cần xem chi tiết. / No batch row selected. — thêm ngoài FS (hiện kèm DISPLAY LIKE E) |
| 011 | S | Characteristic &1 không tồn tại trong hệ thống (CABN). / Characteristic &1 does not exist in the system (CABN). — thêm ngoài FS, dùng ở event 01 của SM30 (mục 0.2 E), hiện kèm DISPLAY LIKE E; đã ghi lên DEV 15/10/2026 |

Message class tạo bằng ngôn ngữ EN, nội dung tiếng Việt như ZWM05; bỏ dấu `"` trong nội dung (xem `_ghichu_mcp_gui.md`).

## 6. Bắt đầu phiên mới

1. Đọc `CodeABAP/BDP/NOTE/note.md` rồi file này (mục 0, đặc biệt "Việc còn lại").
2. Hỏi user đã làm tới đâu trong "Việc còn lại" (event 01 SM30, xóa nút thừa ở status, nhập data `ZTWM_CHAR_PARAM`, đã chạy thử chưa, có lỗi / ảnh chụp không). Báo đã làm xong thì MCP kiểm lại: `TVIMF` (event), `REPOSRC` (chỉ `A`), `RunATCCheck`, `E071` của task `DEVK900648`.
3. Sửa code: sửa local trước, rồi `EditSource` lên DEV_100 (TR cha `DEVK900647`) khi user bảo; cách làm ở mục 0 "Cách làm việc khi sửa tiếp".
4. Nếu BA đổi cấu trúc `ZTWM_CHAR_PARAM` hoặc yêu cầu thêm: xem mục 4 đầu tiên.
5. Comment tiếng Việt ngắn, không marker tên / ngày, không comment lại code cũ (theo `NOTE/note.md`).
