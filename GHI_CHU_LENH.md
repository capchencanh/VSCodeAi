# Ghi chú lệnh

Mở terminal: `` Ctrl+` `` (hoặc chuột phải thư mục trong cây → **Open in Integrated Terminal**)

Mở VS Code mới đúng thư mục terminal đang đứng:

```powershell
code -n .
```

---

Mặc định mở file `.md` ở chế độ Preview: chuột phải file `.md` → **Open With...** → **Configure default editor for '\*.md'...** → **Markdown Preview**

---

Tạo dự án mới (đứng ở gốc repo) → `CodeABAP/<KH>/`:

```powershell
.\scripts\tao-du-an.ps1 <Dự án> gui      # SAP On-Premise (cloud = Public Cloud)
.\scripts\tao-du-an.ps1 <Dự án>          # dự án không phải SAP
```

Tạo bộ thư mục chức năng (FS, TS, TestCase...) → `CodeABAP/<KH>/<CN>/`:

```powershell
.\scripts\tao-chuc-nang.ps1 <Dự án> <Tcode - Chức năng>
```

Hoặc không gõ lệnh: `Ctrl+Shift+P` → **Tasks: Run Task** → **Tạo chức năng mới**

Sửa `.mcp.json` dự án (thêm server, đổi URL...) xong → cập nhật `.mcp.json.example` (xoá mật khẩu) để đẩy git:

```powershell
.\scripts\cap-nhat-mcp-example.ps1 <Dự án>
```

---

Đầu ngày (pull repo team + repo dự án, kiểm tra, việc đang chờ) — hoặc task **Bắt đầu ngày**:

```powershell
.\scripts\bat-dau-ngay.ps1
```

Lưu code/tài liệu dự án lên repo dự án (bỏ `<Dự án>` = mọi dự án) — hoặc task **Lưu dự án**:

```powershell
.\scripts\git-du-an.ps1 luu <Dự án>
```

Nhận dự án của team / nối repo GitHub lần đầu (`citekcstech/abap-<kh>`):

```powershell
.\scripts\git-du-an.ps1 noi <Dự án>
```

---

Lệnh gõ trong khung chat Claude (đang mở `CodeABAP/<KH>` thì bỏ `<KH>`):

```text
/bat-dau                 đầu ngày: việc đang chờ + lệnh gợi ý
/cn-fs <KH> <CN>         đọc FS, soạn câu hỏi
/cn-thiet-ke <KH> <CN>   object list + thiết kế, xin duyệt
/cn-code <KH> <CN>       viết code local + tự kiểm
/cn-day <KH> <CN>        đẩy DEV (hỏi xác nhận trước)
/cn-test <KH> <CN>       test case + sửa lỗi
/cn-xong <KH> <CN>       bàn giao, đóng, lưu
/ghi-nhan <nội dung>     ghi phát hiện vào đúng chỗ
```

---
