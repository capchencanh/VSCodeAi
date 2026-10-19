# ZWM2D (trước đây ZLX02) – Hướng dẫn tạo trên hệ thống

Chương trình mới, bám FS `BIDIPHAR_FS_EWM_ZWM2D_TonKhoTaiBin_SoDoKho2D_v1.0 1.docx` (bản đầu: `..._ZLX02_...v1.0.docx`). Source cũ (WM) không dùng lại.
Nền tảng: S/4HANA On-Premise/Private Cloud (DEV 200, release 816, HANA). Dữ liệu đọc từ CDS EWM chuẩn, không đọc bảng `/SCWM/*` trực tiếp.

Tên chương trình đặt theo quy ước dự án (`ZWM_PG_<viết tắt>`, include `ZWM_IN_<viết tắt>_*`), khác tên đề xuất `ZWM_R_ZLX02` / `ZWM_R_ZWM2D` trong FS. Muốn đổi tên thì thay `TKBIN` trong 7 file chương trình.

> **Các mục 1–15 bên dưới viết lúc còn tên ZLX02 và đã làm xong trên DEV.** Tên cũ trong các mục đó (`ZLX02`, `ZTWM_LX02_PARAM`) tương ứng tên mới `ZWM2D`, `ZTWM_2D_PARAM`. Phần việc **phát sinh khi đổi sang ZWM2D** nằm ở mục 0 ngay dưới đây.

## 0. Việc phải làm khi chuyển sang ZWM2D (08/10/2026) — làm trước khi dán code mới

Code mới dùng `MESSAGE-ID ZWM2D` và đọc bảng `ZTWM_2D_PARAM`; thiếu 2 object này thì không activate được.

| # | Việc | Cách làm |
|---|---|---|
| 1 | Bảng **`ZTWM_2D_PARAM`** | SE11 → mở `ZTWM_LX02_PARAM` → nút **Copy** → tên mới `ZTWM_2D_PARAM` (giữ nguyên field). Sửa Short Description thành `ZWM2D: Storage Type trung gian loại trừ khỏi báo cáo`; kiểm Delivery Class `C`, Technical Settings (tick **Log data changes**) → Activate. Hoặc tạo mới theo mục 4.2 với tên mới |
| 2 | View SM30 cho bảng mới | SE11 → `ZTWM_2D_PARAM` → Utilities → Table Maintenance Generator: Authorization Group `&NC&`, Function Group `ZFG_WM_LX02` (dùng lại), Package `ZPK_BDP`, Maintenance Type `One step`, Overview Screen **`0003`** (`0001`, `0002` đã dùng) → Create |
| 3 | Dữ liệu `ZTWM_2D_PARAM` | SM30 → `ZTWM_2D_PARAM` → New Entries: Warehouse `WTK1`, Storage Type `9010`, `9020`, `8040`, `WC99`. Bảng cũ `ZTWM_LX02_PARAM` không còn được dùng. `ZTWM_BIN_LAYOUT` giữ nguyên (chỉ cần dòng WTK1/TK10 khi Bin của TK10 **không** có sẵn Aisle/Stack/Level/Bin Section/Depth) |
| 4 | Message class **`ZWM2D`** | SE91 → tạo mới theo mục 7 nhưng tên `ZWM2D`, Short Description `ZWM2D - Thông báo báo cáo tồn kho tại Bin`; 10 message nội dung y mục 7 (bản FS ZWM2D dùng đúng 10 text này; 005 vượt 73 ký tự thì dùng bản rút gọn *Sơ đồ kho cần 1 Storage Type có cấu hình trong ZTWM_BIN_LAYOUT.*). Song ngữ làm sau theo ý tư vấn |
| 5 | T-code **`ZWM2D`** | **Đã tồn tại** và đang trỏ `ZWM_QUANLYKHO` (chương trình khác). SE93 → `ZWM2D` → Change → Program `ZWM_PG_TKBIN`, Screen number `1000`, tick *SAP GUI for Windows*. Hỏi lại người đã tạo `ZWM_QUANLYKHO` trước khi đổi; nếu giữ nguyên thì phải dùng tên T-code khác |
| 6 | TITLE và tên chương trình | SE41 → chương trình `ZWM_PG_TKBIN` → Titlebar `TITLE` → text `ZWM2D – Sơ đồ kho, quản lý, tìm kiếm`. SE38 → Attributes → Title `ZWM2D - Tồn kho tại Bin và sơ đồ kho 2D`; title các include đổi `ZLX02` thành `ZWM2D` (không bắt buộc) |
| 7 | Phân quyền | `S_TCODE` = `ZWM2D`; `S_TABU_NAM` thêm `ZTWM_2D_PARAM` (02 chỉ Key user/IT) |
| 8 | Dán code | Thứ tự: `zwm_in_tkbin_top` → `zwm_in_tkbin_f01` → `zwm_in_tkbin_f02` → `zwm_pg_tkbin` (chương trình chính, đổi `MESSAGE-ID`). `zcl_wm_uom_convert` chỉ đổi 1 dòng comment, không cần dán lại. Activate cả nhóm → `SyntaxCheck` → ATC |
| 9 | Dọn (sau khi test xong, user quyết định) | T-code `ZLX02`, bảng `ZTWM_LX02_PARAM` + view SM30 `0002`, message class `ZLX02` không còn dùng |

Chi tiết cách code xử lý từng phần của FS mới: `ghi_chu.md` mục 8.1.

## Trạng thái kiểm tra

