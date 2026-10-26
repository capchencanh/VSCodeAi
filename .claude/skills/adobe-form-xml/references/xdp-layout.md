# Layout XDP (template XFA 3.3): mẫu thật và cách afgen dựng

Nguồn: template trong 3 form mẫu (danh sách ở `xml-structure.md`). Xem nhanh 1 layout: `af_inspect.py <SFPF> --all --xdp ra.xdp`.

## Mục lục
1. Khung file XDP
2. Trang giấy
3. Bind dữ liệu — 3 kiểu
4. Đối tượng: text tĩnh, field, caption, QR, ảnh, viền
5. Bảng
6. Font, tiếng Việt, định dạng số/ngày
7. Mẫu thiết kế đúc kết từ 3 form
8. API afgen (layout)
9. Chưa hỗ trợ / chưa có mẫu

## 1. Khung file XDP

Các packet theo thứ tự: `template` → `config` → `connectionSet` → `xfa:datasets` (`xfa:data` rỗng + `dd:dataDescription`) → `localeSet` (en_US) → `x:xmpmeta`. Chỉ `template` là phần thiết kế; phần còn lại afgen chép nguyên từ mẫu, chỉ thay tên form, timeStamp, uuid.

- `config`: `<base>` = URL `.../sap/bc/fp/form/layout/` của hệ thống (chỉ Designer dùng, để trống được); `psMap` (map font in, có ở 2 mẫu) không cần.
- Gốc template: `<subform layout="tb" locale="en_US" name="data" restoreState="auto">` — tên `data` khớp gốc XML dữ liệu; con đầu tiên là `pageSet`; cuối có `<proto/>` và `<desc><text name="version">`.
- PI `<?formServer defaultPDFRenderFormat acrobat10.0dynamic?>` đầu template; các PI `<?templateDesigner ...?>` chỉ là thiết lập Designer.
- Phần tử text/field thiếu `<font>` → XFA mặc định Courier: afgen luôn ghi `<font typeface=...>`.
- Designer sắp thuộc tính A-Z, thụt 3 dấu cách; thứ tự các phần tử con dạng thuộc tính (ui, font, margin, para, border, bind...) không cố định (3 mẫu ghi lẫn lộn).

## 2. Trang giấy

`pageSet/pageArea` (id, name) chứa `contentArea` (x, y, w, h = vùng in, mm/in) và `medium`:

| Trường hợp | `medium` | Nguồn |
|---|---|---|
| Letter (mặc định SAP cho form mới) | `stock="letter" short="8.5in" long="11in"` | ủy nhiệm chi |
| A4 dọc | `stock="a4" short="210mm" long="297mm"` | chuẩn XFA, chưa có mẫu |
| A4 ngang | thêm `orientation="landscape"` | chưa có mẫu |
| Tem/khổ riêng | `stock="custom" short=<RỘNG> long=<CAO>` — short là chiều rộng kể cả khi lớn hơn long (tem 80×40: `short="80mm" long="40mm"`) | 2 tem |

Đối tượng đặt thẳng trong `pageArea` in lặp mọi trang (ủy nhiệm chi: ảnh PNG nền 203.2×266.7 mm). Chỉ đặt đối tượng tĩnh ở đây.

## 3. Bind dữ liệu — 3 kiểu

Subform gốc `data` bind theo tên vào `<data>`. `<bind match="none"/>` = khung trong suốt, giữ phạm vi dữ liệu của cha. `<bind match="dataRef" ref="..."/>` = bind tường minh; `$` = node dữ liệu của tổ tiên gần nhất đã bind.

| Kiểu | Nguồn | Cấu trúc |
|---|---|---|
| A. Tem: 1 dòng = 1 tem/trang | 2 tem | `subformSet name="DATA"` + `<occur max="-1"/>` → `subform Subform1` (vị trí cố định, h ≈ contentArea, bind none) → field `$.DATA.DATA[*].MATNR` (tuyệt đối) |
| B. Chứng từ lặp theo dòng | ủy nhiệm chi | `subform layout="tb"` bind `$.GT_DATA.DATA[*]` + `<occur max="-1"/>` → các subform con bind none → field `$.ACC_NAME_S` (tương đối) |
| C. Header 1 dòng + bảng item | afgen, **chưa có mẫu** | field `$.GT_HDR.DATA[0].SOCT`; dòng bảng bind `$.GT_ITEM.DATA[*]` + occur -1, ô `$.MATNR` |

