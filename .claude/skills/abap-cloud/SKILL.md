---
name: abap-cloud
description: 'Mô hình 3-tier extensibility, giới hạn ngôn ngữ ABAP for Cloud Development, wrapper pattern cho API chưa released, clean core. TRIGGER — chỉ đọc khi (1) gặp lỗi "use of X is not permitted / not released" và cần tìm API released thay thế; (2) quyết định chọn tier/cách extend (key user vs developer vs classic); (3) user hỏi thẳng về clean core, ABAP Cloud restrictions, released API, wrapper class. SKIP — không đọc khi viết/sửa code Z* bình thường vốn đã dùng API released, hỏi cú pháp, debug logic nghiệp vụ, hay tra cứu object — dù project là ABAP Cloud.'
---

# ABAP Cloud / Clean Core

Guide for developing with the ABAP Cloud programming model, understanding the 3-tier extensibility model, and applying clean core principles.

## Workflow

1. **Determine the user's context**:
   - Understanding ABAP Cloud concepts and restrictions
   - Choosing the right extensibility tier
   - Wrapping unreleased APIs for use in ABAP Cloud
   - Identifying released API alternatives
   - Setting up clean core-compliant development

2. **Identify the extensibility tier**:
   - Tier 1: Key user extensibility (no code)
   - Tier 2: Developer extensibility (ABAP Cloud / ABAP for Cloud Development)
   - Tier 3: Classic extensibility (standard ABAP, only on-premise/private cloud)

3. **Guide implementation** using clean core principles

## ABAP Language Versions

| Language Version               | Scope                                                         | Available In                                       |
| ------------------------------ | ------------------------------------------------------------- | -------------------------------------------------- |
| **ABAP for Cloud Development** | Only released APIs and objects; restricted syntax; no SAP GUI | BTP ABAP Environment, S/4HANA (embedded Steampunk) |
| **Standard ABAP**              | Full ABAP syntax; all repository objects accessible           | On-premise, private cloud                          |

### Key Restrictions in ABAP for Cloud Development

- Only released SAP APIs (C1 contract) can be used
- No direct database table access for SAP tables (use released CDS views instead)
- No classic dynpro, selection screens, or SAP GUI-dependent statements
- No `CALL TRANSACTION`, `SUBMIT`, `AUTHORITY-CHECK` (use `CL_ABAP_AUTHORIZATION` instead)
- No classic BAdIs or user exits
- No `EXEC SQL` or native SQL (use ABAP SQL or AMDP)
- No function modules (except released RFC-enabled ones)
- No `INCLUDE` programs
- No `WRITE` or classic list output
- Must use `if_oo_adt_classrun` for console output

## CDS View Entity — Additional Syntax Restrictions (Verified)

Giới hạn cú pháp `define view entity` xác nhận qua case thật, không phải bug tool. Chi tiết + ví dụ code đầy đủ: `.claude/skills/sap-mcp-cloud/reference/_ghichu_mcp_cloud.md` mục 2, 3, 5, 9.

