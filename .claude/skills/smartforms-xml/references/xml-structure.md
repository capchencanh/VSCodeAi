# Cấu trúc XML Smart Form và mẫu thiết kế

Nguồn: file export thật `examples/zmm_sf_pxkpg_doc.xml` (trong skill) (form `ZMM_SF_PXKPG_DOC`, hệ HPDQ, style `ZCORE_STYLE_REPORT`). `sfgen.py` tái tạo đúng các khối dưới đây.

## Trạng thái xác nhận

| Nội dung | Trạng thái |
|---|---|
| Cấu trúc thẻ, thứ tự con, ý nghĩa node | Đọc từ form export thật (24.09.2026) |
| Form sinh bằng `sfgen.py` upload + activate trên SAP | **ĐÃ CHẠY THẬT (30.09.2026)** — `ZSF_SD_BKBLHHDV` (BDP DEV/200): upload → activate → in preview ra đúng bố cục, tiền, tiếng Việt |
| Bố cục "tất cả trong 1 table" (Header event = khối đầu + tiêu đề cột; Main = dòng; Footer = khối cộng + chữ ký) | Đã chạy thật, ra khung liền mạch giống mẫu FS (30.09.2026) |
| Ý nghĩa chính xác cờ `OCOND` `FOOTER`, `OTABHEADER=A` | Suy từ cách form mẫu dùng, chưa đối chiếu tài liệu SAP |
| 2 table liên tiếp trong cùng window `MAIN` (table 1 lặp `IT_ITEM`, table 2 lặp `IT_TAX` để in mỗi mức thuế 1 dòng + khối cuối ở Footer của table 2) | Sinh được, `sf_validate` PASS (14.10.2026, ZSF_SD_BKBLHHDV theo FS mới); **chưa upload/preview thật** — kiểm khối Footer không lặp mỗi trang khi bảng dài |
| `sf_validate.py` FAIL "Tag không có trong form mẫu" | Do form mẫu thiếu thẻ mà script dùng (`COND/COP/OP1` khi có điều kiện so sánh; `CODE/PLIST` khi có code node), không phải lỗi cấu trúc → chọn form mẫu có đủ (vd `CodeABAP/BDP/ZWM01/Smartforms/FS_v1.0/ZWM_SF_PYCVT.xml`) hoặc thử lần lượt các form mẫu đã activate |

## Bẫy thường gặp khi form in ra sai (đúc kết 30.09.2026, form ZSF_SD_BKBLHHDV)

| Triệu chứng trên preview | Nguyên nhân | Xử lý |
|---|---|---|
| Số/tiền rơi xuống DÒNG DƯỚI, dòng cao gấp đôi | Symbol CURR/QUAN xuất kèm khoảng trắng đệm bằng độ rộng field, ô hẹp không chứa nổi | thêm `(C)` vào symbol: `&GS_ITEM-NETWR(C)&`. **Không phải lỗi định dạng đoạn** |
| Ngày ra "TU NGAY 20 THANG 8. NAM 01.0" | `&DATE+6(2)&` cắt trên chuỗi ĐÃ format dd.mm.yyyy, không phải YYYYMMDD | code node tách `gv_d = date+6(2)`, `gv_m = date+4(2)`, `gv_y = date(4)` rồi in `&GV_D&` |
| `Reference field GS_ITEM-<F> unknown in form` | Field CURR/QUAN tham chiếu currency/unit sang **structure khác** | trường tham chiếu (`WAERK`/`MEINS`) phải nằm **trong cùng structure**; sửa DDIC xong phải **activate lại form** |
| Cột đơn vị in `***` + `BM302 No language-specific unit...` | Đơn vị chưa khai ở CUNI kèm tên theo ngôn ngữ (`T006A`) | không phải lỗi form; mã đơn vị lấy từ ví dụ FS không tự tồn tại trên hệ |
| Chữ tiếng Việt thành `#` (chỉ ký tự ngoài Latin-1: Ư Ơ Ả Ị Ụ Ă Đ) | Thiết bị in sai loại | SPAD: Device type `SWINCF`, Access method `G`, Host printer `__DEFAULT`. Cùng tên `LP01` nhưng mỗi hệ gán loại khác nhau |
| Logo quá nhỏ / quá to | `RESOLUTION` của node Graphic không khớp DPI ảnh nạp ở SE78 | ảnh 100 DPI thì node để `0100` (mặc định `sfgen` là `0600`) |
| Thuế suất % in thành `0` hoặc số nhân 100 | Field % khai kiểu tiền (CURR) có currency reference; VND 0 số lẻ | thuế suất dùng DEC, **không** khai currency reference |
| Sau upload, Form Builder báo cảnh báo vàng `Field GV_X has no defined value` (form vẫn `Active`) | Biến gán trong code node nằm **trong ô bảng** mà Form Builder không theo dõi được; biến gán ở code node cấp event (VD `GV_FD`) thì không bị | cảnh báo, không chặn; muốn hết thì khai `Default Value` cho biến (`gdata` 4 phần tử `('GV_X','TYPE','CHAR10',"' '")`, số thì `"0"`). Cũng nên dùng biến thay vì symbol trực tiếp `&GS_TAX-TAXAMT(C)&` ở table thứ 2 (code node: `WRITE ... TO gv CURRENCY ...` + `CONDENSE`). **[CONFIRMED 14.10.2026]** upload lại bản có Default Value (ZSF_SD_BKBLHHDV), user báo OK |

