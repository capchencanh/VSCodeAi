---
name: sap-mcp-gui
description: 'Quy trình làm việc và kho lỗi đã biết của MCP server `vsp.exe` kết nối SAP S/4HANA On-Premise (server tên `GUI_*`, auth `SAP_USER`/`SAP_PASSWORD`) — tool nào chạy/lỗi (ghi PROG/I, WebSocket ZADT_VSP, TRAN/T, GetPackage quá tải...), cách vòng, lỗi mạng/VPN, nơi ghi lỗi mới. TRIGGER — chỉ đọc khi (1) sắp gọi tool MCP `GUI_*` lần đầu trong phiên; (2) 1 tool `GUI_*` trả lỗi/kết quả lạ (dial tcp, package metadata, WebSocket 500, uriMappingError); (3) vừa phát hiện tool `GUI_*` chạy tốt/bị lỗi và cần ghi nhận. SKIP — không đọc khi: server Public Cloud (dùng `sap-mcp-cloud`), viết code local không gọi MCP, hỏi cú pháp ABAP chung, đặt tên object.'
---

# MCP SAP On-Premise (GUI_*)

Kho kiến thức: [reference/_ghichu_mcp_gui.md](reference/_ghichu_mcp_gui.md) (T3, ~325 dòng).
**Không đọc cả file**: `grep -n '^## ' <file>` → `sed -n '<từ>,<đến>p'` đúng section cần. Phần đầu file (trước `## 1`) còn chứa finding chưa phân loại — grep theo message lỗi thay vì đọc tuần tự.

## Trước khi gọi tool lần đầu

1. Xác định server từ `.mcp.json` của **project đang mở** (`CodeABAP/<KH>/.mcp.json`). Đọc `CodeABAP/<KH>/CLAUDE.md` để biết hệ DEV/QAS/PRD, client, quyền ghi, giờ VPN.
2. `GetConnectionInfo` chỉ trả config tĩnh — muốn biết kết nối thật phải gọi `GetSystemInfo`.
3. Lỗi `dial tcp`/`connectex`/`no such host` → khả năng VPN/mạng (xem `NOTES.md` của KH về khung giờ VPN). Báo user, không thử lại nhiều lần, chuyển sang việc không cần MCP.
4. Server **PRD**: chỉ đọc. Không gọi tool ghi/activate/transport dù config cho phép.

## Khi gặp lỗi

1. Grep message lỗi trong file kho: `grep -n -i '<đoạn message>' <file>`.
2. Có rồi → làm theo cách vòng. Chưa có → chẩn đoán, rồi ghi nhận theo bảng dưới.

## Ghi nhận phát hiện mới (không cần hỏi, nhưng phải đúng nơi)

| Loại phát hiện | Ghi vào | Lên git? |
|---|---|---|
| Hành vi tool `vsp.exe` đúng mọi hệ On-Premise | `reference/_ghichu_mcp_gui.md` đúng section (theo khối "CÁCH GHI THÊM 1 MỤC MỚI" đầu file) | Có — báo user commit |
| Kiến thức ABAP/DDIC chung | `SKILL.md` của skill liên quan hoặc `abap-platform-constraints/reference/_ghichu_local.md` | Có — báo user commit |
| Riêng 1 KH: host, client, user, giờ VPN, DDIC riêng hệ đó | `CodeABAP/<KH>/NOTES.md` | Không |

Cuối việc: nếu đã sửa file trong `.claude/skills/**` → nhắc user "có thay đổi skill team chưa commit" (không tự commit/push).