- afgen `repeat()` = kiểu B; bên trong đặt 1 `block` cao bằng contentArea thì cho kết quả như kiểu A (mỗi dòng sang trang mới, không cần page break).
- Trong `repeat()`/dòng bảng, `$` là dòng hiện tại → node nằm ở gốc dữ liệu (graphic, bảng khác) phải viết `$record.GRAPHIC`, `$record.GT_HDR.DATA[0].X` (SOM chuẩn, chưa có mẫu); hoặc đặt đối tượng ra ngoài khung lặp. `af_validate` báo lỗi khi ref không tới được node nào.
- 1 node bind cho nhiều field: ủy nhiệm chi bind `$.ACC_NO_S` ở 2 field ("Số tài khoản trích nợ" và "Phí thu từ tài khoản") — mẫu có dùng, chưa xem bản in.
- Field `bind match="none"`: ô trống có caption để viết tay (ủy nhiệm chi: "Tỷ giá", "Số CCCD"...).
- Field dữ liệu không đưa lên layout không sao (ủy nhiệm chi dùng 14/37 field, tem LSX bỏ 7).
- `<value>` trong field có bind ở mẫu (VD `5000000001`) chỉ là dữ liệu xem thử của Designer; afgen không ghi để tránh in ra giá trị giả khi thiếu dữ liệu.

## 4. Đối tượng

**Text tĩnh** (`draw`): `ui/textEdit` + `value/text` + `font` + `margin` (mẫu 0.5mm) + `para` (`hAlign` left|center|right, `vAlign` top|middle|bottom). Nhiều dòng hoặc định dạng trong dòng → `value/exData contentType="text/html"` với `<body xmlns="http://www.w3.org/1999/xhtml"><p>..</p></body>`; span mẫu dùng: `font-weight:bold|normal`, `font-style:italic`, `xfa-spacerun:yes` (giữ dấu cách).

**Field** (`field`): `ui/textEdit` chứa `<border presence="hidden"/><margin/>` để in ra như chữ thường; `multiLine="1"` cho phép xuống dòng; `font`, `margin` (mẫu 1mm hoặc 0.5mm), `para`, `bind`. Kích thước cố định `h`; trong ô bảng không ghi `w` (rộng theo cột).

**Caption** (nhãn trái của field): `<caption reserve="22.8mm">` (= rộng phần nhãn) + `value` + `font` + `para`. Nhãn song ngữ ủy nhiệm chi: `Tên tài khoản trích nợ/<span style="font-weight:normal;font-style:italic">Dr A/C name:</span>` → afgen: `caption='Tên tài khoản trích nợ/<ni>Dr A/C name:</ni>'`.

**QR code**: `field access="readOnly"` + `ui/barcode type="QRCode" dataLength="26" errorCorrectionLevel="3" moduleWidth="0.03in" moduleHeight="0.03in"` (mẫu: ô 35.4 và 41.3 mm, module 0.03/0.041 in). QR lớn lên theo độ dài dữ liệu → ô phải đủ chỗ cho dữ liệu dài nhất; test với dữ liệu thật.

**Ảnh tĩnh** (logo cố định, nền): `draw` + `value/image contentType="image/png" aspect=".."` (base64 76 ký tự/dòng) + `ui/imageEdit` (+ `desc/text name="embeddedHref"` = đường dẫn file gốc, bỏ được). Có mẫu.

**Ảnh động** (graphic node, VD logo SE78): `field` + `ui/imageEdit` + bind `$.GRAPHIC` — **chưa có mẫu** (tem LSX có graphic node nhưng layout không dùng). Logo cố định → ưu tiên ảnh tĩnh.

**Viền / nền**: ẩn `<border><edge presence="hidden"/></border>`; kẻ 4 cạnh `<edge thickness="0.254mm"/><corner thickness="0.254mm"/>`; kẻ từng cạnh = 4 `edge` theo thứ tự trên-phải-dưới-trái (cạnh ẩn `presence="hidden"`); nền `<fill><color value="176,234,217"/></fill>` trong `border`.

## 5. Bảng

Bảng Designer = `subform layout="table" columnWidths="20mm 80mm ..."` → các `subform layout="row"` (`assist role="TR"`, dòng tiêu đề `TH`) → mỗi ô 1 `draw`/`field`, thứ tự ô = thứ tự cột. Tem LSX dùng bảng tĩnh lồng bảng (mọi viền ẩn) để căn chỉnh, `keep intact="contentArea"` (không ngắt trang).

afgen `table()`: dòng tiêu đề (draw) + dòng dữ liệu bind `$.<T>.DATA[*]` + `occur max="-1"` + dòng cuối tuỳ chọn, `keep intact="none"` để tự sang trang. Bảng phải nằm trong khung chảy (gốc `data`, `flow()`, `repeat()`), không đặt trong `block()` vị trí cố định. **Chưa có mẫu bảng lặp**; tiêu đề bảng lặp lại mỗi trang chưa hỗ trợ (tick "Include Header Row in Subsequent Pages" trong Designer sau khi upload).

