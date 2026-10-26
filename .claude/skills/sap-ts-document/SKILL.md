---
name: sap-ts-document
description: "Viết/review tài liệu TS (Technical Specification — Tài liệu thiết kế kỹ thuật) chuẩn CITEK cho SAP S/4HANA On-Premise: khung 9 mục, Object List, Enhancement/DDIC, Parameter–Selection-screen, Display output, Logic lấy data, quy ước đặt tên object và cách xuất ra .docx. Dùng khi cần tạo mới, cập nhật version, hoặc review 1 file TS cho bộ phận kỹ thuật — mọi loại RICEFW (Report/ALV, Interface–API/PI-PO, Enhancement/BAdI/User-exit, Form, Conversion)."
user-invocable: true
disable-model-invocation: false
---

# TS — Tài liệu thiết kế kỹ thuật (chuẩn CITEK, S/4HANA On-Premise)

**Nguồn chuẩn — 2 file, mỗi file 1 vai trò:**

| File | Dùng cho |
|---|---|
| `CodeABAP/Document/GGFs_TS_Chucnang&TichhopAPI_trahangbannoibo_MM13_V1.0.docx` | **Nội dung**: khung 9 mục, cách viết từng mục, quy ước đặt tên (§3–§5) |
| `CodeABAP/Document/BIDIPHAR_BP_SD_V2.0.docx` | **Hình thức** (template mới nhất, từ 27/09/2026): font, màu, trang bìa, bảng, header, footer (§2, §6b) — là `-Template` khi xuất `.docx` |

Trong skill này:

- 📌 = **lấy nguyên từ file mẫu** — cứ theo, không cần hỏi.
- ➕ = **mở rộng** cho loại RICEFW mà file mẫu không có (file mẫu chỉ là Report +
  Interface). Lần đầu áp dụng cho 1 dự án mới → nói rõ với user/lead đây là phần mở
  rộng, không phải chuẩn đã có sẵn.

**Ranh giới TS vs FS:** TS chỉ mô tả *làm thế nào trên hệ thống* — object gì, field nào,
logic nào. Lý do nghiệp vụ nằm ở FS; TS **trỏ tên file FS** (mục 1.2) chứ không chép lại
nghiệp vụ. Nếu user đưa yêu cầu nghiệp vụ thô mà chưa có FS → nói rõ TS sẽ thiếu mục 1.2
và hỏi đã có FS chưa.

## ⚠️ TS là tài liệu chính thức gửi khách hàng

Hệ quả bắt buộc — **không có ngoại lệ**:

- **Không có phụ lục, không có mục nhận xét/đánh giá/rủi ro.** Đúng 9 mục ở §3, hết.
- **Không đưa vào tài liệu:** lỗi phát hiện trong code, cảnh báo hiệu năng, đề xuất
  refactor, chê cách code cũ, ghi chú quy trình nội bộ (tên MCP server, hostname, chuyện
  tool đọc được/không đọc được), câu kiểu *"tài liệu này lập ngược từ source"*.
- **Chỉ mô tả code đang làm gì.** Hành vi thật vẫn ghi bình thường kể cả khi nó là hệ quả
  của lỗi — VD *"câu SELECT nạp GT_MARA đang được comment trong source nên cột hiển thị
  rỗng"* là mô tả kỹ thuật hợp lệ; *"đây là bug cần sửa gấp"* thì không.
- **Phát hiện lỗi/hiệu năng đi đâu?** Ghi vào `.claude/skills/abap-platform-constraints/reference/_ghichu_local.md` (kiến thức dùng chung cho
  team) **và báo user trong câu trả lời chat** — không bao giờ nằm trong file giao khách.

Generator `scripts/md2docx.js` có chốt chặn: mọi section có tiêu đề bắt đầu bằng
`PHỤ LỤC` đều bị **loại khỏi file Word**, kể cả khi lỡ còn trong `.md`.

---

## 1. Trước khi viết — thu đủ đầu vào

Không đủ thì **hỏi user, tuyệt đối không bịa tên object / tên bảng / tên field**. TS sai
tên object là lỗi nặng nhất của loại tài liệu này (dev đọc TS để code, tester đọc TS để test).

| Đầu vào cần có | Phục vụ mục |
|---|---|
| Tên + version file FS | 1.2 |
| Mã dự án, phân hệ, mã chức năng (VD: `GGFs` / `MM` / `MM.13`) | Trang bìa, tên file |
| Loại RICEFW (Report / Interface / Enhancement / Form / Conversion) | Chọn mục bắt buộc — §4 |
| Danh sách object (tên + type + mô tả) | 2.2 |
| Cấu trúc bảng Z / structure / message class | 2.4 |
| Màn hình tham số: field, kiểu, bảng nguồn | 2.8 |
| Danh sách cột hiển thị + **nguồn dữ liệu từng cột** | 2.9 |
| Người thiết kế, ngày cập nhật, version | Trang bìa |
| **Tên đầy đủ công ty khách hàng** + **file logo khách** (PNG/JPEG) | Header file Word (§2) — **không đoán**, hỏi user |

