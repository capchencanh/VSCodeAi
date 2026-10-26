---
name: skill-authoring
description: 'Chuẩn viết file .md điều khiển context trong repo này — SKILL.md, CLAUDE.md, file ghi chú lớn (_ghichu_*.md). TRIGGER — chỉ đọc khi (1) tạo mới / sửa 1 skill (`.claude/skills/<ten>/SKILL.md`), đặc biệt là field `description`; (2) thêm/sửa rule trong `CLAUDE.md` hoặc quyết định rule nên nằm ở CLAUDE.md hay tách ra skill; (3) rà soát lại toàn bộ skill/rule vì bị load thừa, tốn token, load nhầm skill; (4) tạo file tài liệu .md dài (>200 dòng) sẽ bị đọc lặp lại nhiều phiên. SKIP — không đọc khi: chỉ *dùng* 1 skill có sẵn, viết code/CDS/class ABAP, viết README hay tài liệu nghiệp vụ dùng 1 lần, hoặc sửa nội dung thân skill mà không đụng tới description/phân tầng.'
argument-hint: '[tên skill hoặc file .md cần viết/rà soát]'
user-invocable: true
disable-model-invocation: false
---

# Chuẩn viết file .md điều khiển context

Mục tiêu: mỗi phiên chỉ nạp đúng thứ cần, không nạp thừa.

## 1. Bốn tầng context — quyết định nội dung nằm ở đâu

| Tầng | Nạp khi nào | Nơi đặt | Ngân sách |
| --- | --- | --- | --- |
| T0 — Luôn nạp | Mọi phiên, không điều kiện | `CLAUDE.md` | ≤ 40 dòng, mỗi rule ≤ 3 dòng |
| T1 — Metadata skill | Mọi phiên (chỉ dòng `description`) | frontmatter `SKILL.md` | ≤ 5 dòng/skill, tổng ≤ 12 skill |
| T2 — Thân skill | Chỉ khi TRIGGER khớp | `.claude/skills/<ten>/SKILL.md` | ≤ 300 dòng |
| T3 — Tài liệu tra cứu | Chỉ khi cần đúng 1 mục | `_ghichu_*.md`, `reference/*.md` | không giới hạn, NHƯNG phải đọc theo section |

Quy tắc chuyển tầng:
- Rule trong `CLAUDE.md` mà dài > 3 dòng, hoặc chỉ đúng trong 1 loại task → đẩy xuống T2 (tạo skill), ở T0 chỉ để lại 1 dòng trỏ tên skill.
- Nội dung T2 mà chỉ tra cứu khi gặp đúng 1 case (bảng lỗi, log kinh nghiệm, danh sách tool) → đẩy xuống T3, trong skill chỉ để đường dẫn + tên section.
- Không bao giờ đặt nội dung tra cứu dài ở T0/T1.

## 2. Công thức `description` (bắt buộc, 3 vế)

```
<1 câu chủ đề: skill này chứa gì, kèm tên object/annotation/prefix thật> TRIGGER — chỉ đọc khi (1) ...; (2) ...; (3) ... SKIP — không đọc khi: ...
```

- **Chủ đề**: nêu từ khoá định danh thật (tên class, annotation, prefix, tên tool), không nêu chủ đề rộng ("ABAP", "code", "dữ liệu").
- **TRIGGER**: 2-3 tình huống CỤ THỂ, mỗi tình huống phải trả lời được "user gõ câu gì thì khớp". Ưu tiên động từ tạo/sửa/debug + tên object cụ thể.
- **SKIP**: các tình huống *gần giống nhưng không cần* skill. Đây là vế quyết định — thiếu nó skill sẽ bị load nhầm. Luôn liệt kê ít nhất: đọc/giải thích code có sẵn, hỏi cú pháp chung, tra cứu object.

**YAML:** `description` luôn bọc trong dấu nháy đơn (`description: '...'`) vì nội dung chứa `:` và `—` — plain scalar dễ vỡ frontmatter, khi vỡ thì skill mất description và bị bỏ qua hoặc load sai. Trong chuỗi, dấu nháy đơn viết đôi (`''`).

