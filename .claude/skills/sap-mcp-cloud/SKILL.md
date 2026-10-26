---
name: sap-mcp-cloud
description: 'Quy trình làm việc và kho lỗi đã biết của MCP server `vsp.exe` kết nối SAP S/4HANA Public Cloud (URL `*.s4hana.cloud.sap`, cookie-file/browser-auth; server dạng `mcp_<KH>`, `CLD_<KH>_*`) — tool nào chạy/lỗi, cách vòng, giới hạn CDS/ABAP Cloud đã xác nhận, nơi ghi lỗi mới. TRIGGER — chỉ đọc khi (1) sắp gọi tool MCP Cloud lần đầu trong phiên; (2) 1 tool MCP Cloud trả lỗi/kết quả lạ (activate fail, 401/403, cookie hết hạn, success nhưng không đổi); (3) vừa phát hiện tool Cloud chạy tốt/bị lỗi và cần ghi nhận. SKIP — không đọc khi: server tên `GUI_*` (dùng `sap-mcp-gui`), viết code local không gọi MCP, hỏi cú pháp ABAP/CDS chung, đặt tên object.'
---

# MCP SAP Public Cloud

Kho kiến thức: [reference/_ghichu_mcp_cloud.md](reference/_ghichu_mcp_cloud.md) (T3, ~270 dòng).
**Không đọc cả file**: `grep -n '^## ' <file>` → `sed -n '<từ>,<đến>p'` đúng section cần.

## Trước khi gọi tool lần đầu

1. Xác định server đang dùng từ `.mcp.json` của **project đang mở** (`CodeABAP/<KH>/.mcp.json`). Đọc `CodeABAP/<KH>/CLAUDE.md` để biết DEV/CUS, client, quyền ghi.
2. Đọc section **1. Trạng thái tool đã xác nhận** để tránh tool đã biết lỗi.
3. **Client 80 (Dev) không tự SELECT data** (rule `CLAUDE.md` gốc) → viết `query_*.sql` vào `CodeABAP/<KH>/sql/`.
4. Class Custom Logic (`*_KU`) không sửa qua MCP — đưa code cho user tự dán qua app Custom Logic.

## Khi gặp lỗi

1. Grep message lỗi trong file kho: `grep -n -i '<đoạn message>' <file>`.
2. Có rồi → làm theo hướng xử lý. Chưa có → chẩn đoán, rồi ghi nhận theo bảng dưới.
3. Lỗi `401`/redirect login/cookie hết hạn → bật server `cloud-refresh-*`/`Cloud_Refresh_*` của đúng KH để đăng nhập lại bằng trình duyệt, không thử lại nhiều lần.

## Ghi nhận phát hiện mới (không cần hỏi, nhưng phải đúng nơi)

| Loại phát hiện | Ghi vào | Lên git? |
|---|---|---|
| Hành vi tool `vsp.exe` đúng mọi tenant Cloud | `reference/_ghichu_mcp_cloud.md` đúng section (theo khối "CÁCH GHI THÊM 1 MỤC MỚI" đầu file) | Có — báo user commit |
| Kiến thức ABAP/CDS Cloud chung | `SKILL.md` của skill liên quan (`abap-cloud`, `authorization-iam`...) + link về mục ghi chú | Có — báo user commit |
| Riêng 1 KH: host, tenant, client, package, dữ liệu | `CodeABAP/<KH>/NOTES.md` | Không |

Cuối việc: nếu đã sửa file trong `.claude/skills/**` → nhắc user "có thay đổi skill team chưa commit" (không tự commit/push).
