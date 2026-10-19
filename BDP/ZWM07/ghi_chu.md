# ZWM07 – Lệnh chuyển vị trí (chương trình ZWM_PG_LCVT)

FS: `FS/BIDIPHAR_FS_EWM_ZWM07_LenhChuyenViTri_v1.0.docx` (v1.0, 16/09/2026; hợp nhất ZWM07 `ZWM_PG_LCVT` và ZWM07A `ZWM_PG_LCVT_A` của ECC). Source ECC: `CODE_FINAL/zwm_pg_lcvt` và `zwm_pg_lcvt_a` (OneDrive Citek Bidiphar: `C:\Users\DanhDangHoang\citek.vn\Citek Bidiphar Upgrade PCE - BIDIPHAR_ECC\CODE_FINAL\`). Hệ: S/4 On-Premise, MCP `GUI_BDP_DEV_100` (client 100). TR: `DanhDH_WM_ZWM07_14.10.2026_Lệnh chuyển vị trí`, TR cha `DEVK900602`, task `DEVK900603`. Qua MCP truyền **TR cha `DEVK900602`**.

## 0. TRẠNG THÁI (14/10/2026) – ĐỌC TRƯỚC

**Chương trình ZWM_PG_LCVT đã active trên DEV, source server khớp local, CHƯA chạy thử** (DEV chưa có dữ liệu EWM). Đã kiểm lại bằng MCP ngày 14/10/2026: `REPOSRC` chỉ còn `R3STATE = A` cho cả 3 (chương trình + 2 include), `SyntaxCheck` chương trình thật sạch, ATC 0 lỗi / 6 cảnh báo (mục 0.2), text elements đã activate.

Local: `Program/zwm_pg_lcvt/` (`zwm_pg_lcvt.abap` main, `zwm_in_lcvt_top.abap`, `zwm_in_lcvt_f01.abap`, `dictionary/zwm_st_lcvt.md`, `dictionary/ztwm_wt_opt.md`) và `Smartforms/` (`gen_zwm_sf_lcvt.py`, `FS_v1.0/ZWM_SF_LCVT.xml`). Khung theo ZWM05 (`ZWM05/Program/zwm_pg_pck`): màn hình trung gian ALV, nút Xem trước / In / Chọn tất cả / Chi tiết WT / Excel, nhật ký in `ZTWM_PRTLOG`.

**ĐANG CHỜ TƯ VẤN PHẢN HỒI (14/10/2026): bảng `ZTWM_WT_OPT`.** Tư vấn đang xem lại FS, user sẽ báo kết quả ở phiên sau. Khi có phản hồi thì cập nhật theo mục dưới, đừng tạo SM30 / bật log trước khi tư vấn chốt.
- **Hiện trạng:** FS chỉ ghi tên bảng và khóa (Warehouse, Option, Loại, WPT, loại chứng từ tham chiếu), không mô tả field; ECC không có bảng tương tự. Mình tự đặt 6 field (`MANDT`, `LGNUM`, `OPT`, `LOAI`, `PROCTY`, `RDOCCAT`, cả 6 là khóa, không có field dữ liệu), đã tạo và active trên DEV (delivery class `A`, `ZPK_BDP`). Chi tiết ở `dictionary/ztwm_wt_opt.md` và mục 3 "Giả định đã chọn".
- **Điểm đang chờ chốt:** (1) cấu trúc field có đúng ý không, có field dữ liệu ngoài khóa không; (2) `RDOCCAT` để trống = áp cho mọi loại chứng từ; (3) `LOAI` chỉ dùng cho Option 1, Option 2/3 để trống; (4) có làm SM30 và bật Log data changes không (FS không ghi, mình làm theo thông lệ các bảng tham số WM khác); (5) Option 2/3 "Dest Bin là PSA": hiện không kiểm Bin đích, dựa vào WPT + `PMR`.
- **Khi tư vấn trả lời, sửa các chỗ:** bảng trên DEV (`UpdateObjectAtomic`, sau đó kiểm `DD03L`: field client phải là `MANDT`); `dictionary/ztwm_wt_opt.md`; code đọc bảng ở `zwm_in_lcvt_f01.abap` (FORM `get_option_config` và `gty_opt` trong `zwm_in_lcvt_top.abap`, phần lọc WPT/`RDOCCAT` trong `get_data`, `check_undeclared_wpt`); mục 3 và mục 6B của file này; sau đó `SyntaxCheck`, `Activate`, kiểm `REPOSRC` (`R3STATE = A`). Muốn thêm lọc PSA thì thêm điều kiện ở `get_data` (field `ORDIM-PSA`). Cấu trúc mới thì báo user nhập lại dữ liệu thử nếu có.

**Việc còn lại (chỉ user làm được trong SAP GUI, hướng dẫn từng bước ở mục 6):**
1. **GUI status `STANDARD`** của `ZWM_PG_LCVT` (SE41, copy từ `ZWM_PG_PCK`): chưa có (`D345T` không có bản ghi). Thiếu thì ALV báo lỗi lúc chạy.
2. **T-code `ZWM07`** (SE93): chưa có (`TSTC` không có bản ghi).
3. **Bảng `ZTWM_WT_OPT`**: bật Log data changes (SE11 → Technical Settings; hiện `DD09L-PROTOKOLL` trống) và tạo SM30 (`TVDIR` chưa có). *FS không ghi chữ SM30 hay Log; FS chỉ ghi bảng này do Key user/IT bảo trì (`S_TABU_NAM` 02). Làm theo thông lệ các bảng tham số WM khác (`ZTWM_LX02_PARAM`, `ZTWM_2D_PARAM` có SM30 trong `ZFG_WM_LX02`; `ZTWM01_PARAM`, `ZTWM_PCK_TITLE`... bật log). SM30 cần để BA nhập; log là tùy chọn.*
4. **Upload Smart Form `ZWM_SF_LCVT`** (XML đã sinh, `sf_validate.py` PASS; `ZWM_ST_LCVT` đã có trên DEV nên upload được ngay). In thử rồi chụp ảnh preview gửi Claude.
5. BA nhập `ZTWM_WT_OPT` (chưa có WPT nào thì chương trình không tìm ra WT, báo ZWM07-004).
6. Chưa có dữ liệu EWM trên DEV để chạy thử (xem mục 3).

### 0.1 Object đã tạo trên DEV bằng MCP (14/10/2026, TR cha `DEVK900602`, kiểm `TADIR` / `DD02L` / `DD04L`)

| Object | Package | Ghi chú |
|---|---|---|
| Data element `ZDE_WM_WT_OPTION`, `ZDE_WM_WT_LOAI` | `ZPK_BDP` | Domain `CHAR1`, nhãn tiếng Việt theo mục 6A |
| Bảng `ZTWM_WT_OPT` | `ZPK_BDP` | Delivery class `A`, 5 field khóa + `MANDT` (data element `MANDT`); active. Lần tạo đầu tool đặt field client là `CLIENT` không data element, đã sửa lại thành `MANDT` và kiểm `DD03L` (14/10/2026). Technical settings chưa bật log (mục việc còn lại 3) |
| Structure `ZWM_ST_LCVT` | `ZPK_WM` | 10 field, `MENGE` có `@Semantics.quantity.unitOfMeasure` trỏ `MEINS`; active |
| Message class `ZWM07` | `ZPK_WM` | 8 message, mục 5. Lúc đầu tạo nhầm ở `ZPK_BDP`, đã xóa và tạo lại ở `ZPK_WM` (như ZWM04, ZWM05) |
| Text elements của `ZWM_PG_LCVT` | – | 4 text symbol, 20 selection text (≤ 30 ký tự); đã activate |
| Program `ZWM_PG_LCVT`, include `ZWM_IN_LCVT_TOP`, `ZWM_IN_LCVT_F01` | `ZPK_BDP` | User tạo và dán source; MCP kích hoạt (xem 0.3) |

### 0.2 Kết quả ATC (`RunATCCheck`, 14/10/2026): 0 lỗi, 6 cảnh báo, 57 info

- 4 cảnh báo "bypass buffer" (`T001L`, `T001W`, `T001K` trong `JOIN @itab`, `/SCWM/T333T` thiếu khóa `PROCTY`): cố ý, dữ liệu nhỏ và đọc 1 lần.
- 1 cảnh báo "Possible sequential read on a sorted table" ở `DELETE gt_wt WHERE vltyp = ... OR nltyp = ...` (loại WT theo quyền Storage Type, lọc theo cột không phải khóa).
- 1 cảnh báo "No exception handling after the CATCH" ở `CATCH cx_salv_not_found` khi đặt tên cột ALV (giống ZWM05).
- Info: chuỗi hard-code tiếng Việt chưa đưa vào text element (giống ZWM05).

### 0.3 Cách đã kích hoạt 3 object (đúc kết, vì `Activate` báo thành công nhưng `REPOSRC` vẫn còn bản `I`)

`TOP` khai báo class `lcl_handler`, `F01` cài đặt class đó, nên không activate riêng từng include được (mỗi include lỗi khi đứng một mình, tool lại không báo lỗi). Cách làm: (1) activate chương trình chính ở dạng khung chỉ có `REPORT` + 2 `INCLUDE`, (2) bỏ `CLASS lcl_handler DEFINITION` khỏi TOP và activate TOP, (3) thêm khai báo class vào F01 ngay trên `CLASS lcl_handler IMPLEMENTATION` rồi activate F01, (4) ghi lại nội dung đầy đủ của chương trình chính. **Vì vậy `CLASS lcl_handler DEFINITION` nằm ở đầu `zwm_in_lcvt_f01.abap`, không còn ở TOP** (file local đã sửa theo). Sau đó chạy `Activate` với `object_url=/sap/bc/adt/textelements/programs/zwm_pg_lcvt` để activate text pool (activate chương trình không kéo theo text pool).

## 1. Đối chiếu source ECC với FS – những gì đã làm

Source ECC không đáp ứng FS (đọc WM `LTAK/LTAP`, không có màn hình trung gian, không phân Option, không nhật ký in), viết lại toàn bộ, giữ tên chương trình `ZWM_PG_LCVT` và tách include.

| # | ECC (`zwm_pg_lcvt`, `zwm_pg_lcvt_a`) | S/4 theo FS |
|---|---|---|
| 1 | Đọc `LTAK` / `LTAP` (Transfer Order WM) | Đọc EWM: WT mở `/SCWM/ORDIM_O`, WT đã xác nhận `/SCWM/ORDIM_C`; bỏ WT hủy (`TOSTAT = A`) |
| 2 | Selection: Warehouse + Transfer Order + song ngữ (+ sắp xếp xuất/nhận ở ZWM07A) | Warehouse, Warehouse Task, WPT, Ngày tạo WT, Storage Type nguồn/đích, Chứng từ tham chiếu, Lệnh SX, Vật tư, Người tạo; radio Trạng thái WT (3), Option (3, Option 1 có 3 loại tick), Gom (2). Bỏ checkbox song ngữ |
| 3 | In thẳng Preview | Luôn qua màn hình ALV (mỗi dòng = 1 WT), nút Xem trước / In / Chọn tất cả / Chi tiết WT / Excel |
| 4 | Không phân biệt nghiệp vụ | 3 Option lấy WT theo WPT khai báo ở `ZTWM_WT_OPT` |
| 5 | Header Plant/SLoc từ `LTAP-WERKS/LGORT` | Plant/SLoc từ ánh xạ chuẩn ERP–EWM `/SCWM/IF_STOCKID_MAPPING->GET_ERP_STLOC` (Party entitled + loại tồn) |
| 6 | Cột Lệnh điều chuyển = TANUM, Vị trí xuất/nhận | Cột theo FS 2.5: STT, Warehouse Task, Xác nhận, Bin nguồn, Bin đích, Số WT, Mã hàng, Tên hàng, Số lô SAP, Số lô NSX, Số lượng, ĐVT, SL thực chuyển, Bin thực tế |
| 7 | ZWM07A: tên khách hàng (`LIKP-KUNNR`), SL quy đổi hộp/thùng, hard-code BOX/CAR | Giữ tên khách hàng (ship-to của Outbound Delivery) và thêm tên NCC (Inbound Delivery). Bỏ SL quy đổi (FS không có cột này) |
| 8 | `FOR ALL ENTRIES`, `SELECT` lồng, `ZCORE_FM_GET_COMCODE` | 1 `SELECT` nối WT + vật tư + chứng từ tham chiếu; master data bằng `INNER JOIN @itab`; Company Code từ `T001K` |
| 9 | F4 Transfer Order tự viết, kiểm tra nhập `LTAP` | Bỏ (FS không nêu); kiểm tra nhập theo FS (ZWM07-002, 003) |
| 10 | Không nhật ký in | Ghi `ZTWM_PRTLOG` mỗi Warehouse Order (WT lẻ: mỗi WT) khi In thật; in lại có "Bản in lại – lần n" |

## 2. Logic chính / giả định

- **Nguồn WT**: Trạng thái "Chưa xác nhận" đọc `/SCWM/ORDIM_O`, "Đã xác nhận" đọc `/SCWM/ORDIM_C` (mỗi item một dòng in, `TAPOS`), "Tất cả" đọc cả hai. Bỏ `TOSTAT = A` (hủy). Mã vật tư lấy qua `MARA-SCM_MATID_GUID16 = ORDIM-MATID` (cách chuẩn của CDS `I_EWM_OpenWarehouseTasks_2`).
- **Ngày tạo WT**: lọc theo `CREATED_AT_WH` (giờ Warehouse, tránh lệch ngày do UTC); FS ghi `CREATED_AT` (UTC). Không nhập Warehouse Task thì bắt buộc Ngày tạo WT, tối đa 31 ngày (ZWM07-002); **có nhập Warehouse Task thì bỏ qua ngày** để ngày mặc định "hôm nay" không làm mất WT cũ.
- **Option** (`ZTWM_WT_OPT`, key Warehouse + Option + Loại + WPT + loại chứng từ tham chiếu): Option 1 lấy WPT của các loại Bin-to-Bin / Putaway / Picking được tick; Option 2, 3 lấy WPT của Option đó. S_PROCTY giao với danh sách này. FS ghi Option 2, 3 "Dest Bin là PSA": code **không kiểm riêng** Bin đích mà dựa vào WPT + loại chứng từ `PMR` khai báo trong bảng.
- **WPT chưa khai báo** (ZWM07-005): WT thỏa các điều kiện lọc khác nhưng WPT không có ở bất kỳ Option nào của Warehouse; báo mỗi WPT một lần kèm WT nhỏ nhất.
- **Chứng từ tham chiếu (H5)**: `RDOCCAT` + số chứng từ (`/SCDL/DB_PROCH_O` cho PDO/PMR, `/SCDL/DB_PROCH_I` cho PDI, nối bằng `RDOCID = DOCID`), VD "PMR 5000123". S_DOCNO so sánh sau khi bỏ số 0 đầu cả hai phía.
- **Lệnh SX / Khách hàng (H6)**: Lệnh SX từ `ORDIM-PROD_ORDER` + tên vật tư của lệnh (`AFPO-MATNR` → `MAKT`), VD "LSX 10019152 - Sorafenib Bidipha 200"; Picking theo Outbound Delivery: tên ship-to của Delivery, đọc 1 lần cho cả danh sách bằng 1 `SELECT` (`LIKP` nối `VBPA` header `WE` và `ADRC` bản gốc `NATION` trống; thiếu địa chỉ thì lấy `KNA1-NAME1` của `LIKP-KUNNR`), `NAME2`–`NAME4` nếu có, không thì `NAME1`: cùng nguồn và quy tắc của `ZCORE_FM_GET_PROFILE_SD` (FS: "tên ship-to (ZWM07A)") nhưng không gọi FM từng Delivery (FM chạy 3 `SELECT SINGLE` mỗi lần gọi). Putaway theo Inbound Delivery: tên NCC (`ZCORE_FM_GET_PROFILE`, `LIKP-LIFNR`, gọi 1 lần mỗi NCC). Ghi chú 14/10/2026: lúc đầu FM `ZCORE_FM_GET_PROFILE_SD` trên DEV chỉ có bản inactive nên phải né; user đã activate cùng ngày (kiểm `FUPARAREF` đủ tham số, `R3STATE = A`), nhưng đã chốt dùng cách đọc gộp ở trên vì đúng FS và nhanh hơn. Số Delivery ERP suy từ `DOCNO` (bỏ số 0 đầu, đệm 10 ký tự).
- **Loại điều chuyển (H7)**: diễn giải WPT `/SCWM/T333T-LBWAT` (VI, thiếu thì EN, thiếu nữa thì mã WPT).
- **Người tạo (H4)**: `CREATED_BY`, loại trùng, cách nhau dấu phẩy. **Plant/SLoc (H3)**: các cặp khác nhau, cách nhau "; ". Dòng thiếu ánh xạ thì để trống.
- **Gom / sắp xếp**: Gom = 1 phiếu cho mọi WT được chọn, sắp theo Bin đích → Bin nguồn → WT (FS hình 2: "sắp xếp cùng Vị trí đích"). Không gom = mỗi Warehouse Order một phiếu (WT chưa có WO: mỗi WT), sắp theo Bin nguồn → WT. FS 2.7 (Sắp xếp) ghi "Bin nguồn hoặc Bin đích theo lựa chọn" nhưng màn hình không có ô chọn riêng, nên lấy theo Gom/Không gom.
- **Ngày trên phiếu**: ngày tạo sớm nhất của các WT trong phiếu. **Bản đối chiếu**: phiếu chỉ gồm WT đã xác nhận thì tiêu đề phụ "Bản đối chiếu", cột Số lượng = SL thực tế (`NISTM`), Bin đích = Bin đã xác nhận.
- **Mã vạch**: số Warehouse Order (WT lẻ: số WT); phiếu gom nhiều Warehouse Order không in mã vạch.
- **Số lô NSX**: `Z_BATCH_NSX` (`ZCORE_FM_GET_CRTRT_MULTIVAL`, class `023`), rồi `MCHA-LICHA`, rồi lô SAP; ưu tiên lô của Plant ánh xạ.
- **Nhật ký in**: `ZTWM_PRTLOG`, `TCODE` / `FORMNAME` = `ZWM07`, `OBJ_KEY` = `<Warehouse>/WO<số WO>` hoặc `<Warehouse>/WT<số WT>`; chỉ ghi khi In thật; cột "Đã in / Lần cuối in / Người in cuối" đọc lại từ bảng này. FS mục nút "In" ghi table `Z_ZWM07` nhưng mục Nhật ký in ghi `ZTWM_PRTLOG` → dùng `ZTWM_PRTLOG` (bảng dùng chung đã có).
- **Phân quyền**: Warehouse kiểm bằng object `/SCWM/LG` (`/SCWM/LGNU`, `ACTVT` 03) lúc Thực hiện, không có quyền thì ZWM07-001. Dòng có Storage Type nguồn hoặc đích không có quyền bị loại, báo ZWM07-008 (số dòng bị loại).
- **Máy in**: máy mặc định của user (`USR01-SPLD`), không có thì hộp thoại; Xem trước dùng `LP01` khi user không có máy mặc định.
- **Performance**: không `FOR ALL ENTRIES`; 1 `SELECT` mỗi bảng WT; 2 `SELECT` gom nhóm kiểm WPT chưa khai báo (trả vài dòng); master data bằng `INNER JOIN @itab`; hàm lấy tên đối tác và đặc tính lô gọi 1 lần mỗi đối tượng.
- Chữ ký: Nhân viên kho, Thủ kho; Option 2, 3 thêm "Người nhận (phân xưởng)" (FS ghi "chờ xác nhận" nhưng hình 4 đã có ô này).

## 3. Câu hỏi còn mở cho BA

Chỉ giữ chỗ FS thiếu / mâu thuẫn ở yêu cầu chính (theo `NOTE/note.md`). Hiện **không còn câu hỏi nào** cho BA. Riêng cấu trúc `ZTWM_WT_OPT` đang do tư vấn xem lại FS, chờ phản hồi (xem mục 0, đầu file).

### Giả định đã chọn (FS thiếu hoặc mâu thuẫn nhẹ, đoán được ý đồ, không hỏi BA)

- **Cấu trúc `ZTWM_WT_OPT`**: FS chỉ nêu khóa, không mô tả field → giả định như `dictionary/ztwm_wt_opt.md`. *(FS thiếu, tự đặt)*
- **Cột (1) và (5) của phiếu** cùng ghi nguồn `/SCWM/ORDIM_C – Whs Task` (hình 4 lại in 2 số khác nhau) → code in số WT ở cả hai cột. Nếu BA muốn cột (1) là Warehouse Order thì đổi 1 dòng ở `FILL_SHEET` (`ls_data-tanum`).
- **ZWM07-002 nhắc "Warehouse Order"** nhưng màn hình chọn (FS 2.3, hình 2) không có tham số Warehouse Order → code kiểm Warehouse Task hoặc Ngày tạo WT, giữ nguyên text message của FS.
- **Nút "In" ghi chú "gom 1 phiếu nếu tick Gom nhiều WT"** → code dùng radio Gom của màn hình chọn (FS hình 2), không có checkbox riêng ở ALV.
- **Tiêu đề FS (H1) và nhãn "T1" của hình 4** → tiêu đề cố định "LỆNH CHUYỂN VỊ TRÍ".

### Chỉ thông báo BA (chưa cấu hình / chưa có data, code đã chạy tạm)

- `ZTWM_WT_OPT` chưa tồn tại / chưa có dòng → chưa tìm ra WT nào (báo ZWM07-004). BA cần nhập WPT cho từng Option (mục 6).
- DEV chỉ có Warehouse `0001`, chưa có WT / Bin / tồn EWM (`/SCWM/ORDIM_O` 0 dòng, kiểm 14/10/2026) → chưa kiểm số liệu. Cần Warehouse thật (WNH1…) và WT mở / đã xác nhận để thử.
- Ánh xạ ERP–EWM (Party entitled + loại tồn → Plant/SLoc) chưa có ở DEV (theo ZWM2D): Plant/SLoc, tên đơn vị, MST ở header sẽ trống cho đến khi có cấu hình `/SCWM/TMAPSTLOC`. FS ghi "Technical xác nhận".
- Đặc tính lô `Z_BATCH_NSX` chưa có trên DEV (theo ZWM04/05) → Số lô NSX lấy `LICHA` hoặc lô SAP.
- Định dạng `DOCNO` của chứng từ tham chiếu EWM (độ rộng, số 0 đầu) chưa kiểm với dữ liệu thật; code bỏ số 0 đầu khi so sánh.
- Phân quyền Warehouse: FS ghi "Technical xác nhận object chuẩn" → dùng `/SCWM/LG` (đã có trong `TOBJ`, theo ZWM2D).
- FS ghi form bằng Adobe Form (đề xuất); user chốt dùng Smart Form như ZWM03/04/05 (14/10/2026).
- Form `ZWM_SF_LCVT` bám hình 4 của FS nhưng **thêm logo `ZLOGO_0001`, địa chỉ, MST/điện thoại/fax** ở khối đầu như các form ZWM03/04/05 và ECC (hình 4 chỉ vẽ tên đơn vị và dòng Warehouse). Muốn bỏ logo thì sửa `row_company` trong `gen_zwm_sf_lcvt.py`.
- Mã vạch dùng định dạng ký tự `Z2` của style `ZCORE_STYLE_REPORT` (theo ghi chú skill: "barcode"), **chưa kiểm trên máy in thật**; nếu preview in ra chữ thường thay vì mã vạch thì cần BA / Basis cho biết barcode system dùng trong SE73 / style.

## 4. Khi BA trả lời / khi có dữ liệu

- BA khai báo WPT: nhập `ZTWM_WT_OPT` (SM30).
- Có WT thật: thử Option 1 (Bin-to-Bin, Putaway, Picking), Option 2, 3, WT mở / đã xác nhận / tất cả, gom và không gom, in lại; kiểm `DOCNO`, Plant/SLoc, cột Bin đích của WT đã xác nhận.
- BA chốt cột (1): sửa `FILL_SHEET`.
- BA muốn lọc thêm "Dest Bin là PSA": thêm điều kiện ở `GET_DATA` (field `ORDIM-PSA`).

## 5. Message class ZWM07 (VI / EN) và interface Smart Form

| Số | Loại | Nội dung |
|---|---|---|
| 001 | E | Bạn không có quyền trên Warehouse &1. / You are not authorized for warehouse &1. |
| 002 | E | Vui lòng nhập Warehouse Task hoặc Ngày tạo WT (tối đa 31 ngày). *(đã ghi trên DEV; text FS có thêm "Warehouse Order" nhưng dài quá 73 ký tự và màn hình chọn không có ô này)* |
| 003 | E | Option 1: chọn ít nhất một loại Bin-to-Bin / Putaway / Picking. / Option 1: select at least one of Bin-to-Bin / Putaway / Picking. |
| 004 | S | Không có Warehouse Task thỏa điều kiện. / No warehouse task found. |
| 005 | W | Warehouse Process Type &1 chưa khai báo trong ZTWM_WT_OPT, WT &2 bị loại. / Warehouse process type &1 is not maintained in ZTWM_WT_OPT, WT &2 excluded. |
| 006 | I | Warehouse Order &1 đã in &2 lần. Bản in này được đánh dấu Bản in lại. / Warehouse order &1 has been printed &2 times. This copy is marked as reprint. |
| 007 | E | Chưa chọn Warehouse Task. / No warehouse task selected. — thêm ngoài FS |
| 008 | W | Đã loại &1 dòng không có quyền (Warehouse &2 / Storage Type &3). / &1 items removed – no authorization (warehouse &2 / storage type &3). — thêm ngoài FS (mục Phân quyền yêu cầu báo số dòng bị loại) |

Lưu ý: câu 006 của FS có dấu `"` quanh "Bản in lại" → bỏ dấu nháy kép khi ghi qua MCP (xem `_ghichu_mcp_gui.md`). 007 và 001 gọi bằng `MESSAGE s… DISPLAY LIKE 'E'` (theo ZWM05).

**Interface Smart Form `ZWM_SF_LCVT` (XML đã sinh, chưa upload):** Import `GS_PARAMETER TYPE ZCORE_ST_PARAMETER`; Tables `IT_DATA LIKE ZWM_ST_LCVT`. Mỗi lần gọi form = 1 phiếu (`SSF_OPEN` 1 lần, gọi form nhiều lần với `NO_OPEN` / `NO_CLOSE`).

| Field GS_PARAMETER | Nội dung |
|---|---|
| LOGO | `ZLOGO_0001` |
| HEADER01–06 | Tên Plant (in hoa), địa chỉ, "Điện thoại: …", "Fax: …", "MST: …" (theo Company Code), "Website: …" |
| HEADER07 | "Warehouse <mã> – <tên>" |
| HEADER08 | "Ngày dd tháng mm năm yyyy" |
| TITLE_REPORT | "LỆNH CHUYỂN VỊ TRÍ" |
| BELOW_TITLE_REPORT | "Bản đối chiếu" (phiếu chỉ gồm WT đã xác nhận), còn lại trống |
| HEADER09 / 10 | Nhãn / (H3) Plant / Storage Location |
| HEADER11 / 12 | Nhãn / (H4) Người tạo phiếu |
| HEADER13 / 14 | Nhãn / (H5) Chứng từ tham chiếu |
| HEADER15 / 16 | Nhãn / (H6) Lệnh SX / Khách hàng |
| HEADER17 / 18 | Nhãn / (H7) Loại điều chuyển |
| BARCODE | Số Warehouse Order (hoặc WT); trống khi phiếu gom nhiều Warehouse Order |
| ISO_LINE01 | "Lần in: 1" / "Bản in lại – lần n" |
| PARAMETER01–14 | Tiêu đề cột: STT, Warehouse Task, Xác nhận, Bin nguồn, Bin đích, Số WT, Mã hàng, Tên hàng, Số lô SAP, Số lô NSX, Số lượng, ĐVT, SL thực chuyển, Bin thực tế |
| SIGN01–03 | Nhân viên kho, Thủ kho, Người nhận (phân xưởng) (chỉ Option 2, 3); SIGN06 "(Ký, ghi rõ họ tên)" |
| FOOTER03 | "In lúc: dd/mm/yyyy hh:mm – User: …" |
| FOOTER05 / 06 / 07 | "Ngày ….. tháng ….. năm ……..", "Trang" (form tự in x/y), "Bản in lại – lần n" |

Dòng `IT_DATA` (`ZWM_ST_LCVT`): `STT, TANUM, VLPLA, NLPLA, MATNR, MAKTX, CHARG, SOLO, MENGE, MEINS`. Cột (1) và (5) dùng cùng `TANUM`; cột (2), (12), (13) để trống ghi tay.

Thiết kế form (FS 2.5): A4 ngang; Times New Roman, tiêu đề 16, nội dung 10; ngắt trang theo phiếu; mẫu hình: FS Hình 4.

## 6. Hướng dẫn việc user làm (làm theo thứ tự)

Giá trị lấy từ ZWM05 (`ZTWM_PCK_TITLE`, `ZTWM_MVT_GRP`, T-code `ZWM05`); đã kiểm bằng MCP ở lần làm ZWM05.

**Trạng thái 14/10/2026:** A, C, D, E và phần tạo bảng ở B **đã được Claude tạo bằng MCP** (mục 0.1), user chỉ cần làm: **B bước 1–3** (log + SM30), **F** (GUI status), **G** (T-code), **H** (upload Smart Form), **J** (phân quyền). I đã xong. Các mục A, C, D, E giữ lại để tham khảo / tạo lại ở hệ khác.

**A. Data element** (SE11 → Data type → Data element; Package `ZPK_BDP`; domain `CHAR1`) *(đã tạo bằng MCP)*

| Data element | Short | Medium | Long | Heading |
|---|---|---|---|---|
| `ZDE_WM_WT_OPTION` | Option | Option ZWM07 | Option lệnh chuyển vị trí | Option |
| `ZDE_WM_WT_LOAI` | Loại ĐC | Loại điều chuyển | Loại: Bin-to-Bin/Putaway/Picking | Loại ĐC |

**B. Bảng `ZTWM_WT_OPT`** (*đã tạo và active bằng MCP*: Short description `Ánh xạ Option – WPT lệnh chuyển vị trí`, Delivery class `A`, Package `ZPK_BDP`, field theo `dictionary/ztwm_wt_opt.md`). **Còn 3 bước user làm:**
1. SE11 → `ZTWM_WT_OPT` → Change → Goto → Technical Settings (đang là Data class `APPL0`, Size category `0`, Buffering not allowed, giữ nguyên) → tick **Log data changes** → Save (chọn TR/task `DEVK900602`) → Back → **Activate** (Ctrl+F3).
2. Vẫn ở SE11 → Utilities → Table Maintenance Generator: Authorization Group `&NC&`; Function group `ZFG_WM_WT_OPT`; Package `ZPK_BDP`; Maintenance type One step; Overview screen `1`; Single screen để trống → Create (chọn TR/task `DEVK900602`).
3. Kiểm tra: SM30 → `ZTWM_WT_OPT` → Maintain → thêm thử 1 dòng; xóa dòng thử.

**C. Structure `ZWM_ST_LCVT`** (SE11 → Structure; Package `ZPK_WM`; Enhancement category Not extensible). Field theo `dictionary/zwm_st_lcvt.md`. *(đã tạo và active bằng MCP; trên DEV `MEINS` đứng trước `MENGE` để annotation đơn vị trỏ tới field phía trên)*

**D. Message class `ZWM07`** (SE91): 8 message ở mục 5. *(đã tạo bằng MCP, package `ZPK_WM`)*

**E. Program** `ZWM_PG_LCVT` + 2 include *(user đã tạo và dán; MCP đã activate cả 3, ghi text elements, xem 0.3)*. Nếu cần dán lại từ local: **`CLASS lcl_handler DEFINITION` đã chuyển sang đầu `zwm_in_lcvt_f01.abap`**, dán đúng 3 file local hiện tại; activate bằng SE38 chọn cả 3 object cùng lúc (Ctrl+F3 → chọn tất cả).

**F. GUI status `STANDARD`** (SE41): Program `ZWM_PG_PCK`, Status `STANDARD` → Copy sang Program `ZWM_PG_LCVT`, Status `STANDARD`. Giữ đủ 5 nút `PREV`, `PRINT`, `SELALL`, `DETAIL`, `EXCEL` (code xử lý cả 5; khác ZWM05, **giữ** `DETAIL` và đổi text thành "Chi tiết WT"). Activate.

**G. T-code `ZWM07`** (SE93): Short text `Lệnh chuyển vị trí`; chọn *Program and selection screen (report transaction)*; Program `ZWM_PG_LCVT`, Screen number `1000`; GUI support tick SAPGUI for HTML, Java, Windows; Package `ZPK_BDP`.

**H. Smart Form `ZWM_SF_LCVT`** (làm sau khi xong C, vì form tham chiếu `ZWM_ST_LCVT`). File: `Smartforms/FS_v1.0/ZWM_SF_LCVT.xml`.
1. Copy file ra đường dẫn ngắn (VD `C:\temp\`).
2. SMARTFORMS → nhập **Form** = `ZWM_SF_LCVT` → menu **Utilities → Upload Form...** → chọn file.
3. Kiểm tra **Global Definitions → Form Interface**: Import `GS_PARAMETER` (Type `ZCORE_ST_PARAMETER`), Tables `IT_DATA` (Like `ZWM_ST_LCVT`); Global Data `GS_DATA` (Type `ZWM_ST_LCVT`).
4. **Activate**. Package `ZPK_BDP`, TR/task của bước I.
5. Logo `ZLOGO_0001` và style `ZCORE_STYLE_REPORT` đã có từ ZWM03/04/05.
6. Xong báo Claude: kiểm `TADIR` (`SSFO`) bằng MCP; lỗi gặp khi in thử thì chụp màn hình preview. Tiếng Việt in ra `#` thì kiểm SPAD: Device type `SWINCF`, Access method `G`, Host printer `__DEFAULT` (theo ghi chú skill `smartforms-xml`).

**I. Transport Request**: đặt tên theo `NOTE/note.md`, VD `DanhDH_WM_ZWM07_14.10.2026_Lệnh chuyển vị trí`; tạo mới (TR cha của ZWM05 là `DEVK900566`).

**J. Phân quyền role**: `S_TCODE` = `ZWM07`; `/SCWM/LG` (`/SCWM/LGNU` = Warehouse, `/SCWM/LGTY` = Storage Type, `ACTVT` = 03); `S_SPO_DEV`; `S_TABU_NAM` cho `ZTWM_WT_OPT` (02 chỉ Key user/IT).

## 7. Bắt đầu phiên mới

1. Đọc `CodeABAP/BDP/NOTE/note.md` rồi file này (mục 0).
2. Hỏi user tư vấn đã phản hồi về `ZTWM_WT_OPT` chưa (mục 0, "ĐANG CHỜ TƯ VẤN PHẢN HỒI"); có thì cập nhật bảng / code / ghi chú theo đó trước. Hỏi tiếp đã tạo object ở mục 6 chưa, đã upload Smart Form chưa, đã có WT thật để thử chưa.
3. Sửa code: sửa local trước, rồi `EditSource` lên DEV khi user yêu cầu (kiểm `SyntaxCheck` chương trình thật `/sap/bc/adt/programs/programs/zwm_pg_lcvt`).
4. Comment tiếng Việt ngắn, không marker tên/ngày, không comment lại code cũ (theo `NOTE/note.md`).
5. Sửa Smart Form: sửa `Smartforms/gen_zwm_sf_lcvt.py` rồi chạy lại `PYTHONUTF8=1 python gen_zwm_sf_lcvt.py FS_v1.0` (máy không có Python thật, xem memory `no-python-smartforms-generator`), kiểm `sf_validate.py FS_v1.0/ZWM_SF_LCVT.xml ../../ZWM05/Smartforms/FS_v1.0/ZWM_SF_PCK.xml` (mẫu là form ZWM05 đã upload được), rồi nhờ user upload lại.