> **Đang có MCP `GUI_*`:** lấy thẳng danh sách object, cấu trúc DDIC, selection-screen,
> source code từ hệ thống thật thay vì hỏi lại user. Thà đọc hệ thống 10 phút còn hơn viết
> 1 TS sai tên field. Phát hiện mới xác nhận được qua MCP → ghi vào `.claude/skills/sap-mcp-gui/reference/_ghichu_mcp_gui.md`
> theo CLAUDE.md.

**Quy trình 5 bước:**

1. Chốt loại RICEFW + gom đầu vào → *verify:* bảng trên không còn ô trống.
2. Copy `references/template-TS.md` → `<MãDA>_TS_<TênChứcNăng>_<Mã>_V<x.y>.md`
   → *verify:* có đủ 9 mục của §3.
3. Điền từng mục theo §3, mục không dùng ghi `N/A` (**không xoá mục, không để trống**)
   → *verify:* mọi cột ở 2.9 đều có giá trị ở cột Logic.
4. Chèn placeholder ảnh theo §6 → *verify:* mỗi placeholder nói rõ chụp Tcode/màn hình nào.
5. Chạy checklist §8 → xuất `.docx` theo §7.

---

## 2. Trang bìa, header/footer, tên file 📌

**Tên file:** `<MãDA>_TS_<TênChứcNăng>_<MãChứcNăng>_V<x.y>.docx`
→ `GGFs_TS_Chucnang&TichhopAPI_trahangbannoibo_MM13_V1.0.docx`
(không dấu, không khoảng trắng; `V1.0` = bản đầu, sửa nhỏ → `V1.1`, đổi thiết kế → `V2.0`).

> Bản `.md` trong repo: đặt cùng tên nhưng **bỏ ký tự `&`** (vướng shell/git/URL trên
> Windows), VD `GGFs_TS_ChucnangTichhopAPI_trahangbannoibo_MM13_V1.0.md`. Chỉ khi xuất
> `.docx` giao khách mới đặt lại đúng tên có `&`.

**Trang bìa** (theo template BIDIPHAR):

1. Tiêu đề `# TÀI LIỆU THIẾT KẾ KỸ THUẬT`
2. Dòng phụ đề ngay dưới tiêu đề (đoạn văn thường trong `.md`) theo mẫu
   `Phân hệ <Tên phân hệ> (<Mã> - <Tên tiếng Anh>) – SAP S/4HANA`,
   VD `Phân hệ Quản lý vật tư (MM - Materials Management) – SAP S/4HANA`
3. Đường kẻ ngắn xanh lá + bảng THÔNG TIN TÀI LIỆU (generator tự dựng)

**Không có trang ký** (`TRANG KÝ CITEK`, `TRANG KÝ <KHÁCH HÀNG>`) — template BIDIPHAR có
nhưng TS không dùng.

**Bảng THÔNG TIN TÀI LIỆU** — đúng 6 dòng, đúng thứ tự:

| | |
|---|---|
| Mã Dự Án | GGFs |
| Phân hệ | MM |
| Tên báo cáo | MM.13 – Quy trình trả hàng bán nội bộ |
| Người thiết kế | Nguyễn Hoàng Duy |
| Phiên bản | 1.0 |
| Ngày cập nhật | 18/03/2024 |

**Bảng GHI NHẬN THAY ĐỔI** (trang 2) — mỗi lần nâng version thêm đúng 1 dòng, **không sửa
đè dòng cũ**:

| Ngày thay đổi | Mục, bảng, sơ đồ thay đổi | Mô tả thay đổi | T / S / X | Phiên bản |
|---|---|---|---|---|
| 18/03/2024 | Toàn bộ | Tạo mới tài liệu | T | 1.0 |

Chú thích cố định dưới bảng: `T - Thêm mới    S - Sửa đổi    X - Xóa`

**Header/footer** (chỉ có trong file `.docx`):

- Header = bảng 3 ô: `[logo Citek]` · 2 dòng chữ · `[logo công ty khách hàng]`
  - Dòng 1 cố định: `CUNG CẤP DỊCH VỤ TRIỂN KHAI GIẢI PHÁP PHẦN MỀM`
  - Dòng 2: `QUẢN TRỊ DOANH NGHIỆP SAP S/4HANA TẠI <TÊN CÔNG TY KHÁCH HÀNG>`
  - Tên công ty + logo **đổi theo từng dự án** → truyền `-CustomerName`/`-CustomerLogo`
    khi build (§7). Thiếu thì script ghi placeholder `[TÊN CÔNG TY KHÁCH HÀNG]` / để trống ô
    logo và in cảnh báo — **tuyệt đối không để lại tên/logo khách của template** (lộ thông tin
    dự án khác cho khách hàng này).