- `WHERE field IN (...)` không dùng được — viết chuỗi `OR` thay thế.
- Association `ON` không được tham chiếu tới association khác của cùng view — chỉ dùng `$projection.<field>` (phải là field thật, không dẫn xuất qua path nhiều cấp).
- Không dùng `CASE` trực tiếp trong `ON` của JOIN (vẫn dùng bình thường trong SELECT list).
- Không dùng sub-select lồng trong `FROM` (derived table) — phải tách thành 1 CDS view riêng rồi SELECT FROM view đó.
- JOIN có `ON` dùng `OR` giữa 2 điều kiện độc lập dễ fan-out (nhân đôi dòng) — thêm `is initial`/`is not initial` để 2 nhánh loại trừ lẫn nhau, thay vì cố dùng CASE/sub-select (2 rule trên).
- Chained lookup (join nhiều cấp phụ thuộc nhau, vd A→B→C) khi có GROUP BY: dùng JOIN trực tiếp trong FROM, KHÔNG khai báo association riêng cho từng bước (association không được tham chiếu association khác kể cả gián tiếp qua GROUP BY).
- View released dạng `as projection on X` không dùng làm base object trong FROM/JOIN, cũng không làm target của 1 association từ view interface thường.
- Composition + to-parent qua tầng `projection`/`redirected to` buộc 2 object phải activate ĐỒNG THỜI (không tool nào atomically activate được 2 object cùng lúc) — nếu cần activate tuần tự, khai báo composition/to-parent MỚI trực tiếp ở từng tầng (`as select from X`), không dùng redirect.
- View lũy kế/cumulative (self-join `<=` + SUM) phải dựng trên **bảng kỳ** (spine table) làm FROM chính — dựng trên bảng phát sinh (transaction table) rồi self-join sẽ MẤT dòng ở kỳ không phát sinh, làm số lũy kế sai lệch từ đó trở đi.
- `coalesce(<field_quan>, cast(0 as ...))` với field quantity còn giữ `@Semantics.quantity.unitOfMeasure` phải cast `abap.quan(n,d)` — dùng `abap.dec` sẽ lỗi activate "Reference Field ... has a wrong data type".
- Join field kiểu `productnumber` (vd `.Product`) giữa 2 view cùng cast từ `matnr` có thể SILENTLY không khớp (0 dòng, không báo lỗi) — ưu tiên join bằng field gốc kiểu `matnr` (vd `.Material`) thay vì `.Product`.
- CDS UNION view (pattern tách 2 tầng để giữ nguyên tên object cũ): association không được expose trong bất kỳ nhánh UNION nào; annotation field-level chỉ đặt được ở nhánh ĐẦU TIÊN; field cùng vị trí giữa các nhánh phải đúng độ dài (nhánh đầu ≥ nhánh sau) và khớp số lượng; `@EndUserText.label`/description object ≤ 40 ký tự.
- Trong `CLASS ... IMPLEMENTATION` ... `ENDCLASS`, không được có comment đứng độc lập ở cấp top-level nằm ngoài khối `METHOD...ENDMETHOD` (lỗi `OO_SOURCE_BASED012`) — marker/comment đánh dấu code mới (vd theo chuẩn đánh dấu ngày trong `CLAUDE.md`) phải đặt BÊN TRONG thân method.

## 3-Tier Extensibility Model

### Tier 1 — Key User Extensibility (No Code)

- Custom fields and logic via SAP Fiori UIs
- Custom CDS views (basic)
- Custom business objects (simple)
- Custom analytical queries
- No ABAP development required

### Tier 2 — Developer Extensibility (ABAP Cloud)

- ABAP for Cloud Development language version
- Only released APIs with stability contracts
- RAP-based business objects
- Side-by-side or embedded development
- Full lifecycle management via ADT

```abap
"Example: Tier 2 class using only released APIs
CLASS zcl_my_extension DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_my_extension IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    "Only released CDS views — no direct table access
    SELECT FROM I_BusinessPartner
      FIELDS BusinessPartner, BusinessPartnerName
      INTO TABLE @DATA(partners)
      UP TO 10 ROWS.
    out->write( partners ).
  ENDMETHOD.
ENDCLASS.
```

### Tier 3 — Classic Extensibility (Standard ABAP)

- Full ABAP language scope
- Access to all repository objects
- Classic enhancement points, BAdIs, user exits
- Only available on-premise or private cloud
- Not recommended for new cloud-ready development

## Wrapper Pattern

When a needed API is not released (Level B/C), create a wrapper in Tier 3 that exposes the functionality via a released interface consumable from Tier 2.

### Wrapper Class Pattern

```abap
"Tier 3: Wrapper class (Standard ABAP language version)
"Released with C1 contract for use from Tier 2
CLASS zcl_wrapper_material DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_material_reader.
    "Set as released API with C1 contract in ADT
ENDCLASS.

CLASS zcl_wrapper_material IMPLEMENTATION.
  METHOD zif_material_reader~get_material.
    "Access unreleased API internally
    SELECT SINGLE * FROM mara
      WHERE matnr = @iv_matnr
      INTO @DATA(ls_mara).
    "Map to released structure
    rs_material = VALUE #(
      matnr = ls_mara-matnr
      mtart = ls_mara-mtart
      matkl = ls_mara-matkl ).
  ENDMETHOD.
ENDCLASS.
```