Ranh giới mặc định: **load** khi tạo/sửa đúng loại object skill nhắm tới, hoặc debug đúng triệu chứng skill mô tả. **Không load** khi chỉ đọc/giải thích/tra cứu, hoặc chỉ trùng chủ đề rộng.

## 3. Test 6 câu trước khi lưu skill

Tự đặt 3 câu hỏi **phải load** và 3 câu hỏi **gần giống nhưng phải skip**; đọc lại `description` và kiểm tra nó tự phân loại đúng cả 6. Nếu 1 câu skip vẫn khớp TRIGGER → viết TRIGGER hẹp lại, đừng thêm chữ vào SKIP.

## 4. Nơi đặt file — chỉ 1 chỗ có tác dụng

- Claude Code chỉ nạp: `.claude/skills/<ten>/SKILL.md` (project) và `~/.claude/skills/<ten>/SKILL.md` (global).
- `.agents/skills/**` KHÔNG được Claude Code nạp (thư mục của công cụ/marketplace khác). Muốn skill có hiệu lực thì copy sang `.claude/skills/`.
- **Không để trùng tên project + global**: bản global (`~/.claude/skills`) được nạp thay bản project (xác nhận 23.10.2026: `context-guard` global cũ che bản team mới hơn) → chỉ giữ 1 bản trong repo team; `check-repo.ps1 -All` cảnh báo R7.
- **Skill lệnh** (chỉ chạy khi user gõ `/tên`, vd `/cn-fs`): đặt `disable-model-invocation: true` → description không nạp vào context, không cần công thức TRIGGER/SKIP (mục 2); description chỉ cần nói lệnh làm gì + cú pháp gọi. Muốn Claude vẫn làm theo khi user nói bằng lời → 1 dòng trong `CLAUDE.md` trỏ tới file `SKILL.md`.
- Skill từ plugin/marketplace thường có description chung chung ("Help with ... Use this skill when users ask about ...") → chỉ bật plugin khi thực sự dùng; nếu chỉ cần vài skill thì copy về `.claude/skills/` và viết lại description theo mục 2.

## 5. File tài liệu lớn (T3) — bắt buộc cấu trúc đọc chọn lọc

Khi tạo/sửa file .md > 200 dòng sẽ bị đọc lại nhiều phiên (`_ghichu_mcp_*.md`, log kinh nghiệm):

1. Dòng đầu file: 1 khối **"CÁCH ĐỌC FILE NÀY"** — nói rõ: không đọc cả file, grep mục lục rồi đọc đúng section.
2. Ngay sau đó: **mục lục** đánh số các section (`## 1. ...`) — giữ đồng bộ khi thêm section mới.
3. Mỗi section tự đủ nghĩa, có ngày xác nhận + tên hệ thống/object liên quan, để đọc 1 mình vẫn hiểu.
4. Nội dung mới **thêm vào đúng section đã có**, chỉ tạo section mới khi thật sự là chủ đề mới (tránh file phình theo kiểu nhật ký).
5. Cách đọc đúng: `grep -n '^## ' file.md` → `sed -n '<from>,<to>p' file.md`. Không `cat` cả file.
6. **Checklist nội dung mỗi mục** (đúc kết 24/09/2026 sau đợt audit `.claude/skills/sap-mcp-cloud/reference/_ghichu_mcp_cloud.md`) — trước khi ghi, tự hỏi:
   - **Cấu trúc**: có nêu rõ lỗi/symptom cụ thể (thông báo lỗi, tool, ngày xác nhận, case) → hướng xử lý/kết luận không? Không viết nhật ký tường thuật thiếu hướng xử lý.
   - **Không trùng lặp**: đã có bullet/section nào nói cùng ý chưa? Có thì gộp/bổ sung vào đó, không tạo đoạn mới lặp lại kết luận cũ (kể cả khi case/hostname khác).
   - **Tổng quát hoá được (đa dự án)**: có khoá cứng tên object/package/hostname của 1 khách hàng như thể dùng chung mọi nơi không? Ví dụ minh hoạ thì ghi rõ "1 dự án cụ thể, tên khác theo hệ thống"; rule chỉ đúng 1 tenant thì nêu rõ phạm vi ngay trong câu.
   - **Đẩy kiến thức ngôn ngữ lên skill**: nếu là kiến thức ABAP/CDS/authorization CHUNG (không phải riêng hành vi 1 MCP tool/tenant) → thêm bản rút gọn vào `SKILL.md` liên quan (`abap-cloud`, `authorization-iam`, `abap-sql-amdp`, `abap-performance-hana`...), kèm link ngược lại đúng mục trong file ghi chú. Đây là cách duy nhất để kiến thức "dùng được nhiều dự án" thay vì chỉ nằm trong 1 file log.

   Áp dụng qua khối **"CÁCH GHI THÊM 1 MỤC MỚI"** ở đầu mỗi file `_ghichu_mcp_*.md`/`.claude/skills/abap-platform-constraints/reference/_ghichu_local.md` (tóm tắt checklist này ngay tại điểm ghi, không cần load skill này mỗi lần thêm 1 finding thường ngày).
