CÁC LƯU Ý KHI MOVE CODE

- Xóa thông tin ngày giờ (date/time) và tên người tạo/sửa của dự án cũ trong các comment, chỉ giữ lại nội dung comment.
- Ví dụ – Trước: \* 20.05.2023 – NguyenVA – Thêm điều kiện lọc theo Plant
- Ví dụ – Sau: \* Thêm điều kiện lọc theo Plant
- Code move sang dự án mới coi như code tạo mới: KHÔNG đánh marker tên người/ngày tháng (bỏ các dòng `" #Tcode • [CS]_... Add Start/End/Line`, `"danhdh add begin/end`), kể cả phần mình thêm/sửa.
- Phong cách comment trong code (chuyên nghiệp, gọn): nội dung comment viết bằng **tiếng Việt ngắn gọn**; tên khối kỹ thuật trong banner giữ nguyên từ khóa ABAP (SELECTION-SCREEN, AT SELECTION-SCREEN, START-OF-SELECTION...). Banner 3 dòng `*---*` / `* TÊN KHỐI` / `*---*` CHỈ dùng cho khối kỹ thuật lớn, KHÔNG banner cho TYPES/DATA/CONSTANTS/class/từng nhóm field (VD sai: banner "Dữ liệu chương trình", "Hằng số"). Đầu FORM: giữ banner chuẩn có tên FORM; chỉ thêm tối đa 1 dòng mô tả khi mục đích/ràng buộc không hiển nhiên từ tên (không viết đoạn nhiều dòng). Trong thân FORM: chỉ comment chỗ logic khó hiểu hoặc chuỗi ưu tiên/fallback, 1 dòng, không comment điều code đã tự nói rõ. Không comment từng field của TYPES.
- Comment: CHỈ comment ý chính và chỉ khi THỰC SỰ CẦN (mục đích FORM/khối logic lớn, chỗ logic khó hiểu nếu không giải thích). Không comment lại điều code đã tự nói rõ, không comment lịch sử sửa đổi ("trước đây...", "không còn dùng...", "bỏ tham số vì..."), không để lại code cũ bị comment. KHÔNG comment số chỉ tiêu/mục FS, VD sai: `(chỉ tiêu 18)`, `(FS 2.3, tham số 11)`, `(H5)`.
  - Khi bỏ/đổi 1 chức năng (VD bỏ mẫu 4 của ZWM05): SỬA THẲNG hoặc XÓA luôn đoạn code đó. KHÔNG comment lại từng dòng code cũ rồi viết dòng mới bên dưới, KHÔNG thêm dòng giải thích kiểu "Bỏ mẫu 4...". Chỉ comment lại khi THỰC SỰ CẦN (user yêu cầu giữ để bật lại sau, hoặc đoạn đó đang chờ BA chốt). Áp dụng cho code dự án BDP, ưu tiên hơn rule "chỉ comment lại đoạn code bỏ" ở `CLAUDE.md`. Lý do: user không muốn code dài dòng.
- Ưu tiên dùng function module / class / API chuẩn SAP có sẵn (VD đổi đơn vị: `MD_CONVERT_MATERIAL_UNIT`, `MATERIAL_UNIT_CONVERSION`) thay vì tự code lại logic bằng tay. Trước khi viết 1 logic tính toán/chuyển đổi/đọc dữ liệu chuẩn: tìm FM/class phù hợp (SearchObject, đọc interface) và dùng nếu dùng được trên hệ đích. Chỉ tự code khi không có FM hợp lý hoặc FS yêu cầu công thức riêng mà FM không làm được (ghi rõ lý do trong ghi chú của Tcode). Hạn chế tối đa set cứng (hard-code) giá trị/mã/danh sách: ưu tiên lấy từ bảng tham số, customizing, STVARV hoặc FM chuẩn.
- Hệ thống S/4 là hệ MỚI: nhiều chỗ chưa có data, đang chờ cấu hình, BA còn đang bàn.
  - Chỗ FS ghi "chờ cung cấp / chờ BP chốt / đang bàn / vấn đề mở" → code TẠM ĐỂ TRỐNG (không bịa giá trị, không hard-code), chương trình vẫn chạy bình thường khi thiếu.
  - Chỗ FS thiếu nhưng đoán được ý đồ → code trước theo cách hợp lý nhất, ghi rõ giả định trong ghi chú của Tcode.
  - Chỗ FS yêu cầu field/nguồn dữ liệu mà S/4 không còn (VD `RESB-EMATN`) → để trống + đưa vào câu hỏi BA.
- Câu hỏi cho BA: CHỈ hỏi chỗ FS mô tả THIẾU, TRỐNG hoặc ĐANG BÀN ở yêu cầu chính. KHÔNG hỏi chi tiết râu ria/bổ sung ngoài FS (edge case FS không nhắc, cách tổ chức kỹ thuật, đánh số message...) — tự chọn cách hợp lý và ghi lại giả định. Chỗ FS đã ghi rõ mà code làm lệch thì SỬA theo FS, không đưa thành câu hỏi.
  - Lọc trước khi liệt kê câu hỏi: với mỗi câu tự trả lời "BA không trả lời thì form/chức năng chính sai ở đâu?". Không chỉ ra được chỗ sai, hoặc code đã chạy tạm theo cách hợp lý mà kết quả in vẫn đúng yêu cầu chính → KHÔNG hỏi, chỉ ghi giả định vào `ghi_chu.md`. Nghi ngờ thì bỏ ngay từ đầu, không đưa vào rồi lần sau mới rút. Không cần thiết thì khỏi, không hỏi cho đủ số lượng.
  - Chỗ chỉ là CHƯA CẤU HÌNH / CHƯA CÓ DATA trên hệ (Text ID, đặc tính lô, bảng Z chưa tạo, danh sách giá trị chưa khai báo...) mà code đã có cách chạy tạm → KHÔNG hỏi, chỉ THÔNG BÁO cho BA biết (đang thiếu gì + code xử lý tạm thế nào + đề xuất nếu có).
  - Mỗi câu hỏi phải trích nguyên văn chỗ FS đang ghi + hiện code đang xử lý tạm thế nào.
  - Ghi danh sách câu hỏi vào mục "Câu hỏi còn mở cho BA" trong file `ghi_chu.md` của Tcode đó.
