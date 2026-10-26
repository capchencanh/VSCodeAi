# Hướng dẫn cấu trúc repo VSCodeSkillAI

Repo này là **bộ kit dùng chung của team** cho Claude Code khi làm SAP ABAP (Public Cloud và On-Premise/GUI).
Có 2 loại repo git, cùng nằm trên 1 thư mục máy bạn:

| Repo | Chứa | Ai thấy |
|---|---|---|
| **Repo team** `citekcstech/VSCodeSkillAI` (repo này) | skill, script, template, `CLAUDE.md` gốc, cấu hình kết nối dự án (`.mcp.json.example`, `.claude/settings.json`) | cả team |
| **Repo dự án** `citekcstech/abap-<kh>` (private, 1 KH 1 repo) | code, FS, TS, test case, `CLAUDE.md`/`NOTES.md`/`TRANG_THAI.md` của dự án — toàn bộ `CodeABAP/<KH>/` trừ mật khẩu | người làm KH đó |

Mật khẩu (`CodeABAP/<KH>/.mcp.json`) **không lên repo nào**. Chi tiết repo dự án: mục 8.

## 1. Sơ đồ thư mục

`[team]` = lên repo team · `[dự án]` = lên repo dự án · `[máy]` = chỉ trên máy bạn

```
VSCodeSkillAI/
├── CLAUDE.md                  [team]  Quy tắc chung team — Claude Code tự nạp ở mọi thư mục con
├── CLAUDE.local.md            [máy]   Quy tắc riêng của bạn (tự nạp)
├── UserName.md                [máy]   Tên viết tắt dùng trong marker comment code
├── HUONG_DAN_CAU_TRUC.md      [team]  File này
├── QUY_TAC_PUSH.md            [team]  Quy tắc push repo team (R1–R11)
├── .mcp.all.json              [máy]   Kho server MCP cá nhân (nguồn cho tao-du-an.ps1 -Servers).
│                                      KHÔNG đặt tên .mcp.json ở gốc — xem "Lưu ý MCP" mục 3
├── .git-du-an/<KH>.git        [máy]   Dữ liệu git của từng repo dự án (mục 8) — không sửa tay
├── .claude/skills/            [team]  Skill dùng chung (mục 4)
├── templates/                 [team]  Mẫu cho dự án mới
│   ├── mcp/cloud|gui|khac.mcp.json.example
│   ├── examples/gui-multi-system/   Ví dụ 1 dự án GUI nhiều môi trường (DEV/QAS/PRD)
│   ├── project/CLAUDE.md, CLAUDE.khac.md, NOTES.md, TRANG_THAI.md, tasks.json
│   └── feature/CAU_HOI_FS.md, NHAT_KY.md, HUONG_DAN_TAO.md, TEST_CASE.md   Mẫu cho tao-chuc-nang.ps1
├── scripts/                   [team]
│   ├── bat-dau-ngay.ps1       Đầu ngày: pull repo team + repo dự án, check-repo, liệt kê việc đang chờ
│   ├── tao-du-an.ps1          Tạo dự án: tao-du-an.ps1 <KH> <gui|cloud>  → CodeABAP/<KH>/ + repo dự án
│   ├── tao-chuc-nang.ps1      Tạo bộ thư mục chức năng: tao-chuc-nang.ps1 <KH> <CN>  → CodeABAP/<KH>/<CN>/
│   ├── git-du-an.ps1          Repo dự án: tao | noi | luu | lay | xem (mục 8)
│   ├── cap-nhat-mcp-example.ps1  Tạo lại .mcp.json.example từ .mcp.json (xoá mật khẩu)
│   ├── check-repo.ps1         Kiểm tra quy tắc push R1–R11 (QUY_TAC_PUSH.md)
│   └── hooks/pre-commit       Gọi check-repo.ps1 -Staged, có LỖI thì chặn commit
├── .vscode/tasks.json         [team]  Task VS Code (Ctrl+Shift+P → Tasks: Run Task), xem mục 3
├── .github/workflows/check-repo.yml   [team] Chạy check-repo.ps1 -All trên GitHub mỗi lần push/PR
└── CodeABAP/<KH>/             Dự án theo khách hàng
    ├── .mcp.json              [máy]   Server MCP (có mật khẩu server GUI)
    ├── .mcp.json.example      [team]  Giống .mcp.json nhưng SAP_PASSWORD = ""
    ├── .claude/settings.json  [team]  Tắt sẵn server refresh cookie
    ├── .claude/skills/<kh>-*  [dự án] Skill riêng KH (vd AVN)
    ├── CLAUDE.md              [dự án] Nền tảng, server, client, tiền tố object
    ├── NOTES.md               [dự án] Landscape + lỗi chỉ đúng hệ KH
    ├── TRANG_THAI.md          [dự án] Bảng trạng thái từng chức năng (task "Bắt đầu ngày" đọc file này)
    ├── <CN>/  sql/  src/      [dự án] Chức năng, câu SQL đưa user chạy, code chung
    └── .vscode/tasks.json     [dự án] Task khi mở riêng thư mục dự án
```

