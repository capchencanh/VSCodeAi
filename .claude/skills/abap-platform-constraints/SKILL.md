---
name: abap-platform-constraints
description: 'Ràng buộc kỹ thuật khác nhau giữa SAP S/4HANA On-Premise và Public Cloud (ABAP Cloud) trong project này — ATC bắt buộc hay khuyến nghị, extensibility (user-exit/BAdI cổ điển vs Key User/RAP), BAPI vs EML, transport SE09/STMS vs Eclipse ADT, sy-* vs cl_abap_context_info. TRIGGER — chỉ đọc khi (1) chuẩn bị viết/review code ABAP mới và chưa chốt nền tảng đang làm trong phiên; (2) cần biết ATC có bắt buộc sạch không, cách nào đổi dữ liệu nghiệp vụ (BAPI hay EML), hay dùng field hệ thống nào cho đúng nền tảng. SKIP — không đọc khi: nền tảng đã xác định rõ trong phiên rồi và chỉ hỏi cú pháp/logic thông thường không liên quan ràng buộc nền tảng, hoặc đang đặt tên object mới (dùng skill `abap-cloud-naming`/`abap-naming-convention` thay vì skill này).'
user-invocable: true
disable-model-invocation: false
---

Kinh nghiệm ABAP/thiết kế khi làm local (Chung / On-Premise / Public Cloud): [reference/_ghichu_local.md](reference/_ghichu_local.md) — đọc theo section (`grep -n '^## '`), ghi thêm theo khối "CÁCH GHI THÊM 1 MỤC MỚI" đầu file.

## Xác định nền tảng

Dự án phục vụ 2 nền tảng với ràng buộc khác nhau. Trước khi viết/review code, chốt nền tảng và giữ nguyên cho cả phiên:

1. Đang dùng MCP: server tên `GUI_*` → **On-Premise**; server URL `*.s4hana.cloud.sap` → **Public Cloud**.
2. Làm local: theo nền tảng user nêu. User chưa nêu → dựa vào code: có `REPORT`/`PROGRAM`, `INCLUDE`, dynpro/selection screen, gọi `BAPI_*`, user-exit → On-Premise; tên object theo skill `abap-cloud-naming` (`Z##_CL_`, `Z##_I_`...), `if_oo_adt_classrun`, `cl_abap_context_info` → Public Cloud.
3. Dấu hiệu mâu thuẫn hoặc không có (CDS/RAP/class thuần — cả 2 nền tảng đều có) → hỏi user 1 câu trước khi làm.

## Ràng buộc: SAP S/4HANA On-Premise

- Hệ thống chạy trên **HANA DB** (in-memory, columnar) theo mô hình on-premise/classic → áp dụng skill `abap-performance-hana` cho mọi việc review/tối ưu performance (không cần `abap-performance-ecc`, vì landscape DEV/QAS/PRD đều chạy trên HANA).
- Cho phép dùng đầy đủ **classic extensibility**: User-exit, BAdI (SE18/SE19), Enhancement point/spot, kể cả modification (SPAU/SPDD) khi thật sự cần thiết.
- **ATC**: khuyến nghị chạy để rà soát chất lượng, nhưng **không bắt buộc sạch 100% finding** trước khi activate/release transport. Ưu tiên xử lý finding Error/Priority cao (performance, security) trước go-live; finding style tuỳ team lead quyết định.
- Transport landscape truyền thống: DEV → QAS → PRD qua **SE09/SE10/STMS**.
- Business object integrity: luôn dùng **BAPI** để đổi dữ liệu nghiệp vụ (không `UPDATE` trực tiếp EKPO/QALS...) để giữ change document và tính nhất quán downstream.

## Ràng buộc: SAP S/4HANA Public Cloud (ABAP Cloud)

- Chỉ dùng **released API** (C1 contract): đọc dữ liệu SAP qua CDS view released (`I_*`) thay bảng chuẩn; class/interface SAP phải released. Kiểm tra bằng `GetAPIReleaseState` hoặc annotation `@VDM.lifecycle.contract.type` = `#PUBLIC_LOCAL_API`.
- Extensibility: Key User (Custom Fields `YY1_`, Custom Logic), released BAdI, developer extensibility (CDS, RAP, class). Classic extensibility (user-exit, enhancement point, modification, dynpro, report program) không tồn tại.
- Business object integrity: đổi dữ liệu nghiệp vụ qua **RAP BO bằng EML** (`MODIFY ENTITIES OF ...`) hoặc released API (OData/SOAP qua Communication Arrangement) — vai trò tương đương BAPI.
- Field hệ thống: `cl_abap_context_info` (`get_system_date`, `get_system_time`, `get_user_technical_name`, `get_user_language_abap_format`) thay cho `sy-datum`/`sy-uzeit`/`sy-uname`/`sy-langu`.
- **ATC bắt buộc sạch** (không lỗi/cảnh báo) trước khi activate hoặc release transport — xử lý dứt điểm finding, không bỏ qua.
- Transport quản lý trong Eclipse ADT trên tenant development; không có SE09/SE10/STMS.
- Performance: skill `abap-performance-hana`, mục "Khác biệt trên S/4HANA Public Cloud".