- Việc chỉ user làm được trong SAP GUI (SM30 / Table Maintenance Generator, Technical Settings log, GUI status, T-code, upload Smart Form...): KHÔNG chỉ nói "bạn làm X". Phải viết luôn hướng dẫn từng bước kèm giá trị cụ thể để user copy (tên object, Short description, Function group, Package, Authorization Group, số màn hình, TR/task...).
  - Lấy giá trị từ object tương tự đã làm, kiểm bằng MCP (`TVDIR`, `TDDAT`, `DD09L`, `TSTC`, `TSTCT`, `TSTCC`), không đoán.
  - Ghi cùng hướng dẫn vào mục "Hướng dẫn việc user làm" của `ghi_chu.md` Tcode đó, để phiên sau còn dùng lại.
- Khi tạo bảng DDIC (table): mỗi field phải có data element có tên và nhãn (short / medium / long / heading) nói rõ ý nghĩa field, để user mở SE11 hoặc SM30 thấy ngay field là gì. KHÔNG gán thẳng data element / kiểu chung như `CHAR255`, `CHAR1`, `CHAR10`, `INT4` (user chỉ thấy mô tả "Char255").
  - Đã có data element chuẩn hoặc `ZDE_*` đúng nghĩa (VD `WERKS_D`, `LGORT_D`, `BWART`) thì dùng lại.
  - Chưa có thì tạo mới: tên `ZDE_<module>_<ý nghĩa>` (VD `ZDE_WM_PCK_TITLE_VI`), package theo các `ZDE_WM_*` đã có (`ZPK_BDP`), nhãn tiếng Việt, domain có cho phép chữ thường (VD `TEXT80UEB`, `TEXT255`) cho field văn bản; field cờ X dùng domain `XFELD`.
  - Kiểm tra trước bằng MCP (`DD04L`, `DD04T`, `DD01L`) xem đã có data element phù hợp chưa, và domain có `LOWERCASE` hay không.
  - Field client của bảng phải tên `MANDT`, data element `MANDT` (không để tool tự đặt `CLIENT` không data element). Tạo bảng bằng MCP xong luôn kiểm `DD03L` (field đầu tiên); sai thì sửa ngay bằng `UpdateObjectAtomic` (`key mandt : mandt not null;`), xem `_ghichu_mcp_gui.md` mục "Tạo DDIC".
- Đặt tên Transport Request (TR): phần description không được chứa các từ liên quan đến “move”, “copy” hoặc tên dự án khác.
- Ví dụ – Sai: “Move code ZMB51 từ dự án ABC”, “Copy ZMB51_OLD”
- Ví dụ – Đúng: “ABAP_SangVT_20261002_ZMB51 – Báo cáo danh sách chứng từ vật tư"
  Cách đặt tên TR:

- TR cho DEV/Enhen: <Tên><mã Module><FS/ TCode><Mục lục Enhen><DD.MM.YYY><Description>
- Ví dụ:
- SangVT_SD_ZEIV01_06.10.2026_Phat hanh hoa don GTGT
  TEMPLATE PROMPT AI:

1. Move code có chỉnh sửa

Tôi đang làm dự án BIDIPHAR upgrade từ SAP ECC -> SAP S/4HANA Private Cloud.

Đọc program C:\Users\KhoaLeDa\Desktop\Github\VSCodeSkillAI\CodeABAP\BIDIPHAR\ZAP03\zfi_pg_ap_zap03\zfi_pg_ap_zap03.abap và các include liên quan và file FS C:\Users\KhoaLeDa\Desktop\Github\VSCodeSkillAI\CodeABAP\BIDIPHAR\ZAP03\FS\BIDIPHAR_FS_FI_AP_ZAP03_BangKeVATDauVao_V1.0.docx

Update lại program C:\Users\KhoaLeDa\Desktop\Github\VSCodeSkillAI\CodeABAP\BIDIPHAR\ZAP03\zfi_pg_ap_zap03\zfi_pg_ap_zap03.abap theo những yêu cầu trong FS( note: màu xanh là thêm logic, màu vàng là chỉnh sửa logic )

Chỉ tạo ở local không có MCP.

Chỗ nào bạn có thể tối ưu performance thì cứ tối ưu nhé bởi vì nâng lên Private cloud thì syntax sẽ mới hơn nhiều so với ECC( ví dụ như thay FOR ALL ENTRIES bằng INNER JOIN Internal table, sử dụng CTE để tối ưu câu truy vấn,.,.. )

Nhớ list ra những gì bạn làm, những gì bạn chỉnh sửa trong 1 file .md để tôi biết bạn làm gì nhé.
