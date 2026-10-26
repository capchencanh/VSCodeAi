---
name: adobe-form-xml
description: 'Sinh/đọc file XML Adobe Form trên SAP GUI On-Premise (SFP → Utilities → Upload/Download: SFPI_<interface>.XML, SFPF_<form>.XML gồm context + layout XDP base64) bằng thư viện afgen.py, kèm code ABAP gọi form (FP_JOB_OPEN, FP_FUNCTION_MODULE_NAME). TRIGGER — chỉ đọc khi (1) thiết kế mới/sửa 1 Adobe Form (SFP, Adobe LiveCycle Designer) để upload dạng XML; (2) đọc/phân tích 1 file SFPF_*.XML hoặc SFPI_*.XML đã download (context, layout, bind); (3) viết/sửa chương trình in Adobe Form bằng FP_JOB_OPEN/FP_FUNCTION_MODULE_NAME. SKIP — không đọc khi: làm Smart Forms (dùng `smartforms-xml`), xuất Excel ZXLWB (dùng `zxlwb-workbench`), form in S/4HANA Public Cloud (Maintain Form Templates), hỏi cú pháp ABAP chung, tra cứu object không liên quan form in.'
---

# Adobe Form (SFP) dạng XML — thiết kế, sinh, kiểm tra

1 Adobe Form = 2 object, mỗi object 1 file XML (SFP → Utilities → Upload/Download):
- `SFPI_<INTERFACE>.XML` — interface: tham số import, global data, code Initialization.
- `SFPF_<FORM>.XML` — form: tên interface + context + layout XDP (XFA 3.3) nén base64 trong 1 thẻ.

Sinh bằng script Python dùng [`scripts/afgen.py`](scripts/afgen.py), không viết tay: file nằm trên 1 dòng, layout là base64, heap asXML phải đúng tham chiếu. Chạy mọi script bằng `PYTHONUTF8=1 python <script>` (Windows mặc định cp1252 làm vỡ tiếng Việt).

**Trạng thái:** afgen đọc rồi sinh lại khớp từng byte 6 file export thật. Upload thử (07.10.2026, 1 hệ S/4 816): **SFPI upload + activate OK**; **SFPF chưa qua được vì hệ đó chưa có ADS** (upload form gọi ADS, báo "Internal error occurred in SAFP API") → layout/context chưa được kiểm chứng đầy đủ — bàn giao phải nói rõ. **Trước khi đưa user upload form: hỏi/kiểm hệ thống đích đã có ADS chưa** (RFC destination `ADS` trong SM59, report `FP_PDF_TEST_00`); chưa có thì dừng, đề xuất Basis cấu hình hoặc dùng Smart Form. Bảng chi tiết: mục 1-2 [`references/xml-structure.md`](references/xml-structure.md).

| Tài liệu | Đọc khi |
|---|---|
| [`references/xml-structure.md`](references/xml-structure.md) | cấu trúc SFPI/SFPF, node context, CACHE_INFO, trạng thái xác nhận |
| [`references/xdp-layout.md`](references/xdp-layout.md) | thiết kế layout: trang, bind, text/field/QR/ảnh/bảng, font, API afgen |
| [`references/abap-call.md`](references/abap-call.md) | chương trình gọi form, chuẩn bị dữ liệu, logo SE78 |

## Quy trình tạo form mới

### 1. Gom đầu vào

- **Mẫu in** (FS Excel/ảnh/PDF): lấy bản thay đổi mới nhất; ảnh chèn trong `.xlsx` lấy ở `xl/media/` sau khi giải nén.
- **Cấu trúc dữ liệu**: table type + line type DDIC của từng tham số interface, **đủ field, đúng thứ tự SE11** (MCP server `GUI_*` nếu có, không thì user dán danh sách field). Chưa có DDIC → đề xuất structure với field CHAR/STRING đã định dạng sẵn để user tạo trong SE11 trước.
- **Chương trình gọi form** (nếu đã có): tên tham số truyền vào FM form phải trùng tên tham số interface.
- **Form của team trên cùng hệ thống** (tuỳ chọn): `af_inspect.py` để lấy base URL, font, quy ước đặt tên.

Xong khi: mọi ô trên mẫu in gắn được với 1 field dữ liệu hoặc 1 text tĩnh; field còn thiếu được liệt kê để sửa DDIC/chương trình.

### 2. Chọn kiểu dữ liệu và cách sinh