- Footer: `Citek@2026` · `Confidential` · `Trang {PAGE} / {NUMPAGES}` (giữ nguyên từ template)
- Trang 3 là **MỤC LỤC** (TOC tự sinh 3 cấp), nội dung bắt đầu từ trang 4.

---

## 3. Khung 9 mục và cách viết từng mục 📌

Giữ **nguyên thứ tự và nguyên cách đánh số**. Mục không áp dụng → ghi `N/A`.

```
1. Tổng quan
   1.1 Mô tả chung
   1.2 Yêu cầu nghiệp vụ chi tiết
2. Mô tả kỹ thuật
   2.1  Cấu hình hệ thống
   2.2  Object List
   2.3  Flow Diagram
   2.4  Enhancement
   2.5  Job Scheduling
   2.6  Error Handling
   2.7  Function Module
   2.8  Parameter/Selection-screen
   2.9  Display output
   2.10 Logic lấy data
```

> File mẫu đánh máy sai chính tả ở 2 chỗ: *"Error Hadling"*, *"Integaration Builder"*.
> **Viết đúng** (`Error Handling`, `Integration Builder`) — đây là lỗi gõ, không phải quy ước.

### 1.1 Mô tả chung
1–3 câu, phạm vi chức năng. Mẫu: *"Tích hợp quy trình trả hàng bán nội bộ GGFs và GGG"*.

### 1.2 Yêu cầu nghiệp vụ chi tiết
Chỉ ghi `Tài liệu FS:` + tên file FS kèm version:
`GGFs_FS_Chucnang&TichhopAPI_trahangbannoibo_MM13_V2.0`.

### 2.1 Cấu hình hệ thống
Cấu hình **ngoài ABAP** cần có để chạy. Với interface qua PI/PO: liệt kê theo từng API các
file import — `File import Enterprise Service Builder`, `File import Integration Builder`
(đính kèm file thật vào Word). Chức năng thuần ABAP → `N/A`.

### 2.2 Object List — **mục quan trọng nhất**
Bảng 5 cột; nhiều API/nhiều chương trình thì tách sub-section (`2.2.1 API 5`, …):

| No. | Object Name | Object Type | Description | File |
|---|---|---|---|---|
| 1 | ZCO_SI_OUT_PORET_GGG_TAYHO | Class/Interface | Proxy Class | |
| 2 | ZMM_PG_PROC_PO_RET | Program | Program chính của option Xử lý đơn trả hàng | |
| 3 | ZMM_IN_PROC_PO_RET_TOP | Include | Màn hình tham số và các khai báo dùng chung cho program ZMM_PG_PROC_PO_RET | |
| 4 | ZEI_VL02N_UPDATE_PO_PRICE | Enhancement Implementation Point | Include: MV50AFZ1 / Xử lý nhập kho trả hàng và call API 7 | |

Quy tắc:

- `Object Type` dùng đúng từ vựng file mẫu: `Program`, `Include`, `Transaction`,
  `Class/Interface`, `Implementing Class`, `Method`,
  `Enhancement Implementation Point`; ➕ thêm `Table`, `Structure`, `Message Class`,
  `Function Module`, `Search Help`, `Data Element`, `Domain`.
- Object **dùng chung nhiều API/nhiều option thì lặp lại ở từng bảng** (file mẫu lặp
  `ZIT01`, `ZMM_PG_CNQLTH` ở cả 4 API) — người chỉ đọc 1 bảng vẫn thấy đủ.
- Enhancement phải ghi **include/exit point** trong Description (`Include: MV50AFZ1`).
- `Method` ghi kèm proxy interface (`Proxy Interface: ZII_SI_IN_PORET_GGG_TAYHO`).
- Cột `File` để trống trừ khi có file đính kèm thật.

### 2.3 Flow Diagram
Sơ đồ luồng, mỗi API/chức năng 1 sub-section, tiêu đề phụ `Luồng tích hợp`. **Chỉ là ảnh**
→ dùng placeholder §6. Cần vẽ mới thì gợi ý user dùng MCP draw.io
(`mcp__plugin_sap-abap_drawio__*`) rồi chụp lại chèn vào.

### 2.4 Enhancement
Bất chấp tên gọi, file mẫu dùng mục này cho **toàn bộ object DDIC + enhancement tự tạo**:
Message Class, Structure, Transparent Table, Enhancement Implementation. Mỗi object 1 dòng
nhãn + screenshot SE11/SE19:

```
Transparent Table: ZTB_PORET_HD
> 📷 [ẢNH] SE11 → ZTB_PORET_HD → tab Fields (thấy đủ key + data element)
```

➕ Khuyến nghị bổ sung bảng dưới mỗi ảnh để dev copy được key mà không phải zoom ảnh:

