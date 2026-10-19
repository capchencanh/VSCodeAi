# Ghi chú dự án ZLX02 / ZWM2D — Tồn kho tại Bin + Sơ đồ kho 2D (BDP / EWM)

FS hiện hành: `FS/BIDIPHAR_FS_EWM_ZWM2D_TonKhoTaiBin_SoDoKho2D_v1.0 1.docx` (T-code đổi từ ZLX02 sang **ZWM2D**). FS gốc: `FS/BIDIPHAR_FS_EWM_ZLX02_...v1.0.docx` (V1.0, 23/09/2026, Võ Hoàng Tuyên).
Cập nhật lần cuối: 13/10/2026 (xem mục 0, đoạn "Cập nhật 13/10/2026"); phần còn lại của dòng này là trạng thái 08/10/2026 tối. **Code local đã sửa theo FS ZWM2D (mục 8.1), `SyntaxCheck` bản ghép sạch, nhưng CHƯA dán lên SAP / chưa ATC / chưa chạy với dữ liệu EWM thật** (bản đang active trên DEV 200 vẫn là bản theo FS cũ, tên ZLX02). Trước khi dán phải tạo object mới ở mục 4.
Hướng dẫn tạo object từng bước: [Program/huong_dan_tao.md](Program/huong_dan_tao.md).

## 0. ĐỌC TRƯỚC KHI LÀM TIẾP (tóm tắt trạng thái, cập nhật 08/10/2026 tối)

**Đang ở đâu (cập nhật 09/10/2026 10:20, kiểm bằng MCP):** code đã **dán và active trên DEV 200** (TOP, F01, F02, chương trình chính `MESSAGE-ID ZWM2D`); `SyntaxCheck` sạch, ATC 0 lỗi / 0 cảnh báo / 10 info (chuỗi HTML). Đã tạo xong: bảng `ZTWM_2D_PARAM` + view SM30 (màn hình `0003`), message class `ZWM2D` (10 message; `ZLX02` đã không còn). Cả `ZTWM_BIN_LAYOUT` và `ZTWM_2D_PARAM` đã đổi sang *Display/Maintenance Allowed* (mặc định *with Restrictions* làm SM30 báo SV792). **CHỐT 09/10/2026: phần lập trình xong.** Dữ liệu 2 bảng cấu hình do **BA nhập**, T-code user **gắn sau**; còn lại chỉ là test khi có dữ liệu EWM thật. **Còn lại (không thuộc nhóm ABAP):** (1) nhập dữ liệu — cả 2 bảng đang 0 dòng ở client 100 và 200 (`ZTWM_2D_PARAM`: WTK1 9010/9020/8040/WC99; `ZTWM_BIN_LAYOUT`: WTK1/TK10); (2) T-code `ZWM2D` vẫn trỏ `ZWM_QUANLYKHO` (SangVT), T-code `ZLX02` đang trỏ đúng `ZWM_PG_TKBIN` để test; (3) test với dữ liệu EWM thật. (Dòng dưới là trạng thái trước đó: ) code local đã sửa xong theo FS ZWM2D (cả Plant/SLoc). User đã dán lên SAP. MCP đã ngắt theo yêu cầu user (muốn nối lại: copy server `GUI_BDP_DEV_200` từ `.mcp.servers-backup.json` vào `.mcp.json`, restart VS Code).

**Cập nhật 13/10/2026 (đọc trước; kiểm bằng MCP `GUI_BDP_DEV_200`, phần sửa SE11/TMG do user làm ở client 100):**
- **Delivery Class của `ZTWM_BIN_LAYOUT`: user chốt giữ `A`.** Đã đổi `C` → `A` rồi chạy lại TMG (tick "Create modules" + "Create maintenance screen") để nhãn `OBJH` thành `APPL`; nhờ vậy SM30 sửa được ở client 200 (trước đó báo `Client 200 has status 'not modifiable'`, kể cả lúc bảng còn `A`, vì nhãn `OBJH` vẫn là `CUST`). Cơ chế: mục 6 (bullet "SM30 báo ...") và `_ghichu_local.md` mục 2. **FS không ghi chữ Delivery Class `C`**, chỉ có 1 câu "customizing (Transport)" ở bảng NGUỒN DỮ LIỆU. Hệ quả của `A`: dữ liệu **không đi theo transport**, sang QAS/PRD phải nhập lại.
- **Chưa quyết:** `ZTWM_2D_PARAM` vẫn `C` + nhãn `CUST` → vẫn bị khóa ở client 200. Hoặc đổi `A` như bảng kia (nhập được ở 200, không theo transport), hoặc giữ `C` (nhập ở client 100, đi theo Customizing request). BA (13/10) đã hỏi "bảng có phải kiểu khai ở 1 client rồi đẩy sang client khác không" và bị chặn khi sửa ở 200; đã trả lời: FS chỉ ghi "customizing (Transport)", client 200 khóa là do Basis. **Cần BA xác nhận chấp nhận bảng `A` (không theo transport).**
- **Client 200 khóa:** `T000` dòng 200 `CCCORACTIV = 2` (không sửa cấu hình), `CCNOCLIIND = 3` (theo ý nghĩa chuẩn: không sửa Repository / cross-client; chưa thử ghi object ở 200), người sửa `CUSTADMIN` ngày 12/10/2026. Client 100 ("Development & Config") sửa được. Sửa bảng DDIC / TMG / code làm ở client 100; MCP 200 dùng để đọc và kiểm.
- **Sơ đồ kho KHÔNG cần có tồn, chỉ cần có Bin (đọc code, chưa chạy thật):** `LOAD_DATA` chế độ sơ đồ gọi `READ_BINS` đọc toàn bộ Bin của Storage Type bất kể tồn; Bin trống = ô xám. `P_EMPTY` chỉ dành cho Danh sách. Điều kiện mở sơ đồ: đúng 1 Storage Type dạng `I`/`EQ` + có nguồn mã Bin (dòng `ZTWM_BIN_LAYOUT` hoặc Bin đủ 5 trường chuẩn), nếu không `ZWM2D-005`; có ít nhất 1 Bin, nếu không `ZWM2D-003`. DEV hiện **0 Bin** nên muốn test sơ đồ phải tạo Bin EWM (không cần tồn).
- **Dữ liệu DEV client 200 (kiểm 13/10):** Warehouse có `0001`, `W498`, `WNH1`, `WTK1`; `ZTWM_BIN_LAYOUT` có 1 dòng `W498`/`NL10` (không rõ ai nhập; không phải `WTK1`/`TK10` như hướng dẫn mục 6); `ZTWM_2D_PARAM` 0 dòng.
- **Cấu trúc `ZTWM_BIN_LAYOUT` do mình tự thiết kế**, chi tiết ở mục 5.2 (đầu mục).
- **MCP:** 13/10 đã thêm `GUI_BDP_DEV_200` vào `.mcp.json` (giữ `GUI_BDP_DEV_100`); trong phiên đó chỉ thấy tool của 200. Tìm trong `CODE_FINAL` (OneDrive, file online-only): tool Grep hết thời gian 20 giây, dùng PowerShell đọc từng file và chỉ quét thư mục liên quan (`zwm_*`, `ywm_*`, `zpg_wm_*`), không quét cả 771 thư mục. Về sau MCP đã ngắt rồi nối lại chỉ còn `GUI_BDP_DEV_100` (client 100).
- **Góp ý BA/tester 13/10/2026 và đã xử lý (đã ghi lên SAP client 100 bằng MCP `EditSource`, TR `DEVK900355` / task `DEVK900356`, đã activate):** (a) **thiếu search help (F4) cho 3 ô** Stock Type, Storage Location, Handling Unit. Đúng, đã kiểm trên SAP: 3 data element đang dùng (`/SCWM/DE_CAT` qua trường CDS, `LGORT_D`, `EWM_DE_HUIDENT` qua trường CDS) đều **không gắn search help** (`DD04L-SHLPNAME` trống). Đã viết F4 riêng, kiểm cú pháp bằng `SyntaxCheck` trên SAP (đoạn mới, sạch) nhưng **chưa chạy thử trên giao diện** (không có dữ liệu HU/Bin để thử): `F4_CAT` (đọc `I_EWM_STOCKTYPETEXT_2` theo Warehouse đang nhập, tên theo ngôn ngữ đăng nhập, thiếu thì lấy ngôn ngữ khác), `F4_LGORT` (đọc CDS `I_STORAGELOCATION`, không đọc thẳng `T001L` vì ATC báo bypass buffer; lọc theo Plant đang nhập ở ô `S_WERKS` dòng đầu nếu có), `F4_HU` (dùng search help chuẩn EWM `/SCWM/SH_HU` có điền sẵn Warehouse, trả về số HU), cộng `READ_SCREEN_FIELD` (đọc giá trị đang gõ trên màn hình bằng `DYNP_VALUES_READ` vì F4 chạy trước khi biến được cập nhật). Gắn qua `AT SELECTION-SCREEN ON VALUE-REQUEST` cho ô `LOW` và `HIGH` của `S_CAT`, `S_LGORT`, `S_HUID`. Vị trí code: `zwm_pg_tkbin.abap` (6 sự kiện) và `zwm_in_tkbin_f01.abap` (4 FORM, ngay sau `F4_VARIANT`). Chưa dùng `MATCHCODE OBJECT` vì search help chuẩn EWM cần tham số Warehouse mà ô `P_LGNUM` không truyền được tự động, và `H_T001L` có nhiều tham số trả về nên không chắc điền đúng vào ô Storage Location. Chưa xử lý F4 trong popup chọn nhiều giá trị. (b) **Danh sách tồn kho và Sơ đồ kho chưa test được vì chưa có Bin EWM** (đã ghi ở trên, DEV 0 Bin).
- **BA nhập sai `ZTWM_BIN_LAYOUT` và đòi gõ chữ ở "Kệ: bắt đầu" (14/10/2026):** DEV 200 hiện có dòng WTK1/TK10 do BA nhập: Dãy dài 11, Kệ đầu 1 / dài 11, Tầng dài 4, Ô dài 12, Vị trí dài 12, ký tự phân cách `A` tại vị trí 1, SL vị trí 12 (đoán BA hiểu "độ dài" là số lượng, chưa xác nhận). Với giá trị này code không tách được mã Bin. Giá trị đúng cho `02B102-03`: 1/2, 3/1, 4/1, 5/2, 8/2, `-` tại 7, `X`, 2 vị trí/Ô. Đã tạo file hướng dẫn BA: `huong_dan_nhap_ZTWM_BIN_LAYOUT.docx` (cùng thư mục với file này). BA yêu cầu cho gõ chữ ở `STACK_OFF`: đã dùng MCP `UpdateDataElementAtomic` đổi `ZDE_WM_STACK_OFF` sang domain `CHAR2` (TR `DEVK900355`) nhưng **bản mới chỉ ở trạng thái inactive** (`DD04L` còn dòng `A` = NUMC2 và dòng `L` = CHAR2; `Activate` báo success nhưng vẫn inactive, cả data element lẫn bảng; chưa thấy lỗi thật). User cần mở SE11 → `ZDE_WM_STACK_OFF` → Activate (Ctrl+F3) để xem log. Đã thêm vào `PARSE_ONE_BIN` (F01, cả local và SAP client 100) đoạn `IF IS_LAY-STACK_OFF CN ' 0123456789'. RETURN.` để chữ không gây dump `CONV` khi bảng đã sang CHAR. Câu hỏi cho BA: mục 5.4 số 3.
- **So sánh SAP và local (13/10/2026, client 100):** chương trình chính `ZWM_PG_TKBIN` trên SAP = bản local + khối chú thích đầu file do SE38 sinh (user tạo); `ZWM_IN_TKBIN_F01` giống bản local (chỉ khác khoảng trắng căn lề); TOP/F02/CLS/PBO/PAI đọc lướt thấy khớp, chưa so từng dòng. Sau đó (cùng ngày) đã ghi 4 FORM + 6 sự kiện F4 lên SAP client 100; kiểm lại: `SyntaxCheck` cả chương trình sạch, ATC **0 lỗi / 0 cảnh báo / 10 info** (chuỗi HTML như trước; lần đầu có thêm 1 warning bypass buffer `T001L` và 3 info `EXCEPTIONS` chưa xử lý, đã sửa), include F01 trên SAP khớp file local, không còn object `ZWM_*TKBIN*` inactive. **Việc còn lại: user mở T-code thử F4 ở 3 ô (chưa có dữ liệu HU/Bin để thử đủ).**