**Nguyên tắc**: đúng cho mọi dự án → skill/template ở repo team. Kết nối của 1 KH (URL, user, client) → `.mcp.json.example` ở repo team. Mọi thứ khác của dự án → repo dự án. Mật khẩu → chỉ trên máy.

## 2. Thiết lập lần đầu (mỗi thành viên)

1. Clone repo team, mở PowerShell tại gốc repo.
2. Bật hook kiểm tra quy tắc push: `git config core.hooksPath scripts/hooks`
3. Tạo `UserName.md` ở gốc, chỉ chứa tên viết tắt của bạn (VD `NghiaHuynh`).
4. (Tuỳ chọn) Tạo `CLAUDE.local.md` cho quy tắc riêng của bạn.
5. **Đăng nhập SAP (server GUI) — ghi thẳng trong `.mcp.json` của dự án:**
   - `CodeABAP/<KH>/.mcp.json` **[máy, có mật khẩu]** — mỗi server GUI: `"env": { "SAP_URL": "...", "SAP_USER": "...", "SAP_CLIENT": "...", "SAP_PASSWORD": "<mật khẩu>" }`. Nhiều môi trường (DEV/QAS/PRD) → mỗi server 1 mật khẩu riêng.
   - `CodeABAP/<KH>/.mcp.json.example` **[team]** — giống hệt nhưng `"SAP_PASSWORD": ""`. **Không sửa tay**: sửa `.mcp.json` xong chạy `.\scripts\cap-nhat-mcp-example.ps1 <KH>` (bỏ `<KH>` = mọi dự án). `check-repo.ps1 -All` cảnh báo `R10` nếu 2 file lệch nhau.
   - Không dùng `.env` / `.vsp.json` / `${BIEN}`: `vsp.exe` chế độ MCP chỉ đọc biến `SAP_PASSWORD`, không đọc `.vsp.json`/`--system`; `${BIEN}` không lấy được từ `.claude/settings*.json` (đọc mã nguồn `cmd/vsp/main.go` + thử nghiệm 19.10.2026).
   - **Ví dụ đầy đủ DEV/QAS/PRD**: [templates/examples/gui-multi-system/](templates/examples/gui-multi-system/README.md).
   - Kiểm tra: mở thư mục dự án → `/mcp` → server phải connected. `SAP URL is required` = thiếu `SAP_URL` trong `env`; `authentication required` = thiếu `SAP_PASSWORD`; `401 Logon failed` = sai mật khẩu (đừng thử lại nhiều lần kẻo khoá user).
   - User dùng chung: `SAP_USER` nên là user kỹ thuật chung (vd `CT_AI`), không dùng user cá nhân.

## 3. Tạo và làm việc với 1 dự án

**Task VS Code** (mở gốc repo → `Ctrl+Shift+P` → **Tasks: Run Task**):

| Task | Làm gì |
|---|---|
| **Bắt đầu ngày** | pull repo team + mọi repo dự án, chạy check-repo, liệt kê việc đang chờ trong `TRANG_THAI.md` |
| **Tạo dự án mới** | `tao-du-an.ps1 <KH> <gui\|cloud\|khac>` (tự tạo repo dự án + commit đầu) |
| **Nhận dự án của team** | `git-du-an.ps1 noi <KH>` — lấy code dự án từ GitHub |
| **Tạo chức năng mới** | `tao-chuc-nang.ps1 <KH> <CN>` |
| **Lưu tất cả dự án** | `git-du-an.ps1 luu` — commit + đẩy mọi repo dự án có thay đổi |
| **Kiểm tra trước khi push repo team** | `check-repo.ps1 -All` |