## Khung file

1 dòng, UTF-8 không BOM. Phần tử cấu trúc có prefix `sf:` (ns `urn:sap-com:SmartForms:2000:internal-structure`), thuộc tính ở ns mặc định (`urn:sap-com:sdixml-ifr:2000`).

```
sf:SMARTFORM
├─ HEADER      FORMNAME, CAPTION, MASTERLANG, LANGVECTOR, DEVCLASS, VERSION, FIRSTUSER/DATE/TIME, LASTUSER/DATE/TIME
├─ INTERFACE   item: IOTYPE (E export chuẩn | I import | X exception | T tables), NAME, TYPING (TYPE/LIKE), TYPENAME,
│              OPTIONAL, BYVALUE, DEFAULTVAL, STANDARD (=X với tham số SAP tự thêm)
├─ GDATA       item: NAME, TYPING, TYPENAME  (Global Definitions → Global Data)
├─ GCODING     item = dòng code Initialization;  FCODING  item = dòng Form Routines
└─ sf:VARHEADER/sf:item: PAGEFORMAT, CPI, LPI, STDSTYLE, sf:PAGETREE
      └─ sf:NODE RP → sf:SUCC → sf:NODE PA (page) → sf:SUCC → các sf:NODE WI (window)
```

Tham số TABLES: `LIKE <structure>` hoặc `TYPE <table type>` đều được form mẫu dùng.

## Node

Mỗi node: `sf:NODE` = `NODETYPE` → `sf:OBJ` (1 đối tượng) → [`sf:OUTATTR`] → [`sf:COND`] → `sf:SUCC` (con: mỗi con bọc trong `sf:item`; không có con = `<sf:SUCC/>`). Mỗi đối tượng có `NAME/INAME` duy nhất và `T_CAPTION` (LANGU, FORMNAME, OBJTYPE, INAME, CAPTION).

| NODETYPE | Đối tượng | Ghi chú |
|---|---|---|
| `RP` | — | gốc cây trang |
| `PA` | `sf:PAGE` | `NEXTPAGE`, `PAGEORTN` P/L |
| `WI` | `sf:WINDOW` | `WTYPE` M (MAIN, INAME `MAIN`) / T (phụ); nội dung trong `sf:PROC_CTRL/sf:NODE RC`; vị trí ở `OUTATTR` (`WLEFT/WWIDTH/WTOP/WHEIGHT`, cm) |
| `SE` | `sf:SECTION` | `SECTTYPE`: `F` folder, `C` table, `R` row, `E` cell |
| `EV` | `sf:EVENT` | con trực tiếp của table: `EVTYPE` H (Header), B (Main Area), F (Footer) |
| `TI` | `sf:TEXT` | text; `NOLANGUAGE=X` thì không cần `T_TEXT` |
| `CO` | `sf:CODE` | `PLIST` (OPD, OUTIN I/O) + `CODE` (mỗi item 1 dòng) |
| `GR` | `sf:GRAPHIC` | `GKEYBDS/NAME` = tên BMP hoặc `&GS_PARA-LOGO&` |

