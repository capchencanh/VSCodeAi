**Chủ đề: ZRSD27 – Báo cáo theo dõi tình hình thực hiện gói thầu: 5 điểm FS V1.0 chưa đủ thông tin để lập trình**

Chào bạn Ngân,

Mình đang làm ZRSD27 theo FS V1.0 (24/09/2026). Có 5 điểm FS chưa đủ thông tin nên mình chưa chốt được code. Nhờ bạn trả lời giúp:

**1. Hợp đồng cấp 2 là loại chứng từ nào?**
- FS ghi: mục 2.1.1 "khoá chính của báo cáo ZRSD27 là Hợp đồng cấp 2"; mục 2.2.1 tham số "Loại chứng từ hợp đồng" mặc định NA; mục 2.2.3 chỉ tiêu (14) chỉ nêu "Contract type = 'ZCQ1'" cho cấp 1.
- Thiếu: loại chứng từ của cấp 2. Client 100 có ZCQ2 (thầu cấp 2), ZCQ3 (HĐ bán hàng), ZCQ4 (HĐ bán XK). Chỉ ZCQ2, hay có cả ZCQ3 / ZCQ4?

**2. Hóa đơn nào được cộng (+) và trừ (−) vào số lượng / thành tiền thực hiện?**
- FS ghi: mục 2.1.1 "Billing bán hàng và Billing hàng bán trả lại (màn hình VF03)"; mục 2.2.3 chỉ tiêu (33)(34)(39)(40) "Sum các Billing Bán – Sum các Billing trả hàng, Billing huỷ".
- Thiếu: không nêu loại hóa đơn (FKART). Hệ có nhiều loại: ZFT* (bán), ZFB* (khuyến mại, tặng, tiêu dùng nội bộ), ZFK* (ký gửi), F2; ZFR*, ZFW* (trả hàng), ZFC* (điều chỉnh giá / CKTM), ZFXN (đổi hàng).
- Cần chốt: danh sách loại hóa đơn tính (+) và tính (−). Đặc biệt: hóa đơn khuyến mại / tặng / ký gửi có cộng không; hóa đơn điều chỉnh giá / CKTM (ZFC*) có trừ vào thành tiền không (FS chỉ nói trả hàng và hủy).

**3. Chỉ tiêu (28) Giá trúng thầu (chưa VAT) lấy từ condition type nào?**
- FS ghi: mục 2.2.3 chỉ tiêu (28) "… [Tab] Conditions → Lấy [Field] Giá trúng thầu (chưa VAT)".
- Thiếu: mã condition type. Hệ không có loại nào tên này (chỉ có PR00, ZRRW, ZRWR, ZRWT, ZRT1).

**4. Nguồn dữ liệu của 4 cột FS chưa nêu field / bảng**
- (12) "Loại hợp đồng cụ thể": có ở Hình 3 (mục 2.2.2) nhưng bảng mô tả mục 2.2.3 nhảy từ (11) sang (13).
- (49) Ghi chú: mục 2.2.3 ghi "VA43 → … Header → Additional Data → Ghi chú" nhưng không nêu field. Hệ chưa có field `ZZ*` ở header hợp đồng, cũng chưa có Text ID `Z*`.
- (47) SPCL: mục 2.2.3 ghi "Lấy giá trị đặc tính Z_SPCL"; đặc tính này chưa tồn tại trên hệ. Cần class type + class gán đặc tính, và giá trị có đổi theo năm không (tên cột "SPCL yyyy").
- (51)(53) Tên TDV / ASM: mục 2.2.3 ghi "Tên nhân viên của mã lấy tại chỉ tiêu (50) / (52)" nhưng không nêu bảng / field (HR PA0001 / PA0002, BP hay bảng Z?).

**5. Trường "hợp đồng giấy": có làm trong ZRSD27 không?**
- FS ghi: 2 comment ở chỉ tiêu (15) (mục 2.2.3): "Bổ sung trường hợp đồng giấy → dạng Custom Field trên VA23" và "Trường hợp đồng giấy không bắt buộc khi tạo Hợp đồng"; mục 2.2.1 có dòng tham số "Hợp đồng thầy" để trống.
- Thiếu: nếu có làm, cần tên kỹ thuật field, kiểu (checkbox / số / text), nằm ở báo giá VA23 hay hợp đồng VA43, dùng làm tham số lọc hay cột hiển thị. "Hợp đồng thầy" có phải "Hợp đồng giấy" không?

**Các điểm khác mình đã tự giả định (nếu sai bạn báo lại là được)**
- Hóa đơn nối với hợp đồng theo dòng: hóa đơn → đơn bán → dòng hợp đồng (VBAP-VGBEL / VGPOS). Hợp đồng có 2 dòng cùng mã hàng thì lên 2 dòng báo cáo riêng.
- Hóa đơn trả hàng truy về dòng hợp đồng qua đơn trả hàng (tạo từ hóa đơn, từ đơn bán hoặc từ hợp đồng). Hóa đơn bị hủy: loại cả hóa đơn gốc lẫn chứng từ hủy.
- Số lượng hóa đơn quy về đơn vị của dòng hợp đồng (chỉ tiêu (27)) theo hệ số quy đổi MARM. FS mục 2.1.1 có nhắc "hệ số quy đổi đơn vị tính" nhưng không nêu cách dùng.
- Tham số Mã ASM = VBPA-PERNR của partner function KM (client 100: KM = "ASM"). FS mục 2.2.1 để trống dòng này.
- Dạng hiển thị "Bảng tính" (Hình 2, không có trong bảng tham số mục 2.2.1): làm ALV có nút Export trước.
- Tỷ lệ thực hiện ở tiêu đề (hình mẫu 58,420 %): = Σ thành tiền thực hiện (40) / Σ thành tiền trúng thầu (30) × 100.
- Số tháng tròn (21)(22): tính cả ngày cuối, ví dụ 01.01.2026 → 31.12.2026 = 12 tháng.

**Lưu ý cấu hình (không phải lỗi FS)**
Client 100 chưa có copy control tạo ZCQ2 từ ZCQ1, nên chưa tạo được hợp đồng cấp 2 có tham chiếu cấp 1; bảng Customer group 1 (TVV1) chưa khai giá trị.

FS còn mấy chỗ cần chỉnh nhỏ, mình gửi riêng sau:
- Chỉ tiêu (15) đang ghi y hệt (14).
- Chỉ tiêu (23) tự tham chiếu.
- Chỉ tiêu (34) "Số lượng" → "Thành tiền".
- Tham số "Tỉnh thành" ghi VBKD-KVGR1, nhưng trên hệ là VBAK-KVGR1.

Cảm ơn bạn.

Đặng Hoàng Danh – Citek