Mở riêng thư mục `CodeABAP/<KH>` thì có task **Tạo chức năng mới** (chỉ hỏi tên chức năng), **Lưu dự án**, **Lấy bản mới dự án**.

**Tạo dự án mới** (terminal tại gốc repo):

```powershell
# Lấy server từ kho .mcp.all.json (tên server TRONG KHO; script tự đổi sang CLD_SGC_* theo quy ước mục 7)
.\scripts\tao-du-an.ps1 SGC cloud -Client 080 -Servers mcp_SGC_DEV,mcp_SGC_CUS,Cloud_Refresh_SGC_DEV,Cloud_Refresh_SGC_CUS
# Hoặc sinh từ template (sửa SAP_URL/SAP_USER/SAP_PASSWORD trong .mcp.json)
.\scripts\tao-du-an.ps1 CADIVI gui -Client 800
# Dự án KHÔNG phải SAP: bỏ trống nền tảng (loại 'khac': src/, .mcp.json rỗng, CLAUDE.md chung)
.\scripts\tao-du-an.ps1 MCP_VPS
```

Script tạo `.mcp.json`, `.mcp.json.example`, `.claude/settings.json`, `CLAUDE.md`, `NOTES.md`, `TRANG_THAI.md`, `.vscode/tasks.json`, rồi **tạo repo dự án + commit đầu** (chưa lên GitHub — xem mục 8 để nối). Không ghi đè file đã có. Sau đó mở `CodeABAP/<KH>/CLAUDE.md` bổ sung thông tin riêng (CUS/PRD chỉ đọc, tiền tố object...). Đẩy cấu hình kết nối cho team: commit `CodeABAP/<KH>/.mcp.json.example` + `.claude/settings.json` vào repo team.

**Nhận dự án đồng nghiệp đã đẩy:**

```powershell
git pull                                   # repo team: có CodeABAP/ACG/.mcp.json.example
.\scripts\git-du-an.ps1 noi ACG            # lấy code dự án từ citekcstech/abap-acg (cần quyền repo)
.\scripts\tao-du-an.ps1 ACG gui            # tạo .mcp.json từ example → điền SAP_PASSWORD từng server GUI
```

**Tạo cây thư mục cho 1 chức năng mới** — chỉ cần tên dự án + tên chức năng:

```powershell
.\scripts\tao-chuc-nang.ps1 AVN YPS05        # tại gốc repo
..\..\scripts\tao-chuc-nang.ps1 YPS05        # đang đứng trong CodeABAP\AVN → tự nhận dự án
```

```
CodeABAP/<KH>/<CN>/
├── FS/                      FS khách hàng
├── TS/                      Technical Specification
├── TestCase/TEST_CASE_<CN>.md   bảng test case + lỗi phát hiện (ảnh lỗi để cùng thư mục)
├── CAU_HOI_FS_<CN>.md       câu hỏi chốt FS với tư vấn
├── NHAT_KY_<CN>.md          mốc tiến độ + quyết định (lệnh /cn-* tự ghi)
├── GUI:   dictionary/  src/  form zxlwb/scripts/  ref/  HUONG_DAN_TAO_<CN>.md
│          (ref/ = code chương trình cũ/chuẩn để tham chiếu, không sửa)
├── Cloud: cds/  class/  ui5/
└── Khác (không SAP): src/
```

Tên file code theo kiểu abapGit (`.prog.abap`, `.clas.abap`, `.ddls.asddls`). Nền tảng tự nhận theo `.mcp.json` của dự án (server `GUI_*` → GUI, `CLD_*` → Cloud, không có → Khác), ép bằng `-Platform gui|cloud|khac`. Chạy lại chỉ bổ sung phần thiếu. Chức năng tạo trước 23.10.2026 giữ nguyên bố cục cũ.

**Làm việc hằng ngày:**