`OUTATTR` có ở: window, row (kèm `T_LINETYPE`), cell, folder khi cần `PROTECT=X` (giữ khối không bị ngắt trang). Table và event không có `OUTATTR`.

## Table

`sf:SECTION` `SECTTYPE=C`:
- Lặp dữ liệu: `DATATYPE=L`, `TABNAME` (bảng interface), `TABHEADER` (work area, khai trong GDATA), `USEBORDER=X`. Table không có `DATATYPE` = chỉ dùng để dàn trang (khối chữ ký).
- `WIDTH` table; `DYNLINES` = danh sách line type (item đầu có `DEFAULTVAL=X`); `CELLS` = mỗi cột của mỗi line type 1 item: `NAME` (line type), `COLUMNNR`, `CWIDTH`, `BORDERS/item`: `LLEFT/LTOP/LRIGHT/LBOTTOM` (`15.00` TW = kẻ, `0.00` = không) + `CLEFT/CTOP/CRIGHT/CBOTTOM` có `USED=X` khi cạnh đó kẻ.
- Row (`SECTTYPE=R`) chọn line type qua `OUTATTR/T_LINETYPE`; cell (`SECTTYPE=E`) không khai số cột — thứ tự cell = thứ tự cột.

## Điều kiện (`sf:COND/sf:CONDITION`)

- So sánh: `COND/item` gồm `COP` (EQ/NE), `OP1`, `OP2` (chuỗi có nháy `'X'`, số trơn `0`), `ICON`; từ item 2 thêm `LOP=AND` ở đầu.
- Cờ sự kiện `OCOND`: `FPAGE` = chỉ trang đầu; form mẫu dùng `FOOTER` cho khối chữ ký trong Footer của table không dữ liệu, `PAGEBREAK`+`HEADER` cho phần chỉ in sau ngắt trang.

## Text

`TEXT/item`: `TDFORMAT` (định dạng đoạn của style: `C` giữa, `L` trái, `R` phải, `*` mặc định) + `TDLINE`. Mỗi item là 1 đoạn/dòng. **Dòng trống** = item chỉ có `<TDFORMAT>*</TDFORMAT>` (dùng để chừa chỗ cho logo window đè lên).

Trong `TDLINE`: `<B0>...</>` định dạng ký tự; `&GS-FIELD(opt)&` biến. Option đã dùng: `C` bỏ khoảng trắng thừa, `Z` bỏ số 0 đầu, `I` không in khi giá trị initial, `<` dấu bên trái. Ngày in theo định dạng user (dd.mm.yyyy). Conversion exit (MATNR, ALPHA, CUNIT) tự áp.

Style `ZCORE_STYLE_REPORT` (đọc từ file style XML thật, 30.09.2026) — ký tự: `B0` đậm **10**, `B1` đậm **11**, `B2` đậm **12**, `B5` đậm **15**, `B9` đậm 9, `N0` thường 10, `N1` thường 11, `Z2` barcode. Chọn theo cỡ chữ FS, đừng đoán theo tên. **Symbol số/tiền trong ô bảng luôn thêm `(C)`** (bỏ khoảng trắng đệm, không thì rơi xuống dòng dưới). Chưa thấy định dạng nghiêng.