| Field | Key | Data element | Mô tả |
|---|---|---|---|

### 2.5 Job Scheduling
Có chạy nền: tên job, biến thể, tần suất, user chạy. Không có → `N/A`.

### 2.6 Error Handling
Cách xử lý lỗi: message class, mã message, ghi log, cơ chế retry. Không có → `N/A`.
➕ Với interface, nêu rõ: lỗi kỹ thuật (timeout/parse) vs lỗi nghiệp vụ (BAPI trả `E`), và
dữ liệu lỗi có cho post lại được không.

### 2.7 Function Module
Tên FM + screenshot Import/Export/Tables + `Source code:` (dán code hoặc đính kèm file).
File mẫu: `ZFM_ADD_MESS`. Không có FM → `N/A`.

### 2.8 Parameter/Selection-screen
Mỗi chương trình 1 sub-section (tiêu đề = **tên chức năng trên màn hình**, VD
`MM.13_Xử lý đơn trả hàng`): screenshot màn hình + dòng `Mô tả:` + bảng 6 cột:

| Description | Type | Field name | SAP table | Default | Required |
|---|---|---|---|---|---|
| PO Number | Select option | S_PONUM | ZTB_PORET_HD-PO | | |
| Dữ liệu đã tạo giao dịch | Check box | P_POST | CHAR1 | | |

- `Type`: `Select option` / `Parameter` / `Check box` / `Radio button`.
- `Field name`: `S_*` cho select-option, `P_*` cho parameter/checkbox (khớp skill
  `abap-naming-convention`).
- `SAP table`: ghi `<BẢNG>-<FIELD>`; field không tham chiếu bảng thì ghi kiểu (`CHAR1`).
- Để trống `Default`/`Required` khi không có — **không ghi "không"**.

### 2.9 Display output
Mỗi chương trình 1 sub-section. Có nhiều trạng thái hiển thị thì tách rõ từng trường hợp
(file mẫu: *"Option không tick Dữ liệu đã tạo giao dịch - ALV"* / *"Option tick … - ALV"*),
mỗi trường hợp 1 screenshot ALV, rồi `Mô tả:` + bảng 3 cột:

| Description | SAP field | Logic |
|---|---|---|
| PO number | PO | ZTB_PORET_HD-PO |
| Material name | MATERIALNAME | Mapping MAKT-MAKTX theo ZTB_PORET_DT-MATERIAL |
| Net Price Update | NETPRICE_U | Mapping VBAK, VBAP-NETPR theo ZTB_PORET_DT-POREFER và ZTB_PORET_DT-POREFERITEM |
| Integrated | ISPOST_ICON | Kết quả subrountine SET_ICON_STATUS với tham số ZTB_PORET_DT-ISPOST |
| Select | SELECT | Field check box |

**Cột Logic là phần có giá trị nhất của cả TS — không được để trống.** 4 dạng hợp lệ:

1. Lấy thẳng: `<BẢNG>-<FIELD>`.
2. Mapping: `Mapping <BẢNG>-<FIELD> theo <khóa nối>` — phải nêu **đủ khóa nối**.
3. Tính qua routine: `Kết quả subrountine <TÊN> với tham số <input>`.
4. Field kỹ thuật: `Field check box`, `Icon trạng thái`…

Field icon đặt tên `<FIELD>_ICON`, field lấy giá trị cập nhật đặt `<FIELD>_U` 📌.

### 2.10 Logic lấy data
Mỗi chương trình 1 sub-section, viết bằng **danh sách đánh số lồng cấp** theo đúng thứ tự
chạy. Trích thật từ file mẫu:

```
1. Lấy data từ table ZTB_PORET_HD và ZTB_PORET_DT theo điều kiện lọc từ màn hình tham số.
2. Lấy data mapping từ table MAKT, VBAP.
3. Mapping Material Name, Net Price Update, Order PU Update, Price Unit Update
   và xử lý giá trị các field status.
4. Tạo internal table chứa thông tin field catalog bằng FM LVC_FIELDCATALOG_MERGE,
   chỉnh sửa hiển thị field và mô tả.
5. Hiển thị ALV bằng FM REUSE_ALV_GRID_DISPLAY_LVC.
6. Xử lý fcode Select All (&SALL), Deselect All (&DALL), Tổ hợp (&TOHOP), Post (&POST).
   a. Select All
      i.   Sử dụng FM GET_GLOBALS_FROM_SLVC_FULLSCR kiểm tra filter.
      ii.  Nếu có filter …
      iii. Nếu không có filter …
   b. Post
      i.   Kiểm tra trạng thái data so với table ZTB_PORET_DT để tránh post trùng.
      ii.  Xử lý mapping data vào request.
      iii. Call API 6.
      iv.  Xử lý lưu data vào table Z.
```