- Đã `SyntaxCheck` trên DEV 200: **0 lỗi** (kiểm bản gộp các include, thay tạm 2 bảng Z và class chưa tạo bằng bản giả lập cục bộ, nên các câu `SELECT` vào `ZTWM_*` chưa được kiểm).
- **Chưa chạy thử được**: DEV 200 chỉ có Warehouse `0001`, không có Storage Bin và không có tồn EWM; chưa có W498/WTK1/WNH1. Cần test ở hệ có dữ liệu (mục 14).
- Chưa chạy ATC.

---

## 1. Danh sách object và thứ tự tạo

Tạo theo đúng thứ tự (object sau dùng object trước; chương trình chỉ activate được khi mọi thứ phía trên đã có).

| # | Object | Tên | Transaction | Mục |
|---|---|---|---|---|
| 1 | Data element (14 cái) | `ZDE_WM_*` | SE11 | 3 |
| 2 | Bảng cấu hình | `ZTWM_BIN_LAYOUT` | SE11 | 4.1 |
| 3 | Bảng cấu hình | `ZTWM_LX02_PARAM` | SE11 | 4.2 |
| 4 | View bảo trì (table maintenance) cho 2 bảng | function group `ZFG_WM_LX02` | SE11 → Utilities | 5 |
| 5 | Dữ liệu cấu hình ban đầu | | SM30 | 6 |
| 6 | Message class | `ZLX02` | SE91 | 7 |
| 7 | Class dùng chung | `ZCL_WM_UOM_CONVERT` | SE24 | 8 |
| 8 | Chương trình + 6 include | `ZWM_PG_TKBIN`, `ZWM_IN_TKBIN_*` | SE38 | 9 |
| 9 | Screen | `0100` của `ZWM_PG_TKBIN` | SE51 | 10 |
| 10 | PF-STATUS + TITLEBAR | `STANDARD`, `TITLE` | SE41 | 11 |
| 11 | Activate toàn bộ + syntax check | | SE80 | 12 |
| 12 | T-code | `ZLX02` | SE93 | 13 |

Package cho tất cả: `ZPK_BDP`.

**Transport request** (đặt tên theo `NOTE/note.md`: `<Tên>_<Module>_<TCode>_<DD.MM.YYYY>_<Mô tả không dấu>`, không có chữ "move", "copy" hay tên dự án khác):
- 1 request **Workbench** cho object 1–4, 6–12. Ví dụ description: `DanhDH_WM_ZLX02_07.10.2026_Ton kho tai Bin va so do kho 2D` (58 ký tự, SAP cho tối đa 60).
- 1 request **Customizing** cho dữ liệu ở mục 5–6 (SM30 sẽ tự hỏi). Ví dụ: `DanhDH_WM_ZLX02_07.10.2026_Cau hinh ma Bin`.

**Ngôn ngữ text**: data element và bảng chỉ cần text tiếng Việt (FS không yêu cầu song ngữ cho DDIC). Chỉ message class `ZLX02` phải song ngữ Việt – Anh theo FS (mục 7).

---

## 2. Chuẩn bị

- Đăng nhập DEV 200 (client 200).
- Biết sẵn số 2 transport request ở trên (SE09 → Create, hoặc để SE11 tự hỏi khi Save).

---

## 3. Data element (`ZDE_WM_*`)

Hai bảng cấu hình ở mục 4 mỗi field có data element riêng, vì **log bảng (SCU3) và SM30 lấy nhãn field từ data element**. Dùng chung 1 data element cho nhiều field thì log hiện cùng 1 nhãn cho các field khác nhau (user không biết field nào đổi). Vì vậy 1 field = 1 data element.

Hai field khóa `LGNUM`, `LGTYP` dùng data element chuẩn của SAP (`/SCWM/LGNUM` "Warehouse Number", `/SCWM/LGTYP` "Storage Type") nên đã có sẵn text và F4, **không tạo mới**.

### 3.1 Cách tạo 1 data element

SE11 → chọn radio **Data type** → gõ tên `ZDE_WM_xxx` → **Create** → chọn **Data element** → Enter.

1. Ô **Short Description** (trên cùng): lấy ở cột *Short text* của bảng 3.2.
2. Tab **Data Type**: chọn radio **Predefined Type**, rồi điền:
   - **Data Type**: theo cột *Kiểu* (`NUMC` hoặc `CHAR`)
   - **No. Characters** (Length): theo cột *Kiểu* (2 hoặc 1)
   - *(Decimal Places để trống)*

   Riêng `ZDE_WM_LEVEL_DESC`: chọn radio **Elementary Type** → **Domain** → gõ `XFELD` (domain chuẩn dạng checkbox, để SM30 hiện ô tick).
3. Tab **Field Label**: điền 4 dòng *Short / Medium / Long / Heading* theo bảng 3.2, mỗi dòng gồm **Length** và **Text**:
   - Length: `10` / `20` / `40` / `55` (đúng tối đa của từng dòng; SAP tự điền khi nhập text, không cần sửa).
   - Text: copy từ bảng. **Bắt buộc điền đủ 4 dòng**, bỏ trống thì activate ra warning và field không có nhãn.
4. Tab **Further Characteristics**: để mặc định (không search help, không parameter ID, không tick Change document).
5. **Save** → package `ZPK_BDP` → transport Workbench → **Activate** (Ctrl+F3).

Đăng nhập bằng **tiếng Việt** (VI) khi tạo để ngôn ngữ gốc của object là VI.

### 3.2 Danh sách cần tạo

Độ dài đã kiểm: Short ≤ 10, Medium ≤ 20, Long ≤ 40, Heading ≤ 55, Short text ≤ 60. Dòng Heading dùng cùng chữ với Long.

