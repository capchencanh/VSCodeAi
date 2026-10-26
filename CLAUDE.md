# Quy tắc ƯU TIÊN BẮT BUỘC (chạy xuyên suốt, thắng mọi rule khác)

- **Hỏi xác nhận trước khi lưu/tạo**: luôn hỏi user và chờ đồng ý rõ ràng trước khi ghi lên hệ thống SAP (tạo/sửa/activate object, lưu vào TR) và trước khi tạo code/object mới. Chưa được đồng ý → không thực hiện. Ghi file `.md` trên máy (NOTES, TRANG_THAI, nhật ký, ghi chú skill) không cần hỏi.
- **Public Cloud client 80 (Dev) cấm đọc data bằng SQL**: chỉ tự đọc data (RunQuery/GetTableContents/SELECT...) khi client ≠ 80. Cloud client 80 hoặc chưa xác định được client → không tự SELECT, tạo file `.sql` (xem "Độ chính xác") để user tự chạy.

# Quy tắc luôn áp dụng

- Luôn trả lời bằng tiếng Việt, trừ khi người dùng yêu cầu khác.
- Không đọc folder `Backup/` và `CodeABAP/DRAFT/` (code nháp, không dùng làm tham chiếu) — kể cả khi grep/glob toàn project.
- Không tự ý xoá code của object đã có — chỉ comment lại đoạn code bỏ (object đang tự tạo mới thì sửa thẳng).
- **Marker comment code** (ngày `dd.mm.yyyy`, giờ `hh:mm:ss`, vd `" <UserName> add end 03.07.2026 09:28:30`): sửa object đã có → bọc đoạn đổi bằng `"<UserName> add|modify|comment begin <ngày giờ>` … `"<UserName> add|modify|comment end <ngày giờ>`;
  object tạo mới hoàn toàn → không marker từng đoạn, chỉ 1 dòng đầu file `" <UserName> create <dd.mm.yyyy>`. CLAUDE.md/skill dự án quy định khác thì theo dự án.
- `<UserName>` lấy từ file `UserName.md` ở gốc project (file cá nhân, không commit lên git): @UserName.md
  Nếu file không tồn tại hoặc rỗng → hỏi user tên viết tắt, tạo file `UserName.md` chỉ chứa tên đó rồi mới viết code.
- **Trước khi viết/review code ABAP**: xác định nền tảng On-Premise (MCP server `GUI_*`) hay Public Cloud (MCP server `*.s4hana.cloud.sap`); ràng buộc khác nhau (ATC, extensibility, BAPI/EML...) — dùng skill `abap-platform-constraints`.

# Cấu trúc repo (chi tiết: `HUONG_DAN_CAU_TRUC.md`)

- Repo = bộ kit team (`.claude/skills/`, `templates/`, `scripts/`, file này). Dự án ở `CodeABAP/<KH>/` — làm dự án nào mở đúng thư mục đó. Lên repo team chỉ có `.mcp.json.example` (mật khẩu `""`, tạo lại bằng `scripts/cap-nhat-mcp-example.ps1`) + `.claude/settings.json` của dự án; code/tài liệu/NOTES lên **repo riêng từng KH** bằng `scripts/git-du-an.ps1` — **không `git init`/`clone` thẳng vào `CodeABAP/<KH>`** (mất skill team).
- `.mcp.json` dự án có mật khẩu (`env.SAP_PASSWORD`) — chỉ trên máy; không dùng `.env`/`.vsp.json`/`${BIEN}` (vsp.exe MCP không đọc). **Mọi thay đổi `.env`/mật khẩu/cấu hình đăng nhập phải hỏi user trước.** Không tạo `.mcp.json` ở gốc repo (nạp cho mọi thư mục con) — kho cá nhân là `.mcp.all.json`.
- Quy tắc riêng từng người (không lên git) đặt ở `CLAUDE.local.md` gốc repo.
- **Khi chuẩn bị commit/push hoặc sửa `.mcp.json.example`/skill**: chạy `scripts/check-repo.ps1 -All`, sửa hết LỖI theo `QUY_TAC_PUSH.md` trước khi đề xuất commit.

# Quy tắc theo tình huống

- **Khi chuẩn bị gọi MCP tool ABAP lần đầu trong phiên**: server `GUI_*` → skill `sap-mcp-gui`; server `*.s4hana.cloud.sap` → skill `sap-mcp-cloud`. Làm local không qua MCP → `abap-platform-constraints/reference/_ghichu_local.md`. Đọc file ghi chú theo section, không đọc cả file.
- **Khi phát hiện tool MCP chạy tốt/bị lỗi hoặc kiến thức ABAP mới**: ghi ngay (không hỏi) — đúng mọi hệ → file ghi chú trong skill (lên git); chỉ đúng 1 KH → `CodeABAP/<KH>/NOTES.md` (bảng nơi ghi đầy đủ: `.claude/skills/ghi-nhan/SKILL.md`). Đã sửa `.claude/skills/**` → cuối việc nhắc user commit, không tự commit/push.
- **Quy trình chức năng** (FS → thiết kế → code → đẩy DEV → test → bàn giao): mỗi bước 1 lệnh `/cn-fs` `/cn-thiet-ke` `/cn-code` `/cn-day` `/cn-test` `/cn-xong` (đầu ngày `/bat-dau`). User yêu cầu 1 bước bằng lời → đọc `.claude/skills/cn-<bước>/SKILL.md` ở gốc repo rồi làm theo.
- **Khi 1 chức năng chuyển giai đoạn**: cập nhật dòng của nó trong `CodeABAP/<KH>/TRANG_THAI.md` + ghi mốc vào `<CN>/NHAT_KY_<CN>.md`. Trạng thái/quyết định dự án không lưu vào auto-memory.
- **Khi đặt tên object ABAP Cloud/UI mới**: dùng skill `abap-cloud-naming`.
- **Khi khai báo biến/bảng/structure/field-symbol ABAP mới**: dùng skill `abap-naming-convention`.
- **Khi tạo/sửa skill, thêm rule vào file này, hoặc rà soát context bị load thừa**: dùng skill `skill-authoring`.

# Độ chính xác

- Cần dữ liệu thực tế để chẩn đoán/kết luận/sửa lỗi → đọc trực tiếp nếu có thể (MCP, Supabase, REST API...; ngoại lệ: client 80 Cloud, xem rule ưu tiên ở đầu file). Không đoán nội dung data rồi kết luận hay sửa code dựa trên đoán đó.
- Không đọc được (chặn quyền, data nhạy cảm) → viết sẵn câu query cho người dùng tự chạy.
- Mọi SQL/ABAP SQL đưa người dùng tự chạy phải nằm trong file `.sql` (tên `snake_case`, tiền tố `query_`, VD `query_check_du_an_ca_nhan.sql`) — không dán SQL trong khung chat (tránh lỗi format/encoding khi copy). Nhiều câu liên quan cùng 1 việc gộp chung 1 file cũng được. SELECT thô trong file `.sql` nối alias bằng `~` (`main~field`), không dùng `.` (cú pháp CDS).
- Project Supabase đặt file trong `supabase/`; project ABAP/HANA đặt trong `CodeABAP/<KH>/sql/` của dự án đang làm.