Yêu cầu:

- Nêu **tên bảng, tên FM, tên subroutine, mã fcode thật** — không viết chung chung kiểu
  "xử lý dữ liệu".
- Mọi nhánh điều kiện phải ghi đủ 2 chiều (`Nếu có filter` / `Nếu không có filter`).
- Điều kiện lọc ghi bằng giá trị thật: `RLSTATUS = '02'`, `ISPOST = ''`.
- Ghi rõ điểm gọi API / commit / update bảng Z.
- Thay đổi dữ liệu nghiệp vụ phải qua **BAPI** (CLAUDE.md) — TS ghi rõ tên BAPI, không bao
  giờ mô tả `UPDATE` trực tiếp bảng chuẩn.

---

## 4. Biến thể theo loại RICEFW

Cột "bắt buộc" = không được ghi `N/A`.

| Loại | Bắt buộc | Có thể `N/A` | Lưu ý |
|---|---|---|---|
| **Report / ALV** 📌 | 2.2, 2.8, 2.9, 2.10 | 2.1, 2.3, 2.5, 2.7 | Ghi rõ ALV grid hay list, FM/class dùng; performance theo skill `abap-performance-hana` |
| **Interface / API** 📌 | 2.1, 2.2, 2.3, 2.6, 2.10 | 2.8, 2.9 (nếu không có màn hình) | Mỗi API 1 sub-section ở 2.1/2.2/2.3; nêu inbound hay outbound, proxy class + interface + method |
| **Enhancement / BAdI / User-exit** 📌 | 2.2, 2.4, 2.10 | 2.8, 2.9 | 2.2 phải ghi include/exit point (`Include: MV50AFZ1`); 2.10 ghi **điều kiện kích hoạt** và ảnh hưởng tới t-code chuẩn |
| **Form (Smartforms/Adobe/ZXLWB)** ➕ | 2.2, 2.9 (layout), 2.10 | 2.1, 2.3 | 2.9 mô tả vùng layout + binding từng field; form Excel ZXLWB → dùng skill `zxlwb-workbench` |
| **Conversion / Data load** ➕ | 2.2, 2.8, 2.10 | 2.3, 2.9 | Thêm bảng mapping cột file → field SAP + rule validate; nêu BAPI/LSMW dùng để ghi |

➕ **Interface — bảng mapping field** (file mẫu để mapping trong ESR nên Word không có).
Nếu dự án không có tài liệu ESR riêng thì bổ sung vào 2.10 hoặc 2.1:

| Field API | Kiểu/độ dài | Bắt buộc | Field SAP | Rule chuyển đổi |
|---|---|---|---|---|

---

## 5. Quy ước đặt tên object 📌

Rút từ object thật trong file mẫu. **Đây là mặc định, không phải luật tuyệt đối** — trước
khi áp cho dự án khác, đối chiếu với Z-object đã có trên hệ thống đó (grep qua MCP `GUI_*`
nếu có) và theo tài liệu naming của dự án nếu tồn tại.

| Loại object | Pattern | Ví dụ thật |
|---|---|---|
| Program | `Z<PH>_PG_<viết tắt>` | `ZMM_PG_PROC_PO_RET`, `ZMM_PG_CNQLTH`, `ZMM_PG_NKTH` |
| Include | `Z<PH>_IN_<tên>_TOP` / `_F01` | `ZMM_IN_PROC_PO_RET_TOP`, `ZMM_IN_SODO_RET_F01` |
| Transaction | `Z<PH><nn>` | `ZIT01` |
| Transparent table | `ZTB_<tên>_HD` (header) / `_DT` (item) | `ZTB_PORET_HD`, `ZTB_GR_PORET_DT` |
| Structure | `Z<PH>_ST_<tên>` hoặc `ZST_<tên>` (dùng chung) | `ZMM_ST_NKTH`, `ZST_UPDATE_INFO` |
| Message class | `ZMC_<tên>` | `ZMC_ITP` |
| Function module | `ZFM_<tên>` | `ZFM_ADD_MESS` |
| Enhancement implementation | `ZEI_<Tcode>_<mô tả>` | `ZEI_VL02N_UPDATE_PO_PRICE` |
| Proxy class (outbound) | `ZCO_SI_OUT_<tên>` | `ZCO_SI_OUT_PORET_GGG_TAYHO`, `ZCO_SI_OUT_GIGR` |
| Implementing class (inbound) | `ZCL_SI_IN_<tên>` | `ZCL_SI_IN_PORET_GGG_TAYHO` |
| Proxy interface | `ZII_SI_IN_<tên>` | `ZII_SI_IN_PORET_GGG_TAYHO` |
| Method proxy | `SI_IN_<tên>` | `SI_IN_PORET_GGG_TAYHO` |

`<PH>` = mã phân hệ (`MM`, `SD`, `FI`…). Tên biến trong code: skill `abap-naming-convention`.