1. VS Code → **File → Open Folder → `CodeABAP/<KH>`**. Mỗi khách hàng 1 cửa sổ, chạy song song được.
2. Lần đầu mở: Claude Code hỏi duyệt các server trong `.mcp.json` → đồng ý. Gõ `/mcp` kiểm tra **chỉ thấy server của KH đó**.
3. Trong khung chat Claude gõ **`/bat-dau`** (hoặc task **Bắt đầu ngày**): lấy bản mới, liệt kê việc đang chờ kèm lệnh nên chạy tiếp.
4. Làm từng chức năng bằng lệnh quy trình (bảng dưới). Mỗi lệnh tự cập nhật `TRANG_THAI.md` + `<CN>/NHAT_KY_<CN>.md`.
5. Cuối ngày: task **Lưu dự án** / **Lưu tất cả dự án** (hoặc `/cn-xong` khi chức năng xong — lệnh hỏi trước khi lưu).
6. Cookie Cloud hết hạn → bật server `*refresh*` của KH (đang tắt sẵn trong `.claude/settings.json`; bật tạm qua `/mcp`, hoặc tạo `.claude/settings.local.json` với `"disabledMcpjsonServers": []` rồi mở lại phiên), đăng nhập trên trình duyệt, xong thì tắt lại. **Không sửa `.claude/settings.json`** (file của team).

**Lệnh quy trình chức năng** (gõ trong khung chat; `[KH]` bỏ được khi đang mở `CodeABAP/<KH>`; nói bằng lời "phân tích FS YPS05" cũng được):

| Lệnh | Làm gì | Giai đoạn sau |
|---|---|---|
| `/bat-dau [KH]` | Pull, check-repo, bảng việc chờ + lệnh gợi ý | — |
| `/cn-fs [KH] <CN>` | Tạo thư mục (nếu chưa có), đọc FS, đối chiếu hệ thống, soạn `CAU_HOI_FS_<CN>.md`. Chạy lại khi có trả lời/FS mới | `Hỏi` |
| `/cn-thiet-ke [KH] <CN>` | Object list + luồng + quyết định → `TS/THIET_KE_<CN>.md` → **xin duyệt** | `Code` |
| `/cn-code [KH] <CN>` | Viết code local, tự kiểm, báo duyệt | `Code` |
| `/cn-day [KH] <CN>` | **Xác nhận** → đẩy DEV đúng thứ tự, kiểm activate/ATC, ghi TR | `Đẩy` |
| `/cn-test [KH] <CN>` | Test case, file `.sql` dữ liệu test, vòng sửa lỗi | `Test` |
| `/cn-xong [KH] <CN>` | Tiêu chí xong, hướng dẫn tạo tay/TS, rút kinh nghiệm, lưu repo dự án | `Xong` |
| `/ghi-nhan [nội dung]` | Ghi 1 phát hiện vào đúng nơi (mục 5) | — |

Dự án có quy trình riêng (vd AVN `avn-fs-to-chuc-nang`) → lệnh `/cn-*` tự áp thêm phần riêng đó.

**Lưu ý MCP (đã kiểm chứng 19.10.2026, Claude Code 2.1.237):** nếu **gốc repo có `.mcp.json`**, Claude Code nạp file đó cho **mọi thư mục con** → mở `CodeABAP/<KH>` vẫn thấy server của gốc. Vì vậy gốc repo **không** có `.mcp.json` (kho cá nhân đặt tên `.mcp.all.json`). `check-repo.ps1 -All` cảnh báo `R9` nếu gốc lại có `.mcp.json`.

Claude Code tự nạp khi mở `CodeABAP/<KH>`: `CLAUDE.md` + `CLAUDE.local.md` ở gốc repo, `CLAUDE.md` của dự án, toàn bộ skill trong `.claude/skills/` gốc repo và skill trong `CodeABAP/<KH>/.claude/skills/` — **với điều kiện `CodeABAP/<KH>` không có `.git` riêng** (mục 8). Auto-memory dùng chung cho cả repo nhưng chỉ nằm trên máy bạn.

## 4. Skill theo nhóm

| Nhóm | Skill |
|---|---|
| **MCP** | `sap-mcp-cloud`, `sap-mcp-gui` |
| **Public Cloud** | `abap-cloud`, `abap-cloud-naming`, `abap-rap-query-provider`, `sap-fiori-guidelines`, `ui5-best-practices` |
| **On-Premise (GUI)** | `abap-naming-convention`, `smartforms-xml`, `adobe-form-xml`, `zxlwb-workbench`, `sap-ts-document`, `badi-enhancement`, `abap-fi-upload-fidoc` |
| **Dùng chung** | `abap-platform-constraints`, `abap-performance-hana`, `abap-sql-amdp`, `authorization-iam`, `abap` (Clean ABAP), `sap-atc-checker-main` |
| **Quy trình / tài liệu** | `skill-authoring`, `skill-specification`, `spec-writing`, `context-guard` |
| **Lệnh** (chỉ chạy khi gõ `/tên`) | `bat-dau`, `cn-fs`, `cn-thiet-ke`, `cn-code`, `cn-day`, `cn-test`, `cn-xong`, `ghi-nhan` |
| **Riêng KH** (repo dự án) | `CodeABAP/AVN/.claude/skills/avn-*` |