| Tình huống | Interface + context | Layout |
|---|---|---|
| Tem/nhãn, 1 dòng = 1 tem (như 2 tem mẫu) | 1 tham số bảng | `repeat(T, [block(..., h = cao contentArea)])` |
| Chứng từ không có bảng item, 1 dòng = 1 chứng từ (như ủy nhiệm chi) | 1 tham số bảng | `repeat(T, [block(...), ...])` |
| Chứng từ có bảng item, 1 lần gọi = 1 chứng từ | 2 tham số bảng: `GT_HDR` (1 dòng) + `GT_ITEM` | field `'$.GT_HDR.DATA[0].X'` + `table('GT_ITEM', ...)` |
| Cần node chưa có mẫu (structure, field đơn, text module, address, điều kiện...) | user tạo interface + context bằng SFP, mở tab Layout 1 lần, Save, Download SFPF | `inject_layout(src, dst, ...)` |

Chỉ dòng cuối cần user thao tác SFP trước; 3 dòng đầu afgen sinh cả 2 file.

### 3. Viết script sinh

Đặt `gen_<form>.py` trong thư mục project (VD `CodeABAP/<project>/adobe/`), chép khung [`scripts/example_demo.py`](scripts/example_demo.py) (tem QR + phiếu A4 có bảng). Chốt trước:
- Khổ giấy + lề: `page('A4', margin=10)`; tem `page((rộng, cao), margin=0)`; toạ độ mm.
- Tên form/interface theo quy ước dự án (mẫu: `ZAF_*`/`ZIF_*`, `ZFI_AF_*`/`ZFI_IF_*`) — chưa rõ thì hỏi user.
- `Form.loop(T, fields)`: toàn bộ field của line type đúng thứ tự, kể cả field không in.
- Code Initialization: `init_code(lines, user=<tên trong UserName.md>)` để có marker add begin/end theo `CLAUDE.md`.
- Font Arial / Times New Roman (đã dùng trong mẫu); font khác phải xác nhận ADS có font.
- Chỉ dùng tính năng có mẫu khi được; tính năng ở mục 9 `xdp-layout.md` → để user làm trong Designer sau khi upload.

### 4. Sinh và kiểm tra

```
python gen_<form>.py
python <skill>/scripts/af_validate.py SFPF_<FORM>.XML SFPI_<INTERFACE>.XML
python <skill>/scripts/af_inspect.py SFPF_<FORM>.XML --all
```

Xong khi `af_validate` in **PASS** và từng cảnh báo đã giải thích được (cảnh báo "chưa có trong 3 form mẫu" = phải kiểm trên bản in thật), `af_inspect` cho cây layout + bind đúng thiết kế. Sửa script rồi sinh lại, không sửa tay XML.

### 5. Chương trình gọi form

Theo [`references/abap-call.md`](references/abap-call.md): `FP_JOB_OPEN` → `FP_FUNCTION_MODULE_NAME` → FM form (tham số trùng interface) → `FP_JOB_CLOSE`; định dạng số/ngày trong ABAP trước khi truyền.

### 6. Bàn giao

- Đường dẫn 2 file XML + script; bảng mapping ô ↔ field; điểm chưa xác nhận; thay đổi cần làm ở DDIC/chương trình.
- Hướng dẫn upload: SE11 tạo structure/table type → SFP Interface → Upload `SFPI_*.XML` → Activate → SFP Form → Upload `SFPF_*.XML` → Activate → mở tab Layout xem → chạy chương trình ở chế độ xem trước.
- User upload/chạy xong: ghi kết quả (lỗi thật hoặc OK) vào `_ghichu_local.md` mục On-Premise và cập nhật bảng trạng thái mục 1 `references/xml-structure.md`.

## Sửa / đọc form có sẵn

- Đọc: `af_inspect.py <SFPF hoặc SFPI> [--xdp ra.xdp] [--all]` → interface, context, trang, cây layout + bind, bind lỗi, field dữ liệu chưa dùng.
- Đổi layout, giữ context: dựng layout mới bằng afgen rồi `inject_layout(SFPF_tải_về, SFPF_mới, page(...), [...])`; thay đổi nhỏ thì sửa thẳng trong Designer.
- Thêm field: sửa line type SE11 trước → SFP tự sinh lại node context → Download lại rồi mới inject.

## Bảo trì afgen

Sửa `afgen.py` → chạy `scripts/af_selftest.py` (mặc định dùng mẫu export thật ở `examples/` trong skill; truyền thư mục khác nếu có mẫu mới) — phải PASS. Có form mẫu mới dùng tính năng chưa hỗ trợ → thêm vào thư mục mẫu, mở rộng afgen + `SEEN_VOCAB`, cập nhật `references/`.
