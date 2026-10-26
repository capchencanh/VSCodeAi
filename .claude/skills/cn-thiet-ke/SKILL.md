---
name: cn-thiet-ke
description: 'Bước 2 quy trình chức năng: lập danh sách object (đặt tên đúng chuẩn), luồng xử lý, quyết định kỹ thuật vào TS/THIET_KE_<CN>.md rồi xin user duyệt trước khi viết code. Gọi: /cn-thiet-ke [KH] <CN>'
argument-hint: '[KH] <CN>'
disable-model-invocation: true
---

# /cn-thiet-ke — Thiết kế kỹ thuật, xin duyệt

Phần chung (xác định KH/CN, TRANG_THAI, nhật ký): mục 0 của `.claude/skills/cn-fs/SKILL.md`.

1. **Điều kiện**: `CAU_HOI_FS_<CN>.md` không còn [CHẶN] chưa trả lời. Còn → báo danh sách, hỏi user có chấp nhận giả định đề xuất không.
2. **Nền tảng**: theo `CLAUDE.md` dự án; ràng buộc khác nhau → skill `abap-platform-constraints`.
3. **Danh sách object**: tên theo skill `abap-cloud-naming` (Cloud) hoặc tiền tố dự án (GUI, vd AVN `Y`); kiểm giới hạn độ dài và chưa tồn tại (MCP `SearchObject`). Gồm DDIC, CDS (R/I/C), BDEF/service, class, program/include, message/text, T-code/app, form in/Excel.
4. **Thiết kế**: luồng xử lý chính; bố cục (GUI: TOP/F01/F02…; Cloud: view → BDEF → behavior/query provider → service); đọc data (JOIN, `INNER JOIN @itab` thay FAE — skill `abap-performance-hana` khi data lớn); đổi dữ liệu nghiệp vụ qua BAPI (GUI) / EML–released API (Cloud); message; phân quyền (skill `authorization-iam` nếu có); chạy lại sau lỗi, khoá, test run.
5. **Ghi `TS/THIET_KE_<CN>.md`**: (1) Object list — bảng `# | Loại | Tên | Mô tả | File local`; (2) Luồng xử lý + sơ đồ mermaid ngắn; (3) Quyết định kỹ thuật + lý do; (4) Giả định còn mở. GUI: chép Object list sang mục 1 của `HUONG_DAN_TAO_<CN>.md`.
6. **Cổng duyệt (bắt buộc)**: trình bày object list + quyết định chính → hỏi user đồng ý (rule ưu tiên: tạo code/object mới phải được đồng ý). Chưa đồng ý → dừng, sửa theo góp ý.
7. Đồng ý → ghi mốc "đã duyệt thiết kế" vào nhật ký, TRANG_THAI `Code` (Đang chờ: "viết code"), gợi ý `/cn-code <CN>`.