---

## 6. Placeholder ảnh — phần AI không tự làm được

File mẫu có **45+ ảnh** (screenshot màn hình, cấu trúc DDIC, flow diagram, giao diện FM).
Không được bỏ qua và **không được mô tả bằng lời thay cho ảnh**. Chèn đúng định dạng này để
người thực hiện biết chính xác phải chụp gì:

```markdown
> 📷 **[ẢNH]** SE11 → ZTB_PORET_HD → tab Fields — chụp đủ cột Key/Initial/Data element
> 📷 **[ẢNH]** Chạy ZIT01 → option "Xử lý đơn trả hàng" — chụp toàn bộ selection-screen
> 📷 **[ẢNH]** ALV kết quả khi KHÔNG tick "Dữ liệu đã tạo giao dịch" — chụp 2 nửa trái/phải
```

Trong file Word, mỗi placeholder được render thành **1 ô nền xám nhạt `F5F5F5`** (màu có sẵn
trong template) để người chèn ảnh nhìn là thấy ngay, và xoá ô đó sau khi dán ảnh vào.
Placeholder viết trên nhiều dòng `>` liên tiếp được gộp vào cùng 1 ô.

**Không tạo "Phụ lục — danh sách ảnh" ở cuối tài liệu** (vi phạm quy tắc không phụ lục ở
đầu skill). Thay vào đó, liệt kê danh sách ảnh còn thiếu **trong câu trả lời chat** khi bàn
giao, kèm câu nói rõ: TS chưa hoàn chỉnh cho tới khi ảnh được chèn.

---

## 6b. Font và màu — bám đúng template 📌

Đọc trực tiếp từ `BIDIPHAR_BP_SD_V2.0.docx` (template mới nhất), **không được tự chọn màu/font
khác**. `scripts/md2docx.js` đã hard-code đúng các giá trị này:

| Thành phần | Giá trị |
|---|---|
| Khổ giấy | A4 **dọc** — generator đọc `sectPr` từ chính template, không hard-code |
| Font chữ | **Không khai `rFonts`** → kế thừa style `Normal` = `Myriad Pro` 11pt |
| Màu chữ thân bài | `00586F` trên mọi đoạn văn, ô bảng, list (template tô trực tiếp từng run) |
| Tiêu đề trang bìa | đậm, `00586F`, `sz 40` (20pt), căn giữa |
| Phụ đề trang bìa | nghiêng, `00586F`, `sz 32` (16pt), căn giữa |
| Đường kẻ trang bìa | viền dưới `sz 24` màu `A2D45E`, thụt 2 bên `3969` |
| Heading 1/2/3 | style của template (đậm `00586F`, 18/14/12pt, tự đánh số `1` / `1.1` / `1.1.1`) |
| Viền bảng | `single`, `sz 4`, màu `BFBFBF` |
| Header cột bảng thân tài liệu | nền `00586F`, chữ `FFFFFF` đậm, căn giữa, lặp lại đầu trang |
| Lề ô | trên/dưới `60`, trái/phải `100` twips |
| Placeholder ảnh / code block | nền `F5F5F5`; code dùng `Courier New` |
| Mục lục | chữ `00586F` (build script tô sau khi Word sinh TOC) |

Cạm bẫy đã gặp: **đừng khai `w:sz`/`spacing` trong ô bảng** để "cho gọn". Template không khai
— ô bảng kế thừa `Normal` (11pt, `after=200`), nên dòng bảng cao hơn bảng Word mặc định; đó là
đúng template.

`Myriad Pro` là font Adobe — đã kiểm tra có sẵn trên máy dev. Máy nào thiếu thì Word tự thay
font khác và tài liệu sẽ trông lệch; kiểm tra bằng `(New-Object -ComObject Word.Application).FontNames`.

### 2 bảng trang bìa có cấu trúc RIÊNG, khác bảng thường 📌

| | `THÔNG TIN TÀI LIỆU` | `BẢNG GHI NHẬN THAY ĐỔI` | Bảng thân tài liệu |
|---|---|---|---|
| Tiêu đề | dòng **merge hết cột TRONG bảng**, nền `00586F`, chữ trắng đậm 14pt, căn giữa | như bên trái | Không có |
| Header cột | Không có | nền `F5F5F5`, chữ `00586F` **đậm**, căn giữa | nền `00586F`, chữ trắng đậm |
| Cột nhãn | cột 1 nền `F5F5F5`, chữ đậm | — | — |
| Độ rộng cột | cố định `30% / 70%` | cố định theo tỉ lệ template `1417/2551/3118/1020/1224` | tự tính theo nội dung |
| Chú thích | — | `T - Thêm mới …` là **đoạn văn nghiêng NGOÀI bảng** | — |