| Data element | Field dùng | Kiểu | Short text | Short (10) | Medium (20) | Long (40) | Heading (55) |
|---|---|---|---|---|---|---|---|
| `ZDE_WM_AISLE_OFF` | AISLE_OFF | NUMC 2 | Mã Bin: vị trí bắt đầu của Dãy | Dãy: đầu | Dãy: bắt đầu | Dãy - vị trí bắt đầu trong mã Bin | Dãy - vị trí bắt đầu trong mã Bin |
| `ZDE_WM_AISLE_LEN` | AISLE_LEN | NUMC 2 | Mã Bin: độ dài của Dãy | Dãy: dài | Dãy: độ dài | Dãy - độ dài trong mã Bin | Dãy - độ dài trong mã Bin |
| `ZDE_WM_STACK_OFF` | STACK_OFF | NUMC 2 | Mã Bin: vị trí bắt đầu của Kệ | Kệ: đầu | Kệ: bắt đầu | Kệ - vị trí bắt đầu trong mã Bin | Kệ - vị trí bắt đầu trong mã Bin |
| `ZDE_WM_STACK_LEN` | STACK_LEN | NUMC 2 | Mã Bin: độ dài của Kệ | Kệ: dài | Kệ: độ dài | Kệ - độ dài trong mã Bin | Kệ - độ dài trong mã Bin |
| `ZDE_WM_LEVEL_OFF` | LEVEL_OFF | NUMC 2 | Mã Bin: vị trí bắt đầu của Tầng | Tầng: đầu | Tầng: bắt đầu | Tầng - vị trí bắt đầu trong mã Bin | Tầng - vị trí bắt đầu trong mã Bin |
| `ZDE_WM_LEVEL_LEN` | LEVEL_LEN | NUMC 2 | Mã Bin: độ dài của Tầng | Tầng: dài | Tầng: độ dài | Tầng - độ dài trong mã Bin | Tầng - độ dài trong mã Bin |
| `ZDE_WM_CELL_OFF` | CELL_OFF | NUMC 2 | Mã Bin: vị trí bắt đầu của Ô | Ô: đầu | Ô: bắt đầu | Ô - vị trí bắt đầu trong mã Bin | Ô - vị trí bắt đầu trong mã Bin |
| `ZDE_WM_CELL_LEN` | CELL_LEN | NUMC 2 | Mã Bin: độ dài của Ô | Ô: dài | Ô: độ dài | Ô - độ dài trong mã Bin | Ô - độ dài trong mã Bin |
| `ZDE_WM_SLOT_OFF` | SLOT_OFF | NUMC 2 | Mã Bin: vị trí bắt đầu của phần Vị trí | V.trí: đầu | Vị trí: bắt đầu | Phần Vị trí - bắt đầu trong mã Bin | Phần Vị trí - bắt đầu trong mã Bin |
| `ZDE_WM_SLOT_LEN` | SLOT_LEN | NUMC 2 | Mã Bin: độ dài của phần Vị trí | V.trí: dài | Vị trí: độ dài | Phần Vị trí - độ dài trong mã Bin | Phần Vị trí - độ dài trong mã Bin |
| `ZDE_WM_SEP_CHAR` | SEP_CHAR | CHAR 1 | Mã Bin: ký tự phân cách | KT p.cách | Ký tự phân cách | Ký tự phân cách trong mã Bin | Ký tự phân cách trong mã Bin |
| `ZDE_WM_SEP_OFF` | SEP_OFF | NUMC 2 | Mã Bin: vị trí của ký tự phân cách | VT p.cách | Vị trí ký tự p.cách | Vị trí ký tự phân cách trong mã Bin | Vị trí ký tự phân cách trong mã Bin |
| `ZDE_WM_LEVEL_DESC` | LEVEL_DESC | Domain `XFELD` | Sơ đồ kho: tầng cao xếp trên | Tầng cao | Tầng cao xếp trên | Hiển thị tầng cao xếp trên (X = có) | Hiển thị tầng cao xếp trên (X = có) |
| `ZDE_WM_SLOTS_CELL` | SLOTS_PER_CELL | NUMC 2 | Sơ đồ kho: số vị trí trong 1 Ô | SL vị trí | Số vị trí / Ô | Số vị trí trong 1 Ô | Số vị trí trong 1 Ô |

---

## 4. Hai bảng cấu hình

### 4.1 `ZTWM_BIN_LAYOUT` – cách tách mã Bin theo Storage Type

SE11 → radio **Database table** → gõ `ZTWM_BIN_LAYOUT` → **Create**.

**Tab Delivery and Maintenance**

| Ô | Giá trị |
|---|---|
| Short Description | `ZLX02: cấu hình tách mã Bin theo Storage Type` |
| Delivery Class | **`A`** (Application table). *Cập nhật 13/10/2026: bản đầu ghi `C`, nhưng bảng `C` bị khóa sửa ở client 200 và dữ liệu phải nhập ở client 100; đang dùng `A` để sửa trực tiếp ở 200 (hệ quả: dữ liệu không đi theo transport). Xem `ghi_chu.md` mục 6.* |
| Data Browser/Table View Maint. | `Display/Maintenance Allowed` (mặc định *with Restrictions* làm SM30 báo SV792) |

**Tab Fields** (gõ đúng thứ tự dưới đây; cột *Key* tick = field khóa; **không** tick *Initial Values* cho field không khóa):

