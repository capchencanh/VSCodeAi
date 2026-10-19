# Bảng ZTWM_CHAR_PARAM – Thuộc tính lô hiển thị trên ALV của ZWM11

Đã tạo trên S/4 DEV (15/10/2026), package `ZPK_BDP`, delivery class **A**, task `DEVK900648` (TR `DEVK900647`). Cấu trúc theo file BA gửi `FS/BDP_ZWM11_ZTWM_CHAR_PARAM.xlsx`: "Table này lưu trữ những Characteristic có trong Class được đưa lên ALV hay không".
BA không đặt tên kỹ thuật field, tên dưới đây do tự đặt theo `KLAH` / `CABN` / `CABNT`. Bảo trì bằng SM30, bật table logging (hướng dẫn trong `ghi_chu.md` mục 0.2).

| # | Field | Data element | Key | Ý nghĩa (theo BA) |
|---|---|---|---|---|
| 1 | MANDT | MANDT | X | Client (tool tạo thành `CLIENT` không data element, đã sửa lại `MANDT`, kiểm `DD03L`) |
| 2 | CLASS | KLASSE_D (CHAR 18) | X | Class của lô, VD `B_BATCH`. BA ghi CHAR(10), dùng 18 như `KLAH-CLASS` vì class `SAP_EWM_LOBM` trên DEV dài 12 ký tự |
| 3 | ATNAM | ATNAM (CHAR 30) | X | Characteristic (thuộc tính lô), VD `ZQC_POTENCY`, `Z_BAO_QUAN`. Phải có trong `CABN-ATNAM` (kiểm ở event 01 của SM30) |
| 4 | ATBEZ | ZDE_WM_CHAR_DESC (domain `TEXT40`, CHAR 40, cho chữ thường) |  | Mô tả thuộc tính lô, VD "QC API", "Điều kiện bảo quản_Mã". Tự lấy từ `CABNT-ATBEZ` khi lưu (BA ghi `CABN-ATBEZ`, bảng `CABN` không có field này) |
| 5 | SHOW_ALV | ZDE_WM_CHAR_SHOW (domain `XFELD`) |  | `X` = cho phép hiển thị trên ALV, trống = không |

Data element mới (package `ZPK_BDP`, nhãn tiếng Việt):

| Data element | Short (10) | Medium (20) | Long (40) | Heading |
|---|---|---|---|---|
| ZDE_WM_CHAR_DESC | Mô tả | Mô tả thuộc tính | Mô tả thuộc tính lô | Mô tả thuộc tính lô |
| ZDE_WM_CHAR_SHOW | Hiển thị | Hiển thị trên ALV | Cho phép hiển thị trên ALV | Hiển thị trên ALV |

Dữ liệu mẫu BA:

| Class | Characteristic | Char. Description | Hiển thị |
|---|---|---|---|
| B_BATCH | ZQC_POTENCY | QC API | X |
| B_BATCH | Z_BAO_QUAN | Điều kiện bảo quản_Mã |  |
| Z_BATCH | Z_BATCH_NSX | Lô NSX | X |

Cách chương trình dùng bảng (FORM `READ_CHAR_CONFIG`, `BUILD_CHAR_LIST` trong `zwm_in_tonthuoctinh_f01.abap`):
- Khối lọc và cột ALV: thuộc tính `SHOW_ALV = X` xếp trước, rồi thuộc tính có dòng cấu hình nhưng trống, rồi thuộc tính chưa khai báo (bảng không có cột thứ tự, trong mỗi nhóm giữ thứ tự trong class); tối đa 15.
- Ô tick "Hiển thị" mặc định: `X` thì tick. Bảng chưa có dòng nào cho class thì tick tất cả.
- Nhãn: `ATBEZ`, trống thì mô tả `CABNT`.
- Không chọn Batch Class: đọc mọi class, thuộc tính trùng tên lấy dòng `SHOW_ALV = X` nếu có.
- Bảng trống thì chương trình vẫn chạy.

Event 01 của SM30 (kiểm Characteristic, điền `ATBEZ`): `ztwm_char_param_tmg_event01.abap` cùng thư mục.