Trang 1 = bìa + THÔNG TIN TÀI LIỆU · trang 2 = BẢNG GHI NHẬN THAY ĐỔI · trang 3 = MỤC LỤC
(1 ô nền teal + TOC) · nội dung từ trang 4.

Generator nhận diện 2 bảng bìa qua tiêu đề `## THÔNG TIN TÀI LIỆU` và
`## BẢNG GHI NHẬN THAY ĐỔI` (chấp nhận cả tên cũ `## QUẢN LÝ THAY ĐỔI`). **Giữ nguyên các
tiêu đề này trong `.md`** — đổi chữ là mất nhận diện. MỤC LỤC được chèn ngay sau dòng chú thích
`T - …`, hoặc trước heading nội dung đầu tiên nếu thiếu dòng chú thích.

### Độ rộng cột — tự tính theo nội dung

Cột có độ rộng khác nhau theo **từng bảng**, không chia đều. `colWidths` trong `md2docx.js`:

1. Trọng số theo nội dung:
   `clamp( max( len(tiêu_đề)+2 , min( max(len ô), trung_bình(len ô) × 1.6 ) ), 6, 50 )` —
   kéo về phía trung bình để một ô dài bất thường không nuốt cả bảng.
2. **Sàn tối thiểu** = độ rộng từ dài nhất của cột (tiêu đề in đậm + nội dung) để Word không
   gãy chữ giữa từ (`Defaul|t`, `ZMM_PG_ZMB|51`). Ước lượng: chữ thường ~105 twips, HOA/số/`_`
   ~140, đậm ×1.1, `` `code` `` ~132/ký tự; Word được ngắt sau `-` nên `MSEG-USNAM_MKPF` tính
   theo `USNAM_MKPF`. Cột thiếu sàn lấy bù từ cột còn dư.
3. Tổng sàn vượt khổ giấy → chia theo tỉ lệ sàn.

Khổ dọc chỉ còn `9332` twips (khổ ngang cũ `14317`) nên bước 2 là bắt buộc — thiếu nó bảng
selection-screen 6 cột bị gãy chữ ở header.

---

## 7. Xuất `.docx` — đã tự động hoá

```powershell
powershell -File .claude\skills\sap-ts-document\scripts\build-docx.ps1 `
  -MdPath       "CodeABAP\Document\<TS>.md" `
  -Template     "CodeABAP\Document\BIDIPHAR_BP_SD_V2.0.docx" `
  -CustomerName "CÔNG TY CỔ PHẦN ... (TÊN VIẾT TẮT)" `
  -CustomerLogo "<đường dẫn logo khách>.png"
```

- `-CustomerName`: phần sau chữ `TẠI` ở dòng 2 header (script tự viết HOA).
- `-CustomerLogo`: PNG/JPEG, script tự co vừa khung logo cũ và **giữ tỉ lệ** ảnh.
- Thiếu 1 trong 2 → vẫn build, in `CANH BAO` và để placeholder/ô trống. **Hỏi user** thay vì
  đoán tên công ty hay lấy logo trên mạng.

**Nguyên lý:** copy nguyên file `.docx` template, thay `word/document.xml`, vá header +
`docProps/core.xml`. `styles.xml`, `footer*.xml`, `numbering.xml`, `theme` giữ nguyên byte →
định dạng CITEK không thể sai lệch. Mọi nội dung của template (kể cả trang ký, TOC cũ) bị thay
hết vì `document.xml` sinh mới hoàn toàn.

Các bước script tự làm:

1. `scripts/md2docx.js` (Node) parse Markdown → WordprocessingML: heading, bảng, list lồng
   cấp, blockquote, code block, `**đậm**` (lồng được `` `code` ``), placeholder ảnh — áp đúng
   font/màu §6b, lấy `sectPr` từ template, **bỏ comment `<!-- -->`** và **mọi section `PHỤ LỤC`**.
2. `scripts/patch-package.js` (Node): thay tên công ty + logo khách ở header; ghi
   `core.xml` (title = `Tên báo cáo`, creator = `Người thiết kế`, xoá description cũ của
   template — template BIDIPHAR mang `generated by python-docx`).
3. Validate mọi part XML bằng `[xml]` **trước khi** đóng gói — chặn lỗi Word đòi repair.
4. Thay/thêm entry bằng `System.IO.Compression.ZipFile` chế độ `Update`
   (**không dùng `Compress-Archive`** — nó dựng lại toàn bộ zip và làm hỏng cấu trúc OPC).
5. Mở bằng Word COM: update field ở header/footer chính (`Headers.Item(1)`/`Footers.Item(1)`;
   `$d.StoryRanges` không đủ, footer sẽ kẹt số trang cũ), sinh TOC, tô TOC `00586F`, save.
   Word mở được mà không hỏi repair = phép thử file hợp lệ; Word save cũng bỏ media thừa
   (logo khách cũ của template). Script **chỉ `Quit` Word khi không còn tài liệu nào mở** — COM
   có thể gắn vào Word user đang dùng.