| # | Field | Key | Data element | Mô tả (ghi chú cho người tạo, không nhập) |
|---|---|---|---|---|
| 1 | `MANDT` | X | `MANDT` | Client |
| 2 | `LGNUM` | X | `/SCWM/LGNUM` | Warehouse |
| 3 | `LGTYP` | X | `/SCWM/LGTYP` | Storage Type |
| 4 | `AISLE_OFF` | | `ZDE_WM_AISLE_OFF` | Dãy: vị trí bắt đầu |
| 5 | `AISLE_LEN` | | `ZDE_WM_AISLE_LEN` | Dãy: độ dài |
| 6 | `STACK_OFF` | | `ZDE_WM_STACK_OFF` | Kệ: vị trí bắt đầu |
| 7 | `STACK_LEN` | | `ZDE_WM_STACK_LEN` | Kệ: độ dài |
| 8 | `LEVEL_OFF` | | `ZDE_WM_LEVEL_OFF` | Tầng: vị trí bắt đầu (phải là số) |
| 9 | `LEVEL_LEN` | | `ZDE_WM_LEVEL_LEN` | Tầng: độ dài |
| 10 | `CELL_OFF` | | `ZDE_WM_CELL_OFF` | Ô: vị trí bắt đầu (phải là số) |
| 11 | `CELL_LEN` | | `ZDE_WM_CELL_LEN` | Ô: độ dài |
| 12 | `SLOT_OFF` | | `ZDE_WM_SLOT_OFF` | Vị trí: vị trí bắt đầu (phải là số) |
| 13 | `SLOT_LEN` | | `ZDE_WM_SLOT_LEN` | Vị trí: độ dài |
| 14 | `SEP_CHAR` | | `ZDE_WM_SEP_CHAR` | Ký tự phân cách, để trống nếu mã Bin không có |
| 15 | `SEP_OFF` | | `ZDE_WM_SEP_OFF` | Vị trí của ký tự phân cách |
| 16 | `LEVEL_DESC` | | `ZDE_WM_LEVEL_DESC` | X = tầng cao xếp trên |
| 17 | `SLOTS_PER_CELL` | | `ZDE_WM_SLOTS_CELL` | Số vị trí trong 1 Ô |

Tên field giữ đúng như cột *Field* vì code đọc theo tên này (`ZWM_IN_TKBIN_F01` form `PARSE_ONE_BIN`; `ZWM_IN_TKBIN_F02` form `BUILD_HTML`). Mọi vị trí tính từ 1.

**Foreign key** (để có F4 và kiểm tra giá trị nhập):
1. Chọn field `LGNUM` → nhấn biểu tượng **Foreign Keys** (hình chìa khóa) → **Check table** = `/SCWM/T300` → **Generate proposal** → Enter → Save (chấp nhận đề xuất).
2. Chọn field `LGTYP` → **Foreign Keys** → **Check table** = `/SCWM/T301` → **Generate proposal** (tự gán `LGNUM`, `LGTYP`) → Enter.

**Technical Settings** (nút trên thanh công cụ hoặc Goto → Technical Settings), điền:

| Ô | Giá trị |
|---|---|
| Data Class | `APPL2` (Organization and customizing) |
| Size Category | `0` |
| Buffering | `Buffering not allowed` |
| **Log data changes** | **Tick** (bắt buộc: FS yêu cầu có table logging) |

Bảng nhỏ và chỉ đọc một lần mỗi lần chạy báo cáo nên không cần buffer. Log chỉ ghi được khi Basis đã bật profile parameter `rec/client` (giá trị `ALL` hoặc có client 200); nhờ Basis kiểm tra, không có thì tick cũng không ghi log.

**Enhancement Category**: menu **Extras → Enhancement Category** → chọn `Can Be Enhanced (Character-Type or Numeric)` → Copy.

Save → package `ZPK_BDP` → transport Workbench → **Activate**.

Xem log sau này: SCU3 → nhập bảng `ZTWM_BIN_LAYOUT` → tab *Table history*; cột nhãn field hiện đúng nhãn data element ở mục 3.

### 4.2 `ZTWM_LX02_PARAM` – Storage Type trung gian cần loại trừ

SE11 → radio **Database table** → gõ `ZTWM_LX02_PARAM` → **Create**.

| Ô | Giá trị |
|---|---|
| Short Description | `ZLX02: Storage Type trung gian loại trừ khỏi báo cáo` |
| Delivery Class | `C` |
| Data Browser/Table View Maint. | `Display/Maintenance Allowed with Restrictions` |

**Tab Fields**:

| # | Field | Key | Data element |
|---|---|---|---|
| 1 | `MANDT` | X | `MANDT` |
| 2 | `LGNUM` | X | `/SCWM/LGNUM` |
| 3 | `LGTYP` | X | `/SCWM/LGTYP` |

Bảng chỉ có 3 field khóa nên không cần data element tự tạo. Mỗi dòng nghĩa là: Storage Type `LGTYP` của Warehouse `LGNUM` bị loại khỏi báo cáo khi tick "Loại trừ ST trung gian".

Foreign key và Technical Settings làm **giống hệt** mục 4.1 (LGNUM → `/SCWM/T300`; LGTYP → `/SCWM/T301`; Data Class `APPL2`, Size `0`, Buffering not allowed, tick **Log data changes**; Enhancement Category như trên). Save → Activate.

---

## 5. View bảo trì cho 2 bảng (SM30)

Làm lần lượt cho từng bảng. SE11 → mở bảng → menu **Utilities → Table Maintenance Generator**:

| Ô | Bảng `ZTWM_BIN_LAYOUT` | Bảng `ZTWM_LX02_PARAM` |
|---|---|---|
| Authorization Group | `&NC&` (không nhóm quyền) | `&NC&` |
| Function Group | `ZFG_WM_LX02` | `ZFG_WM_LX02` (đã có từ bảng trước) |
| Function group short text (khi tạo mới) | `ZLX02 - Bảo trì bảng cấu hình` | |
| Package | `ZPK_BDP` | `ZPK_BDP` |
| Maintenance Type | `One step` | `One step` |
| Maint. Screen No. – Overview Screen | `0001` | `0002` |
| Recording routine | `Standard recording routine` | `Standard recording routine` |

