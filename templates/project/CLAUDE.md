# Dự án __KH__ (lưu ở repo dự án — `scripts/git-du-an.ps1`, không lên repo team)

Rule chung của team nạp tự động từ `CLAUDE.md` ở gốc repo. File này chỉ ghi phần RIÊNG của dự án.

- **Nền tảng**: __PLATFORM__ → dùng skill `sap-mcp-__PLATFORM_KEY__` khi gọi MCP.
- **MCP server** (khai báo trong `.mcp.json` cùng thư mục):
  - `__SERVER_DEV__` — hệ DEV, được ghi/activate.
  - (thêm QAS/CUS/PRD nếu có — PRD chỉ đọc)
- **Client**: __CLIENT__.
- [cloud] **Client 80 (DEV)**: không tự SELECT data, viết `sql/query_*.sql` cho user tự chạy.
- **Tiền tố object**: Z (sửa nếu KH dùng tiền tố khác, VD AVN dùng Y).
- **Code**: theo chức năng `<CN>/` (cây do `tao-chuc-nang.ps1` tạo; tên file kiểu abapGit `.prog.abap`, `.clas.abap`, `.ddls.asddls`). Code chung nhiều chức năng: `src/`; SQL đưa user tự chạy: `sql/`.
- **Trạng thái chức năng** (giai đoạn, đang chờ ai, TR): `TRANG_THAI.md` — cập nhật khi chuyển giai đoạn; mốc chi tiết + quyết định: `<CN>/NHAT_KY_<CN>.md`. Quy trình: lệnh `/cn-*` của team.
- **Ghi chú riêng dự án** (landscape, lỗi chỉ đúng hệ này, giờ VPN, câu hỏi chờ tư vấn): `NOTES.md` — đọc theo section khi cần.
