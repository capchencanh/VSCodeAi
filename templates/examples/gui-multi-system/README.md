# Ví dụ: 1 dự án GUI có nhiều môi trường (DEV / QAS / PRD)

1. Copy `.mcp.json.example` vào `CodeABAP/<KH>/`, đổi `KH`, host, user, client cho đúng khách hàng.
2. Copy thêm 1 bản thành `CodeABAP/<KH>/.mcp.json` rồi điền `SAP_PASSWORD` cho từng server.
   (Hoặc chạy `.\scripts\tao-du-an.ps1 <KH> gui` — tự tạo `.mcp.json` từ example.)

| File | Lên git | Nội dung |
|---|---|---|
| `.mcp.json.example` | **Có** | URL/user/client từng server, `SAP_PASSWORD` để trống `""` |
| `.mcp.json` | **Không** (gitignore) | Giống hệt example nhưng **có mật khẩu** của bạn |

Mỗi server có `SAP_PASSWORD` riêng trong khối `env` → dự án bao nhiêu môi trường, bao nhiêu mật khẩu cũng được.
Sửa `.mcp.json` (thêm server, đổi URL…) xong chạy `.\scripts\cap-nhat-mcp-example.ps1 <KH>` để cập nhật `.mcp.json.example` (mật khẩu tự xoá).

## Vì sao không dùng `.env` / `.vsp.json` / `${BIEN}`

Đã đọc mã nguồn `vsp.exe` (`cmd/vsp/main.go`) và thử nghiệm 19.10.2026:
- `vsp.exe` chế độ MCP chỉ đọc 1 biến `SAP_PASSWORD` (từ `env`/`.env`), **không** đọc `.vsp.json`/`--system`.
- `${BIEN}` trong `.mcp.json` chỉ lấy từ biến môi trường hệ điều hành; khai trong `.claude/settings*.json` **không** có tác dụng (server nhận nguyên chuỗi `${...}` → đăng nhập sai, có thể khoá user).

## Quyền theo môi trường

| Server | Quyền |
|---|---|
| `GUI_KH_DEV100` | Đọc/ghi/activate/transport (`RSQFCUATLI`) |
| `GUI_KH_QAS200` | Chỉ đọc + SQL (`RSQ`) — `--insecure` vì chứng chỉ tự ký |
| `GUI_KH_PRD800` | `--read-only` + user chỉ đọc riêng `CT_READONLY` |

Kiểm tra: mở thư mục dự án trong VS Code → `/mcp` → các server phải connected.