**Việc kế tiếp (theo thứ tự):**
1. User làm các bước ở mục 4 (bảng `ZTWM_2D_PARAM` + SM30, message class `ZWM2D`, T-code, TITLE) rồi dán `top → f01 → f02 → zwm_pg_tkbin`, activate.
2. Chạy `SyntaxCheck` + ATC trên bản thật (nối lại MCP). Bản kiểm ghép **chưa chạy lại cho toàn chương trình sau khi thêm Plant/SLoc** (chỉ kiểm riêng đoạn mới → sạch); bản ghép trước đó sạch. Nếu ATC báo `SELECT SINGLE` không đủ khóa ở `HAS_STRUCTURE` thì đổi sang kiểu "tồn tại" hoặc bỏ qua (info).
3. Khi có dữ liệu EWM thật thì test và đối chiếu giả định ở mục 8.1.

**Vấn đề đang mở (cần user quyết):** T-code `ZWM2D` trên DEV **đã tồn tại và trỏ `ZWM_QUANLYKHO`** (chương trình khác, tạo 07/10/2026) → phải đổi sang `ZWM_PG_TKBIN` (hỏi người tạo) hoặc dùng tên khác.

**Các ý cần nắm (quyết định đã chốt):**
- **Khả dụng = Số lượng − SL đang pick**, SL đang pick / Chờ putaway tính từ WT chưa xác nhận (`I_EWM_OpenWarehouseTasks_2`, trừ trạng thái `A` hủy và `C` đã xác nhận). Không đọc `/SCWM/AQUA` nữa. Mỗi dòng ALV có số riêng (Hình 4): khớp theo (Bin, `StockItemUUID`, HU). WT theo HU lấy cả HU.
- **Hàng đang về** chưa có tồn khớp: chỉ thêm dòng (Số lượng 0) ở vùng (4) của sơ đồ, không thêm vào danh sách.
- **Thống kê 9 dòng theo Hình 4**: "Tổng" = số Bin (208 = 146 + 45 + 13 + 4), "Không có Bin" tách riêng; chữ FS ("gồm cả vị trí không có Bin") khác hình → theo hình.
- **Mã Bin**: ưu tiên trường chuẩn `AISLE`/`STACK`/`LVL_V`/`BINSC`/`DEPTH`, thiếu mới tách theo `ZTWM_BIN_LAYOUT`. Sơ đồ mở khi có **một trong hai nguồn**. Ô/Vị trí dùng `BINSC`/`DEPTH` (chưa kiểm bằng Bin thật; có thể phải đổi sang `PLAUF`/`PLPOS`).
- **E/B (sửa 09/10)**: `STK_USG` = `E` nếu loại chứng từ `SOS`, `Q` nếu `PJS`, `B` nếu Owner khác Party entitled (B chưa kiểm). Chi tiết ở mục 5.2.
- **Plant/SLoc**: API chuẩn `/SCWM/IF_STOCKID_MAPPING->GET_ERP_STLOC`; 2 ô lọc `S_WERKS`, `S_LGORT` (chỉ áp cho Danh sách). DEV chưa có cấu hình ánh xạ nên chưa kiểm số liệu.
- **Diễn giải khóa** sinh từ 3 cờ khóa (+ số chứng từ kiểm kê, + người/ngày/giờ đổi Bin gần nhất); không có ngày chứng từ kiểm kê.
- **Sơ đồ vẫn là HTML viewer** (không ALV Grid); mỗi khối có hàng tiêu đề Ô riêng; tiêu đề Ô lấy từ Ô thật của Bin (`SLOTS_PER_CELL` không còn dùng trong logic).
- Màu: xanh lá có hàng, xám trống, đỏ khóa nhập/xuất, vàng khóa kiểm kê, trắng không có Bin; ưu tiên khóa nhập/xuất > khóa kiểm kê > có hàng > trống; tìm = viền xanh, chọn = viền đen.

**Chưa làm / đang chờ (không phải lỗi code):**
- "Thông báo số dòng bị loại" — user bảo tạm bỏ qua (SAP tự ẩn dòng không có quyền nên không đếm được).
- Sơ đồ TK20, TKFB (WTK1), W498, WNH1 — FS ghi "Chờ BP Kho cung cấp" quy ước mã Bin; khi có chỉ nhập cấu hình, không sửa code.
- Cột "SL theo ĐVT kho (Logistics UoM)" (tùy chọn, ẩn) — FS không nêu trường, hệ không có trường tên đó → hỏi tư vấn trước khi làm.
- Không làm (chỉ có trong hình mẫu): nút "Chi tiết Bin", "Lịch sử WT của Bin", "Sơ đồ kho" trong ALV, dòng tổng "Tổng số dòng · Bin có tồn · Bin khóa", E/B dạng radio.
- Message class chưa song ngữ (user bảo để sau theo tư vấn); phân quyền và dữ liệu cấu hình do bên khác phụ trách.