**Độ rộng cột chứa số/mã (đo trên preview PDF, ZWM03 23/10/2026): font 10 ≈ 0,19 cm/ký tự + lề ô ≈ 0,16 cm** ⇒ số 10 chữ số (EBELN) cần cột ≥ 2,1 cm, số lô ≤ 10 ký tự ≥ 2,2 cm, ngày dd.mm.yyyy ≥ 1,9 cm, header "STT" ≥ 1,0 cm; cột nhỏ hơn thì số rớt dòng ("410000017/1"). Cột số giữ đủ rộng trước, cột chữ (tên hàng, quy cách…) chia phần còn lại. Row sát nhau: preview PDF vẽ đường viền bảng đè lên dòng chữ liền kề ⇒ chèn 1 row đệm (text trống) trước và sau bảng.

**Logo cạnh khối chữ (ZWM03 23/10/2026)**: ô Graphic và ô Text cùng canh mép trên ô; logo `FES_LOGO` là ảnh vuông 505×505 px (2,14 cm ở 600 dpi) với chữ logo nằm giữa ảnh ⇒ khối chữ 3 dòng trông bị lệch lên so với logo. Chỉnh bằng 1 dòng trống ở đầu ô chữ (`sf.text([('*', None)], cnd=EQ HEADER39 ' ')`, chỉ khi không in song ngữ); khối 5 dòng (song ngữ) đã bằng chiều cao logo nên không thêm. Graphic không có căn dọc, resolution hợp lệ chỉ 100/300/600 nên không thu nhỏ logo được.

**Bảng chi tiết (ZWM04/05/07, 24/10/2026, user chụp preview)**: (1) cột STT rộng 0,8 cm làm chữ "STT" in đậm rớt dòng thành "ST/T" ⇒ cột STT tối thiểu **1,0 cm** (bớt 0,2 cm ở cột Tên hàng để tổng vẫn bằng W). (2) Preview PDF vẽ viền bảng đè lên dòng thông tin ngay phía trên ⇒ thêm 1 row đệm trống (linetype 1 ô `NT`, `sf.text([('*', None)])`) vào cuối folder thông tin đầu phiếu, và 1 row đệm tương tự ở đầu folder chữ ký/chú thích dưới bảng (cách làm sẵn ở `ZWM03/Smartforms/gen_zwm_sf_pnk.py`: `row_gap_head`, `row_gap_foot`).

## Mẫu thiết kế của team (form HPDQ)

- **1 page, header nằm trong Header event của table chính**: folder điều kiện `FPAGE` chứa logo/tên công ty/tiêu đề/ngày (chỉ trang đầu); row tiêu đề cột đặt ngoài folder đó → lặp lại mỗi trang.
- **Logo**: window phụ (`WTYPE=T`, điều kiện `FPAGE`) đè lên row đầu của table; row đó chừa chỗ bằng text nhiều dòng trống.
- **Dòng tổng**: chương trình append 1 dòng `LEVEL=2` vào bảng; row chi tiết điều kiện `LEVEL = 1`, row tổng `LEVEL = 2` (chỉ in cột tổng, các field khác của dòng đó là rác từ dòng cuối).
- **Số lượng bỏ phần thập phân khi chẵn**: code node `IF FLOOR( x ) = x. gv_int = x. ELSE. CLEAR gv_int. ENDIF.` (gv_int kiểu `I`), rồi 2 text: `&GV_INT(<ZC)&` khi `GV_INT NE 0`, `&X(<ZC)&` khi `GV_INT EQ 0`.
- **Chữ ký**: table thứ 2 không dữ liệu, Footer event → folder `PROTECT=X` + `OCOND FOOTER` → row dòng trống + row chữ ký (mỗi ô: `<B0>Chức danh</>` + dòng "Ký ghi rõ họ tên").
- **Dòng phụ chỉ in khi có dữ liệu**: tách thành text riêng có điều kiện `FIELD NE ' '` thay vì để dòng trống trong cùng text.

## API `sfgen.py`

