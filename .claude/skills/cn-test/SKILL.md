---
name: cn-test
description: 'Bước 5 quy trình chức năng: sinh/cập nhật TestCase/TEST_CASE_<CN>.md từ FS + thiết kế, chuẩn bị dữ liệu test (file .sql nếu không tự đọc được), ghi kết quả và vòng sửa lỗi. Gọi: /cn-test [KH] <CN>'
argument-hint: '[KH] <CN>'
disable-model-invocation: true
---

# /cn-test — Test case + vòng sửa lỗi

Phần chung (xác định KH/CN, TRANG_THAI, nhật ký): mục 0 của `.claude/skills/cn-fs/SKILL.md`.

1. **Sinh/cập nhật `TestCase/TEST_CASE_<CN>.md`** (giữ mã TC cũ, thêm mới cuối bảng): mỗi mục FS ít nhất 1 TC chức năng chính; thêm dữ liệu sai/thiếu, biên (rỗng, nhiều dòng), từng message lỗi, phân quyền, chạy lại sau lỗi, dữ liệu lớn. Mỗi TC có dữ liệu vào + kết quả mong đợi đo được.
2. **Dữ liệu test**: đọc được (đúng rule client, có quyền) → tự tìm qua MCP; không → `sql/query_<cn>_test.sql` cho user chạy. Không bịa dữ liệu.
3. **Ghi kết quả** user báo: Đạt / Lỗi (ảnh lỗi để trong `TestCase/`, tên theo mã TC). Lỗi → bảng "Lỗi phát hiện" → sửa local (`/cn-code`) → đẩy lại (`/cn-day`) → test lại đúng TC đó.
4. Hết lỗi chặn → TRANG_THAI `Test` (Đang chờ: "user/tư vấn xác nhận"), gợi ý `/cn-xong <CN>`.