**Cách làm việc với user này:** trả lời tiếng Việt, ngắn, đơn giản, không thuật ngữ; làm nhanh, không suy nghĩ dài; theo FS đúng chữ ("FS nói sao làm vậy"); mục FS ghi "chờ"/"Technical xác nhận" thì tạm bỏ qua nhưng phải ghi lại; không hỏi BA thừa. **FS thiếu cấu trúc bảng/field: vẫn tự đặt hợp lý (đúng `NOTE/note.md` dòng 12) nhưng PHẢI ghi ngay "FS thiếu, mình tự đặt" vào mục 5.2 và đưa câu hỏi vào mục 5.4** (user nhắc 13/10/2026 sau vụ `ZTWM_BIN_LAYOUT`, lúc đó chưa ghi gì). User **tự dán code** lên SAP (MCP ghi bị chặn TK 730, chỉ dùng để đọc/kiểm). Code chuyển dự án: không đánh dấu tên/ngày, không ghi số chỉ tiêu FS trong comment (`NOTE/note.md`). Link khi báo cáo: đường dẫn tính từ gốc workspace (`CodeABAP/BDP/ZLX02/Program/...#Lnn`).

## 1. Chương trình làm gì

Báo cáo **chỉ xem** tồn kho theo từng ô kệ (Bin) trên EWM, 2 chế độ:
- **Danh sách**: ALV, mỗi dòng 1 quant (Bin + HU + vật tư + lô + loại tồn), đèn trạng thái Bin, cột Dãy/Kệ/Tầng/Ô/Vị trí, hạn dùng, khóa Bin, di chuyển gần nhất, 2 cột quy đổi ĐVT.
- **Sơ đồ kho 2D**: tấm bản đồ 1 Storage Type, ô tô màu theo trạng thái Bin (xanh lá có hàng không khóa, xám trống, đỏ khóa nhập/xuất, vàng khóa kiểm kê, trắng không có Bin; kết quả tìm = viền xanh đậm, ô đang chọn = viền đen), thanh tìm (Bin/vật tư/mô tả/lô/E-B), thống kê 9 dòng, ALV tồn của ô chọn.

Cần **cấu hình cách tách mã Bin** theo Storage Type (bảng `ZTWM_BIN_LAYOUT`) để vẽ được sơ đồ. Ví dụ WTK1/TK10: `02B102-03` = Dãy 02, Kệ B, Tầng 1, Ô 02, phân cách `-`, Vị trí 03.

## 2. Quyết định đã chốt

| Nội dung | Quyết định |
|---|---|
| Code cũ (`Tham khao/zrls10020`, `zmllvskon`) | **Không dùng lại**: là WM (`LAGP/LQUA`), copy report chuẩn LX02 + 3 chỗ custom (Material Group, cột Quy đổi, PO). Chỉ tham khảo công thức quy đổi |
| `thamkhao/zwm_quanlykho` | Là sơ đồ kho 2D của dự án khác (WM, mã Bin `A-8-5-01`, hard-code nhiều). **Chỉ tham khảo thiết kế** (bố cục, màu, đếm); là nguồn gốc của tiêu đề FS "Sơ đồ kho, quản lý, tìm kiếm" |
| Tạo code | Viết **local** trong `Program/`, user tự copy lên hệ thống. MCP chỉ dùng kiểm tra/tạo data element |
| Tên chương trình | `ZWM_PG_TKBIN` + 6 include `ZWM_IN_TKBIN_*` (theo quy ước dự án, khác `ZWM_R_ZLX02` đề xuất trong FS) |
| Nguồn dữ liệu | CDS EWM chuẩn: `I_EWM_PhysStockProd` (tồn), `I_EWM_StorageBin_2` (Bin), `I_EWM_OpenWarehouseTasks_2` (WT chưa xác nhận, bảng `/SCWM/ORDIM_O`, dùng tính Chờ putaway / SL đang pick / Khả dụng). Bản theo FS cũ dùng `I_EWM_AvailableStock` (`/SCWM/AQUA`) — **đã bỏ** |
| Vẽ sơ đồ | **HTML viewer** (không phải ALV Grid): ALV Grid không có tooltip theo từng ô (`IT_EXCEPT_QINFO` chỉ theo giá trị icon) và không gộp tiêu đề Ô. Nhấp ô tô xanh bằng JS ngay tại trình duyệt. Mô hình dữ liệu `GT_CELL` tách khỏi phần vẽ → đổi sang ALV Grid chỉ sửa `BUILD_HTML`/`SHOW_HTML` |
| Quy đổi ĐVT | 1 ĐVT + 2 cột số (mục 2.3 FS), class dùng chung `ZCL_WM_UOM_CONVERT` (gọi `MD_CONVERT_MATERIAL_UNIT`) cho ZLX02/ZWM11/ZMM60 |
| Text DDIC | Data element/bảng chỉ cần **tiếng Việt** (FS không yêu cầu song ngữ). Chỉ **message class `ZLX02` song ngữ Việt–Anh** |
| Transport | Request `DEVK900355` (task `DEVK900356`), tên `DanhDH_WM_ZLX02_07.10.2026_Ton kho tai Bin va so do kho 2D`. Tool MCP phải truyền **số request** `DEVK900355`, không truyền số task |

## 3. Trạng thái object trên DEV (kiểm bằng MCP 08/10/2026)

| Object | Trạng thái |
|---|---|
| Chương trình `ZWM_PG_TKBIN` + 6 include | Có, active (TOP/F01/F02 cập nhật 08/10 11:07, khớp file local). `SyntaxCheck` = `null`; ATC: 0 error, 0 warning, 10 info (chuỗi HTML chưa có text element, bỏ qua được) |
| Screen `0100`, `0110`, `1000` | Có (đọc từ `D020S`) |
| TITLEBAR `TITLE`, PF-STATUS `STANDARD` | TITLE đã có (ATC không còn báo 0701). STANDARD: ATC không báo thiếu. MCP không đọc trực tiếp được (`RSMPE` bị chặn authorization) |
| 14 data element `ZDE_WM_*` | Đủ, active. Domain `NUMC2`/`CHAR1`/`XFELD`. Nhãn chỉ lưu ngôn ngữ `E` (nội dung tiếng Việt) |
| Bảng `ZTWM_BIN_LAYOUT` (17 field), `ZTWM_LX02_PARAM` (3 field) | Có, active, **bật Log data changes**, Data Class `APPL0` (hướng dẫn ghi `APPL2`, không bắt buộc), **không có foreign key** (cố ý: DEV chỉ có Warehouse `0001`). **Delivery Class (kiểm 13/10/2026): `ZTWM_BIN_LAYOUT` = `A`** (đổi từ `C`, nhãn `OBJH` = `APPL`, sửa được ở client 200), `ZTWM_LX02_PARAM` không còn dùng. **`ZTWM_2D_PARAM` vẫn `C`, nhãn `OBJH` = `CUST` → khóa ở client 200**, chờ user quyết đổi sang `A` hay không. Xem mục 6 "SM30 báo client 200 not modifiable" |
| View SM30 cho 2 bảng | Đã tạo: function group `ZFG_WM_LX02`, overview screen `0001` / `0002` (`TVDIR`), nằm trong task `DEVK900356` |
| T-code `ZLX02` | Có → `ZWM_PG_TKBIN`, screen `1000` |
| T-code `ZWM2D` | **Đã tồn tại** (TADIR 07/10/2026, user `CT.CSTECH`, package `ZPK_BDP`) nhưng trỏ **`ZWM_QUANLYKHO` screen 1000**, mô tả "Sơ đồ kho, quản lý, tìm kiếm" — **không phải chương trình này**. Cùng đợt có `ZWM_QUANLYKHO` (+ `ZWM_QUANLYKHO_O01/_I01`, `MESSAGE-ID ZMC_HN`), function group `ZFG_WM2D_A`, `ZFG_WM2D_B` (trông giống bản tham khảo `thamkhao/zwm_quanlykho` đã được tạo lên DEV). Phải quyết định: đổi T-code `ZWM2D` sang `ZWM_PG_TKBIN` (SE93) hay dùng tên khác |
| Bảng `ZTWM_2D_PARAM`, message class `ZWM2D` | **Chưa có** (kiểm `TADIR` 08/10/2026) — phải tạo trước khi dán code mới |
| Class `ZCL_WM_UOM_CONVERT` | Có, ATC 0 finding |
| Message class `ZLX02` | Có 10 message nhưng chỉ ngôn ngữ `E` (nội dung tiếng Việt) |
| Dữ liệu 2 bảng cấu hình | 0 dòng (kiểm 08/10). **Kiểm lại 13/10 ở client 200:** `ZTWM_BIN_LAYOUT` có 1 dòng `W498`/`NL10` (không rõ ai nhập), `ZTWM_2D_PARAM` 0 dòng |
| Dữ liệu EWM để test | **Không có**: `I_EWM_PhysStockProd`, `I_EWM_OpenWarehouseTasks_2`, `I_EWM_ConfirmedWarehouseTask_2` đều 0 dòng trên DEV 200 → chỉ kiểm được cú pháp, chưa kiểm được số liệu. **Kiểm lại 13/10/2026 ở client 200:** `I_EWM_StorageBin_2` cũng **0 Bin** (thiếu Bin chứ không chỉ thiếu tồn) |

