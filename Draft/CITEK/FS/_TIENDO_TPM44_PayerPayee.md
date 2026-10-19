# Tiến độ điều tra — FS-BDP-TPM44-001 (Bổ sung Payer/Payee TPM44)

> File tổng hợp để tiếp tục công việc ở workspace mới (`SKill_CSTECH/VSCodeSkillAI`). Đọc file này trước khi làm gì tiếp.

## 1. Bối cảnh gốc (từ FS)

- FS: `BDP_FS_TR_TPM44_BoSungPayerPayee.xlsx` (cùng thư mục), mã tài liệu `FS-BDP-TPM44-001`.
- Hệ thống test: `<S4S/500>`, user `CT.HUY`.
- Lỗi: chạy **Tcode TPM44** (Execute Accrual/Deferral) cho giao dịch OTC vay vốn (Company Code 1000, Transaction `1000000000021`, Product Type 55A, Key Date 21.09.2026, Test Run) → báo:
  - Error: `Account determination: Missing payer/payee for posting to customer acct` (VA 001)
  - Error: `Error in update to Accounting; see log` (VA 001)
  - Warning: `No Customizing entry found for position AC=1000,VA=Z01,PT=55A,DN=1000000000021` (VA Z01)
- Giao dịch gốc TRM (FTR_EDIT, Company Code 1000, Product Type 55A, Transaction Type 100) có field **Partner = 34000005** (BIDV Bến Nghệ) ở tab Additional data — field này TPM44 không tự lấy được khi hạch toán.

## 2. Đã xác nhận qua debug thật trên hệ thống (KHÔNG phải suy đoán)

### 2.1. Field Partner — đã xác định chính xác
- Qua F1 → Technical Information trên field Partner ở FTR_EDIT: **table `VTGFHA`, field `KONTRH`**.
- `VTGFHA` chỉ là **display structure** (không phải bảng vật lý, không có key) — nó `.INCLUDE VTBFHA` toàn bộ bên trong.
- Xác nhận qua dictionary export (`dictionary/vtbfha.html`): **field `KONTRH` thực chất thuộc bảng vật lý `VTBFHA`** (data element `TB_KUNNR_NEW`, domain `BU_PARTNER`, CHAR 10), key chính = `MANDT + BUKRS + RFHA` (đã xác nhận Key=X trên cả 3 field này qua export dictionary).
- Field đích cần set trong structure `ACCIT` (Accounting Interface): `ACCIT-KUNNR` — user đã xác nhận field này tồn tại trong `ACCIT` (SE11).

### 2.2. BAdI `TPM_ACCIF_TRAC` — ĐÃ LOẠI TRỪ, KHÔNG PHẢI ĐIỂM CẦN SỬA
- BAdI: `TPM_ACCIF_TRAC`, interface `IF_EX_TPM_ACCIF_TRAC`, implementation `ZENH_TPM_ACCIF_TRAC`, class `ZCL_IM_ENH_TPM_ACCIF_TRAC`.
- Method `ACCIT_KUNNR_EXIT` (Changes the Customer Number) đang **trống hoàn toàn** — ban đầu nghi đây là chỗ cần code.
- Method `ACCIT_EXIT` (Changes the Entire Structure) đã có code sẵn (tác giả LeHangNT, 23.08.2023) — set `GSBER`/`PRCTR`/`ZFBDT` cho cả `CH_ACCIT_D`/`CH_ACCIT_C`, query từ `VTBFHA`/`VTBFHAZU` theo `IM_DATA-COMPANY_CODE`/`IM_DATA-DEAL_NUMBER`. Đây là pattern chuẩn đã dùng trong dự án — **dùng để tham khảo cú pháp nếu sau này thực sự cần sửa `ACCIT_KUNNR_EXIT`**.
- **Debug xác nhận (đặt breakpoint tại ENDMETHOD của TẤT CẢ method trong class, chạy TPM44 Test Run cho Transaction 1000000000021):**
  - Luồng CHỈ dừng ở 2 method: `TRANS_POSTING_TRAC_ONLY` rồi `FLOW_POSTING_RELEVANCE`.
  - Sau đó KHÔNG bao giờ tới `ACCIT_EXIT` hay `ACCIT_KUNNR_EXIT` — luồng dừng/raise lỗi TRƯỚC KHI kịp build dòng hạch toán.
- **Kết luận: viết code vào `ACCIT_KUNNR_EXIT` là VÔ NGHĨA trong ca lỗi này — method không bao giờ được thực thi.** Đã có 1 bản code nháp SAI HƯỚNG lưu tại `ABAP/ZCL_IM_ENH_TPM_ACCIF_TRAC.md` (thư mục gốc `CITEK/ABAP/`) — **KHÔNG dùng bản đó**, cần viết lại toàn bộ note trong file đó hoặc xoá.

### 2.3. Nguyên nhân gốc thật sự — đang điều tra dở, CHƯA XONG
- Debug sâu hơn (F8 tiếp sau khi qua `FLOW_POSTING_RELEVANCE`, hoặc set breakpoint tại statement `MESSAGE`) cho thấy debugger dừng tại:
  ```abap
  " FM: BUP_BUPA_MEMORY_GET
  *------ ... no data for BP found: error message ---------------------
      IF sy-subrc <> 0.
        MESSAGE e248 WITH i_partner RAISING no_data_found.
  ```
  - Giá trị biến `I_PARTNER` lúc dừng = `0034000005` — đúng chính xác BP `34000005` (BIDV Bến Nghệ).
  - FM này đọc BP từ **workarea/buffer** hoặc **local memory nội bộ của function group** (`mem_but000`), KHÔNG đọc trực tiếp DB — nếu BP chưa được 1 giao dịch khác "nạp" vào buffer trước đó trong cùng LUW/session, FM này raise lỗi `no_data_found` dù BP có tồn tại thật trong hệ thống.