Bấm **Create** (biểu tượng cây bút) → chọn transport Workbench → Enter. Lần thứ hai nếu SAP báo function group đã tồn tại thì chọn tiếp tục dùng nhóm này.

Phân quyền bảo trì: FS yêu cầu chỉ Key user/IT (`S_TABU_NAM` cho 2 bảng). SM30 kiểm theo `S_TABU_DIS` (nhóm quyền); nếu cần siết riêng, nhờ Basis gán nhóm quyền cho bảng trong view `V_TDDAT` rồi phân quyền `S_TABU_DIS` tương ứng.

---

## 6. Nhập dữ liệu cấu hình ban đầu (SM30)

SM30 → Table/View `ZTWM_BIN_LAYOUT` → **Maintain** → **New Entries** → nhập → Save. *(Cập nhật 13/10/2026: bảng đang Delivery Class `A` nên SM30 không hỏi transport Customizing và dữ liệu không đi theo transport; nhập lại ở từng hệ thống. Nếu bảng là `C` thì nhập ở client 100 và chọn transport Customizing.)*

FS đã xác nhận cấu trúc mã Bin của WTK1 / TK10 (ví dụ `02B102-03` = Dãy `02`, Kệ `B`, Tầng `1`, Ô `02`, ký tự phân cách `-`, Vị trí `03`):

| Field | Giá trị | Ý nghĩa |
|---|---|---|
| `LGNUM` | `WTK1` | |
| `LGTYP` | `TK10` | |
| `AISLE_OFF` / `AISLE_LEN` | `01` / `02` | Dãy = ký tự 1–2 |
| `STACK_OFF` / `STACK_LEN` | `03` / `01` | Kệ = ký tự 3 |
| `LEVEL_OFF` / `LEVEL_LEN` | `04` / `01` | Tầng = ký tự 4 |
| `CELL_OFF` / `CELL_LEN` | `05` / `02` | Ô = ký tự 5–6 |
| `SEP_CHAR` / `SEP_OFF` | `-` / `07` | Phân cách `-` tại ký tự 7 |
| `SLOT_OFF` / `SLOT_LEN` | `08` / `02` | Vị trí = ký tự 8–9 |
| `LEVEL_DESC` | tick | Tầng cao xếp trên |
| `SLOTS_PER_CELL` | `02` | Ô n chứa vị trí 2n-1 và 2n |

TK20, TKFB và Storage Type của W498, WNH1: FS chưa nêu quy ước mã Bin, cần bổ sung sau (thêm dòng mới theo cùng cách).

SM30 → `ZTWM_LX02_PARAM` → New Entries: Warehouse `WTK1`, Storage Type `9010`, `9020`, `8040`, `WC99` (4 dòng).

Kiểm tra: SE16N → bảng `ZTWM_BIN_LAYOUT` phải có 1 dòng, `ZTWM_LX02_PARAM` 4 dòng.

---

## 7. Message class `ZLX02` (SE91)

SE91 → Message class `ZLX02` → **Create**.

| Ô | Giá trị |
|---|---|
| Short Description (VI) | `ZLX02 - Thông báo báo cáo tồn kho tại Bin` |
| Short Description (EN) | `ZLX02 - Messages for bin stock report` |
| Package | `ZPK_BDP` |

Tab **Messages**: nhập từng dòng (cột *Message*, cột *Message short text*). Không tick *Self-explanatory*. Mỗi text tối đa 73 ký tự.

| No | Tiếng Việt | Tiếng Anh |
|---|---|---|
| 001 | Bạn không có quyền trên Warehouse &1. | You are not authorized for warehouse &1. |
| 002 | Vui lòng nhập thêm Storage Type, Storage Bin, Vật tư, Lô hoặc HU. | Enter at least one of storage type, bin, product, batch or HU. |
| 003 | Không có dữ liệu thỏa điều kiện. | No data found for the selection. |
| 004 | &1 Bin của Storage Type &2 chưa xác định được vị trí trên sơ đồ. | &1 bin(s) of storage type &2 could not be placed on the map. |
| 005 | Chức năng Sơ đồ kho cần chọn một Storage Type có cấu hình trong ZTWM_BIN_LAYOUT. | The warehouse map needs one storage type configured in ZTWM_BIN_LAYOUT. |
| 006 | &1 vật tư chưa khai báo ĐVT quy đổi &2 – cột SL quy đổi để trống. | &1 product(s) have no unit &2 - converted quantity left blank. |
| 007 | Không tìm thấy vị trí thỏa điều kiện tìm. | No position matches the search criteria. |
| 008 | Vị trí &1 đang trống (&2). | Position &1 is empty (&2). |
| 009 | Vui lòng nhập ĐVT quy đổi khi chọn "Xem tồn kho theo ĐVT quy đổi". | Enter the conversion unit when conversion is selected. |
| 010 | ĐVT quy đổi &1 không có trong danh mục đơn vị đo. | Unit &1 does not exist in the unit of measure list. |

Thêm bản tiếng Anh: **Goto → Translation** (hoặc đăng nhập EN và nhập lại cột text). Save → Activate.

Nếu text 005 hay 009 báo quá 73 ký tự thì rút gọn bớt chữ (nội dung số/ý nghĩa giữ nguyên).

Code dùng `MESSAGE S/E/…` với số 001–010 đúng như bảng. 004/006/007/008 hiển thị dạng status bar (type S + `DISPLAY LIKE`), không bật popup.

---

## 8. Class `ZCL_WM_UOM_CONVERT` (SE24)

