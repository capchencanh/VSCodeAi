---
name: zxlwb-workbench
description: Thiết kế/sửa file .xlsx cho tool XLSX Workbench (ZXLWB, FM ZXLWB_CALLFORM, Tcode ZXLWB_WORKBENCH) dùng để xuất Excel từ report ABAP trong project này. Dùng khi cần tạo mới hoặc sửa 1 form .xlsx trong thư mục "form zxlwb" của 1 project ABAP (report gọi ZXLWB_CALLFORM để xuất Excel), khi gặp lỗi import file .xlsx vào SAP ("Error while reading template file" / LP000, "No MIME type assigned to object"), hoặc khi cần hiểu cơ chế binding field/loop/điều kiện hiển thị của form.
---

# XLSX Workbench (ZXLWB) — thiết kế file `.xlsx` cho xuất Excel từ ABAP

Tool nội bộ dựa trên thư viện mã nguồn mở "XLSX-Workbench" (Igor Borodin,
Apache 2.0, https://sites.google.com/site/sapxlwb/home). Mỗi report
dùng tool này thường có 1 function group riêng (copy nguyên khối
`zxlwb_include.abap` ~35.000 dòng vào local, xem
`ABAP/<program>/zxlwb_callform/`), và 1 file `.xlsx` "form" trong thư
mục `ABAP/<program>/form zxlwb/` đóng vai trò template thiết kế +
metadata binding.

**Toàn bộ kiến thức trong skill này đến từ việc đọc trực tiếp source
thật `LCL_FORMRUNTIME` + tra DDIC thật qua MCP** (không đoán) trong lúc
làm report ZCO07 (HPDQ_ZCO07). Nếu source `zxlwb_include.abap` của
project khác đã bị sửa/patch riêng, luôn tự verify lại bằng cách grep
đúng các method nêu dưới trước khi tin tưởng hoàn toàn.

## 1. File `.xlsx` KHÔNG phải file Excel thường

Nó là 1 file ZIP/OOXML chuẩn (mở được bằng Excel bình thường) nhưng có
thêm 1 folder gốc **`FormParameters/`** chứa metadata riêng của tool:

| File | Vai trò |
|---|---|
| `FormParameters/head.xml` | 1 dòng duy nhất: `FORMNAME`, `CONTEXTNAME`, `ACTIVE`, ngày/người tạo |
| `FormParameters/hierarchy.xml` | Cây node (ID/PARENT/CHILD/NEXT dạng linked-list, TLEVEL) |
| `FormParameters/properties.xml` | Thuộc tính của từng node, join bằng `ID` với hierarchy.xml |
| `xl/worksheets/sheet1.xml` | Nội dung Excel hiển thị bình thường — vùng ô của mỗi node "Pattern" (xem mục 3) được dùng làm **khuôn mẫu** (copy nguyên style+layout khi render) |

Design-time, người dùng chỉnh sửa cây này bằng Add-in Excel (Tcode
`ZXLWB_WORKBENCH` → Edit). Không có Add-in vẫn **dựng được bằng tay**
bằng cách sinh đúng 2 file XML này (xem mục 5 + script mẫu ở
`scripts/`), nhưng luôn nhờ người có Add-in mở lại kiểm tra trước khi
coi là xong (skill này không có cách tự test).

## 2. Cơ chế binding — ĐÃ XÁC MINH qua source thật

Runtime là class `LCL_FORMRUNTIME` (trong `zxlwb_include.abap`). Điểm
mấu chốt nhất, dễ đoán sai nhất:

> **`ASSIGN COMPONENT ... OF STRUCTURE ...` — CHỈ 1 CẤP.** Không có cơ
> chế nào tự đi xuyên qua sub-structure nhiều cấp lồng nhau.

Cơ chế cụ thể (method `shift_relpath`):
```
mk_shift_left cv_relpath: r_context->v_contextname , '-' , 'LINE-' .
```
Với 1 giá trị `CB_VAL_RELPATH`/`CB_APR_RELPATH`/`CB_RELPATH` bất kỳ,
runtime lần lượt thử cắt bỏ (nếu khớp ở đầu chuỗi):
1. `<CONTEXTNAME>` (giá trị khai trong `head.xml`)
2. `-` (1 dấu gạch)
3. `LINE-` (chuỗi cố định, hardcode — **không phải** tên do người dùng đặt)

Sau khi cắt, phần còn lại được dùng thẳng trong
`ASSIGN COMPONENT <con_lai> OF STRUCTURE <context_ref>` — nghĩa là phần
còn lại **BẮT BUỘC** phải là tên 1 field TRỰC TIẾP (không có dấu `-`
nào nữa) của structure `<context_ref>` tại đúng vị trí đó trong cây.

Suy ra 2 quy tắc thiết kế an toàn:

- **Field ở ngoài loop** (bind trực tiếp vào context gốc, node cha
  không shift path — `CB_RELPATH` của node cha để trống):
  `CB_VAL_RELPATH = "<CONTEXTNAME>-<TEN_FIELD_PHANG>"`.
  ⇒ Context truyền cho `IV_CONTEXT_REF` phải là **structure PHẲNG**
  (không có sub-structure lồng nhau kiểu `PARAMETER TYPE ZCORE_ST_PARAMETER`
  của quy ước cũ một số report trong tổ chức) — 2 cấp `A-B-C` sau khi
  trừ contextname **không được xác nhận là hoạt động đúng** (nghi ngờ
  là bug tiềm ẩn trong ít nhất 1 report cũ, không ai phát hiện vì phần
  bị ảnh hưởng chỉ là khối header, không phải bảng chi tiết).
- **Field trong loop** (bind vào từng dòng của bảng đang lặp):
  `CB_VAL_RELPATH = "LINE-<TEN_FIELD>"` — chữ `LINE` là **bắt buộc
  đúng chữ này**, không đổi tên khác được, bất kể node Pattern chứa nó
  tên gì (`COMP_NAME` của Pattern chỉ là nhãn hiển thị, không liên quan
  cơ chế binding).

**Context PHẢI là DDIC (SE11) khi thiết kế form — [CONFIRMED 06.10.2026,
DEV BIDIPHAR, form `ZFI_ZAP03_BKVAT`].** Runtime `ZXLWB_CALLFORM` chỉ so
khớp chuỗi + `ASSIGN COMPONENT` động nên chạy được với `TYPES` local,
NHƯNG `ZXLWB_WORKBENCH` chỉ cho gán "Name of the context" (Form
properties) bằng structure/table type DDIC. Context là `TYPES` local →
form hiện `<...not assigned...>` và node Loop `TABLE_DATA` đỏ. Quy trình:
(1) tạo trong SE11 TRƯỚC khi import form: structure dòng (+ cờ `FL_*`),
table type của dòng, structure context phẳng có field `TABLE_DATA` kiểu
table type đó (mẫu: `ZCO_ST_CCGTSP_EXL`/`ZCO_TT_CCGTSP_LINE`;
BIDIPHAR: `ZFI_ST_ZAP03_EXL`/`ZFI_TT_ZAP03_EXL_LINE`/`ZFI_ST_ZAP03_EXL_LINE`,
spec ở `ZFI_ST_ZAP03_EXL_SE11.md`); (2) đặt `CONTEXTNAME` trong `head.xml`
+ tiền tố `CB_RELPATH`/`CB_VAL_RELPATH` = đúng tên DDIC đó; (3) code ABAP
khai `DATA ls_ctx TYPE <structure DDIC>` — không dùng `TYPES` local;
(4) nếu đã import trước khi có DDIC: Form properties → Name of the context
→ bút chì → chọn DDIC. Context vẫn phải PHẲNG (xem trên); field
PACKED/QUAN/CURR chuẩn ABAP tự nhận đúng `type_kind`.

## 3. Component type (`COMP_TYPE`) cần biết

| Code | Ý nghĩa | Ghi chú |
|---|---|---|
| `R` | Root | 1 node duy nhất, con là Sheet |
| `S` | Sheet | `TB_SHEETNAME` = tên sheet Excel |
| `P` | Pattern | Vùng ô hình chữ nhật (`TB_AREA_TOP/LEFT/ROWS/COLUMNS`) copy nguyên xi từ `sheet1.xml` khi render — dùng làm "khối header" hoặc "1 mẫu dòng lặp" |
| `F` | Field | 1 ô cụ thể trong 1 Pattern, ghi đè giá trị runtime vào đúng `TB_AREA_TOP/LEFT` |
| `L` | Loopstep | Lặp qua 1 internal table (`CB_RELPATH` trỏ tới table, `CB_LOOP_FROM`/`CB_LOOP_TO`) |

(Còn `pattern`/`respattern`/`tree`/`grid`/`chart`/`folder`/`drawing` cho
nhu cầu phức tạp hơn — chưa cần dùng tới trong các report hiện tại.)

> **`TB_ROWPROP`/`TB_COLPROP` trên mọi node Pattern PHẢI = `"X"`, nếu
> không độ rộng cột (và độ cao dòng) của file mẫu sẽ KHÔNG được copy
> sang file Excel render ra.** (23/09/2026, xác nhận qua đọc trực tiếp
> `LCL_FORMRUNTIME`: property `tb_colprop`/`tb_rowprop` = "flag: copy
> the properties of columns/rows" — khi Add-in tạo 1 Pattern mới, nó tự
> set 2 flag này = `abap_on`; nhưng khi dựng `properties.xml` bằng tay
> theo mục 5, dễ bỏ sót vì 2 field này trông giống mọi field `TB_*`
> khác đang để rỗng.) Hậu quả thực tế nếu bỏ sót (case report ZCO07,
> `ZCO_PG_CCGTSP_EXL.xlsx`): tất cả cột trong file Excel xuất ra đều bị
> co về độ rộng mặc định của Excel, số liệu hiển thị `#######`, text
* dài bị cắt — trong khi `<cols>`/`width` trong `sheet1.xml` (file mẫu)
> hoàn toàn đúng. Đối chiếu 1 file `.xlsx` cũ **đang chạy tốt** (bất kỳ
> report nào, không chỉ ZCO07) luôn thấy `TB_ROWPROP="X" TB_COLPROP="X"`
> trên toàn bộ node `COMP_TYPE="P"` — dùng cách đối chiếu này (mục 5
> bước 1) để tự phát hiện thiếu sót tương tự ở form khác, không chỉ dựa
> vào việc file "import được" (import vẫn thành công dù thiếu 2 flag
> này, vì nó không phải lỗi cấu trúc XML — chỉ là sai hành vi render).

## 4. Chọn 1-trong-N mẫu dòng khi lặp (rất hay dùng cho báo cáo có nhiều loại dòng: chi tiết / subtotal / tổng)

Method `get_appearance_req`: mỗi node có thể có `CB_APR_RELPATH` (theo
đúng cơ chế cắt chuỗi ở mục 2). Nếu để trống → node luôn hiện. Nếu có
giá trị → node CHỈ hiện khi field đó **khác rỗng/khác 0** (không so
sánh bằng giá trị cụ thể, chỉ kiểm tra "có giá trị hay không").

⇒ Muốn 1 loop có N kiểu dòng khác nhau (khác style/bố cục): tạo N
Pattern **là anh em (cùng cha là node Loop)**, mỗi Pattern gán
`CB_APR_RELPATH = "LINE-<CO_RIENG>"` với **N cờ boolean riêng biệt**
(không dùng chung 1 field so sánh nhiều giá trị) khai trong structure
dòng của bảng, và phía ABAP set đúng 1 cờ = `'X'`/khác rỗng cho mỗi
dòng trước khi gọi `ZXLWB_CALLFORM`. Ví dụ đã dùng trong ZCO07: 6 cờ
`FL_ORGRP/FL_MAT/FL_COST/FL_OTHSUM/FL_OTHER/FL_TOTAL`.

Cách gọn hơn (xác nhận 24.09.2026, form HPDQ `ZXLSX_PP_BCTDTD_2`): 1 field
CHAR dài N + `CB_APR_OFFSET`/`CB_APR_MATCH` trên từng Pattern. Runtime kiểm tra
`<field>+offset(match) IS NOT INITIAL`, vd `LEVEL = 'X  '`/`' X '`/`'  X'`.
`TB_DIRECTION = X` đặt Pattern sang phải để sinh cột động. Comp type `E` =
folder, `D` = drawing. Xem `README_ZXLSX_PP_BCTDTD_2.md` trong thư mục form
của HPDQ_FAGLL03.

Mỗi Pattern anh em này đặt ở **1 dòng vật lý khác nhau** trên
`sheet1.xml` (style/format khác nhau cho từng dòng mẫu) — runtime sẽ
"stamp" đúng dòng được chọn vào vị trí output tuần tự, không phụ thuộc
việc nó nằm ở đâu trên sheet thiết kế.

## 5. Dựng file bằng tay (không có Add-in)

> **Lưu ý (25/09/2026): thư mục `scripts/` KHÔNG tồn tại thường trực
> trên đĩa** — các lần trước tạo script vào scratchpad phiên làm việc
> (temp, bị dọn sau khi phiên kết thúc), không commit vào skill. Nếu
> cần dùng lại `zipwriter.js`, phải **tự viết lại từ đầu** theo đặc tả ở
> mục 6 (ZIP local header + central directory + EOCD chuẩn, CRC32,
> `zlib.deflateRawSync`, tên entry dùng `/`) — không giả định file có sẵn,
> luôn `Glob`/`ls` kiểm tra trước.
>
> Script mẫu (cập nhật 23.09.2026 — `scripts/gen_formparams.js` và ví dụ
> ZCO07 nêu ở bản cũ **không còn trong repo**): thư mục
> `CodeABAP/HPDQ_FAGLL03_Kiểm tra và đề xuất giải pháp Export file Excel/scripts/`
> - `build_form_v2.js` — sinh trọn 1 form (sheet mẫu + styles + `FormParameters/`)
>   từ khai báo cây JS (nodes + parent), tự tính CHILD/NEXT/TLEVEL, dùng đúng bộ
>   attribute của hệ HPDQ (mục 10). Copy script này làm điểm xuất phát.
>   Giữ nguyên đủ danh sách attribute như file gốc (ép về rỗng/"0" nếu
>   không dùng) — KHÔNG được bỏ bớt/thêm attribute.
> - `zipwriter.js` / `list_zip.js` — xem mục 6.
>
> Cách dựng file bằng tay (đã dùng thành công cho ZCO07):
> - 1 script sinh `head.xml`/`hierarchy.xml`/`properties.xml` từ 1 khai báo
>   cây JS đơn giản (nodes + parent), tự tính `CHILD`/`NEXT`/`TLEVEL`. Giữ
>   nguyên đủ danh sách attribute như file gốc (ép về rỗng/"0" nếu không
>   dùng) — KHÔNG được bỏ bớt attribute, tool có thể yêu cầu đủ.
> - 1 ZIP writer tay — xem mục 6.

Quy trình khuyến nghị khi cần sửa/tạo 1 form mới:
1. Lấy 1 file `.xlsx` ZXLWB **đang hoạt động tốt** trong cùng tổ chức
   làm mẫu tham chiếu (unzip, đọc `head.xml`/`hierarchy.xml`/`properties.xml`
   để biết đúng danh sách attribute + convention header context của
   report đó — KHÔNG suy đoán khi có file mẫu thật để đọc).
2. Thiết kế cây node mới (header fields + loop + N mẫu dòng nếu cần).
3. Sinh `sheet1.xml` (layout hiển thị, style, merge) khớp đúng toạ độ
   `TB_AREA_TOP/LEFT` của từng node Pattern; ô của Field chứa chuỗi
   textmark `[FIELD]` (mục 10).
4. Đóng gói lại bằng ZIP writer đúng chuẩn (mục 6) — **không dùng
   PowerShell `Compress-Archive`**.
5. Giao cho người có Add-in Excel mở lại kiểm tra cây + chạy thử thật
   trước khi coi là xong — bản thân việc sinh XML đúng cấu trúc KHÔNG
   đảm bảo layout/style đẹp hay logic nghiệp vụ đúng 100%, chỉ đảm bảo
   file **import được**.

## 6. Bẫy đóng gói ZIP trên Windows — ĐỌC KỸ

**Không bao giờ dùng PowerShell `Compress-Archive` để tạo lại file
`.xlsx`/`.docx`/`.pptx`/bất kỳ OOXML nào sẽ bị SAP/ABAP đọc lại.** Lệnh
này tạo tên entry trong ZIP dùng dấu `\` (sai chuẩn PKZIP, spec bắt
buộc `/`) kèm entry thư mục rác nếu nguồn có folder rỗng. Windows tự
đọc lại được (khoan dung) nên **không phát hiện ra khi tự kiểm tra
bằng cách giải nén lại trên cùng máy** — nhưng ZIP reader phía SAP
(`CL_ABAP_ZIP`, chuẩn POSIX) đọc thất bại ngay từ bước mở file, báo lỗi
**"Error while reading template file" (message LP000)** khi Import
trong Tcode `ZXLWB_WORKBENCH`.

Dùng `scripts/zipwriter.js` (Node, không phụ thuộc thư viện ngoài — tự
cài CRC32 + gọi `zlib.deflateRawSync`) để đóng gói đúng chuẩn. Sau khi
đóng gói, **luôn tự kiểm tra lại central directory** (không chỉ giải
nén rồi xem file list) để xác nhận toàn bộ tên entry dùng `/`, không có
entry rác — dùng `scripts/list_zip.js` (đọc EOCD signature
`0x06054b50` → central directory `0x02014b50` → in tên từng entry).

## 7. Quy ước header context đã thấy trong tổ chức (tham khảo, KHÔNG bắt buộc theo)

Một số report cũ dùng context 2 lớp: `PARAMETER TYPE ZCORE_ST_PARAMETER`
(structure DDIC dùng chung toàn tổ chức, field đặt tên chung chung
`PARAMETER01..76`, `QUANTITY1-3`+`UOM1-3`, `AMOUNT01-08`, `SIGN01-10`,
`HEADER01-6x`, `FOOTER01-06`...) + `TABLE_DATA TYPE TABLE OF <row-struct>`.
Cách này ĐÚNG QUY ƯỚC nhưng dùng cấu trúc lồng 2 cấp — theo phân tích ở
mục 2, phần field trong `PARAMETER` **chưa được xác nhận hoạt động
đúng** qua cơ chế binding hiện tại. Khi làm mới, ưu tiên dùng structure
PHẲNG (mục 2) cho chắc chắn; chỉ theo quy ước `ZCORE_ST_PARAMETER` nếu
có bằng chứng thực tế (test được bằng Add-in thật) rằng nó hoạt động
trên hệ thống đang làm.

## 8. Gọi từ ABAP

```abap
CALL FUNCTION 'ZXLWB_CALLFORM'
  EXPORTING
    IV_FORMNAME        = <ten_form_trong_head.xml>
    IV_CONTEXT_REF     = <structure_context>
  EXCEPTIONS
    PROCESS_TERMINATED = 1
    OTHERS             = 2.
```
**Interface thật của FM chỉ có đúng 1 exception: `PROCESS_TERMINATED`.**
Nhiều report cũ trong tổ chức copy nhầm 3 tên exception không tồn tại
(`FORMATTING_ERROR`/`INTERNAL_ERROR`/`SEND_ERROR`) — ATC (Extended
Program Check/SLIN) sẽ báo lỗi này, và về logic thì `SY-SUBRC` sẽ không
bao giờ được set đúng khi có lỗi thật. Luôn dùng `GetFunction` (tra
`function_group` qua `RunQuery` trên `TFDIR` nếu cần) để xác nhận đúng
interface thật trước khi viết `EXCEPTIONS`, đừng copy nguyên từ code cũ.

**Tham số tuỳ chọn (bản 4.06, đọc source thật trên 1 hệ HPDQ 23.09.2026 — kiểm
lại bằng `GetFunction` nếu hệ khác bản):** `IV_VIEWER_SUPPRESS` (không mở viewer),
`IV_SAVE_AS` (tự `GUI_DOWNLOAD` ra máy trạm), `IV_SAVE_AS_APPSERVER` (tự
`OPEN DATASET`), `EV_DOCUMENT_RAWDATA` (trả xstring file) → không cần tự viết
code lưu file.

- **Amount ghi theo giá trị nội bộ, không quy đổi `TCURX`:** runtime gán thẳng
  `rv_value = <component>` cho field số (kể cả `CURR` có reference currency) ⇒
  amount VND (DB lưu 2 số lẻ) phải **tự quy đổi** trước khi đưa vào context,
  nếu không Excel lệch 100 lần so với màn hình. Hệ số = `10 ** ( 2 - decimals )`
  theo currency thật của field (TCURX; VND = 100, ngoại tệ 2 số lẻ = 1) — không
  hardcode 100. Field nào bị scale phải kiểm từng field (CURR gắn currency ref
  thật, hoặc class ghi có block `/= 100` tường minh), không suy theo "bảng custom".
- **`IV_SAVE_AS` không tự thêm đuôi:** `CL_GUI_FRONTEND_SERVICES=>FILE_SAVE_DIALOG`
  trả `FULLPATH` không có `.xlsx` khi user gõ tên trần, dù đã truyền
  `DEFAULT_EXTENSION` → file đúng nội dung nhưng Windows không mở bằng Excel.
  Luôn tự nối `.xlsx` sau dialog nếu thiếu.

## 9. Bẫy: Field "mồ côi" đè lên vùng khác sau khi thu gọn layout

Khi bỏ 1 Field khỏi report (vd ngừng gán giá trị 1 field ở ABAP vì chỉ
tiêu đã bỏ), **XOÁ LUÔN node Field tương ứng khỏi cây `FormParameters`**
(`hierarchy.xml` + `properties.xml`, nối lại `NEXT` của node liền trước)
— đừng chỉ dừng ở phía ABAP. Nếu chỉ bỏ gán giá trị bên ABAP mà giữ
nguyên node Field trong form, node đó vẫn tồn tại với `CB_VAL_RELPATH`
trỏ tới 1 field nay luôn rỗng, và **toạ độ `TB_AREA_TOP/LEFT` cũ của nó
vẫn được ghi đè tại runtime** — nếu sau đó thu gọn layout (dịch chuyển
Pattern khác lên lấp chỗ trống), giá trị rỗng của Field mồ côi sẽ **xoá
mất nội dung** đang ở đúng toạ độ đó. Case thật (25/09/2026, ZCO07,
`ZCO_PG_CCGTSP_EXL.xlsx`): field `RATE` (chỉ tiêu 6.2 đã bỏ) vẫn trỏ ô
`TOP=9,LEFT=3`, đúng ô sau này chứa text tiêu đề "Đơn giá thực tế" khi
khối header được thu gọn — field rỗng ghi đè lên, xoá mất chữ. Cách phát
hiện: đọc `properties.xml`, liệt kê mọi node `COMP_TYPE="F"` kèm toạ độ
`TB_AREA_TOP/LEFT`, đối chiếu xem có node nào KHÔNG còn field ABAP tương
ứng (hoặc field ABAP không còn được gán giá trị) mà toạ độ lại trùng với
1 vùng Pattern/Field khác đang dùng thật.

## 10. Ví dụ tham chiếu đầy đủ (chỉ có trên máy người làm dự án HPDQ — `CodeABAP/` không lên git)

`CodeABAP/HPDQ_ZCO07/ABAP/form zxlwb/ZCO_PG_CCGTSP_EXL.xlsx` +
`README_ZCO_PG_CCGTSP_EXL.md` cùng thư mục — form đã dựng theo đúng
skill này (context phẳng, 6 mẫu dòng điều kiện theo cờ). Ban đầu dùng
local `TYPES: BEGIN OF GTY_XLWB`, sau đó (18/09/2026) đổi hẳn sang DDIC
thật `ZCO_ST_CCGTSP_EXL`/`ZCO_TT_CCGTSP_LINE` — chỉ cần đổi
`CONTEXTNAME` trong `head.xml` + tiền tố `CB_RELPATH`/`CB_VAL_RELPATH`
tương ứng trong `properties.xml` (field name giữ nguyên), xác nhận đúng
mục 2: cơ chế binding so khớp CHUỖI tiền tố, không tra tên type ABAP
thật nên việc đổi context bên ABAP không bắt buộc phải sửa lại file
`.xlsx` (chỉ nên sửa cho đồng bộ tài liệu). Source cũ (quy ước
`ZCORE_ST_PARAMETER`) lưu ở `ZCO_PG_CCGTSP_EXL.xlsx.zco03.bak` trong
cùng thư mục để đối chiếu.

## 11. Quy tắc bắt buộc khi sinh form cho hệ HPDQ (xác nhận 23.09.2026)

Nguồn: form đang chạy của HPDQ `ZXLSX_PP_BCTDTD_2.xlsx` (export từ ZXLWB) +
source `ZXLWB_INCLUDE` / `UPLOAD_WEB_OBJECT` đọc qua MCP `GUI_HPDQ_DEV_800`.

1. **Import: đường dẫn file ≤ 128 ký tự.** Nút Import gọi FM chuẩn
   `UPLOAD_WEB_OBJECT`, chép đường dẫn vào `RLGRAP-FILENAME` (CHAR 128) rồi lấy
   đuôi sau dấu `.` cuối để tra MIME. Dài hơn → mất `.xlsx` → popup
   **"No MIME type assigned to object <path>"** và không lưu gì. Thư mục project
   `CodeABAP/<tên dài tiếng Việt>/form zxlwb/` thường đã vượt → luôn copy form
   ra Desktop trước khi import.
2. **Bộ attribute:** `properties.xml` đúng 77 attribute, `hierarchy.xml` 122 — lấy
   nguyên từ form HPDQ (xem `PROP_TPL`/`HIER_TPL` trong `build_form_v2.js`). Mẫu
   PPV dùng ở bản cũ thừa `TB_RESPATTERN_PLACE`, `TB_KEEP_FORMULAS`.
3. **Root:** `CB_RELPATH = <CONTEXTNAME>`. **Loop:** `CB_LOOP_FROM = "1 "`.
   `CONTEXTNAME` được phép là structure hoặc **table type** (form HPDQ dùng table
   type, Loop cấp đầu `CB_RELPATH = <CONTEXTNAME>`) và phải là tên DDIC đã tồn tại
   trong SE11 (xem mục 2).
4. **Field bind bằng textmark:** `CB_VAL_RELPATH = "LINE-<F>"`,
   `TB_AREA_TEXTMARK = "[<F>]"`, `TB_AREA_TOP/LEFT = 0`; ô tương ứng trong Pattern
   chứa đúng chuỗi `[<F>]` (shared string). Không đặt Field theo toạ độ.
5. **Kiểu ô trong file kết quả do style ô mẫu quyết định:** numFmtId `49` → chuỗi;
   `14..22` hoặc `165..180` → ngày (giá trị `YYYYMMDD` đổi sang số seri Excel);
   còn lại + giá trị dạng số → ô số. Định dạng số tự định nghĩa **không** dùng
   id 165..180 (dùng built-in 3 `#,##0`).
   **Chuẩn hiển thị ô ngày của team: `dd.MM.yyyy`** (quy ước user 27.09.2026).
   Đặt trong Excel: Format Cells → Category **Date** → Locale **Armenian** →
   Type **`14.03.2012`** (= `dd.MM.yyyy`, không phụ thuộc Regional setting máy).
   Bẫy bắt buộc kiểm: đây là định dạng *tự định nghĩa* → Excel/Add-in lưu với
   numFmtId ≥ 164; ZXLWB chỉ nhận ngày khi id **165..180** (id 164 → ô ra số thô
   `20260823` hiện `#######`, xác nhận 25.09.2026). Sau khi lưu form, giải nén
   kiểm `xl/styles.xml`: xf của ô ngày phải trỏ numFmtId 165..180. Nếu ra 164
   thì cho 1 định dạng tự định nghĩa khác chiếm 164 trước (VD cột số tiền dùng
   custom `#,##0;-#,##0` thay built-in 3), hoặc dùng built-in 14 (ngày ngắn theo
   máy) làm phương án dự phòng.
6. **Số sheet động:** `Root → Loop (bảng sheet) → Sheet (TB_SHEETNAME = sheet mẫu,
   CB_VAL_RELPATH = LINE-<tên sheet>) → Pattern/Loop`. Tên sheet trùng thì runtime
   tự thêm hậu tố. `CB_VAL_RELPATH` rỗng → lấy `TB_SHEETNAME` của sheet mẫu; Sheet
   có `CB_RELPATH` rỗng giữ context dòng loop cha; Sheet lồng trong Sheet bị validate
   chặn. (Xác nhận qua source `compose_process_sheet`, chưa chạy thật.)
7. Tránh `CB_VAL_CONVERT = "X"` với dữ liệu lớn: mỗi ô tạo 1 `CL_FOBU_INPUT_UTIL`.
   Làm ALPHA/format sẵn trong ABAP.
8. Kiểm tra trước khi giao: `list_zip.js` (tên entry dùng `/`), `[xml]` từng part,
   mở thử bằng Excel không hỏi repair.
9. **`Target` trong `xl/_rels/workbook.xml.rels` phải TƯƠNG ĐỐI** (`worksheets/sheet1.xml`,
   `styles.xml`...) như file do Excel lưu — **[CONFIRMED 06.10.2026, DEV BIDIPHAR]**.
   `LCL_EXCEL=>BUFFERIZATION_BASEINFO` (`ZXLWB_INCLUDE` ~4888) ghép `'/xl/' + Target`;
   Target tuyệt đối `/xl/worksheets/sheet1.xml` (openpyxl ghi kiểu này) thành
   `/xl//xl/worksheets/sheet1.xml` → `xml_load` trả rỗng → Import vẫn lưu được nhưng bấm
   Edit/Display dump `OBJECTS_OBJREF_NOT_ASSIGNED_NO` (`CX_SY_REF_IS_INITIAL`, dòng 4899
   `ZXLWB_INCLUDE`, `LV_PATH_SHEET` có chữ `/xl//xl/`). Nếu sinh form bằng openpyxl phải
   sửa lại rels (`re.sub('Target="/xl/', 'Target="', ...)`) trước khi đóng zip; mẫu code
   ở `CodeABAP/BIDIPHAR/ZAP03/zfi_pg_ap_zap03/form zxlwb/_build/build_form.py`.
10. **Sinh form bằng openpyxl 3.1.x cần hậu xử lý thêm** (ZGL04, 08.10.2026 — **[NGHI NGỜ/TODO]** chưa import thật; **15.10.2026 ZGL08: Excel báo "corrupt" với file kết quả — nghi do thiếu `xmlns:r` ở gốc `xl/workbook.xml`** (runtime xoá và tạo lại `<sheet r:id>` mà không khai báo namespace, openpyxl chỉ khai báo trên từng `<sheet>`) → khai báo `xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"` ở gốc `workbook.xml` + `sheet1.xml`; xem `_ghichu_local.md`, mục công cụ trên máy dev/ZGL04 openpyxl): openpyxl ghi chuỗi dạng `inlineStr` và ô trống `t="n"` → chuyển lại `xl/sharedStrings.xml` + `<c r= s=/>` cho giống file Excel lưu; `Target` trong `xl/_rels/workbook.xml.rels` là `worksheets/sheet1.xml`, `styles.xml`, `theme/theme1.xml`, `sharedStrings.xml` (tương đối so với `xl/`, KHÔNG phải `xl/worksheets/...`), `_rels/.rels` bỏ `/` đầu; `numFmtId` tự định nghĩa thứ 2 đổi từ 165 sang 181. Mẫu: `CodeABAP/BIDIPHAR/ZGL04/zfi_pg_gl_bclcttgt/form zxlwb/_build/build_forms.py` (kèm tự kiểm textmark/Pattern không chồng nhau). Chi tiết: `_ghichu_local.md` mục On-Premise (ZGL04).
11. **Cột ngang theo số lượng giá trị (vd mỗi Segment/Profit center 1 bộ cột)** (ZGL04 — **[NGHI NGỜ/TODO]**, theo tài liệu XLSX Workbench ví dụ 4.09 "Dynamic table"): `Loop dòng → Folder (giữ 1 dòng) → Pattern phần cố định + Loop bảng lồng (CB_RELPATH = LINE-<bảng>) → Pattern giá trị có TB_DIRECTION = X`; Pattern đặt "bên dưới" = góc trên-trái ngay dưới góc dưới-trái thành phần trước, "sang phải" = ngay cạnh góc trên-phải; trong loop mọi relpath chỉ trỏ vào dòng đang lặp nên tiêu đề cột lặp ngang phải là field của bảng tiêu đề (không dùng field gốc). `CodeABAP/BIDIPHAR/ZGL04/zfi_pg_gl_bclcttgt/form zxlwb/_build/mock_zxlwb.py` mô phỏng cách ghép để xem hình dạng (không phải runtime thật).
12. **Báo cáo có 2 kiểu cột (vd Năm | giữa niên độ) × (1 bộ cột | cột ngang) = 4 form dùng chung 1 context** (ZGL03, 08.10.2026 — **[NGHI NGỜ/TODO]** chưa import thật): script dựng theo bảng cột (`value_cols`) nên đổi số cột / thêm cột % chỉ sửa 1 chỗ (`SET_WITH_PCT`); 1 field context dùng cho nhiều ô trong cùng Pattern bằng textmark khác nhau (`[H_CUR]` / `[H_CUR2]` cùng `CB_VAL_RELPATH`); số âm trong ngoặc + 0 hiện `-` bằng định dạng ô `#,##0_);(#,##0);"-"_)` (id 164, định dạng thứ 2 → 181) — phụ thuộc ZXLWB có ghi giá trị 0 vào ô; khối đầu / khối ký của form cột ngang chỉ rộng bằng phần cố định + 1 bộ cột (không căn theo bề rộng động); script tự kiểm mọi ô `[..]` trong Pattern phải có Field. Mẫu: `CodeABAP/BIDIPHAR/ZGL03/zfi_pg_gl_bckqhdkd_mul/form zxlwb/_build/build_forms.py` (+ `mock_zxlwb.py`, xem trước qua LibreOffice → PDF → PNG).