7. **Checklist tối ưu lưu trữ/tổ chức** (đúc kết 24/09/2026 sau khi soát `.claude/skills/sap-mcp-gui/reference/_ghichu_mcp_gui.md` — file có block `"sangvt add begin/end"` bọc ~40 dòng nhiều chủ đề khác nhau nằm hẳn TRƯỚC section 1, và 1 bài học bị viết lại 2 lần ở 2 chỗ cách xa nhau):
   - Không dùng marker kiểu comment code (`" ... add begin/end` của `CLAUDE.md`) trong file `.md` — quy ước đó chỉ dành cho code có cú pháp comment `"`.
   - Nội dung mới luôn xếp vào đúng section theo mục lục (điểm 4 ở trên), tuyệt đối không chèn thẳng vào đầu file trước section 1 — đó là dấu hiệu "vùng chưa phân loại" sẽ phình dần không kiểm soát.
   - Bullet dài (>~80 từ) mở đầu bằng 1 câu kết luận in đậm trước khi vào chi tiết/bằng chứng.
   - Đánh dấu độ tin cậy `**[CONFIRMED]**`/`**[NGHI NGỜ/TODO]**` ngay đầu câu khi chưa chắc chắn.
   - Xác nhận lại đúng bài học cũ (case mới, cùng kết luận) → chỉ dẫn chiếu ngược + case mới, không diễn giải lại từ đầu (tránh lặp như case trên).
   - Landscape/host/tenant tách riêng khỏi hành vi tool — tuổi thọ thông tin khác nhau.
   - Không dán nguyên văn response/exception dài (JSON/XML) — chỉ giữ message chính.
   - File vượt ~300 dòng hoặc 1 chủ đề hẹp phình to → tách file `_ghichu_<chủ đề>.md` riêng (đã làm với BAdI MIGO), để lại 1 dòng tóm tắt + link.
   - 1 bug bị test lại nhiều lần → gộp 1 mục có mốc thời gian con, không rải rác.
   - Finding hết hiệu lực → đánh dấu `~~gạch ngang~~`/"[OUTDATED]" kèm lý do, không xoá âm thầm.

## 6. Viết rule trong CLAUDE.md

- Mỗi rule 1 gạch đầu dòng, ≤ 3 dòng, câu lệnh trực tiếp.
- Rule có điều kiện PHẢI mở đầu bằng "Khi ..." / "Chỉ khi ..." — không dùng "Đầu mỗi phiên..." trừ khi thật sự cần mọi phiên (rule đó nhân chi phí với mọi phiên làm việc).
- Rule chỉ đúng cho 1 loại project (Supabase, Fiori, on-premise...) phải ghi rõ phạm vi ngay trong rule.
- Nhóm rule theo tiêu đề `##` để dễ soát; định kỳ rà: rule nào chưa từng dùng tới trong nhiều phiên → hạ tầng hoặc xoá.
