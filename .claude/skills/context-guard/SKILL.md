---
name: context-guard
description: 'Quy trình lưu trạng thái công việc + chạy /compact khi context sắp đầy, để tiếp tục đúng điểm dừng. TRIGGER — chỉ đọc khi (1) user gọi thẳng /context-guard hoặc yêu cầu bật chế độ theo dõi context; (2) context thực sự đã vượt ngưỡng (~65%) và cần lưu trạng thái trước khi compact. SKIP — không đọc trong mọi tác vụ thông thường (viết/sửa/đọc code, phân tích, tra cứu) khi context còn thoải mái — đây không phải skill kỹ thuật ABAP.'
argument-hint: '[mô tả tác vụ đang làm, nếu có]'
user-invocable: true
disable-model-invocation: false
---

# Context Guard — Quản lý Context Tự Động

## Mục tiêu

Khi context đạt ~65% dung lượng (chủ động, không đợi đến gần max), thực hiện 3 bước theo thứ tự:
1. **Ghi lại trạng thái** — snapshot công việc hiện tại vào file tạm
2. **Compact** — chạy `/compact` để giải phóng context
3. **Tiếp tục** — đọc lại snapshot và làm việc tiếp từ đúng điểm dừng

Ngưỡng 65% (thay vì đợi 80-85%) vì hai lý do: (1) context càng lớn thì `/compact` càng chậm — tóm tắt sớm khi còn nhỏ thì nhanh hơn nhiều; (2) snapshot tự viết ở bước 1 giữ đúng ý người dùng hơn bản tóm tắt tự động của `/compact`, nên compact sớm không đánh đổi độ chính xác.

---

## Khi nào kích hoạt

Kích hoạt khi **một trong hai** điều kiện xảy ra:

- **Tự động:** Context token đã dùng ≥ 65% giới hạn (quan sát dấu hiệu: response chậm lại, cảnh báo context, hoặc hệ thống báo "approaching limit")
- **Thủ công:** User gọi `/context-guard` hoặc yêu cầu "compact và tiếp tục"

---

## Bước 1 — Ghi Trạng Thái (State Snapshot)

Trước khi compact, viết file snapshot vào scratchpad. File phải đủ để khôi phục hoàn toàn mà không cần nhớ conversation cũ.

**Cấu trúc file** `context-snapshot.md`:

```markdown
# Context Snapshot — [timestamp ngắn gọn]

## Tác vụ đang làm
[Mô tả 1-2 câu: user muốn làm gì, mục tiêu cuối cùng là gì]

## Đã hoàn thành
- [file/bước đã xong, kết quả cụ thể]
- [...]

## Đang làm dở
- File: [path]
- Tại bước: [mô tả bước cụ thể]
- Vấn đề gặp phải (nếu có): [...]

## Chưa làm
- [ ] [bước tiếp theo cụ thể]
- [ ] [...]

## Quyết định đã chốt
- [lý do chọn approach A thay vì B]
- [constraint/requirement quan trọng]

## Thông tin cần nhớ
- [key variable, API, config, path quan trọng]
- [lỗi đang debug và hypothesis hiện tại]
```

**Quy tắc viết snapshot:**
- Viết như brief cho đồng nghiệp vừa bước vào — không giả định họ đọc conversation
- Mỗi mục phải đủ cụ thể để hành động ngay: path đầy đủ, giá trị cụ thể, không "xem thêm ở trên"
- Không viết "đang nghĩ" hay "có thể" — chỉ ghi điều đã xác định

---

## Bước 2 — Compact

Sau khi file snapshot đã được ghi thành công, thông báo với user:

```
Context đã đạt ~65%. Đã lưu trạng thái vào [đường dẫn snapshot].
Đang chạy /compact...
```

Sau đó chạy `/compact`.

---

## Bước 3 — Tiếp tục sau Compact

Ngay sau khi compact xong, **đọc lại file snapshot** và thông báo:

```
Context đã được compact. Đang tiếp tục từ: [tên bước đang làm dở].
```

Rồi tiếp tục thực hiện từ mục **"Đang làm dở"** trong snapshot, không hỏi lại user trừ khi có ambiguity thật sự.

---

## Chế độ Tự Động (Auto-Guard)

Khi user yêu cầu bật auto-guard (ví dụ: "bật context-guard tự động"), Claude chủ động:

1. Theo dõi độ đầy context sau mỗi response lớn
2. Tự kích hoạt quy trình trên khi đạt ngưỡng 65%
3. Không cần user nhắc lại

Tắt auto-guard khi user nói: "tắt context-guard" hoặc kết thúc tác vụ.

---

## Ghi chú quan trọng

- **Snapshot phải được ghi TRƯỚC khi compact** — compact xóa context, không khôi phục được
- Đường dẫn snapshot mặc định: scratchpad directory của session hiện tại
- Nếu tác vụ đơn giản (< 5 phút), không cần snapshot chi tiết — một paragraph tóm tắt là đủ
- Sau compact, **không tóm tắt lại những gì đã làm** — đọc snapshot và làm tiếp luôn
- Việc thăm dò tốn context (đọc nhiều file, grep lớn, research) nên giao cho fork/subagent thay vì đọc thẳng vào context chính — giảm lượng phải tóm tắt mỗi lần compact mà không mất chi tiết (vẫn gọi lại được từ fork nếu cần)
- Thông tin cần nhớ **xuyên nhiều session** không chỉ nằm trong snapshot (snapshot chỉ dùng cho phiên hiện tại): trạng thái/quyết định của chức năng → `TRANG_THAI.md` + `<CN>/NHAT_KY_<CN>.md` của dự án (team cùng thấy); chỉ sở thích/cách làm riêng của user mới vào auto-memory
- Khi chuyển sang task mới hoàn toàn không liên quan tới task cũ, cân nhắc `/clear` thay vì `/compact` — tránh nén dồn nhiều task rời rạc vào chung 1 bản tóm tắt, vừa chậm vừa dễ lẫn ý
