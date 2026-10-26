---
name: cn-fs
description: 'Bước 1 quy trình chức năng: tạo thư mục chức năng (nếu chưa có), đọc FS, đối chiếu hệ thống, soạn CAU_HOI_FS_<CN>.md, cập nhật TRANG_THAI → Hỏi. Chạy lại khi có câu trả lời hoặc FS mới. Gọi: /cn-fs [KH] <CN>'
argument-hint: '[KH] <CN>'
disable-model-invocation: true
---

# /cn-fs — Nhận FS, đối chiếu, chốt câu hỏi

## 0. Chung cho mọi lệnh `/cn-*`

1. `$ARGUMENTS`: 2 tham số = `<KH> <CN>`; 1 tham số = `<CN>`, KH lấy từ thư mục `CodeABAP/<KH>` đang mở. Thiếu → liệt kê dòng trong `TRANG_THAI.md` rồi hỏi. `<CN>` viết HOA.
2. Gốc repo = thư mục chứa `scripts/`. Nền tảng, server, client, tiền tố object: `CodeABAP/<KH>/CLAUDE.md`.
3. Dự án có skill quy trình riêng (vd AVN `avn-fs-to-chuc-nang`) → đọc và áp phần riêng; phần chung theo lệnh này.
4. Kết thúc bước: cập nhật dòng `<CN>` trong `TRANG_THAI.md` (Giai đoạn · Đang chờ · Cập nhật = hôm nay `dd.mm.yyyy`) + thêm mục `### dd.mm.yyyy — <bước>` vào `<CN>/NHAT_KY_<CN>.md` (chưa có → tạo từ `templates/feature/NHAT_KY.md`). Không ghi vào auto-memory. Gợi ý lệnh tiếp theo.

## 1. Chuẩn bị

1. Chưa có `CodeABAP/<KH>/<CN>/` → chạy `powershell -NoProfile -ExecutionPolicy Bypass -File <gốc>\scripts\tao-chuc-nang.ps1 <KH> <CN>` (chỉ tạo cây thư mục + file mẫu, không phải object SAP). Dự án chưa tồn tại → dừng, hướng dẫn user chạy `tao-du-an.ps1`.
2. Tìm FS trong `<CN>/FS/`. Không có → nhờ user bỏ file vào đó rồi dừng. Nhiều version → dùng bản mới nhất, giữ bản cũ.
3. File `.docx`/`.xlsx` dài: chuyển **1 lần** sang `FS/<tên file>.md` (docx: `pandoc -t gfm`; xlsx: đọc từng sheet ra bảng markdown, ghi cả màu ô/cột bắt buộc nếu FS dùng). Các lần sau đọc bản `.md`.

## 2. Đọc và tóm tắt

1. Đọc **toàn bộ** FS: mọi sheet/mục, selection screen, logic, template, ví dụ, ghi chú màu ô.
2. Tóm tắt cho user (ngắn, mỗi dòng ghi số mục FS): Input/màn hình → Nguồn data (bảng/field/điều kiện) → Xử lý (BAPI/EML/BDC/ghi bảng) → Output (ALV/Excel/Fiori/log).
3. Liệt kê mọi hằng số customizing FS nêu (plant, loại chứng từ, material type, class/characteristic…) — sau thành hằng số trong code.
4. Có chức năng cũ để tham khảo → đặt code vào `<CN>/ref/` (GUI), không copy nguyên logic khác FS.

## 3. Đối chiếu hệ thống (trước khi hỏi)

- Cấu trúc: bảng/field/CDS/FM/BAPI có tồn tại, đúng nghĩa; tên object FS vượt giới hạn độ dài (bảng ≤ 16 ký tự); Cloud: API/CDS đã released chưa. Đọc qua MCP theo skill `sap-mcp-gui` / `sap-mcp-cloud`.
- Data: theo rule client trong `CLAUDE.md` gốc (Cloud client 80 → không SELECT). Không đọc được → `sql/query_<cn>_check_fs.sql`, mỗi câu trả lời 1 câu hỏi (Q1, Q2…). Không đoán data rồi code theo đoán.

## 4. Câu hỏi chốt FS

1. Ghi vào `CAU_HOI_FS_<CN>.md` (bảng mẫu): mỗi câu 1 dòng, nhóm **mâu thuẫn / thiếu / kỹ thuật**, có Mục FS + Đề xuất của dev. Câu phải chốt trước khi code đánh **[CHẶN]**.
2. User muốn hỏi ngay → `AskUserQuestion` 1 câu/lượt, phương án đề xuất đặt đầu; ghi trả lời + ngày vào cột Trả lời.
3. Câu chờ bên ngoài (SQL, recording, tư vấn) không chặn code → ghi rõ giả định sẽ dùng.

## 5. Chạy lại (có câu trả lời / FS mới)

Cập nhật cột Trả lời/Trạng thái; FS mới → diff theo sheet/mục với bản trước, câu mới thêm cuối bảng, ghi điểm thay đổi vào nhật ký.

## 6. Kết thúc

Còn [CHẶN] chưa trả lời → Giai đoạn `Hỏi` (Đang chờ: "tư vấn trả lời Q-..") ; hết → `Code`, gợi ý `/cn-thiet-ke <CN>`.
