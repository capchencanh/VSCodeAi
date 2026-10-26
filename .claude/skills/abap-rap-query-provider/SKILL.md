---
name: abap-rap-query-provider
description: 'RAP Custom Entity Query Provider pattern (filter push-down/post-filter, authorization check thủ công, paging/sort generic, bẫy annotation DDLX) — đúc kết từ ZSD_I_SALESFLOW + ZSD_CL_SALESFLOW_QRY/_QRY_MANAGE (package ZPK_SD_ZSD01). TRIGGER — chỉ đọc khi: (1) sửa/tạo 1 class implement if_rap_query_provider (entry point thường tên hậu tố _QRY, manager _QRY_MANAGE); (2) CDS entity đang xét có annotation @ObjectModel.query.implementedBy; (3) debug "$filter/$orderby/$top/$skip trên Fiori report không có tác dụng" mà nghi ngờ nằm ở 1 custom entity (không phải managed RAP BO thường). SKIP — không đọc khi: câu hỏi về CDS view/managed RAP BO thông thường (không phải custom entity + query provider), object/package khác không liên quan pattern này, câu hỏi chung về MCP tool (dùng skill `sap-mcp-cloud`/`sap-mcp-gui`), hoặc câu hỏi ABAP không liên quan filter/paging/query provider.'
---

Pattern cho CDS `custom entity` gắn `@ObjectModel.query.implementedBy` (thường dùng cho report tổng hợp nhiều bảng, không map 1-1 vào 1 DB table nên không dùng managed RAP BO được). Nguồn tham khảo gốc: package `ZPK_SD_ZSD01`, entity `ZSD_I_SALESFLOW`, class `ZSD_CL_SALESFLOW_QRY` (entry point) + `ZSD_CL_SALESFLOW_QRY_MANAGE` (manager, method `RUN`).

## 1. Kiến trúc: tách entry point / manager

- Class implement `if_rap_query_provider~select` **chỉ** parse paging/sort rồi delegate toàn bộ logic sang 1 class manager riêng — không nhồi hết vào 1 class.
- Lý do: entry point gọn, dễ đọc; logic SQL/enrich/filter nặng (có thể >1000 dòng với report nhiều bảng) tách riêng dễ maintain, dễ trace lỗi.

## 2. Lấy filter từ UI ($filter OData)

```abap
DATA(lo_filter) = io_request->get_filter( ).
TRY.
    LOOP AT lo_filter->get_as_ranges( ) ASSIGNING FIELD-SYMBOL(<f>).
      CASE <f>-name.                         " LUÔN viết hoa, đúng tên field CDS (không dấu _)
        WHEN 'FIELDNAME'. lr_x = CORRESPONDING #( <f>-range ).
      ENDCASE.
    ENDLOOP.
  CATCH cx_rap_query_filter_no_range ##NO_HANDLER.
    " Filter dạng expression phức tạp (không phải simple eq/in) → bị BỎ QUA LẶNG LẼ, không lỗi.
    " UI Fiori Elements thường chỉ gửi simple eq/in nên hiếm khi gặp, nhưng cần biết để không
    " nhầm lẫn khi debug "sao filter phức tạp (vd OR khác field) không có tác dụng".
ENDTRY.
```

**Bẫy quan trọng nhất**: field nào KHÔNG có nhánh `WHEN` tương ứng → filter của field đó bị rơi mất hoàn toàn, không báo lỗi gì. Vì vậy field list trong DDLX (`@Consumption.filter`) và field list trong `CASE` của ABAP **phải khớp nhau tuyệt đối** — nếu không sẽ có tình trạng UI cho filter nhưng data trả về không lọc theo field đó (silent bug, rất khó phát hiện qua test thông thường).

## 3. Push-down SQL vs Post-filter — nguyên tắc chọn

| Field | Cách filter |
|---|---|
| Có sẵn ở SELECT driver đầu tiên (bảng chính, vd SO header/item) | Push-down vào `WHERE` của SELECT đó — tối ưu performance, tránh full fetch |
| Derived/tính toán/enrich sau (lookup text, "bản ghi đầu tiên theo logic nghiệp vụ"...) | CHỈ filter được SAU KHI build xong dòng dữ liệu (`ls_row`), vì giá trị chưa tồn tại ở tầng SQL |

Post-filter pattern — đặt ngay trước dòng `APPEND ls_row TO lt_assembled`:

```abap
IF lr_x IS NOT INITIAL AND ls_row-x NOT IN lr_x.
  CONTINUE.
ENDIF.
```

## 4. Authorization check thủ công (không dùng DCL) ngay trong query provider

Dùng khi cần lọc theo quyền của user (vd company code) nhưng entity là custom entity không gắn DCL access control được theo cách chuẩn:

