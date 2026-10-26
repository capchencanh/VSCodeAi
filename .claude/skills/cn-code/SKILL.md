---
name: cn-code
description: 'Bước 3 quy trình chức năng: viết code local theo thiết kế đã duyệt (đúng thư mục, đúng chuẩn đặt tên/marker/nền tảng), tự kiểm rồi báo user duyệt. Gọi: /cn-code [KH] <CN>'
argument-hint: '[KH] <CN>'
disable-model-invocation: true
---

# /cn-code — Viết code local + tự kiểm

Phần chung (xác định KH/CN, TRANG_THAI, nhật ký): mục 0 của `.claude/skills/cn-fs/SKILL.md`.

1. **Điều kiện**: `TS/THIET_KE_<CN>.md` đã được duyệt (nhật ký có mốc duyệt). Chưa → chạy `/cn-thiet-ke` trước. Sửa lỗi nhỏ sau test thì không cần.
2. **Nơi đặt file** (file local là nguồn chính, tên kiểu abapGit `.prog.abap`, `.clas.abap`, `.ddls.asddls`): GUI → `dictionary/`, `src/`, `form zxlwb/`; Cloud → `cds/`, `class/`, `ui5/`; khác → `src/`.
3. **Chuẩn áp dụng**:
   - Marker `<UserName>` theo `CLAUDE.md` gốc (trừ khi `CLAUDE.md`/skill dự án quy định khác).
   - Tên biến: `abap-naming-convention`. Nền tảng: `abap-platform-constraints`.
   - Khi cần: SQL nâng cao `abap-sql-amdp`; SELECT trong LOOP/itab lớn `abap-performance-hana`; Excel ZXLWB `zxlwb-workbench`; form in `smartforms-xml`/`adobe-form-xml`; RAP query provider `abap-rap-query-provider`; UI5 `ui5-best-practices`.
4. **Tự kiểm trước khi báo**:
   - Mọi `PERFORM`/method gọi đều có định nghĩa, chữ ký khớp giữa các include/class.
   - Text symbol/message dùng trong code có đủ trong file text.
   - Không `SORT`/`DELETE ADJACENT DUPLICATES` thiếu `BY`/`COMPARING` trên bảng empty key; không `FOR ALL ENTRIES` trên HANA.
   - Không còn `TODO` không lý do; không tên AI trong code/comment.
   - Có MCP: `SyntaxCheck` (không lưu object). Không dùng cho class Custom Logic Cloud (`*_KU`).
5. **Báo duyệt**: liệt kê file đã tạo/sửa (link), điểm cần user xem kỹ, câu hỏi còn mở. Dừng, chờ user.
6. TRANG_THAI giữ `Code` (Đang chờ: "user duyệt code"), gợi ý `/cn-day <CN>`.