| Hàm | Tạo |
|---|---|
| `SF(formname, caption, devclass, user, style, now)` | đối tượng form, tự đánh số `%TEXTn`, `%ROWn`... |
| `cond(items=[(COP, OP1, OP2)], ocond=['FPAGE'])` | chuỗi điều kiện, truyền vào `cnd=` |
| `folder(caption, children, cnd, protect)` | folder |
| `table(caption, width, linetypes, events, tabname, tabheader, cnd)` | table; `linetypes=[(TEN, [(rong_cm, (trai, tren, phai, duoi))])]`, hằng `ALL`/`NONE` |
| `event(caption, 'H'/'B'/'F', children)` | event của table |
| `row(caption, linetype, cells, cnd)` / `cell(caption, children)` | dòng / ô |
| `text([(TDFORMAT, TDLINE hoặc None)], cnd, caption)` | text |
| `code(caption, inputs, outputs, lines)` | program lines |
| `graphic(name_expr, caption, alignment)` | ảnh BMP |
| `window(iname, caption, 'M'/'T', content, (left, width, top, height), wid, cnd)` | window; `wid` số nguyên khác nhau cho mỗi window |
| `render(interface=[(IOTYPE, NAME, TYPING, TYPENAME)], gdata=[(NAME, TYPING, TYPENAME)], windows, orientation)` | chuỗi XML; tham số chuẩn SAP tự thêm |

Thứ tự gọi hàm quyết định số thứ tự `%...n` (đối số được tạo trước node cha) — không ảnh hưởng hoạt động, chỉ ảnh hưởng tên hiển thị.

## Sửa form đã có file export thật (vá thay vì sinh lại)

Form đích đã có file export của hệ thống và chỉ cần đổi cột/chữ/khung: **vá XML bằng `lxml`** (mẫu: `CodeABAP/BIDIPHAR/ZGL04/Smartforms/patch_zfi_sf_gl_bclcttgt.py`, ZGL04 08.10.2026) — giữ nguyên style từng text (có form dùng `ZST_REP` khác `STDSTYLE`), đơn vị viền `MM`/`TW`, `PROTECT` của line type… mà `sfgen.py` không tái tạo. Kiểm bằng `sf_validate.py <file vá> <file gốc>` (PASS) + `sf_inspect.py`. Bẫy: text **không** có `NOLANGUAGE=X` còn bản sao `T_TEXT` (SPRAS/TXTYPE/FORMNAME/INAME/LINENR/TDFORMAT/TDLINE) → sửa `TEXT` phải sửa cả `T_TEXT` (hoặc chuyển `NOLANGUAGE=X` và bỏ `T_TEXT`); nhân bản node phải đổi mọi `INAME` (`NAME` + `T_CAPTION`, `OUTATTR`, `CONDITION`) và tên ≤ 30 ký tự; đổi số cột line type thì sửa `CELLS` (đánh lại `COLUMNNR`) lẫn mọi row dùng line type đó; ~~`sf_inspect.py` lỗi `NoneType` nếu form không có `GCODING`/`FCODING`~~ (đã sửa 09.10.2026). **[NGHI NGỜ/TODO]** chưa upload/activate file vá lên SAP.

Tái xác nhận ZGL03 (08.10.2026, 2 form Năm + giữa niên độ, `CodeABAP/BIDIPHAR/ZGL03/Smartforms/patch_zfi_sf_gl_bckqhdkd_mul.py`): file export gốc có **cell (SE) và text (TI) trùng INAME** (`ISO`, `TITLE_REPORT`, `HEADER_*`…) → `find()` phải lọc theo `NODETYPE`, `clone()` phải đổi tên theo khóa (tên cũ, loại đối tượng) để không nhân thêm chỗ trùng; `sf_validate.py` báo FAIL vì trùng INAME có sẵn trong file gốc (chạy gốc với chính nó cũng FAIL) → so với bản gốc, đừng đòi PASS; text có `CAPTION` + `T_TEXT` khi chuyển `NOLANGUAGE=X` phải bỏ luôn `CAPTION` (cả trong `T_CAPTION`) để giữ đúng thứ tự con đã có; đổi hướng trang = `PAGEORTN` của object `sf:PAGE` + toạ độ window; bỏ điều kiện "First page" = xóa `sf:COND` của row.
