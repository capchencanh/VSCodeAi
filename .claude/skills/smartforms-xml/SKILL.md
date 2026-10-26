---
name: smartforms-xml
description: Sinh file XML Smart Form (SMARTFORMS → Utilities → Upload form) cho SAP On-Premise từ yêu cầu FS + chương trình ABAP gọi form. Dùng khi cần thiết kế mới/sửa 1 form in Smart Forms dạng XML để upload, hoặc khi cần đọc/phân tích 1 file XML Smart Form đã export.
---

# Smart Form dạng XML — thiết kế, sinh, kiểm tra

Form được **sinh bằng script Python** dùng thư viện [`scripts/sfgen.py`](scripts/sfgen.py), không viết tay XML: file export thật dài hàng trăm nghìn ký tự trên 1 dòng, mỗi phần tử phải đúng thứ tự con như SAP xuất ra. Cấu trúc XML, ý nghĩa từng thẻ, các mẫu thiết kế đã dùng: [`references/xml-structure.md`](references/xml-structure.md) — đọc trước khi viết script.

Các script chạy bằng `PYTHONUTF8=1 python <script>` (Windows mặc định cp1252 làm vỡ tiếng Việt).

## Quy trình

### 1. Gom đầu vào

- **Form mẫu thật** (file XML user Download từ chính hệ thống đích: SMARTFORMS → Utilities → Download form). Bắt buộc: nó quyết định style, định dạng ký tự/đoạn được phép dùng, và là chuẩn để `sf_validate.py` so thứ tự thẻ. Không có → hỏi user trước khi làm tiếp; nếu user đồng ý dùng tạm thì lấy `examples/zmm_sf_pxkpg_doc.xml` (form thật hệ HPDQ, style `ZCORE_STYLE_REPORT` — hệ đích phải có style này hoặc đổi sang style có sẵn).
- **Yêu cầu FS**: file Excel/ảnh mẫu in. Sheet FS thường có ảnh mẫu in chèn vào (openpyxl không đọc ảnh) → giải nén `.xlsx`, map sheet → `xl/drawings/drawingN.xml` → `xl/media/*` để xem ảnh theo vị trí dòng. Lấy **thay đổi mới nhất** (các mục "Thay đổi ngày ..." cuối sheet) làm chuẩn.
- **Chương trình gọi form** (qua MCP khi có): tìm `SSF_FUNCTION_MODULE_NAME` và `CALL FUNCTION fm_name`, ghi lại **đúng tên + kiểu** từng tham số `EXPORTING`/`TABLES` truyền vào form; đọc FORM chuẩn bị dữ liệu cho đúng option (field nào được điền, dòng tổng/`LEVEL`, thứ tự sort); `GetStructure` từng structure tham số.

Xong bước này khi: **mọi ô trên mẫu in** đã gắn được với 1 field tham số mà chương trình thật sự điền cho option đó, hoặc được liệt kê là thiếu (chương trình chưa điền / cần sửa chương trình).

### 2. Đọc form mẫu

`python scripts/sf_inspect.py <mau.xml>` → interface, global data, line type, cây node kèm điều kiện và nội dung text. `--node %ROW13 %TEXT54` để dump chi tiết node. Rút ra: style (`STDSTYLE`), định dạng ký tự (`<B0>`, `<N0>`...) và đoạn (`C`/`L`/`R`/`*`) đang dùng, cách bố trí header/logo/chữ ký của team.

### 3. Thiết kế và viết script sinh form

Viết `scripts/gen_<tenform>.py` trong thư mục project chứa form (mẫu hoàn chỉnh: `examples/gen_bkpxk.py` trong skill, form mẫu export thật `examples/zmm_sf_pxkpg_doc.xml`). Chốt trước:

- Khổ giấy/hướng (`orientation='L'` khi > ~12 cột), toạ độ window, độ rộng table = độ rộng MAIN.
- Line type cho từng loại dòng; mỗi line type tổng độ rộng cột = độ rộng table; mỗi row có số cell = số cột line type.
- Interface của form: **trùng tên và kiểu** với tham số chương trình truyền (bước 1) — lệch tên là FM sinh ra báo lỗi khi gọi.
- Chỉ dùng định dạng ký tự/đoạn đã thấy trong form mẫu cùng style.
- Code node có tag tác giả theo CLAUDE.md (`"<UserName> add begin dd.mm.yyyy hh:mm:ss` ... `add end`), `user=` trong `SF(...)` lấy từ `UserName.md`.

### 4. Sinh và kiểm tra

```
python scripts/gen_<tenform>.py <tenform>.xml
python <skill>/scripts/sf_validate.py <tenform>.xml <mau.xml>
```

Xong khi `sf_validate.py` in **PASS** (tag + thứ tự con khớp form mẫu, không trùng INAME, độ rộng và số cell khớp line type) và `sf_inspect.py <tenform>.xml` cho cây node đúng thiết kế. Sửa script rồi sinh lại — không sửa tay file XML.

### 5. Bàn giao

Báo user: đường dẫn file XML + script, bảng mapping ô ↔ field, các điểm chưa xác nhận, và **thay đổi cần làm ở chương trình** (tên form mới, tham số, dữ liệu còn thiếu). Cách upload: SMARTFORMS → nhập tên form → Utilities → Upload form → chọn file → Activate; copy file ra đường dẫn ngắn trước khi upload.

Sau khi user upload/activate: lỗi hay kết quả thật → ghi vào `.claude/skills/abap-platform-constraints/reference/_ghichu_local.md` (mục On-Premise) và cập nhật mục "Trạng thái xác nhận" trong `references/xml-structure.md`.