## 6. Font, tiếng Việt, định dạng số/ngày

- Font trong mẫu: Times New Roman (tem barcode, ủy nhiệm chi), Arial (tem LSX); chữ Việt ghi thẳng UTF-8 (`Khách Hàng:`, `Số Lô:`). `af_validate` cảnh báo font khác 2 font này → xác nhận ADS có font trước khi dùng.
- `locale="en_US"` giữ nguyên. Cả 3 mẫu **không** dùng display pattern, không script: số tiền, số lượng, ngày đều định dạng sẵn trong ABAP thành CHAR (ủy nhiệm chi có cả `WRBTR` lẫn `AMOUNT` và `AMOUNT_IN_WORDS`).

## 7. Mẫu thiết kế đúc kết từ 3 form

- 1 tham số bảng, 1 dòng = 1 tem/chứng từ, mọi thông tin header nằm phẳng trong dòng; form không chứa logic.
- Tem: subform vị trí cố định cao ≈ contentArea → mỗi dòng 1 tem, máy in tem tự cắt theo khổ `custom`.
- Chứng từ mẫu ngân hàng: ảnh scan mẫu làm nền master page, field đặt chồng; nhãn song ngữ VN/EN bằng rich text.
- Nhãn + giá trị cùng 1 field (caption) thay vì text + field rời — dễ căn hàng.

## 8. API afgen (layout)

Đơn vị mm; `x/y` = vị trí trong khung cha vị trí cố định (bỏ khi khung cha là `flow`/`repeat`/bảng). Text dùng thẻ rút gọn: `<b>` đậm, `<i>` nghiêng, `<bi>`, `<n>` thường, `<ni>` thường nghiêng, `\n` xuống dòng.

| Hàm | Sinh ra |
|---|---|
| `page(size='A4', landscape=False, margin=10, kids=())` | pageArea; `size` 'A4'/'A5'/'A3'/'LETTER' hoặc `(rộng, cao)` cho tem; `margin` số hoặc (trên, phải, dưới, trái); `kids` = đối tượng tĩnh mọi trang |
| `text(value, x, y, w, h, size, bold, font, align, valign, border, fill)` | draw text tĩnh |
| `field(ref, x, y, w, h, caption, caption_w, size, bold, font, align, valign='middle', multiline, grow, border, fill)` | text field; `ref` 'FIELD' (tương đối) hoặc '$.T.DATA[0].FIELD'; `grow=True` cao theo nội dung (**chưa có mẫu**, sinh `minH`) |
| `qrcode(ref, data_length, x, y, size=30, ecc=3, module='0.03in')` | QR code |
| `image(path, x, y, w, h, aspect='fit')` | ảnh tĩnh nhúng (png/jpg/bmp/gif) |
| `image_field(ref, x, y, w, h)` | ảnh động từ graphic node (**chưa có mẫu**) |
| `block(kids, x, y, w, h, name, border, fill)` | subform vị trí cố định, bind none |
| `flow(kids, w, name, direction='tb'/'lr-tb')` | subform chảy, bind none |
| `repeat(table, kids, w, h, name, flowed=True)` | subform lặp mỗi dòng của `table` |
| `table(data, columns, row_h=6, size, header_fill, grid=True, footer, grow)` | bảng; `columns=[(rộng, 'Tiêu đề', 'FIELD'|None, align)]`; `footer` cùng số cột: None / 'text' / '$.ref' / (giá trị, align) |
| `Form.layout(pages, content, font='Arial', base_url='')` | ráp XDP; `content` = list phần tử dưới gốc `data` (chảy trên → dưới) |
| `inject_layout(src, dst, pages, content, font)` | thay template trong SFPF tải từ SAP |

## 9. Chưa hỗ trợ / chưa có mẫu

Script FormCalc/JavaScript, "Trang x/y", ẩn/hiện theo dữ liệu (`presence`), display pattern số/ngày, tiêu đề bảng lặp mỗi trang, gộp ô (colSpan), đường kẻ `line`/`rectangle` (dùng viền thay thế), barcode 1D (Code128...), field bind dữ liệu trong master page, nhiều pageArea. Cách mở rộng: làm tính năng đó trong Designer trên 1 form thử, Download, đọc bằng `af_inspect.py --xdp`, rồi thêm hàm vào afgen + bổ sung `SEEN_VOCAB` và mục này.