Class dùng chung cho ZLX02, ZWM11, ZMM60 (FS yêu cầu): sửa class này phải kiểm thử hồi quy cả ba báo cáo.

SE24 → Object type `ZCL_WM_UOM_CONVERT` → **Create**:

| Ô | Giá trị |
|---|---|
| Description | `Quy đổi số lượng sang ĐVT khai báo trên vật tư` |
| Instantiation | `Public` |
| Final | tick |
| Package | `ZPK_BDP` |

Sau khi Save, chuyển sang **chế độ source code**: menu **Utilities → Settings → tab Class Builder → chọn Source Code-Based Class Editor** → mở lại class → xóa nội dung mặc định, dán toàn bộ file [zcl_wm_uom_convert.abap](zcl_wm_uom_convert.abap) → Save → Activate.

(Làm bằng Eclipse ADT thì: New → ABAP Class → tên `ZCL_WM_UOM_CONVERT`, package `ZPK_BDP`, dán nội dung file.)

---

## 9. Chương trình `ZWM_PG_TKBIN` và 6 include (SE38)

### 9.1 Chương trình chính

SE38 → Program `ZWM_PG_TKBIN` → **Create**. Hộp thoại Attributes:

| Ô | Giá trị |
|---|---|
| Title | `ZLX02 - Tồn kho tại Bin và sơ đồ kho 2D` |
| Type | `1` Executable program |
| Status | `K` Customer production program |
| Application | để mặc định |
| Authorization Group | để trống |
| Logical database | để trống |
| **Fixed point arithmetic** | **Tick (bắt buộc**; không tick thì mọi câu SQL báo lỗi) |
| Unicode checks active | tick (mặc định) |

Save → package `ZPK_BDP` → transport Workbench. Dán nội dung [zwm_pg_tkbin.abap](zwm_pg_tkbin.abap) → **Save** (chưa Activate).

### 9.2 Include

Mỗi include: **double-click tên include** ngay trong câu `INCLUDE ...` của chương trình chính → hỏi tạo mới → Yes → hộp thoại Attributes:

| Include | Title | Type | Status | File nội dung |
|---|---|---|---|---|
| `ZWM_IN_TKBIN_TOP` | `ZLX02 - Khai báo dữ liệu và màn hình chọn` | `I` Include program | `K` | [zwm_in_tkbin_top.abap](zwm_in_tkbin_top.abap) |
| `ZWM_IN_TKBIN_CLS` | `ZLX02 - Class cục bộ` | `I` | `K` | [zwm_in_tkbin_cls.abap](zwm_in_tkbin_cls.abap) |
| `ZWM_IN_TKBIN_PBO` | `ZLX02 - Module PBO màn hình 0100` | `I` | `K` | [zwm_in_tkbin_pbo.abap](zwm_in_tkbin_pbo.abap) |
| `ZWM_IN_TKBIN_PAI` | `ZLX02 - Module PAI màn hình 0100` | `I` | `K` | [zwm_in_tkbin_pai.abap](zwm_in_tkbin_pai.abap) |
| `ZWM_IN_TKBIN_F01` | `ZLX02 - Đọc và xử lý dữ liệu` | `I` | `K` | [zwm_in_tkbin_f01.abap](zwm_in_tkbin_f01.abap) |
| `ZWM_IN_TKBIN_F02` | `ZLX02 - Hiển thị ALV và sơ đồ HTML` | `I` | `K` | [zwm_in_tkbin_f02.abap](zwm_in_tkbin_f02.abap) |

Dán nội dung từng file → **Save**, **chưa Activate**. Include lấy thuộc tính Fixed point arithmetic từ chương trình chính nên không cần tick riêng.

Không cần nhập Text Elements / Selection Texts: tên cột ALV, tiêu đề và nhãn màn hình chọn đã viết trong code (`%_<tên>_%_APP_%-TEXT`).

---

## 10. Screen 0100 (SE51)

SE51 → Program `ZWM_PG_TKBIN`, Screen number `0100` → **Create**.

**Tab Attributes**

| Ô | Giá trị |
|---|---|
| Short description | `Sơ đồ kho 2D` |
| Screen type | `Normal` |
| Next screen | `0` |

**Layout** (nhấn Layout, trình thiết kế đồ họa):
1. **Subscreen area**: kéo từ thanh công cụ bên trái, đặt phía trên, rộng khoảng 83 cột, cao 4 dòng. Nhấp đôi vào vùng vừa vẽ → ô **Name** = `SUB_SEARCH`.
2. **Custom control**: đặt ngay dưới subscreen, kéo chiếm hết phần còn lại của màn hình. Nhấp đôi → ô **Name** = `CC_MAIN`; trong thuộc tính element tick **Resizing Vertical** và **Horizontal** để sơ đồ co giãn theo cửa sổ.

Tên `SUB_SEARCH`, `CC_MAIN` phải đúng chữ vì code gọi theo tên này.

**Tab Flow logic** (thay nội dung mặc định):

```
PROCESS BEFORE OUTPUT.
  MODULE STATUS_0100.
  CALL SUBSCREEN SUB_SEARCH INCLUDING SY-REPID '0110'.
  MODULE INIT_CONTROLS_0100.

PROCESS AFTER INPUT.
  MODULE EXIT_COMMAND_0100 AT EXIT-COMMAND.
  CALL SUBSCREEN SUB_SEARCH.
  MODULE USER_COMMAND_0100.
```

Subscreen `0110` do chính chương trình sinh ra từ `SELECTION-SCREEN ... AS SUBSCREEN`, không cần vẽ. Save → **Activate** (activate screen xong mới activate chương trình ở mục 12).

---

## 11. PF-STATUS và TITLEBAR (SE41)

