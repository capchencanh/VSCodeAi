> **[14/10/2026] File này là bản nháp CŨ, đừng gửi nguyên văn.** Theo bộ lọc ở `CodeABAP/BDP/NOTE/note.md`, hiện không còn câu hỏi nào bắt buộc phải BA trả lời: câu 1–3 đã được xử lý, các câu còn lại chỉ là thông báo (FS ghi sai/lệch nhưng code đã làm theo mẫu in; chưa có customizing/data test). Danh sách thông báo hiện hành nằm ở `ghi_chu.md`, mục "Trạng thái cuối phiên".

**Chủ đề: ZRSD08 – Bảng kê bán lẻ hàng hoá dịch vụ: 5 điểm cần chốt trước khi test dữ liệu thật**

> **Cập nhật 05/10/2026:** câu 2 (Chiết khấu sau) và câu 3 (Ghi chú) đã được BA xác nhận
> miệng là **bỏ hẳn 2 chỉ tiêu này**, không cần trả lời nữa — xem `ghi_chu.md`. Giữ lại
> nguyên văn 2 câu dưới đây để lưu vết, không gửi lại cho Bidiphar.
>
> **Cập nhật 14/10/2026 (FS mới):** câu 1 (MWAS hay MWST) đã được trả lời — FS mới dùng **`MWST`** cho cả
> thuế suất từng dòng (16) và tiền thuế (20). Còn lại câu 4 và các điểm ở câu 5 (`LIKP-VKORG` vẫn chưa sửa, `ZF2`
> vẫn là loại hoá đơn không có trên hệ). Thêm 1 điểm thông báo: văn bản chỉ tiêu (21) trong FS mới vẫn ghi công thức
> và ví dụ của bản cũ (`(17) + (20) − (18)`, 1.168.125), trong khi mẫu in ghi 1.202.710 = (17) + (19) — code làm theo mẫu.

Chào chị Thư,

Em đã lập trình xong chương trình và Smartform ZRSD08 theo FS V1.0 (09/09/2026). Form in thử bằng dữ liệu mẫu trong FS đã khớp mẫu (tổng 1.112.500, thuế 5%, thanh toán 1.168.125). Khi đối chiếu FS với cấu hình trên hệ DEV, em còn 5 điểm cần chị / Bidiphar xác nhận để chạy được với hoá đơn thật.

**1. [ĐÃ XỬ LÝ 14/10/2026 — FS mới dùng `MWST`] Chỉ tiêu (19), (20) – Thuế GTGT: điều kiện `MWAS` hay `MWST`?**
- FS ghi: *"dòng có Condition type MWAS"* ở cả (19) và (20).
- Trên hệ, pricing procedure `ZRVA01` (procedure chứa `ZRT1`, gán cho Sales Org 1000, Division 99, loại đơn `ZD01`) tính thuế bằng **`MWST`** (step 450), không có `MWAS`. Các procedure có `MWAS` (A10xxx) thì lại không có `ZRT1`.
- Nếu giữ `MWAS`, thuế suất và tiền thuế trên bảng kê sẽ ra **0**.
- **Cần chốt:** thuế lấy từ `MWST` hay `MWAS`? Hay Bidiphar dùng pricing procedure khác `ZRVA01`? Nếu khác, xin cho tên procedure.

**2. [ĐÃ XỬ LÝ 05/10/2026 — BA xác nhận bỏ] Chỉ tiêu (18) – Chiết khấu sau: Item Category nào thuộc nhóm chiết khấu / hàng tặng?**
- Ô *Mô tả kỹ thuật* của (18) đang **để trống**. Mục *Những yêu cầu khác* chỉ ghi: *"Các dòng hàng có Item Category thuộc nhóm chiết khấu và hàng tặng không in… giá trị của các dòng này cộng vào chỉ tiêu (18)"* nhưng không liệt kê Item Category.
- Hiện em để (18) = 0 và in tất cả dòng hàng, nên (21) = (17) + (20).
- **Cần chốt:** (a) danh sách Item Category của nhóm chiết khấu, và của nhóm hàng tặng; (b) giá trị cộng vào (18) là NETWR của các dòng đó (dương hay âm?); (c) (17) Tổng cộng có tính các dòng này không.

**3. [ĐÃ XỬ LÝ 05/10/2026 — BA xác nhận bỏ] Chỉ tiêu (16) – Ghi chú: field `VBRP-ZZGHICHU` chưa tồn tại**
- FS ghi: *"VBRP-ZZGHICHU … ghi chú khai bằng custom field trên bảng chứng từ, không lấy theo Text ID"*.
- Trên hệ DEV (cả client 100 và 200), bảng VBRP **chưa có** field `ZZ*` nào. Cột Ghi chú hiện để trống.
- **Cần chốt:** (a) ai tạo field (append structure cho VBRP, kèm VBAP / LIPS và copy control để giá trị đi từ đơn hàng sang hoá đơn); (b) người dùng nhập ghi chú ở bước nào và màn hình nào; (c) nếu chưa làm được thì có đổi sang đọc Text ID không.

**4. Chỉ tiêu (14) – Đơn giá `ZRT1`: cấu hình chưa có ở client 200**
- FS ghi: *"Condition type ZRT1"*, loại điều kiện giá bán lẻ. `ZRT1` có ở client 100 (pricing procedure `ZRVA01`, access sequence `PR02`) nhưng **không có ở client 200**. Cấu hình client 100 chưa được transport sang 200.
- Cả hệ DEV hiện chưa có hoá đơn, khách hàng, vật tư hay bản ghi giá `ZRT1` nào.
- **Cần chốt:** (a) khi nào transport customizing (ZRT1, ZRVA01, loại đơn ZD01, loại hoá đơn ZFD1) sang client 200; (b) ai cung cấp bộ dữ liệu test: 1 nhà thuốc, 1 đơn vị mua hàng, 3 vật tư theo mẫu FS kèm đơn vị quy đổi (bảng MARM) và giá ZRT1.

**5. Chỗ chưa khớp khác trong FS (không ảnh hưởng chức năng)**
- Chỉ tiêu (1) Logo: FS ghi *"đọc TVKO với VKORG bằng **LIKP**-VKORG"*. LIKP là bảng giao hàng. Báo cáo chạy trên hoá đơn nên phải là **VBRK-VKORG**. Em đã lập trình theo VBRK-VKORG, đề nghị chị sửa lại FS cho khớp.
- Mục *Mẫu báo cáo*: ví dụ loại hoá đơn `ZF2` (mục 6, 7) không tồn tại trên hệ. Loại đi cùng đơn `ZD01` là `ZFD1`, còn hoá đơn chuẩn là `F2`. Xin chị xác nhận đây chỉ là ví dụ.
- Đầu FS ghi *"Nội dung bôi vàng là điểm cần Bidiphar xác nhận"*, nhưng bản V1.0 không có chỗ nào bôi vàng. Xin chị cho biết còn điểm nào chờ xác nhận nữa không.

Đồng thời có 2 việc phía hệ thống em đã phát hiện:
- Cột ĐVT sẽ in `***` nếu đơn vị đo (VNS, VNA, LO…) chưa được khai ở CUNI kèm tên theo ngôn ngữ đăng nhập.
- Cần Basis cấu hình thiết bị in `LP01` loại `SWINCF` để in tiếng Việt đúng dấu (đã làm ở DEV, QAS / PRD cần làm riêng).

Chị phản hồi giúp em các điểm 1 đến 4 để em hoàn thiện và test với hoá đơn thật. Em cảm ơn chị.

Đặng Hoàng Danh – Citek