Skill thường chỉ được nạp phần `description`; thân skill chỉ đọc khi tình huống khớp TRIGGER. Skill **lệnh** (`disable-model-invocation: true`) không nạp gì vào context cho tới khi bạn gõ lệnh. Không đặt skill trùng tên ở `~/.claude/skills` — bản cá nhân sẽ che bản team (`check-repo -All` cảnh báo R7).

## 5. Ghi nhận lỗi và kiến thức mới

Claude tự ghi (không hỏi) theo bảng sau; muốn chủ động ghi 1 điều thì gõ `/ghi-nhan <nội dung>` (bảng đầy đủ + cách giữ gọn: `.claude/skills/ghi-nhan/SKILL.md`). Đi từ trên xuống, dừng ở dòng đầu tiên khớp:

| Phát hiện | Ghi vào | Ai thấy |
|---|---|---|
| Trạng thái / quyết định của 1 chức năng | `TRANG_THAI.md` + `<CN>/NHAT_KY_<CN>.md` (quyết định FS → `CAU_HOI_FS_<CN>.md`) | Người làm KH đó (repo dự án) |
| Chỉ đúng 1 KH (host, client, giờ VPN, customizing, DDIC riêng) | `CodeABAP/<KH>/NOTES.md` | Như trên |
| Quy ước/quy trình riêng 1 KH dùng cho nhiều chức năng | `CodeABAP/<KH>/CLAUDE.md` hoặc skill `CodeABAP/<KH>/.claude/skills/<kh>-*` | Như trên |
| Tool MCP lỗi/chạy tốt, đúng mọi hệ cùng nền tảng | `.claude/skills/sap-mcp-<cloud\|gui>/reference/_ghichu_mcp_*.md` | Team, sau khi bạn commit + push repo team |
| Kiến thức ABAP/CDS chung | `_ghichu_local.md` (+ bản rút gọn vào `SKILL.md` liên quan nếu hay gặp) | Như trên |
| Khung/pattern code tái dùng nhiều KH | Skill team mới (`skill-authoring`, nhánh + PR) | Như trên |
| Sở thích/cách làm của riêng bạn | `CLAUDE.local.md` hoặc auto-memory | Chỉ bạn |

- **Không ghi trạng thái/quyết định dự án vào auto-memory** — team không thấy và dễ lệch với `TRANG_THAI.md`.
- **Giữ gọn**: cùng 1 ý xuất hiện ở `NOTES.md` của ≥ 2 KH → tổng quát hoá lên skill team, `NOTES.md` chỉ giữ phần riêng + link; skill `<kh>-*` dùng được cho KH khác → tách phần chung thành skill team.

- Sửa skill có hiệu lực **ngay trên máy bạn**. **Không tự lên git** — Claude nhắc cuối việc, bạn tự xem diff rồi commit.
- Mỗi mục ghi chú theo khối **"CÁCH GHI THÊM 1 MỤC MỚI"** ở đầu file: triệu chứng → kết luận, có ngày, đánh dấu `[CONFIRMED]`/`[NGHI NGỜ/TODO]`, không trùng mục cũ, không khoá tên KH.

## 6. Đóng góp lên repo team

**Bộ quy tắc push đầy đủ (R1–R11) và cách bị chặn: [QUY_TAC_PUSH.md](QUY_TAC_PUSH.md).** Tóm tắt:

1. `git pull` trước khi sửa (file ghi chú do nhiều người cùng ghi, dễ conflict).
2. **Nhánh**: việc nhỏ (ghi chú, sửa nội dung skill) commit + push thẳng `main`; đổi script/quy tắc/skill mới → nhánh ngắn `<UserName>/<việc>` + PR, merge xong xoá nhánh. Không giữ nhánh cá nhân lâu dài.
3. Trước khi push chạy task **Kiểm tra trước khi push repo team** — hook `pre-commit` và GitHub Actions cũng chạy, có LỖI là chặn.
4. Skill mới hoặc sửa `description`: theo skill `skill-authoring` (công thức 3 vế chủ đề / TRIGGER / SKIP, test 6 câu).
5. Commit nhỏ, message nói rõ skill/dự án nào. Trong `CodeABAP/` repo team chỉ nhận `.mcp.json.example`, `.claude/settings.json`.