- **Đã loại trừ nghi ngờ Master Data thiếu role:** kiểm tra qua Tcode BP → BP `34000005` có ĐẦY ĐỦ role: `FLCU00` (Customer Fin.Accounting), `FLCU01` (Customer), `FLVN00` (Supplier Fin.Accounting), `FLVN01` (Supplier), `TR0150/151/152` (Treasury Issuer/Counterparty/Depository Bank). Không phải thiếu BP role.
- **Chương trình chính TPM44:** `RTPM_ACCRUAL_DEFERRAL` → gọi FM `TPM_AD_ACCRUAL_DEFERRAL` (single task hoặc parallel task tuỳ config) — logic thật nằm sâu trong FM này, report chỉ làm selection-screen + gọi FM + hiển thị protocol.

## 3. Việc cần làm tiếp (theo đúng thứ tự ưu tiên FS đã đặt ra: Master Data → Config → Code)

1. **[ĐANG LÀM DỞ]** Debug sâu hơn để tìm CHÍNH XÁC đoạn code nào gọi `BUP_BUPA_MEMORY_GET` (nằm trong `FLOW_POSTING_RELEVANCE` hoặc chuỗi gọi bên trong `TPM_AD_ACCRUAL_DEFERRAL`), và tại sao buffer BP trống tại thời điểm đó — dù BP có đủ role. Có thể liên quan tới:
   - Thiếu bước "load BP vào buffer" trước khi TPM44 chạy accrual/deferral (khác với khi chạy qua FTR_EDIT — nơi BP chắc chắn đã được load vì đang hiển thị Partner trên màn hình đó).
   - Có thể là hành vi chuẩn SAP cần 1 Customizing/setup riêng (không phải bug code) — cần đối chiếu OSS Note hoặc so sánh với 1 transaction khác đã chạy TPM44 thành công trước đây (nếu có) xem điểm khác biệt.
2. Sau khi xác định đúng nguyên nhân — mới quyết định hướng xử lý thật (Customizing / BAdI khác / sửa code khác `ACCIT_KUNNR_EXIT`).
3. **KHÔNG quay lại sửa `ACCIT_KUNNR_EXIT`** cho tới khi có bằng chứng debug mới xác nhận luồng thực sự chạy tới đó.

## 4. Trạng thái MCP (để làm việc tự động qua Claude thay vì thao tác tay SAP GUI)

- Đã tạo entry MCP `CITEKSO_500` trong `SKill_CSTECH/VSCodeSkillAI/.mcp.json`:
  - `--url http://10.1.2.43:8000/ --user CT.HUY --client 500`
  - **Port `8000` là suy đoán theo convention (80+instance 00), CHƯA XÁC NHẬN THẬT** — nếu không kết nối được, đây là nghi phạm số 1.
  - `SAP_INSECURE: true` (dùng http, không SSL).
- **Vấn đề đang gặp:** MCP server này chưa được Claude Code nạp — do `.mcp.json` nằm ở `SKill_CSTECH/VSCodeSkillAI/.mcp.json` (thư mục con), nhưng workspace VSCode đang mở ở root `CITEK` → Claude Code không tự đọc `.mcp.json` ở thư mục con.
  - **Giải pháp đang thực hiện:** mở lại VSCode với **File → Open Folder** trỏ thẳng vào `C:\DangHoangDanh\AI_PROJECT\CITEK\SKill_CSTECH\VSCodeSkillAI` làm root workspace mới — sau đó `.mcp.json` sẽ được đọc đúng.
  - Đã xác nhận `vsp.exe` tồn tại và chạy được bình thường (`--help` ra kết quả đúng) — không phải lỗi binary.
- **Việc cần làm ở phiên mới (sau khi mở đúng workspace):**
  1. Xác nhận tool `mcp__CITEKSO_500__*` đã xuất hiện chưa.
  2. Thử gọi 1 lệnh đơn giản (search/read/system) để test kết nối thật.
  3. Nếu lỗi host/port → hỏi lại port thật (từ Basis hoặc SAP Logon Pad properties) thay vì tiếp tục đoán `8000`.
  4. **QUAN TRỌNG — bảo mật:** password SAP (`#AbCitek@12345`) đã bị dán vào lịch sử chat text thường — khuyến nghị đổi password trên hệ thống thật sau khi setup/test xong.

## 5. Quy tắc làm việc cần nhớ (đã lưu vào memory, nhắc lại ở đây cho chắc)

- **Tuyệt đối không tự sửa `.mcp.json`** khi user chưa yêu cầu rõ ràng trong lượt hội thoại đó.
- Theo CLAUDE.md của dự án: trả lời tiếng Việt, đọc skill `abap-performance-hana`/`abap-cloud-naming` trước khi code ABAP, đánh dấu code mới bằng marker `"danhdh add begin/end <dd.mm.yyyy hh:mm:ss>`, không tự xoá code (chỉ comment), luôn link tới file/vị trí đã sửa sau khi hoàn tất.
- Nguyên tắc "Độ chính xác": cần dữ liệu thực tế thì đọc trực tiếp (MCP/debug), không đoán rồi kết luận — đã áp dụng xuyên suốt quá trình điều tra này (xác nhận field bằng F1 Technical Info + dictionary export + debug thật, không đoán tên bảng/field).

---
*Cập nhật lần cuối: phiên làm việc tại workspace root `CITEK`, trước khi chuyển sang workspace `SKill_CSTECH/VSCodeSkillAI`.*
