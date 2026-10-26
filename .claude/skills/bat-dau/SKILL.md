---
name: bat-dau
description: 'Đầu ngày: lấy bản mới repo team + repo dự án, kiểm quy tắc repo, liệt kê chức năng đang chờ kèm lệnh /cn-* nên chạy tiếp. Gọi: /bat-dau [KH]'
argument-hint: '[KH]'
disable-model-invocation: true
---

# /bat-dau — Bắt đầu ngày làm việc

Lệnh này **chỉ đọc và báo cáo**, không sửa file nào.

1. Gốc repo = thư mục chứa `scripts/` (đang mở `CodeABAP/<KH>` thì là `..\..`). Chạy:
   `powershell -NoProfile -ExecutionPolicy Bypass -File <gốc>\scripts\bat-dau-ngay.ps1`
   (pull repo team + mọi repo dự án, chạy `check-repo`, liệt kê dòng `TRANG_THAI.md` chưa `Xong`). Pull lỗi (có thay đổi chưa commit, lệch nhánh) → báo nguyên văn, không tự xử lý.
2. Phạm vi: có `$ARGUMENTS` → chỉ dự án đó; đang mở `CodeABAP/<KH>` → dự án đó; mở gốc repo → mọi dự án.
3. Trình bày 1 bảng: KH · Chức năng · Giai đoạn · Đang chờ · Cập nhật (quá 7 ngày → đánh dấu ⚠) · **Lệnh gợi ý**:

   | Giai đoạn | Lệnh gợi ý |
   |---|---|
   | `FS`, `Hỏi` | `/cn-fs <CN>` (cập nhật câu trả lời / FS mới) |
   | `Code` chưa có `TS/THIET_KE_<CN>.md` được duyệt | `/cn-thiet-ke <CN>` |
   | `Code` | `/cn-code <CN>` |
   | `Đẩy` | `/cn-test <CN>` |
   | `Test` | `/cn-xong <CN>` |
   | `?` | hỏi user giai đoạn thật rồi sửa dòng đó |

4. Nhắc nếu có: skill team sửa chưa commit (`git -C <gốc> status --short .claude/skills`), repo dự án chưa lưu (`<gốc>\scripts\git-du-an.ps1 xem <KH>`), LOI của check-repo.
5. MCP: không tự gọi tool. Chỉ nhắc khung giờ VPN nếu `NOTES.md` dự án có ghi.
6. Kết thúc bằng 1 câu hỏi: hôm nay làm chức năng nào trước.