## 7. Quy ước

- **Tên server MCP** (trong `CodeABAP/<KH>/.mcp.json`, `<KH>` viết hoa = tên thư mục dự án):

  | Loại | Tên server | File cookie (`C:\Citek\vibing-steampunk\`) | Mật khẩu |
  |---|---|---|---|
  | Cloud chính | `CLD_<KH>_DEV`, `CLD_<KH>_CUS` | `cookies-cloud-<KH>_DEV.txt`, `cookies-cloud-<KH>_CUS.txt` | — |
  | Cloud refresh cookie | `CLD_<KH>_REFRESH_DEV`, `CLD_<KH>_REFRESH_CUS` | cùng file với server chính tương ứng (`--cookie-save`) | — |
  | GUI | `GUI_<KH>_<DEV\|QAS\|PRD><client>` (vd `GUI_ACG_DEV300`) | — | `env.SAP_PASSWORD` của server trong `.mcp.json` (máy) |

  Ngoại lệ: AVN dùng hệ test nội bộ S19 → `GUI_S19_DEV100`. `tao-du-an.ps1 -Servers ...` tự đổi tên server và đường dẫn cookie theo bảng này.
- **Cookie là riêng từng máy** (không lên git): nhận dự án mới → chạy server `CLD_<KH>_REFRESH_*` (bật tạm qua `/mcp`) để đăng nhập trình duyệt, file cookie đúng tên sẽ được tạo.
- Server **PRD chỉ đọc** — không gọi tool ghi/activate/transport.
- File SQL đưa user tự chạy: `CodeABAP/<KH>/sql/query_<việc>.sql`.
- **Repo dự án**: `citekcstech/abap-<kh>` (chữ thường), private, chỉ mời người làm KH đó.

## 8. Repo dự án (`scripts/git-du-an.ps1`)

**Vì sao không `git init` trong `CodeABAP/<KH>`:** thư mục có `.git` riêng thì Claude Code dừng tìm skill tại đó → **mất toàn bộ skill của repo team** (vẫn nạp `CLAUDE.md` gốc). Đã thử 23.10.2026, Claude Code 2.1.237. Vì vậy dữ liệu git của repo dự án nằm ở `.git-du-an/<KH>.git` (gốc repo team, đã gitignore), thư mục dự án không có `.git`. `check-repo.ps1 -All` báo LỖI `R11` nếu thấy `CodeABAP/<KH>/.git`.

| Lệnh | Khi nào |
|---|---|
| `.\scripts\git-du-an.ps1 tao <KH>` | Dự án mới chưa có repo (tao-du-an.ps1 tự gọi) — tạo repo + commit đầu, chỉ trên máy |
| `.\scripts\git-du-an.ps1 noi <KH>` | Đã tạo repo **private** `citekcstech/abap-<kh>` trên GitHub: đẩy lần đầu, hoặc nhận dự án đồng nghiệp (file trên máy trùng tên mà khác bản GitHub được sao lưu vào `.git-du-an/<KH>.bak-<giờ>/` trước). URL khác: `-Url <url>` |
| `.\scripts\git-du-an.ps1 luu [<KH>] [-m "..."]` | Lưu: add + commit + push. Bỏ `<KH>` = mọi dự án. Chặn file có mật khẩu thật hoặc > 50 MB. GitHub có bản mới hơn → tự lấy về rồi đẩy lại; xung đột thật → huỷ gộp, giữ nguyên bản trên máy, báo tên file |
| `.\scripts\git-du-an.ps1 lay [<KH>]` | Lấy bản mới của đồng nghiệp |
| `.\scripts\git-du-an.ps1 xem [<KH>]` | Thay đổi chưa lưu, commit chưa đẩy, 3 commit gần nhất |

- Đứng trong `CodeABAP\<KH>` thì bỏ `<KH>`. Lệnh git bất kỳ: `git --git-dir=.git-du-an\<KH>.git --work-tree=CodeABAP\<KH> <lệnh>`.
- Không lên repo dự án: `.mcp.json` (mật khẩu), `.mcp.json.example` + `.claude/settings.json` (thuộc repo team), `cookies*.txt`, `.env`, `*.rar`, `*.zip`.
- Repo dự án **không** có hook `check-repo` — chỉ có kiểm tra mật khẩu/kích thước trong `luu`.