**Quy tắc bắt buộc khi viết Markdown nguồn:**

- Heading `#`/`##`/`###` map sang `Heading1/2/3` — các style này **tự đánh số**, nên script
  **cắt bỏ số thủ công** trong text (`## 2.1. Cấu hình` → Word hiển thị `2.1 Cấu hình`).
  Viết số vào Markdown vẫn đúng, đừng bỏ — script lo phần cắt.
- Dòng ngay dưới `# TÀI LIỆU THIẾT KẾ KỸ THUẬT` là phụ đề trang bìa (§2).
- Mọi `## PHỤ LỤC ...` bị bỏ hẳn (§ đầu skill) — script in ra số section đã bỏ để đối chiếu.

Nếu không có Word: thêm `-SkipWord`, file vẫn hợp lệ, chỉ cần mở Word bấm `Ctrl+A` rồi `F9`.

**Kiểm tra bằng mắt** (Word COM chạy được inline, không chạy trong background job):
mở file bằng Word COM ở chế độ read-only → `SaveAs2(<pdf>, 17)` → render trang PDF ra PNG bằng
`pymupdf` (`python` có sẵn trên máy dev) → xem trang bìa, trang ghi nhận thay đổi, mục lục và
1 bảng nhiều cột. **Không dùng `ExportAsFixedFormat`** — treo vô thời hạn.

**Ảnh vẫn phải chèn tay** (§6) — script chỉ dựng ô placeholder nền `F5F5F5` đúng vị trí.

**Định dạng file:** script xuất `.docx` (đúng định dạng của template). Đổi đuôi `.md`/`.docx`
thành `.doc` **không** biến nó thành file Word — Word sẽ mở ra text lỗi hoặc hỏi encoding.
Nếu khách bắt buộc `.doc` (Word 97-2003) thì mở file `.docx` bằng Word rồi Save As → `.doc`.

---

## 8. Checklist nghiệm thu

Chưa qua hết checklist thì **chưa được coi là xong**:

- [ ] Đủ 9 mục, đúng thứ tự, đúng số; mục không dùng ghi `N/A` chứ không xoá/để trống.
- [ ] **Không có phụ lục, không có mục nhận xét/rủi ro/đề xuất sửa code.** Grep file `.md`
      với `PHỤ LỤC`, `nên sửa`, `rủi ro`, `bug`, `cần tối ưu` → phải sạch.
- [ ] **Không lộ thông tin nội bộ:** grep `MCP`, hostname hệ thống, `lập ngược`,
      `reverse engineering`, tên tool nội bộ → phải sạch.
- [ ] Mọi object ở 2.2 là **tên thật đã/sẽ tồn tại** — không có tên bịa, không có `<TBD>`.
- [ ] Object List khớp với tên object nhắc ở 2.4 / 2.7 / 2.10 (grep chéo tên object giữa các mục).
- [ ] Mọi dòng ở 2.9 có cột `Logic`; mapping ghi đủ khóa nối.
- [ ] 2.10 nêu tên bảng/FM/subroutine/fcode thật; nhánh điều kiện ghi đủ 2 chiều.
- [ ] Thay đổi dữ liệu nghiệp vụ mô tả qua **BAPI**, không `UPDATE` trực tiếp bảng chuẩn.
- [ ] 1.2 trỏ đúng tên + version file FS.
- [ ] Header file Word đúng **tên công ty + logo của khách dự án này** — build không còn dòng
      `CANH BAO`; không sót tên/logo khách của template.
- [ ] Bảng GHI NHẬN THAY ĐỔI có dòng cho version hiện tại; version ở bảng này = version ở
      THÔNG TIN TÀI LIỆU = version trong tên file.
- [ ] Tên file đúng `<MãDA>_TS_<Tên>_<Mã>_V<x.y>`.
- [ ] Danh sách placeholder ảnh đã liệt kê và đã báo cho user.
- [ ] Không có tên AI (`Claude`, `ClaudeAI`, "AI") ở bất kỳ đâu trong tài liệu/metadata —
      quy ước bắt buộc, xem `.claude/skills/abap-platform-constraints/reference/_ghichu_local.md` §1.

---

## 9. Skill liên quan

| Việc | Skill |
|---|---|
| Đặt tên biến/internal table trong đoạn code dán vào TS | `abap-naming-convention` |
| Review/tối ưu logic ở 2.10 | `abap-performance-hana` |
| TS cho form Excel ZXLWB | `zxlwb-workbench` |
| Vẽ Flow Diagram (2.3) | MCP draw.io `mcp__plugin_sap-abap_drawio__*` |
| Sinh `.docx` khi không dùng file Word gốc | `anthropic-skills:docx` |

**Template điền sẵn:** `references/template-TS.md`.