**Cách nhanh** (cùng cách đã làm cho ZRSD26): SE41 → menu **Status → Copy**: From program `ZPG_SD_THCPVC`, status `STANDARD` → To program `ZWM_PG_TKBIN`, status `STANDARD`. Tương tự **Title → Copy** (From `ZPG_SD_THCPVC` title `TITLE` → To `ZWM_PG_TKBIN` title `TITLE`). Sau đó sửa text của title thành `ZLX02 - Sơ đồ kho 2D`.

**Cách tự tạo**:
1. SE41 → Program `ZWM_PG_TKBIN`, Status `STANDARD` → **Create** → Short text `Sơ đồ kho 2D`, Status type `Normal screen`.
2. Mục **Function Keys → Standard toolbar** điền vào 3 ô: `BACK` (biểu tượng mũi tên xanh Back, F3), `EXIT` (Exit, Shift+F3), `CANC` (Cancel, F12). Ba mã này tự thành Function type `E` (Exit command): kiểm tra bằng menu Goto → Attributes → Function attributes.
3. Title: SE41 → Title `TITLE` → Create → text `ZLX02 - Sơ đồ kho 2D`.

Code xử lý các mã `BACK`, `EXIT`, `CANC`, `&F03`, `&BACK`, `&F12`, `&F15` nên status copy từ ZRSD26 dùng được ngay. Các nút Tìm / Làm mới / Chuyển Storage Type / Danh sách tồn kho nằm trong subscreen, **không cần** thêm vào status. Activate status và title.

---

## 12. Activate toàn bộ và kiểm tra cú pháp

1. SE80 → Program `ZWM_PG_TKBIN` → chuột phải → **Activate** (hoặc Ctrl+F3 từ SE38). Hộp thoại liệt kê các object chưa activate (chương trình, 6 include, screen 0100, status, title): chọn tất cả → OK.
2. SE38 → `ZWM_PG_TKBIN` → **Check** (Ctrl+F2) và **Extended check** (SLIN). Cần 0 lỗi; warning "buffered table" hoặc "replacement object" thì báo lại cho tôi.
3. Gửi tôi báo cáo kết quả (hoặc nhắn "đã tạo xong"), tôi sẽ chạy lại `SyntaxCheck` trên object thật qua MCP, kiểm cả các câu `SELECT` vào 2 bảng Z mà lần trước chưa kiểm được.

---

## 13. T-code và phân quyền

**SE93** → Transaction code `ZLX02` → **Create**:

| Ô | Giá trị |
|---|---|
| Short text | `Tồn kho tại Bin và sơ đồ kho 2D` |
| Start object | `Program and selection screen (report transaction)` |
| Program | `ZWM_PG_TKBIN` |
| Selection screen | `1000` |
| GUI support | tick **SAP GUI for Windows** |
| Package | `ZPK_BDP` |

**Phân quyền** (nhờ Basis/Security gán vào role):
- `S_TCODE` = `ZLX02`.
- Object EWM theo Warehouse: `/SCWM/LG` với `/SCWM/LGNU` = Warehouse được xem, `/SCWM/LGTY` = `*` hoặc Storage Type tương ứng, `ACTVT` = `03`. Code kiểm tra trước khi chạy và báo `ZLX02-001`. Các CDS EWM chuẩn còn tự lọc dòng theo quyền của SAP.
- Xuất ALV theo `S_GUI` (`ACTVT` = `61`) như chuẩn.
- `S_TABU_NAM` / `S_TABU_DIS` cho 2 bảng cấu hình: theo mục 5.

---

## 14. Đối chiếu FS và điểm cần BA xác nhận

### Đã làm đúng theo FS
- Màn hình chọn (mục 2.3) trừ tham số Plant/SLoc; kiểm tra `ZLX02-002/005/009/010`.
- Danh sách tồn kho (3.4.1): ALV chuẩn, đèn trạng thái Bin (xanh/vàng/đỏ/xám), cột Dãy-Kệ-Tầng-Ô-Vị trí, Hạn dùng, Ngày KNL (MCHA-QNDAT), Ngày nhập, Ngày tồn, khóa nhập/xuất/kiểm kê, Kiểm kê gần nhất, Di chuyển gần nhất + số WT, 2 cột quy đổi gắn đơn vị.
- Quy đổi: `ZCL_WM_UOM_CONVERT` (dùng chung với ZWM11, ZMM60), gọi `MD_CONVERT_MATERIAL_UNIT`, vật tư không khai báo ĐVT thì để trống và báo `ZLX02-006`.
- Sơ đồ kho (3.4.2): màn hình chia vùng (1) thanh tìm, (2) sơ đồ, (3) chú thích + thống kê 7 dòng, (4) ALV tồn của ô chọn; tìm theo Bin/vật tư/mô tả/lô/E-B; Làm mới; Chuyển Storage Type; sang danh sách; popup Bin chưa xác định vị trí; màu ô ưu tiên chọn > tìm > khóa > có hàng > trống.
- Dữ liệu đọc một lần, tìm/nhấp ô xử lý trên bộ nhớ.

### Khác FS (đã quyết, cần BA/user biết)
1. **Sơ đồ 2D dựng bằng HTML viewer, không dùng ALV Grid tô màu.** Lý do: ALV Grid không có tooltip cho từng ô (`IT_EXCEPT_QINFO` chỉ gắn tooltip theo giá trị icon/exception, không theo ô) và không gộp được tiêu đề Ô; FS yêu cầu cả hai. FS cho phép HTML viewer khi ALV không đáp ứng. Hệ quả: cần SAP GUI for Windows có HTML control; không còn giới hạn 10 tầng/60 cột, sơ đồ lớn cuộn bình thường. Phần mô hình dữ liệu (`GT_CELL`) tách khỏi phần vẽ, đổi sang ALV Grid sau này chỉ sửa form `BUILD_HTML`/`SHOW_HTML`.
2. Nhấp ô tô xanh bằng JavaScript ngay tại trình duyệt (không dựng lại sơ đồ, giữ nguyên vị trí cuộn). Nếu HTML control tắt script thì ô không đổi màu, nhưng vùng (3) (4) vẫn cập nhật đúng.

