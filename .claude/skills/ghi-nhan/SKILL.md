---
name: ghi-nhan
description: 'Ghi 1 phát hiện (lỗi tool MCP, kiến thức ABAP, thông tin riêng KH, quyết định chức năng) vào ĐÚNG nơi theo bảng quyết định — giữ skill team gọn, phần riêng KH nằm ở repo dự án. Gọi: /ghi-nhan [nội dung]'
argument-hint: '[nội dung phát hiện]'
disable-model-invocation: true
---

# /ghi-nhan — Ghi phát hiện đúng chỗ

`$ARGUMENTS` = nội dung phát hiện. Trống → rà lại phiên hiện tại, liệt kê các phát hiện đáng ghi (1 dòng/mục, kèm nơi đề xuất) rồi hỏi user chọn.

## 1. Bảng quyết định — đi từ trên xuống, dừng ở dòng đầu tiên khớp

| # | Phát hiện là… | Ghi vào | Repo |
|---|---|---|---|
| 1 | Trạng thái / quyết định của 1 chức năng | `TRANG_THAI.md` + `<CN>/NHAT_KY_<CN>.md`; quyết định FS → cột Trả lời `CAU_HOI_FS_<CN>.md` | dự án |
| 2 | Chỉ đúng 1 KH: host/client/user, giờ VPN, customizing, DDIC/object riêng, lỗi chỉ gặp ở hệ đó | `CodeABAP/<KH>/NOTES.md` đúng mục 1–4 | dự án |
| 3 | Quy ước/quy trình riêng 1 KH lặp lại ở nhiều chức năng (tiền tố, mẫu bàn giao) | `CodeABAP/<KH>/CLAUDE.md` (≤ 3 dòng) hoặc skill `CodeABAP/<KH>/.claude/skills/<kh>-*` | dự án |
| 4 | Hành vi tool MCP `vsp.exe` đúng mọi hệ cùng nền tảng | `.claude/skills/sap-mcp-<gui\|cloud>/reference/_ghichu_mcp_*.md` đúng section | team |
| 5 | Kiến thức ABAP/CDS/nền tảng dùng được nhiều dự án | `.claude/skills/abap-platform-constraints/reference/_ghichu_local.md` đúng mục (Chung / On-Premise / Public Cloud); hay gặp → thêm bản rút gọn ≤ 3 dòng vào `SKILL.md` liên quan, kèm link ngược | team |
| 6 | Khung/pattern code tái dùng cho nhiều KH | skill team mới theo `skill-authoring` (nhánh + PR) | team |
| 7 | Sở thích/cách làm riêng của bạn | `CLAUDE.local.md` hoặc auto-memory | máy |

Không bao giờ ghi trạng thái/quyết định dự án vào auto-memory (team không thấy, dễ cũ).

## 2. Cách ghi vào file team (dòng 4–6)

1. **Grep trước** theo từ khoá/message lỗi. Đã có ý tương tự → bổ sung mục cũ (thêm case + ngày), không tạo mục mới.
2. **Không khoá tên KH**: viết "1 dự án Cloud/GUI"; host, client, tên object riêng để ở `NOTES.md` dự án và trỏ sang.
3. Mẫu: `- **[CONFIRMED|NGHI NGỜ/TODO] <kết luận 1 câu>** — <tool/object>, dd.mm.yyyy. <triệu chứng → cách xử lý>`. Không marker kiểu code, không dán log dài, giữ kiểu xuống dòng của file, không ghi mật khẩu/token.

## 3. Giữ cấu trúc gọn — khi nào nâng cấp / tách

- Cùng 1 ý xuất hiện trong `NOTES.md` của ≥ 2 KH → tổng quát hoá lên team (dòng 4/5); `NOTES.md` chỉ giữ phần riêng + link.
- Skill dự án `<kh>-*` mà KH khác cũng dùng được → tách phần chung thành skill team; skill dự án chỉ còn phần riêng.
- File ghi chú team > ~300 dòng hoặc 1 chủ đề phình to → tách `_ghichu_<chủ đề>.md`, để lại 1 dòng tóm tắt + link.
- Tài liệu của 1 chức năng nằm trong `<CN>/`; tài liệu dùng chung nhiều chức năng của 1 KH → file ở gốc dự án, liệt kê trong `CLAUDE.md` dự án.

## 4. Sau khi ghi

- Đã sửa `.claude/skills/**`: chạy `<gốc>\scripts\check-repo.ps1 -All`, nhắc user commit repo team — ghi chú/nội dung skill → push thẳng `main`; skill mới, đổi `description`, script, quy tắc → nhánh `<UserName>/<việc>` + PR (`QUY_TAC_PUSH.md`). Không tự commit.
- Đã sửa file dự án: nhắc `git-du-an.ps1 luu <KH>` cuối ngày.