```abap
LOOP AT lt_companycode INTO DATA(ls).
  AUTHORITY-CHECK OBJECT 'ZAO_BUKRS' ID 'ZAF_BUKRS' FIELD ls-companycode ID 'ACTVT' FIELD '03'.
  IF sy-subrc = 0.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = ls-companycode ) TO lr_compcode.
  ENDIF.
ENDLOOP.
IF lr_compcode IS INITIAL.
  RETURN.   " user không có quyền company code nào → trả rỗng, không lỗi
ENDIF.
" ... push-down: WHERE field IN @lr_compcode
```

- Có thể check nhiều object khác nhau trong cùng 1 loop cho các mục đích khác nhau (vd 1 object gate hiện DÒNG, 1 object khác gate hiện CỘT giá vốn/lợi nhuận — field đó chỉ enrich nếu user có quyền, còn lại để trống).
- Build range các giá trị user CÓ quyền rồi push-down `IN @range`, thay vì filter runtime qua DCL.

## 5. `LEFT OUTER JOIN` + range rỗng = giữ nguyên dòng khi filter optional

```
LEFT OUTER JOIN partner ON partner~key = so~key AND partner~function = 'ZM'
WHERE partner~personnel IN @lr_filter
```

- Range rỗng (`lr_filter` không set) → điều kiện `IN` của Open SQL luôn TRUE kể cả khi giá trị NULL → không lọc gì, giữ nguyên dòng dù SO chưa có partner.
- Range có giá trị → NULL không match → loại đúng những dòng chưa có partner (đúng ý user đang filter cụ thể theo partner).
- Đây là cách chuẩn để 1 field filter optional (qua LEFT JOIN) không vô tình làm mất dòng khi user không dùng filter đó.

## 6. Paging + Sort generic qua `SELECT FROM @itab`

```abap
" page_size_unlimited (sentinel = -1 phía RAP) → UP TO 0 ROWS (0 = không giới hạn trong Open SQL)
DATA(lv_max_rows) = COND int8( WHEN iv_top = if_rap_query_paging=>page_size_unlimited
                               THEN 0 ELSE iv_top ).

" Default order khi UI không gửi $orderby
DATA(lv_order) = COND string( WHEN iv_order_by IS INITIAL THEN `key1, key2` ELSE iv_order_by ).

SELECT FROM @lt_assembled AS src
  FIELDS *
  ORDER BY (lv_order)
  INTO TABLE @et_data
  OFFSET @iv_offset
  UP TO @lv_max_rows ROWS.
```

`ORDER BY (dynamic_string)` cho phép sort động theo `$orderby` OData mà không cần code cứng từng field.

## 7. Giới hạn identifier ABAP hay bị dính khi đặt tên biến theo tên field CDS

- Tên biến/method/attribute tối đa **30 ký tự**.
- Field CDS tên dài (vd `AdditionalMaterialGroup1Name` = 28 ký tự) → nếu đặt biến local `lr_additionalmaterialgroup1name` (31 ký tự) sẽ **lỗi activate**. Phải rút gọn (vd `lr_addlmatgrp1name`).
- Luôn đếm ký tự trước khi đặt tên biến/method mới khi tên field CDS dài.

## 8. DDLX annotation — bẫy hay gặp

- `@Consumption.filter.hidden: false` nghĩa là **CHO PHÉP** filter field đó (hiện trong "Adapt Filters" của Fiori Elements) — tên annotation dễ gây hiểu lầm ngược (`hidden: false` = "không ẩn" = "có filter", không phải "không filter").
- Annotation UI cho phép filter 1 field **không đảm bảo** backend thực sự xử lý field đó (xem mục 2) — với custom entity tự code, phải luôn đối chiếu 2 phía DDLX ⟷ ABAP CASE khi review hoặc khi thêm field filter mới.
- `@UI.selectionField` chỉ quyết định field có hiện MẶC ĐỊNH trên filter bar hay không; field không có `@UI.selectionField` nhưng có `@Consumption.filter` (không set `hidden: true`) vẫn filter được qua "Adapt Filters".

## 9. Checklist khi thêm 1 field filter mới vào entity dạng này

1. Thêm `@Consumption.filter: { selectionType: #INTERVAL, ... }` (+ `@UI.selectionField` nếu muốn hiện mặc định) vào DDLX.
2. Khai báo `DATA lr_x TYPE RANGE OF <entity>-<field>.` trong method manager.
3. Thêm `WHEN 'FIELDNAME'. lr_x = CORRESPONDING #( <f>-range ).` vào CASE extract filter.
4. Chọn 1 trong 2: push-down vào `WHERE` của SELECT driver (nếu field có sẵn ở tầng SQL) HOẶC thêm post-filter `IF lr_x IS NOT INITIAL AND ls_row-x NOT IN lr_x. CONTINUE. ENDIF.` trước `APPEND ls_row` (nếu field derived/enrich sau).
5. `SyntaxCheck` trước khi activate, nhờ user verify lại qua Fiori app / Eclipse mass activation (không tin 100% response `success: true` của tool MCP — xem `.claude/skills/sap-mcp-cloud/reference/_ghichu_mcp_cloud.md` mục 9).