## 4. Việc còn lại (TODO)

**Làm ngay (08/10/2026 tối) — trước khi dán code mới (code theo FS ZWM2D):**
1. SE11: tạo bảng **`ZTWM_2D_PARAM`** (copy `ZTWM_LX02_PARAM`: `LGNUM`, `LGTYP`; Delivery Class `C`, bật Log data changes) + view SM30 (function group `ZFG_WM_LX02`, thêm screen mới) + cập nhật `S_TABU_NAM`. Code đọc `ZTWM_2D_PARAM` ở FORM `READ_CONFIG`.
2. SE91: tạo message class **`ZWM2D`** (copy từ `ZLX02`, 001–010; song ngữ để sau). Dòng `REPORT ... MESSAGE-ID ZWM2D` cần class này mới activate được.
3. SE93: T-code **`ZWM2D`** đang trỏ `ZWM_QUANLYKHO` → đổi sang chương trình `ZWM_PG_TKBIN`, screen `1000` (hoặc quyết định tên khác). Xem mục 3.
4. SE41: sửa text TITLE `TITLE` thành `ZWM2D – Sơ đồ kho, quản lý, tìm kiếm`; SE38: sửa title chương trình (theo FS: màn hình danh sách "ZWM2D – Tồn kho tại Storage Bin").
5. Dán theo thứ tự: `zwm_in_tkbin_top` → `zwm_in_tkbin_f01` → `zwm_in_tkbin_f02` → `zwm_pg_tkbin` (chương trình chính); `zcl_wm_uom_convert` chỉ đổi dòng comment (không bắt buộc dán lại). Activate cả nhóm, chạy ATC.

**Đã xong (08/10/2026, theo FS cũ):** T-code `ZLX02`, view SM30 cho 2 bảng, Delivery Class `C`, TITLE, sửa code đợt 2 (nhấp ô không chạy lại tìm, JS đổi màu ô, cột quy đổi từ thanh tìm, ẩn `WDATU_TS`, cột mô tả Stock Type, tooltip ô trắng, hàng nhãn Vị trí, tiêu đề vùng 4, 2 warning ATC), `SyntaxCheck` + ATC sạch.

1. **Message class `ZLX02` chưa song ngữ**: hiện chỉ ngôn ngữ `E` mà nội dung là tiếng Việt; message 005 còn bị cắt cụt ở 73 ký tự. Hoãn, chỉnh sau theo ý tư vấn. Khi test nên đăng nhập EN để thấy text. Bản rút gọn 005 đề xuất: *Sơ đồ kho cần 1 Storage Type có cấu hình trong ZTWM_BIN_LAYOUT.*
2. **Dữ liệu cấu hình 2 bảng đang 0 dòng** (WTK1/TK10 theo mục 6 hướng dẫn; `ZTWM_LX02_PARAM`: WTK1 9010, 9020, 8040, WC99) và **phân quyền** (`S_TCODE` ZLX02, `/SCWM/LG` `/SCWM/LGNU`+`ACTVT` 03, `S_GUI` 61, `S_TABU_NAM`/`S_TABU_DIS`): do bên khác phụ trách, không thuộc nhóm ABAP.
3. **Nhãn 14 data element chỉ lưu ngôn ngữ `E`**: nếu user đăng nhập VI mà nhãn cột trống ở SM30/SCU3 thì dịch bằng SE63 hoặc đăng nhập EN.
4. **Test thật** trên hệ có dữ liệu EWM (DEV 200/100 chỉ có Warehouse `0001`, không Bin/tồn; chưa có W498/WTK1/WNH1). Kịch bản ở mục 15 hướng dẫn. Trên DEV chỉ test được màn hình chọn và các thông báo kiểm tra (ZLX02-002/003/005/009/010).
5. **Release transport** `DEVK900355` (task `DEVK900356`) sau khi test. Dữ liệu cấu hình: bảng Delivery Class `C` (hiện chỉ `ZTWM_2D_PARAM`) nhập ở client 100 và đi theo Customizing request; bảng `A` (`ZTWM_BIN_LAYOUT`) **không** đi theo transport, phải nhập lại ở từng hệ thống (DEV 200, QAS, PRD).

## 5. Phần FS chưa làm / thiếu thông tin (hỏi BA)

> Mục này viết theo FS ZLX02 cũ. **Sau khi code theo FS ZWM2D (mục 8.1):** #2 (Lý do khóa → "Diễn giải khóa"), #3 (Chờ putaway / SL đang pick / Khả dụng) và #6 (Loại Bin, sức chứa còn lại) đã làm; #5 bỏ vì mục 2.4 đã bị xóa; còn chưa làm: #1 Plant/SLoc, #4 Logistics UoM, #7 số dòng bị loại, #8 mã Bin các Storage Type khác.

### 5.1 Chưa làm vì FS không nêu nguồn dữ liệu / cách lấy