### Wrapper via RFC Proxy (Remote Tier 2 to Tier 3)

```abap
"Tier 2 consumer calls released RFC wrapper
DATA(lo_dest) = cl_rfc_destination_provider=>create_by_comm_arrangement(
  comm_scenario  = 'Z_MY_COMM_SCENARIO'
  service_id     = 'Z_MY_OUTBOUND_SRV' ).

CALL FUNCTION 'Z_WRAPPER_FM'
  DESTINATION lo_dest->get_destination_name( )
  EXPORTING iv_param = lv_value
  IMPORTING ev_result = lv_result.
```

## Released API Discovery

| Method                          | Description                                                   |
| ------------------------------- | ------------------------------------------------------------- |
| **ADT: Released Object Search** | In ADT, search with `api:` prefix (e.g., `api:cl_*`)          |
| **Cloudification API Viewer**   | Browse at https://sap.github.io/abap-atc-cr-cv-s4hc/          |
| **ATC Cloud Readiness Check**   | Run ATC checks to identify unreleased API usage               |
| **Released ABAP Classes skill** | Use `released-abap-classes` skill for common released classes |
| **XCO Library**                 | `XCO_CP_*` classes provide cloud-ready alternatives           |

## Common Unreleased → Released Replacements

| Unreleased (Classic)        | Released Alternative (ABAP Cloud)                 |
| --------------------------- | ------------------------------------------------- |
| `AUTHORITY-CHECK`           | `CL_ABAP_AUTHORIZATION=>check_authorization()`    |
| `sy-uname`                  | `cl_abap_context_info=>get_user_technical_name()` |
| `sy-datum` / `sy-uzeit`     | `cl_abap_context_info=>get_system_date/time()`    |
| `cl_gui_frontend_services`  | Not available — use Fiori UI instead              |
| `CALL TRANSACTION`          | RAP action or Fiori navigation                    |
| `SUBMIT ... AND RETURN`     | Background job via `CL_APJ_RT_API`                |
| Direct SAP table `SELECT`   | Use released CDS view (I\_\* views)               |
| `CONVERSION_EXIT_ALPHA_INPUT`/`_OUTPUT` | String template format option: `\|{ val WIDTH = n ALIGN = RIGHT PAD = '0' }\|` |
| `CONVERSION_EXIT_*` khác (codepage)     | `CL_ABAP_CONV_CODEPAGE`, domain fixed values      |
| `BAPI_*` function modules   | Released APIs or RAP BO consumption               |
| Classic `MESSAGE` statement | RAP messages via `REPORTED`                       |

`ALPHA = IN/OUT` trong string template chỉ pad đúng khi biến nguồn đã có type/length cố định khớp đích — dùng trực tiếp trên 1 literal sẽ KHÔNG pad gì (literal tự lấy length của chính nó), âm thầm gửi sai key cho OData filter. Dùng `WIDTH/ALIGN/PAD` để chủ động chỉ định độ dài đích, an toàn hơn `ALPHA` trong trường hợp này. Chi tiết + case thật: `.claude/skills/sap-mcp-cloud/reference/_ghichu_mcp_cloud.md` mục 5.

## Output Format

When helping with ABAP Cloud / clean core topics, structure responses as:

```markdown
## ABAP Cloud Guidance

### Context

- Extensibility tier: [Tier 1/2/3]
- Language version: [ABAP for Cloud Development / Standard ABAP]
- Target platform: [BTP / S/4HANA embedded / on-premise]

### Recommendation

[Guidance on the approach]

### Code Example

[ABAP code following clean core principles]

### Released API References

- [List of relevant released APIs used]
```

## References

- SAP Cloudification Repository: https://github.com/SAP/abap-atc-cr-cv-s4hc
- ABAP Cloud Cheat Sheet: https://github.com/SAP-samples/abap-cheat-sheets
- Clean Core Guidelines: https://help.sap.com/docs/abap-cloud