### Chưa làm / thiếu thông tin
| # | Nội dung FS | Lý do | Cần |
|---|---|---|---|
| 1 | Tham số và cột **Plant / SLoc** | Chưa rõ quy tắc: Party entitled → Plant; Stock Type + availability group → SLoc qua `/SCWM/TMAPSTLOC` | BA/Technical chốt cách ánh xạ |
| 2 | Cột **Lý do khóa** | `/SCWM/LAGP` và `I_EWM_StorageBin_2` chỉ có 3 cờ khóa, không có field lý do | BA xác nhận có lấy từ nơi khác không |
| 3 | **Chờ putaway**, **SL đang pick** | Không có nguồn rõ ràng trong CDS tồn. Đã làm `Đang giữ (WT mở)` = Tổng tồn − Khả dụng (Khả dụng lấy từ `I_EWM_AvailableStock`, tức bảng `/SCWM/AQUA`) | BA xác nhận ý nghĩa |
| 4 | Cột **SL theo ĐVT kho (Logistics UoM)** (tuỳ chọn, ẩn) | Chưa tìm field | Technical |
| 5 | Nhấp dòng danh sách để xem chi tiết Bin / WT gần nhất (mục 2.4) | Chưa có T-code/API xác nhận; hiện chỉ hiển thị số WT gần nhất | Technical |
| 6 | Cột **Loại Bin, sức chứa còn lại** (tuỳ chọn) | Loại Bin có trong cấu trúc nhưng ẩn; chưa làm sức chứa | Nếu cần |

### Giả định đang dùng (xác nhận trước khi go-live)
- **E / B** trong thanh tìm: E so khớp `EWMStockUsage = 'E'` + số Sales Document với `ExternalStockDocumentNumber`; B so khớp `EWMStockUsage = 'B'` + số khách hàng với chủ sở hữu tồn (`EWMStockOwner`, giả định số BP = số khách hàng). Số nhập vào được dò dạng `*<số>`.
- Plant của lô lấy `MIN(MCHA-WERKS)` theo (vật tư, lô) để đọc đặc tính lô; Số lô NSX = `Z_BATCH_NSX` (trống thì `MCHA-LICHA`), NSX = `Z_NSX` đổi mã NCC sang tên bằng `ZCORE_FM_GET_PROFILE` giống ZWM01.
- Storage Type loại trừ (tuỳ chọn *Loại trừ ST trung gian*) áp dụng cho cả sơ đồ.
- Ngày/giờ đổi theo múi giờ của Warehouse (`I_EWM_WarehouseNumber_2-TimeZoneID`).
- Đọc tồn qua `I_EWM_PhysStockProd`: view chỉ trả dữ liệu khi migration `/SCWM/CL_SDM_HUHDR_GUID_HU_TOP` đã xong; trên DEV 200 trạng thái là `F` (xong). Cần kiểm tra lại trên QAS/PRD.

### Mâu thuẫn tài liệu cần hỏi lại
- Mục *Thuật ngữ* #6 của FS mô tả quy đổi dạng chuỗi nhiều đơn vị (`3 THÙNG 5 HỘP`, là cách của code cũ) nhưng mục 2.3 và 2.6.3 quy định 1 ĐVT, 2 cột số. **Code làm theo mục 2.3/2.6.3.**
- Ghi chú trong BP EWM: "hiển thị và **trích xuất** báo cáo/hình ảnh mô hình kho 2D". FS lại ghi "chỉ xem, không xuất Excel/PDF" (xác nhận 17/09/2026). **Code làm theo FS.**

---

## 15. Kịch bản test gợi ý (cần hệ có dữ liệu EWM)

1. Danh sách: chọn Warehouse + 1 Storage Type, kiểm số dòng so với `/SCWM/MON`; thử từng bộ lọc Vật tư / Lô / HU / Hạn dùng / Ngày nhập; tick *Hiển thị Bin trống*, *Chỉ Bin đang bị khóa*.
2. Quy đổi: chọn 1 ĐVT có ở vài vật tư, không có ở vật tư khác → cột để trống, hiện `ZLX02-006` với số vật tư đúng.
3. Sơ đồ: mở WTK1/TK10, kiểm các Bin mẫu (01A103-05, 01A209-18, 02B102-03, 02B414-28) nằm đúng khối/tầng/vị trí; Ô 07 của khối 01A trắng; Bin `TK10-TEMP` vào popup `ZLX02-004`.
4. Tìm theo vật tư, theo lô, theo mô tả (gần đúng); nhấp ô có hàng / ô trống / ô khóa; thống kê 7 dòng khớp số liệu; *Tổng tồn kho* chỉ hiện khi tìm đúng 1 vật tư.
5. Chuyển Storage Type, Làm mới, sang Danh sách rồi Back về sơ đồ.
6. Phân quyền: user thiếu `/SCWM/LG` báo `ZLX02-001`; user chỉ có quyền 1 Warehouse không thấy Warehouse khác.
7. Log bảng cấu hình: đổi 1 giá trị trong SM30 rồi mở SCU3, kiểm nhãn field hiển thị đúng (mục 3).
8. Hiệu năng Storage Type lớn (nhiều nghìn Bin): thời gian mở sơ đồ, kích thước HTML.