| # | FS | Lý do chưa làm / cần BA |
|---|---|---|
| 1 | Tham số + cột **Plant / SLoc** (tham số #8, cột #8, ALV vùng 4) | FS chỉ ghi "Party entitled → Plant; Stock Type + availability group → SLoc theo cấu hình ánh xạ ERP–EWM", không nêu bảng/cấu hình cụ thể (gợi ý `/SCWM/TMAPSTLOC`) |
| 2 | Cột **Lý do khóa** (#24) | Đã kiểm 08/10/2026 trên DEV: bảng Bin `/SCWM/LAGP` (64 field) và CDS `I_EWM_StorageBin_2` chỉ có 3 cờ khóa `SKZUE` (nhập), `SKZUA` (xuất), `SKZSI` (kiểm kê), **không có field lý do**. Data element "Blocking reason" `/SCWM/LVS_SPGRU` chỉ nằm trong 4 cấu trúc nạp dữ liệu/migration (`/SCWM/S_LAGP_LSMW`, `_LSMW_MIG`, `_UPLOAD_MIG`, `/SCWM/S_BIN_MIG_MC`), không có bảng nào lưu. FS không nói lấy từ đâu |
| 3 | **Chờ putaway**, **SL đang pick** (ALV vùng 4) và **SL khả dụng** (#17 "Quantity − SL đã giữ cho WT mở") | Không nêu nguồn. Đang làm "Khả dụng" = `I_EWM_AvailableStock` (`/SCWM/AQUA`) và "Đang giữ (WT mở)" = Tổng tồn − Khả dụng. Cần BA xác nhận ý nghĩa, có cần 2 cột riêng không |
| 4 | Cột **SL theo ĐVT kho (Logistics UoM)** (#21, tuỳ chọn, mặc định ẩn) | **FS có mô tả** khái niệm (Logistics UoM của sản phẩm trong EWM, khác ĐVT quy đổi) nhưng không nêu field/bảng. Việc của lập trình tra field, **không cần hỏi BA**. Tồn kho EWM có `EWMStockQuantityAltvUnit` nhưng chưa đủ kết luận |
| 5 | Nhấp dòng danh sách xem **chi tiết Bin / Warehouse Task** (mục 2.4; mockup có nút "Chi tiết Bin", "Lịch sử WT của Bin") | FS không chỉ T-code/API; chỉ hiện số WT gần nhất |
| 6 | **Loại Bin, sức chứa còn lại** (#5, tuỳ chọn hiển thị) | **FS có mô tả** nguồn: "Storage Bin master (Bin Type, capacity)". Nguồn có sẵn trong `I_EWM_StorageBin_2`: `EWMStorageBinType` (đang ẩn), `EWMStorBinAvailCapacityValue` (= `/SCWM/LAGP-FCAPA`, "Available Capacity in Storage Bin"), `EWMStorBinTotalCapacityValue` (`MAX_CAPA`). Chỉ cần thêm cột, **không cần hỏi BA** |
| 7 | Phân quyền: "hệ thống thông báo **số dòng bị loại**" | CDS EWM tự lọc theo quyền nên không đếm được; FS không nêu cách. Object EWM "Technical xác nhận" → đã dùng `/SCWM/LG` (đã kiểm tồn tại trong TOBJ) |
| 8 | Quy ước mã Bin của **TK20, TKFB, W498, WNH1** | FS chỉ cho WTK1/TK10. Storage Type khác sẽ báo ZLX02-005 (sơ đồ) hoặc vào popup "Bin chưa xác định vị trí" cho tới khi BA cung cấp quy ước để cấu hình |

### 5.2 Code theo giả định, cần BA/tư vấn xác nhận

- **[CONFIRMED 13/10/2026] Cấu trúc bảng `ZTWM_BIN_LAYOUT` (17 field) do mình tự thiết kế, không lấy từ nguồn nào có sẵn; BA/tư vấn chưa xác nhận.** FS chỉ có đúng 1 câu mô tả (bản ZWM2D: THIẾT KẾ CHỨC NĂNG → Logic xử lý đặc biệt → Tách mã Bin và dựng sơ đồ, đoạn thứ 2, tìm từ khóa `vị trí bắt đầu và độ dài`; bản ZLX02 cũng có câu tương tự): *"Chỉ khi Bin của Storage Type không được tạo từ cấu trúc (các trường Dãy/Kệ/Tầng để trống) mới dùng bảng ZTWM_BIN_LAYOUT (khóa Warehouse + Storage Type): vị trí bắt đầu và độ dài của Dãy, Kệ, Tầng, Ô, Vị trí; ký tự phân cách; thứ tự hiển thị tầng (giảm dần); số vị trí trên một ô."* Từ câu đó mình suy ra: khóa `MANDT` + `LGNUM` + `LGTYP`; mỗi đoạn Dãy/Kệ/Tầng/Ô/Vị trí có 1 field `*_OFF` (bắt đầu) + 1 field `*_LEN` (độ dài); `SEP_CHAR` + `SEP_OFF`; `LEVEL_DESC`; `SLOTS_PER_CELL`. **Tên field, kiểu, độ dài (data element `ZDE_WM_*`) là do mình đặt**, FS không có bảng liệt kê field. Đã tìm nguồn khác: `Tham khao/zrls10020`, `zmllvskon` (báo cáo LX02 của WM, ghi chú mục 2 ghi không dùng lại); `zwm_quanlykho` (hard-code, không còn trong workspace); thư mục `CODE_FINAL` ECC (29 thư mục WM, 179 file) **không có file nào chứa `BIN_LAYOUT`**. Bảng chỉ là phương án dự phòng (FS ưu tiên trường chuẩn Aisle/Stack/Level/Bin Section/Depth); nếu BA/tư vấn có mẫu cấu trúc khác thì đối chiếu lại. `SLOTS_PER_CELL` còn trong bảng nhưng không dùng (mục 8.1).

- **E/B trong thanh tìm — ĐÃ SỬA 09/10/2026 sau khi kiểm hệ thống:** domain `/LIME/STOCK_USAGE` (field `EWMStockUsage`) **không có giá trị cố định** nên cách cũ `EWMStockUsage = 'E'` là sai. SAP chuẩn ánh xạ tồn đơn bán hàng bằng `StockDocumentCategory = 'SOS'` (domain `/SCWM/DO_STOCK_DOCCAT`: SOS đơn bán, PJS dự án, WIP, S2C, S2P) + số chứng từ; ký gửi vendor/customer dùng Owner + vai trò (`VE`/`CU`). Code nay tính chỉ báo tồn đặc biệt `STK_USG` bằng CASE trong SQL: SOS → `E`, PJS → `Q`, Owner khác Party entitled → `B` (**B là suy đoán**, chưa kiểm bằng dữ liệu thật vì CDS không lộ vai trò Owner); E so số chứng từ ngoài (`ExternalStockDocumentNumber`), B so Owner. Bản SangVT (`ZWM_QUANLYKHO`) gán E khi có `STOCK_DOCNO`, gần đúng nhưng không phân biệt SOS/PJS. Ghi chú cũ bên dưới là trước khi sửa:
- (cũ) **E/B trong thanh tìm**: FS chỉ nói "special stock E = số Sales Document/dòng, B = số khách hàng", không nêu field EWM. Code: E = `EWMStockUsage='E'` + `ExternalStockDocumentNumber`; B = `EWMStockUsage='B'` + `EWMStockOwner` (giả định số BP = số khách hàng). Bản cũ `zwm_quanlykho` so cả hai với `SONUM` = số tồn đặc biệt → **có thể phải đổi B sang số tồn đặc biệt**.
- **"Chỉ Bin đang bị khóa"**: FS mục 3.4.1 nói Bin khóa không có tồn hiện 1 dòng "khi chọn tùy chọn tương ứng" nhưng tham số #15 không mô tả. Code: Bin khóa không có tồn chỉ hiện khi tick thêm "Hiển thị Bin trống".
- **Loại message**: FS ghi 004/006 là W, 007/008 là I; code hiển thị ở status bar (type S + `DISPLAY LIKE`), không popup.
- **Hạn dùng**: FS ghi `MCHA-VFDAT`; code lấy SLED trên quant (`I_EWM_PhysStockProd`). Kiểm lại khi có dữ liệu.
- **Plant của lô** lấy `MIN(MCHA-WERKS)` theo (vật tư, lô) để đọc đặc tính lô (FM `ZCORE_FM_GET_CRTRT_MULTIVAL` cần Plant).
- Loại trừ Storage Type trung gian áp dụng cả sơ đồ; giờ đổi theo múi giờ Warehouse; `I_EWM_PhysStockProd` chỉ có dữ liệu khi migration `/SCWM/CL_SDM_HUHDR_GUID_HU_TOP` xong (DEV 200: `F`, cần kiểm QAS/PRD).
- **HTML viewer thay ALV Grid** (FS mục 2.6.4 khuyến nghị ALV Grid, cho phép HTML viewer nếu ALV không đủ, "Technical chốt ở TS"): cần ghi vào TS và báo BA đồng ý; chỉ chạy trên SAP GUI for Windows (cần HTML control). Hệ quả: không áp giới hạn "10 tầng / 60 cột" của FS vì sơ đồ cuộn được.
- **Tên chương trình** `ZWM_PG_TKBIN` (theo quy ước dự án) khác `ZWM_R_ZLX02` đề xuất trong FS.
- **Chi tiết giao diện chưa làm (chỉ có trong mockup, không có trong phần chữ của FS)**: E/B dạng radio (code là ô nhập 1 ký tự), dòng tổng "Tổng số dòng · Bin có tồn · Bin khóa" dưới ALV danh sách, nút "Sơ đồ kho" trong ALV danh sách.

### 5.3 FS mâu thuẫn
- Mục Thuật ngữ #6 ("3 THÙNG 5 HỘP") ≠ mục 2.3/2.6.3 (1 ĐVT, 2 cột). Code theo 2.3/2.6.3.
- BP EWM: "trích xuất hình ảnh sơ đồ" ≠ FS "chỉ xem, không xuất" (xác nhận 17/09/2026). Code theo FS.
- FS không mô tả view bảo trì/SM30; chỉ nói *"bảo trì bởi Key user/IT"* (mục 3 trang 19) và `S_TABU_NAM … Bảo trì tham số` (mục 4 trang 20). View là suy luận → hỏi BA cho chắc.

### 5.4 Câu hỏi còn mở cho BA (theo `NOTE/note.md`: trích FS + code đang xử lý tạm thế nào)

1. **Cấu trúc bảng `ZTWM_BIN_LAYOUT` (thêm 13/10/2026).** FS ghi: *"Chỉ khi Bin của Storage Type không được tạo từ cấu trúc (các trường Dãy/Kệ/Tầng để trống) mới dùng bảng ZTWM_BIN_LAYOUT (khóa Warehouse + Storage Type): vị trí bắt đầu và độ dài của Dãy, Kệ, Tầng, Ô, Vị trí; ký tự phân cách; thứ tự hiển thị tầng (giảm dần); số vị trí trên một ô."* FS không liệt kê field. Code tạm: bảng 17 field do mình tự đặt (mục 5.2, đầu mục), đủ để nhập cấu hình WTK1/TK10 theo ví dụ của FS. Hỏi BA/tư vấn: cấu trúc này đủ chưa, có cần thêm hoặc bớt field không (VD `SLOTS_PER_CELL` hiện không dùng).
3. **Ô "Kệ: bắt đầu" (`STACK_OFF`) cho gõ chữ để làm gì (thêm 14/10/2026).** BA nhắn: *"chỉnh lại giúp em cho phép gõ chữ ở cái field kệ"*, nghĩa là field `STACK_OFF`. FS không mô tả field này; code tạm hiểu `STACK_OFF` là **ký tự thứ mấy** trong mã Bin (số), chữ A–D của Kệ nằm trong mã Bin chứ không nhập vào bảng. Đã cho phép gõ chữ theo yêu cầu (xem mục 0, bullet 14/10) nhưng chữ trong ô này **không có ý nghĩa với chương trình**: dòng đó bị bỏ qua, Bin của Storage Type rơi vào popup "Bin chưa xác định vị trí" (ZWM2D-004). Hỏi BA: muốn gõ chữ vào ô này để biểu diễn gì (VD Kệ đầu tiên là A, số Kệ là 4)? Nếu BA muốn khai báo dải Kệ A–D thì cần thêm field mới, không dùng `STACK_OFF`.
2. **Bảng tham số có đi theo transport không (thêm 13/10/2026; BA đã hỏi miệng).** FS ghi: *"Hai bảng tham số là customizing (Transport), bảo trì bởi Key user/IT; có table logging."* FS không nêu Delivery Class. Code tạm: `ZTWM_BIN_LAYOUT` đang Delivery Class `A` (nhập thẳng ở client 200, **không đi theo transport**, sang QAS/PRD phải nhập lại); `ZTWM_2D_PARAM` đang `C` (nhập ở client 100, đi theo Customizing request, bị khóa ở client 200). Hỏi BA: dữ liệu 2 bảng có cần đi theo transport không? Nếu có thì đổi `ZTWM_BIN_LAYOUT` về `C`.

## 6. Bài học kỹ thuật (đã ghi tóm tắt ở `_ghichu_local.md` / `_ghichu_mcp_gui.md`)

- **Tool MCP `GUI_BDP_DEV_*`** (đã thử 07/10/2026):
  - `CreateDataElementAtomic`/`UpdateDataElementAtomic`: chỉ nhận **domain** (hoặc CHAR 10 mặc định), không đặt được "predefined NUMC 2" → dùng domain chuẩn `NUMC2`/`CHAR1`/`XFELD` (kết quả giống nhau). Nhãn lưu theo ngôn ngữ đăng nhập của tool (`EN`).
  - `transport` phải là **số request** (`DEVK900355`); truyền số task (`DEVK900356`) → object tạo dở (có `TADIR` nhưng rỗng), bị khóa và không sửa được qua tool.
  - `CreateObject` **không hỗ trợ** `MSAG` (message class); `WriteMessageClassTexts` không có tham số nội dung → không ghi được message. Phải SE91.
  - Không có tool tạo Table Maintenance Generator (view SM30), screen, PF-STATUS, T-code.
  - `SyntaxCheck` cho chương trình **chưa tồn tại**: mượn `object_url` của chương trình có sẵn (đã bật Fixed point arithmetic). Với chương trình đã tồn tại thì dùng `object_url` chính nó; muốn kiểm 1 include chưa dán lên hệ thống thì dán nội dung include thay cho dòng `INCLUDE`. Lỗi báo từng đợt → sửa xong phải kiểm lại toàn bộ.
  - `GetInactiveObjects`, `GetPackage` trả kết quả rất lớn (ghi ra file) → dùng `RunQuery` trên `TADIR`/`DD04L`/`DD03L`/`TSTC`/`D020S`/`T100` để kiểm nhanh.
- **SM30 báo `Client 200 has status 'not modifiable'` với `ZTWM_BIN_LAYOUT` (13/10/2026, đã xử lý):** nguyên nhân là nhãn `OBJH-OBJCATEG` = `CUST` do TMG ghi lúc tạo view khi bảng còn Delivery Class `C`, và client 200 khóa sửa cấu hình (`T000`: `CCCORACTIV = 2`, do Basis `CUSTADMIN`). Đổi Delivery Class ở SE11 không đổi nhãn này. Đã sửa: client 100 → SE11 đặt `A` → TMG tick "Create modules" + "Create maintenance screen" → `OBJCATEG = APPL`, sửa được ở 200 như `ZTWM_MVT_GRP`. Chi tiết cơ chế: `_ghichu_local.md` mục 2. **Về FS:** FS chỉ ghi 1 câu "Hai bảng tham số là customizing (Transport), bảo trì bởi Key user/IT; có table logging" (phần Nguồn dữ liệu), **không ghi chữ Delivery Class `C`**; chữ `C` là do hướng dẫn tạo của mình tự thêm. Chọn `A` là lệch với chữ "customizing (Transport)" của FS → báo BA là dữ liệu không đi theo transport.
- **Server MCP**: (cập nhật 13/10/2026) `.mcp.json` có cả `GUI_BDP_DEV_100` (vsp bản `vsp_tn_20261007`) và `GUI_BDP_DEV_200` (bản cũ `vsp_v6_20260924`, không tạo được message class); cùng host `vhbzddevap01.sap.bidiphar.com:44300`, khác client. Cả hai kết nối tốt, không dính CSRF. Client 200 khóa sửa nên dùng 200 để đọc/kiểm.
- **Lỗi cú pháp đã gặp khi viết code** (chi tiết ở `_ghichu_local.md` mục 2): `VALUE STANDARD TABLE OF ... (` sai (cần `TYPES tt` rồi `VALUE tt(`), `VALUE` kiểu generic, biểu thức/hàm trong `PERFORM USING`/`MESSAGE WITH`, `SORT` bảng SORTED, `url` của HTML viewer cần `c(250)`, selection-screen tối đa 83 cột.
- **Quy ước TR** (`NOTE/note.md`): `<Tên>_<Module>_<TCode>_<DD.MM.YYYY>_<Mô tả không dấu>`, mô tả không chứa "move/copy"; SAP giới hạn 60 ký tự.

## 7. Kiến thức EWM (BDP DEV)

- WM ≠ EWM: WM đọc `LAGP/LQUA`, TO; EWM đọc `/SCWM/*`/CDS `I_EWM_*`, WT, tồn gắn HU/stock item/owner/entitled. Vì vậy báo cáo WM cũ không dùng được.
- Authorization object theo Warehouse: `/SCWM/LG` (`/SCWM/LGNU`, `/SCWM/LGTY`, `ACTVT`); user parameter Warehouse: `/SCWM/LGN`.
- `I_EWM_StorageBin` đã deprecated → dùng `I_EWM_StorageBin_2`. Số WT/giờ di chuyển gần nhất nằm sẵn trên Bin.
- Data DEV: chỉ Warehouse `0001`, không Bin/quant.

## 8. FS mới `ZWM2D` (08/10/2026): thay đổi, việc tạm bỏ qua, quyết định đã chốt

File: `FS/BIDIPHAR_FS_EWM_ZWM2D_TonKhoTaiBin_SoDoKho2D_v1.0.docx` (thay FS ZLX02, cùng v1.0, thêm dòng thay đổi 08/10/2026). **Code local đã sửa theo FS này (mục 8.1, tối 08/10/2026) nhưng chưa dán lên SAP.** Mục 5 ở trên là theo FS cũ; mục này là phần cập nhật theo FS mới.

**Thay đổi so với FS cũ**
- **Đổi tên:** T-code `ZWM2D` (BIDIPHAR xác nhận 08/10/2026; tư vấn nhắn "ZWM02D" nhưng FS ghi `ZWM2D` ở 32 chỗ → theo FS), message class `ZWM2D` (001–010), bảng `ZTWM_2D_PARAM` (thay `ZTWM_LX02_PARAM`), `S_TCODE` = `ZWM2D`, chương trình đề xuất `ZWM_R_ZWM2D` (code đang giữ `ZWM_PG_TKBIN`).
- **Màu trạng thái Bin dùng chung danh sách và sơ đồ:** xanh lá = có hàng không khóa; xám nhạt = trống; đỏ = khóa nhập/xuất; vàng = khóa kiểm kê; trắng = không có Bin. Kết quả tìm = viền xanh đậm; ô đang chọn = viền đen đậm (không đổi màu nền).
- **Thống kê 9 dòng** (thêm "Không có Bin", tách "Khóa nhập/xuất" và "Khóa kiểm kê").
- **Đã có định nghĩa:** Chờ putaway (SL còn mở của WT có Bin đích là Bin này), SL đang pick (Bin nguồn), Khả dụng = Số lượng − SL đang pick; Plant/SLoc (Party entitled → Plant; Stock Type → availability group → `/SCWM/TMAPSTLOC` lọc theo Plant); "Lý do khóa" đổi thành "Diễn giải khóa" (chương trình sinh chữ từ 3 cờ + người/thời điểm thay đổi gần nhất của Bin).
- **Mã Bin:** ưu tiên đọc trường chuẩn của Bin (Aisle, Stack, Level, Bin Section, Depth); chỉ khi không có mới tách chuỗi theo `ZTWM_BIN_LAYOUT`.
- **Hết 2 mâu thuẫn cũ** (Thuật ngữ #6 theo 1 ĐVT; bỏ chữ "trích xuất").

**Tạm bỏ qua (FS ghi đang chờ hoặc giao Technical, không hỏi lại)**

| Mục | FS ghi | Xử lý tạm |
|---|---|---|
| Sơ đồ cho TK20, TKFB (WTK1), W498, WNH1 | Bảng "Cấu trúc mã Bin theo từng Warehouse / Storage Type": "Chờ xác nhận", "Chờ BP Kho cung cấp" | Không cấu hình trong `ZTWM_BIN_LAYOUT` → sơ đồ báo `ZWM2D-005`, danh sách vẫn chạy (đúng FS). Khi BP Kho gửi quy ước chỉ cần nhập cấu hình, không sửa code |
| Cột Plant, SLoc và ô lọc Plant/SLoc | Dòng 8 bảng "Mô tả các trường": "Technical xác nhận cách đang được cấu hình trên hệ BIDIPHAR" (3 cách gắn BP với Plant) | **ĐÃ LÀM (08/10 tối)** bằng API chuẩn `/SCWM/IF_STOCKID_MAPPING->GET_ERP_STLOC` (Warehouse + Party entitled + Stock Type → Plant + SLoc), không phụ thuộc cách cấu hình (FS khuyến nghị dùng API chuẩn). DEV không có cấu hình (`/SCWM/TMAPPLANT`, `/SCWM/TMAPSTLOC` = 0 dòng) nên chưa kiểm được số liệu; chưa có ánh xạ thì 2 cột để trống. Xem 8.1 |
| Thông báo "số dòng bị loại" (mục 4 Phân quyền) | "Dòng dữ liệu người dùng không có quyền bị loại khỏi kết quả; hệ thống thông báo số dòng bị loại". Từ khóa: `hệ thống thông báo số dòng bị loại` | Tạm bỏ qua theo ý user (08/10/2026), tư vấn nhắn khi cần. Lý do kỹ thuật: SAP tự ẩn dòng không có quyền ngay khi đọc dữ liệu nên chương trình không đếm được số dòng bị ẩn; chỉ kiểm quyền Warehouse (`ZWM2D-001`) |

**FS giao Technical chọn (đã quyết hoặc sẽ quyết, không hỏi):** SL khả dụng (đọc từ tồn khả dụng hoặc = Số lượng − SL đang pick, ghi rõ trong TS); object phân quyền EWM (`/SCWM/LG`, đã kiểm có trong TOBJ); hàm quy đổi ĐVT (`MD_CONVERT_MATERIAL_UNIT`); CDS/API đọc EWM; phương án vẽ sơ đồ ALV Grid hay HTML viewer ("chốt ở bước TS", đang dùng HTML viewer).

**Đã hỏi tư vấn và có trả lời (08/10/2026 chiều)** — file FS mới nhất: `FS/BIDIPHAR_FS_EWM_ZWM2D_TonKhoTaiBin_SoDoKho2D_v1.0 1.docx` (17:00)
1. **Chờ putaway / SL đang pick: làm theo Hình 4, tách dòng theo từng tham số, không gom theo Bin.** Mỗi dòng = 1 tổ hợp (Bin + vật tư + lô + HU + Stock Type + tồn đặc biệt/chủ sở hữu); 2 cột này cộng riêng cho từng tổ hợp. Hàng đang về (có WT putaway mở) mà chưa có tồn trong Bin thì thêm 1 dòng riêng với Số lượng = 0 (cách hiểu của lập trình, chưa hỏi lại). **FS chưa sửa chữ:** dòng 18, 19 bảng "Mô tả các trường" vẫn ghi tổng theo cả Bin.
2. **Mục 2.4 "Màn hình trung gian" đã bị xóa** (câu "từ danh sách có thể nhấp để xem chi tiết Bin và Warehouse Task gần nhất"). → Không làm phần nhấp dòng xem chi tiết. Danh sách vẫn có cột "Di chuyển gần nhất" (ngày, giờ, số WT; dòng 28). Hình 3 vẫn còn nút "Chi tiết Bin", "Lịch sử WT của Bin" và "Sơ đồ kho" (hình chưa đổi) → không làm.

**FS bản "v1.0 1" chỉ đổi:** xóa mục 2.4, đánh lại số mục kết quả thành 2.4.1 / 2.4.2. Còn sót: 3 chỗ vẫn ghi "3.4.1 / 3.4.2" (bảng Selection Screen dòng 12, bảng hành vi tương tác dòng 8, mục quy đổi ĐVT), mục lục chưa cập nhật (vẫn có "2.4 Màn hình trung gian"), 4 hình giữ nguyên. Không ảnh hưởng code.

**Tạm theo Hình 4, hỏi nếu cần chốt:** thống kê "Tổng". Chữ FS ghi "gồm cả vị trí không có Bin" (từ khóa `gồm cả vị trí không có Bin`) nhưng Hình 4 có Tổng 208 = 146 + 45 + 13 + 4 và "Không có Bin 28" tách riêng. Code sẽ theo hình.

**Chưa đổi so với FS cũ, chưa hỏi:** E/B (FS chưa nói field EWM, code tạm giả định), "Chỉ Bin đang bị khóa" có hiện Bin khóa chưa có tồn không, loại thông báo W/I, HTML viewer thay ALV Grid. FS dòng 26 còn nhắc "xem Điểm cần xác nhận" nhưng FS không có mục đó.

### 8.1 Đã code theo FS ZWM2D (08/10/2026 tối) — đối chiếu code ↔ FS

Nguồn: tab "Mô tả các trường", "Quy định chung", Hình 3, Hình 4. Vị trí code: `Program/zwm_in_tkbin_*.abap`.

| Nội dung FS | Cách code | FORM |
|---|---|---|
| Đổi tên ZWM2D | `MESSAGE-ID ZWM2D`, đọc bảng `ZTWM_2D_PARAM`, comment class | `zwm_pg_tkbin`, `READ_CONFIG`, `zcl_wm_uom_convert` |
| Màu Bin dùng chung (ưu tiên khóa nhập/xuất > khóa kiểm kê > có hàng > trống) | Đèn ở danh sách (đã đúng từ trước) + màu ô sơ đồ + đếm thống kê cùng một hàm `CELL_STATUS` (L/K/F/E) | `CELL_STATUS`, `BUILD_HTML`, `BUILD_STAT`, `ENRICH_ROW` |
| Kết quả tìm = viền đậm, ô chọn = viền đen, không đổi màu nền | CSS: mọi ô có viền trong suốt 2px; `.s` viền xanh, `.c` viền đen; JS `pk()` chỉ thêm/bớt class `c`. Ô vừa tìm thấy vừa được chọn hiện viền đen | `BUILD_HTML` |
| Thống kê 9 dòng theo Hình 4 | Tổng = số Bin của Storage Type (kể cả Bin chưa xác định vị trí); Có hàng không khóa / Trống / Khóa nhập-xuất / Khóa kiểm kê chia đúng 4 nhóm cộng lại = Tổng; Không có Bin = số ô trắng trên lưới (đếm khi vẽ HTML); Kết quả tìm; Ô đang chọn; Tổng tồn kho (chỉ khi tìm đúng 1 vật tư, kèm ĐVT). Cột "Chú thích" to màu SALV (xanh lá/xám/đỏ/vàng; kết quả tìm = màu đậm, ô chọn = đảo màu — đúng gợi ý intensified/inverse trong FS) | `BUILD_STAT`, `ADD_STAT`, `CREATE_CONTROLS` |
| Tiêu đề Ô, nhãn Tầng, tên khối (Hình 4) | Tiêu đề Ô lấy theo Ô thật của các Bin trong cột; cột không có Bin (đường đi, VD Ô 07) để trống; nhãn "Tầng n"; tên khối chỉ ghi "01A". Mỗi khối là một bảng riêng, mỗi bảng có hàng tiêu đề riêng (Hình 4 chỉ vẽ 1 hàng tiêu đề cho cả sơ đồ — chọn lặp lại để cuộn xuống vẫn thấy) | `BUILD_HTML` |
| Mã Bin: ưu tiên trường chuẩn Aisle/Stack/Level/Bin Section/Depth, thiếu thì `ZTWM_BIN_LAYOUT` | `PARSE_STD_BIN` (đủ 5 trường, Tầng/Ô/Vị trí là số ≤ 3 chữ số) rồi mới `PARSE_ONE_BIN`. Kiểm `ZWM2D-005` và popup "Chuyển Storage Type" chấp nhận **một trong hai nguồn** (có dòng cấu hình **hoặc** có Bin đủ 5 trường chuẩn) | `PARSE_BINS`, `PARSE_STD_BIN`, `HAS_STRUCTURE`, `PICK_STORAGE_TYPE` |
| SL khả dụng, Chờ putaway, SL đang pick | Theo Hình 4: mỗi dòng ALV có số riêng. Nguồn WT: `I_EWM_OpenWarehouseTasks_2` (`/SCWM/ORDIM_O`), loại trừ trạng thái `A` (hủy) và `C` (đã xác nhận); số lượng = `TargetQuantityInBaseUnit`. **Khả dụng = Số lượng − SL đang pick** (không đọc `/SCWM/AQUA` nữa; FS cho Technical chọn, ghi vào TS). WT theo vật tư khớp dòng theo (Bin, `StockItemUUID`, HU); WT theo HU (cờ `IsHandlingUnitWarehouseTask`) lấy cả HU (số lượng = tồn của HU). Chờ putaway **không** cộng vào Số lượng | `READ_OPEN_WT`, `APPLY_WT` |
| Hàng đang về mà chưa có tồn khớp | Chỉ ở ALV vùng (4) của sơ đồ (đọc sẵn khi mở/làm mới, không đọc DB khi nhấp ô): thêm dòng Số lượng = 0, Chờ putaway = n. WT theo HU lấy nội dung HU từ tồn (`READ_HU_CONTENT`). **Danh sách (ALV chính) không thêm dòng này** | `ADD_PENDING_ROWS`, `READ_HU_CONTENT`, `FINISH_PENDING` |
| "Lý do khóa" → "Diễn giải khóa" | Chữ sinh từ 3 cờ: "Khóa nhập", "Khóa xuất", "Khóa nhập + xuất", "Khóa do kiểm kê (chứng từ <số>)"; nếu Bin đang khóa thì nối thêm " - <người đổi> <ngày> <giờ>" (người/thời điểm đổi gần nhất của Bin master). 3 cột riêng "Người đổi Bin / Ngày đổi Bin / Giờ đổi Bin" tạo sẵn nhưng ẩn | `LOCK_DESC`, `LOCK_PHRASE`, `LOCK_TEXT` |
| Loại Bin, sức chứa còn lại (tùy chọn hiển thị) | 2 cột `LPTYP`, `CAPA` (= `EWMStorBinAvailCapacityValue`) ẩn mặc định, bật qua layout ALV | `FORMAT_ALV` |
| ALV vùng (4) đúng thứ tự cột FS | `SET_COLUMN_POSITION`: Vật tư, Storage Bin, Mô tả, Số lô SAP, Số lô NSX, Hạn dùng, Ngày KNL, Tổng tồn, Khả dụng, Chờ putaway, SL đang pick, ĐVT, SL quy đổi, ĐVT quy đổi, Stock Type, Tồn đặc biệt, HU, Ngày nhập (thiếu Plant, SLoc — chờ Technical) | `FORMAT_ALV` |
| Plant / SLoc (cột + ô lọc) | 2 cột `Plant`, `SLoc` (danh sách và vùng 4) + 2 ô lọc `S_WERKS`, `S_LGORT` ở màn hình chọn (Hình 2 vẽ 1 dòng "Plant / Storage Location"; code tách 2 dòng cho rõ). Mỗi cặp (Party entitled, Stock Type) gọi API 1 lần rồi nhớ lại; cột ẩn "Party entitled" để đối chiếu. Ô lọc chỉ áp cho Danh sách (sơ đồ không dùng các ô lọc Vật tư/Lô/...) | `ADD_PLANT_SLOC`, `RUN_LIST`, `BUILD_VIEW` |
| Hình 3: dòng thông tin đầu danh sách | "Warehouse X \| Storage Type Y \| Thời điểm chạy … \| User …" bằng top-of-list SALV (thay tiêu đề cũ "ZLX02 - ...") | `SHOW_LIST` |

**Giả định / hạn chế của đợt này (chưa thể kiểm bằng dữ liệu thật):**
- **Chưa có dữ liệu để chạy thử**: DEV 200 không có tồn, WT mở hay WT đã xác nhận. Cách ghép WT ↔ dòng tồn, WT theo HU và dòng "đang về" **dựa trên hiểu biết về EWM, chưa kiểm số liệu**. Khi có dữ liệu thì test: pick từng phần từ pallet, pick nguyên pallet (HU WT), putaway pallet vào Bin trống, putaway thêm vào pallet đã có.
- **Ô và Vị trí đọc từ trường nào**: FS ghi "Bin Section = Ô, Bin Depth / Position = Vị trí". Trên Bin có 2 cặp field gần giống nhau: `BINSC` ("Bin Section of a Storage Bin") + `DEPTH` ("Bin Depth") là phần điền từ cấu trúc mã Bin (cùng nhóm với Aisle `AISLE`, Stack `STACK`, Level `LVL_V`), và `PLAUF` ("Storage Bin Section") + `PLPOS` ("Position in Storage Bin"). Code dùng **`BINSC` + `DEPTH`**. Chưa kiểm bằng Bin thật; nếu Bin thật điền vào `PLAUF`/`PLPOS` thì đổi alias trong `READ_BINS`, `READ_BINS_KEYED`, `HAS_STRUCTURE`, `PICK_STORAGE_TYPE`.
- WT theo HU được giả định **không mang thông tin vật tư** (cờ `IsHandlingUnitWarehouseTask` = X → dùng nội dung HU). Nếu WT theo HU của BIDIPHAR có số lượng riêng thì cần đổi `APPLY_WT`.
- Trạng thái WT tính là "chưa xác nhận": mọi trạng thái trừ `A` (Canceled) và `C` (Confirmed); gồm cả `B` (Waiting) và trống (Open).
- "Diễn giải khóa" **chỉ có số chứng từ kiểm kê, không có ngày chứng từ** (FS: "kèm số và ngày chứng từ"): bảng Bin chỉ lưu số chứng từ; ngày chứng từ nằm ở header kiểm kê, không có CDS chuẩn đọc theo số chứng từ. Nếu BA bắt buộc có ngày thì phải đọc thêm bảng `/LIME/PI_DOC_*`.
- "Tổng" theo Hình 4 (208 = tổng 4 nhóm trạng thái), **khác chữ trong FS** ("gồm cả vị trí không có Bin").
- Cột "SL theo ĐVT kho (Logistics UoM)" (tùy chọn, ẩn) **chưa làm**: nguồn có thể là `I_EWM_ProductWarehouse-EWMPreferredUnit` (`puom_wh`) nhưng chưa chắc trùng khái niệm "Logistics UoM" của FS và view này cần quyền riêng (`#MANDATORY`) + nối Business Partner của Warehouse → hỏi tư vấn trước khi làm.
- Không làm (hình mẫu, không có trong chữ FS): nút "Chi tiết Bin", "Lịch sử WT của Bin", "Sơ đồ kho" trong ALV danh sách; dòng tổng "Tổng số dòng · Bin có tồn · Bin khóa"; E/B dạng radio.
- Đã **bỏ** `SLOTS_PER_CELL` khỏi logic vẽ (vẫn còn trong `ZTWM_BIN_LAYOUT`, không dùng): tiêu đề Ô lấy từ Ô thật của Bin.
- Giới hạn thiết kế 10 tầng / 60 cột của FS không áp dụng (HTML cuộn được).
- `SyntaxCheck` 08/10/2026 tối: dán nội dung 6 include + chương trình chính gộp vào `object_url=/sap/bc/adt/programs/programs/zwm_pg_tkbin` → `null` (đã chứng minh công cụ bắt lỗi: thử 1 lỗi cố ý → báo đúng). Bản kiểm dùng `MESSAGE-ID ZLX02` và `ZTWM_LX02_PARAM` vì `ZWM2D` / `ZTWM_2D_PARAM` chưa tồn tại; **ATC và kiểm cú pháp bản thật chỉ làm được sau khi dán lên SAP.**
