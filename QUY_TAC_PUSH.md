# Quy tắc push repo VSCodeSkillAI

Áp dụng cho mọi thành viên khi commit/push **repo team**. Code/tài liệu dự án đi repo dự án riêng (`scripts/git-du-an.ps1`, xem `HUONG_DAN_CAU_TRUC.md` mục 8) — không thuộc các quy tắc này. Các quy tắc được **kiểm tự động** bằng `scripts/check-repo.ps1`:

- **Trên máy bạn**: hook `pre-commit` chặn commit có LỖI. Bật 1 lần sau khi clone: `git config core.hooksPath scripts/hooks`
- **Trên GitHub**: workflow `check-repo` chạy lại mọi lần push / pull request (bắt cả trường hợp chưa bật hook hoặc commit `--no-verify`).
- **Chạy tay** trước khi push: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check-repo.ps1 -All`

**LỖI** = chặn commit/push. **CẢNH BÁO** = chỉ nhắc, nên sửa khi đụng tới file đó.

## Bảng quy tắc

| Mã | Quy tắc | Mức |
|---|---|---|
| **R1** | **Không có mật khẩu thật** trong bất kỳ file nào: `"SAP_PASSWORD"`/`"password"` có giá trị, `SAP_PASSWORD=`/`VSP_<HỆ>_PASSWORD=` có giá trị, `--password` trong args. `SAP_PASSWORD` trong `.mcp.json.example` phải là `""`. Chỉ được placeholder: rỗng, `...`, `<...>`, `${BIEN}`, `__X__`, `***`. | LỖI |
| **R2** | **Không đẩy file cá nhân/bí mật**: `.mcp.json` (gốc repo **và** `CodeABAP/<KH>/.mcp.json` — có mật khẩu), `.mcp.all.json`, `.vsp.json`, `.env`, `cookies*.txt`, `UserName.md`, `CLAUDE.local.md`, `*.bak`, `Backup/`, `.agents/`, `.git-du-an/`, `skills-lock.json`. Trong `CodeABAP/` **chỉ** được đẩy `CodeABAP/<KH>/.mcp.json.example`, `.claude/settings.json` — phần còn lại lưu bằng `.\scripts\git-du-an.ps1 luu <KH>`. | LỖI |
| **R3** | **Tên server MCP đúng quy ước** (`<KH>` = tên thư mục dự án, viết hoa): Cloud `CLD_<KH>_<DEV\|CUS>`, refresh `CLD_<KH>_REFRESH_<DEV\|CUS>`, cookie `cookies-cloud-<KH>_<DEV\|CUS>.txt`; GUI `GUI_<KH>_<DEV\|QAS\|PRD><client>`. `.mcp.json.example` phải là JSON hợp lệ. | LỖI |
| **R4** | **Server GUI khai báo đúng cách `vsp.exe` đọc ở chế độ MCP**: có `SAP_URL` trong `env` (thiếu `SAP_USER`/`SAP_CLIENT` → cảnh báo); **không** dùng `--system` hay `.vsp.json` (chế độ MCP bỏ qua → lỗi `SAP URL is required`). | LỖI / CẢNH BÁO |
| **R5** | **Server refresh cookie phải tắt sẵn**: mọi `CLD_<KH>_REFRESH_*` nằm trong `disabledMcpjsonServers` của `CodeABAP/<KH>/.claude/settings.json`. | LỖI |
| **R6** | **PRD chỉ đọc**: server `GUI_*_PRD*` có `--read-only`. | LỖI |
| **R7** | **Skill đúng chuẩn**: `SKILL.md` có frontmatter, `name` trùng tên thư mục, có `description` ≤ 1024 ký tự (LỖI). Description theo công thức 3 vế chủ đề / TRIGGER / SKIP — trừ skill lệnh `disable-model-invocation: true`; file `.md` không dùng marker kiểu code `" ... add begin/end`; không trùng tên skill ở `~/.claude/skills` (bản cá nhân che bản team — chỉ kiểm khi `-All` trên máy) (CẢNH BÁO). Chi tiết: skill `skill-authoring`. | LỖI / CẢNH BÁO |
| **R8** | **File ≤ 5 MB** (tài liệu lớn, file Excel/FS khách hàng để ngoài repo). | LỖI |
| **R9** | **Gốc repo không có `.mcp.json`** trên máy bạn — Claude Code nạp nó cho mọi thư mục con, làm lẫn server giữa các dự án. Kho cá nhân đặt tên `.mcp.all.json`. (Chỉ kiểm khi chạy `-All` trên máy.) | CẢNH BÁO |
| **R10** | **`.mcp.json.example` khớp `.mcp.json` trên máy** (trừ mật khẩu). Lệch → chạy `.\scripts\cap-nhat-mcp-example.ps1 <KH>` để tạo lại example. (Chỉ kiểm khi chạy `-All` trên máy.) | CẢNH BÁO |
| **R11** | **`CodeABAP/<KH>/` không có `.git` riêng** — có `.git` thì Claude Code mất toàn bộ skill repo team khi mở thư mục đó. Repo dự án dùng `.\scripts\git-du-an.ps1` (git-dir ở `.git-du-an/`). (Chỉ kiểm khi chạy `-All` trên máy.) | LỖI |

## Quy ước không kiểm tự động (review khi tạo PR)

- Lỗi/kinh nghiệm **đúng mọi hệ** → file ghi chú trong skill (`sap-mcp-cloud`, `sap-mcp-gui`, `_ghichu_local.md`) theo khối "CÁCH GHI THÊM 1 MỤC MỚI" đầu file. Chỉ đúng **1 khách hàng** → `CodeABAP/<KH>/NOTES.md` (repo dự án).
- Skill mới / sửa `description`: tự chạy "test 6 câu" (skill `skill-authoring`) trước khi đẩy.
- **Nhánh**: việc nhỏ (ghi chú, nội dung skill) push thẳng `main`; đổi script/quy tắc/skill mới → nhánh ngắn `<UserName>/<việc>` + PR, merge xong xoá nhánh. Không giữ nhánh cá nhân lâu dài (skill sửa trên nhánh riêng thì team không nhận được).
- Commit nhỏ, message nói rõ skill/dự án nào. `git pull` trước khi sửa file ghi chú dùng chung.
- `SAP_USER` trong `.mcp.json.example` nên là user kỹ thuật dùng chung (vd `CT_AI`), không dùng user cá nhân.

## Khi bị chặn

1. Đọc dòng `LOI [Rx] <file> : <lý do>` → sửa theo bảng trên.
2. Lỡ commit mật khẩu từ trước: **đổi mật khẩu ngay**, rồi báo người quản lý repo để xoá khỏi lịch sử git.
3. Không dùng `git commit --no-verify` để lách — GitHub vẫn chạy lại kiểm tra và báo đỏ.
