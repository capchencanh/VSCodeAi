---
name: abap-performance-hana
description: 'Performance ABAP/CDS trên HANA (On-Premise và Public Cloud) — code pushdown, CDS view, AMDP, SELECT trong LOOP, internal table lớn. TRIGGER — chỉ đọc khi (1) user nói thẳng tới performance/tối ưu/chạy chậm/timeout/dump TIME_OUT của 1 đoạn code cụ thể; (2) đang VIẾT MỚI hoặc chuyển code cũ có SELECT lồng trong LOOP, FOR ALL ENTRIES / SELECT lọc theo internal table (thay bằng INNER JOIN @itab), SELECT rồi SORT / DELETE ADJACENT DUPLICATES, hoặc xử lý internal table lớn (>10k dòng) và phải chọn cách pushdown; (3) review code mà mục tiêu performance được nêu rõ. SKIP — không đọc khi: viết/sửa/đọc code ABAP-CDS thông thường không đả động performance, hỏi cú pháp, hỏi nghiệp vụ, debug lỗi chức năng/authorization/filter, tra cứu object, chỉ giải thích code có sẵn, hoặc hệ ECC/DB truyền thống (Oracle, DB2, MSSQL).'
argument-hint: '[ABAP code to optimize on HANA]'
user-invocable: true
disable-model-invocation: false
---

# ABAP Performance — S/4HANA / HANA Database

These rules apply to SAP S/4HANA systems or any ABAP system running on HANA DB.

**Before using this skill:** Call the SAP system info tool. If the system is ECC on a traditional DB, use the `abap-performance-ecc` skill instead.

**Nền tảng Public Cloud:** đọc mục [Khác biệt trên S/4HANA Public Cloud](#khác-biệt-trên-s4hana-public-cloud-abap-cloud) ở cuối file trước khi áp dụng — các ví dụ bên dưới dùng bảng chuẩn SAP (`MARA`, `MAKT`, `T001`...), `sy-langu` và SAP GUI transaction; mục đó thay thế những chỗ này.

**Core philosophy on HANA:** Push data-intensive operations to the database. HANA is a columnar in-memory DB optimized for set-based operations, aggregations, and complex SQL. Let it do the heavy lifting. Keep ABAP for business logic, authorization, and exception handling.

---

## Code Pushdown — The #1 Rule

**Move data-intensive operations to the database layer.**

### Push down to HANA:
- Aggregations (SUM, COUNT, AVG, MIN, MAX)
- Filtering (WHERE clauses — the more selective, the better)
- Sorting (ORDER BY)
- JOINs (HANA handles complex multi-table JOINs efficiently)
- String operations and arithmetic in SQL
- CASE expressions / conditional logic on data
- Grouping and HAVING
- Window functions (OVER/PARTITION BY)
- UNION / INTERSECT / EXCEPT

### Keep in ABAP:
- Complex business logic with many branches
- Authority checks, messages, exceptions
- Small dataset processing where pushdown overhead exceeds benefit
- Operations requiring ABAP runtime features (RFC calls, file I/O, etc.)

### Avoid:
- Reading all rows to ABAP and filtering/aggregating in loops
- Using internal tables as intermediate storage for what SQL can do in one statement
- Multiple sequential SELECTs that could be a single JOIN

---

## Database Access

### SELECT Patterns

- Select only the fields you need. Never `SELECT *` in production.
  ```abap
  SELECT matnr, maktx FROM mara INTO TABLE @DATA(itab).
  ```

- Always use a WHERE clause. Always use `@` escaped host variables.

- Use JOINs aggressively — HANA handles complex JOINs very well, even 5+ tables.
  ```abap
  SELECT m~matnr, t~maktx, p~werks, p~ekgrp
    FROM mara AS m
    INNER JOIN makt AS t ON t~matnr = m~matnr AND t~spras = @sy-langu
    INNER JOIN marc AS p ON p~matnr = m~matnr
    LEFT OUTER JOIN mvke AS s ON s~matnr = m~matnr
    WHERE m~mtart = @material_type
    INTO TABLE @DATA(materials).
  ```

- Use aggregate functions and GROUP BY — let HANA calculate:
  ```abap
  SELECT werks, SUM( labst ) AS total_stock, COUNT(*) AS item_count
    FROM mard
    WHERE matnr = @matnr
    GROUP BY werks
    INTO TABLE @DATA(stock_by_plant).
  ```

- Use CASE expressions to push conditional logic to the DB:
  ```abap
  SELECT matnr,
         CASE mtart
           WHEN 'FERT' THEN 'Finished'
           WHEN 'ROH' THEN 'Raw Material'
           ELSE 'Other'
         END AS type_text
    FROM mara
    INTO TABLE @DATA(materials).
  ```

- Use string functions in SQL:
  ```abap
  SELECT matnr, CONCAT( matnr, CONCAT( ' - ', maktx ) ) AS display_text
    FROM mara
    INNER JOIN makt ON makt~matnr = mara~matnr AND makt~spras = @sy-langu
    INTO TABLE @DATA(display_data).
  ```

- **Không dùng `FOR ALL ENTRIES` trên mọi hệ KHÁC ECC (S/4HANA, ABAP ≥ 7.52).** Đây là kỹ thuật workaround cho các DB truyền thống (Oracle/DB2/MSSQL) để né chi phí JOIN lớn khi driver table nằm trong ABAP. Trên HANA, JOIN được tối ưu native nên luôn ưu tiên theo thứ tự sau:

  1. **Cả hai vế đều là bảng DB** → gộp thành **JOIN** trực tiếp trong một câu SELECT duy nhất, không tách thành 2 SELECT rồi FOR ALL ENTRIES.
  2. **Vế filter là internal table có sẵn trong ABAP** → **`INNER JOIN @itab AS alias ON ...`** — lựa chọn ưu tiên số 1 thay cho FOR ALL ENTRIES (yêu cầu user 09.10.2026). Gộp được vào chung 1 câu SELECT với các bảng DB khác, so khớp nhiều cột, itab rỗng → kết quả rỗng đúng kỳ vọng (không bị "driver rỗng → SELECT toàn bộ bảng", không cần `IF itab IS NOT INITIAL`).
  3. **`IN @itab` chỉ dùng khi itab là range table** (sign/option/low/high). Itab chỉ có 1 cột giá trị mà viết `WHERE matnr IN @lt_matnr` → lỗi `The row structure of the table "LT_MATNR" is incorrect` (SyntaxCheck S19, 09.10.2026) — dùng `INNER JOIN @itab` thay thế.
  4. **Subquery** khi giá trị lọc đến từ bảng DB khác.

  `INNER JOIN @itab` đã xác nhận qua SyntaxCheck (S19, ABAP 7.56): itab có component (`k~matnr`), itab đứng đầu `FROM @itab AS k INNER JOIN mara ...`, itab 1 cột kiểu elementary (`e~table_line`), itab nằm trong CTE, so khớp cột kiểu khác độ dài (`CHAR40 = CHAR90`). Cảnh báo `The primary key of "<itab>" is ignored because it is generic or is the standard key` chỉ xuất hiện khi itab là STANDARD với DEFAULT KEY — khai báo `WITH EMPTY KEY` hoặc dùng bảng SORTED/HASHED thì SyntaxCheck sạch (đã thử). Cảnh báo `The field "ATWRT" used in the WHERE condition may contain NULL values` (cột DB cho phép NULL, vd `AUSP-ATWRT`) là warning, không đổi kết quả khi so sánh bằng `=`.

  **⚠️ Nguy hiểm hơn cả vấn đề hiệu năng — lỗi ĐÚNG/SAI dữ liệu, âm thầm mất dòng:** `FOR ALL ENTRIES` tự động áp dụng **DISTINCT ẩn trên toàn bộ trường được SELECT** (hành vi mặc định của ABAP, không tắt được). Nếu SELECT list **không chứa đủ trường khoá** của bảng nguồn (ví dụ chỉ select vài cột nghiệp vụ, bỏ qua khoá dòng vật lý như `BELNR`/`BUZEI`), **2 bản ghi khác nhau nhưng tình cờ có cùng giá trị trên các trường được chọn sẽ bị coi là "trùng lặp" và tự động gộp còn 1 dòng** — mất dữ liệu thật mà không có bất kỳ cảnh báo/lỗi nào.

  **Case thật đã gặp** (report `ZFI_PG_BTGT_07`, dự án này, 25/09/2026): `SELECT AUFNR, KSTAR, WKGBTR FROM COVP FOR ALL ENTRIES IN @gt_aufnr WHERE aufnr = @gt_aufnr-aufnr ...` — SELECT list chỉ có 3 trường nghiệp vụ, thiếu `BELNR`/`BUZEI`. Khi 2 chứng từ CO khác nhau (2 `BELNR` khác nhau) tình cờ có cùng `AUFNR`+`KSTAR`+`WKGBTR` (thường gặp ở chứng từ settlement/storno — nhiều dòng đảo ngược cùng 1 số tiền), ABAP tự gộp 2 dòng đó thành 1, làm tổng `SUM` tính sai (thiếu 1 dòng thật) mà `SY-SUBRC`, số dòng kết quả, hay bất kỳ cơ chế nào khác đều không báo hiệu gì bất thường. Xác nhận lỗi bằng cách đối chiếu số dòng SE16N (đọc bảng trực tiếp, không qua FOR ALL ENTRIES) với số dòng ABAP thực nhận được sau SELECT.

  **Quy tắc an toàn**: nếu bắt buộc phải dùng `FOR ALL ENTRIES` (hệ không phải HANA, hoặc lý do khác), luôn SELECT kèm **đủ trường khoá chính của bảng nguồn** (dù không dùng tới trong logic sau đó) để đảm bảo mỗi dòng SELECT ra là duy nhất tuyệt đối — không dựa vào tổ hợp trường nghiệp vụ để suy ra tính duy nhất. Nếu bắt buộc phải dùng `FOR ALL ENTRIES` (case hiếm không tránh được): **KHÔNG được dùng `CASE`/SQL expression trong SELECT list cùng với FAE** — lỗi activate "The addition CASE is not allowed in combination with FOR ALL ENTRIES". SELECT field thô rồi tính/ghép bằng ABAP (`COND` + `condense`) sau khi SELECT xong.

  Trên HANA, cách an toàn nhất vẫn là tránh hẳn `FOR ALL ENTRIES`, dùng `INNER JOIN @itab` hoặc JOIN như khuyến nghị ở trên. Khác FOR ALL ENTRIES, 2 cách này **không có DISTINCT ẩn** (thêm `DISTINCT` thủ công khi cần, xem mục "Ưu tiên cú pháp ABAP SQL mới") và itab rỗng cho kết quả rỗng.

  ```abap
  " Tránh — pattern FOR ALL ENTRIES cũ (bắt buộc check rỗng thủ công, dễ quên, DISTINCT ẩn)
  IF lt_matnr IS NOT INITIAL.
    SELECT matnr, maktx FROM makt
      FOR ALL ENTRIES IN lt_matnr
      WHERE matnr = lt_matnr-matnr AND spras = @sy-langu
      INTO TABLE @DATA(lt_makt).
  ENDIF.

  " Ưu tiên — INNER JOIN internal table (lt_matnr có component MATNR): không cần check rỗng
  SELECT m~matnr, m~maktx
    FROM makt AS m
    INNER JOIN @lt_matnr AS k ON k~matnr = m~matnr
    WHERE m~spras = @sy-langu
    INTO TABLE @DATA(lt_makt).

  " Hoặc — nếu cả 2 vế đều là bảng DB, gộp thành JOIN thay vì 2 SELECT + FOR ALL ENTRIES
  SELECT m~matnr, m~maktx, p~werks
    FROM makt AS m
    INNER JOIN marc AS p ON p~matnr = m~matnr
    WHERE m~spras = @sy-langu
    INTO TABLE @DATA(lt_result).

  " IN @itab chỉ khi lt_range là RANGE TABLE (sign/option/low/high)
  SELECT matnr, maktx FROM makt
    WHERE matnr IN @lt_range
    INTO TABLE @DATA(lt_makt2).
  ```

### Ưu tiên cú pháp ABAP SQL mới khi nhanh hơn (hệ KHÁC ECC)

Khi viết mới hoặc sửa code trên hệ không phải ECC (ABAP ≥ 7.52), **ưu tiên cú pháp mới nếu tối ưu hiệu năng hơn code cũ** — nhưng **chỉ chuyển khi chắc chắn không làm đổi kết quả hay ý đồ của code cũ** (yêu cầu user 09.10.2026). Không chắc → giữ nguyên code cũ và hỏi user.

| Code cũ | Cú pháp mới |
|---|---|
| SELECT + `FOR ALL ENTRIES IN itab` | `INNER JOIN @itab AS k ON ...` (hoặc JOIN thẳng nếu cả 2 vế là bảng DB) |
| SELECT xong rồi `SORT` | `ORDER BY` trong SELECT (xem lưu ý BINARY SEARCH bên dưới), hoặc `INTO TABLE` kiểu SORTED/HASHED |
| SELECT xong rồi `SORT` + `DELETE ADJACENT DUPLICATES` | `SELECT DISTINCT` |
| Vài SELECT trung gian nối bằng LOOP/READ | 1 SELECT có JOIN, hoặc CTE `WITH +cte AS ( ... ) SELECT ... FROM +cte` khi cần tách bước/tái dùng kết quả |
| SELECT rồi LOOP cộng dồn/gom nhóm | `GROUP BY` + hàm tổng hợp |
| SELECT rồi lấy dòng đầu theo thứ tự | `ORDER BY ... UP TO 1 ROWS` |

**Kiểm tra trước khi chuyển `FOR ALL ENTRIES` → `INNER JOIN @itab`:**
1. FAE tự `DISTINCT` toàn bộ SELECT list, join thì không. Kết quả đi vào bảng có key unique, hoặc code cũ dựa vào việc trùng đã bị gộp → thêm `DISTINCT` (hoặc thêm đủ trường khoá nếu cần giữ mọi dòng thật).
2. FAE với itab rỗng đọc cả bảng, join trả rỗng. Code cũ có `IF itab IS NOT INITIAL` → bỏ được. Code cũ KHÔNG check (vô tình đọc cả bảng) → báo user, đừng âm thầm đổi hành vi.
3. Cột ở `ON` phải so sánh được (đã chạy: `CHAR40 = CHAR90`). Itab lớn: nội dung itab được đưa sang DB khi chạy câu SELECT — đo lại bằng ST05 trước khi kết luận nhanh hơn.

**Kiểm tra trước khi chuyển `SELECT` + `SORT` → `ORDER BY`:** nếu sau đó dùng `READ TABLE ... BINARY SEARCH`, `AT NEW`, hoặc so sánh thứ tự theo ABAP, thứ tự DB có thể khác `SORT` của ABAP (chữ hoa/thường, dấu, NULL) → giữ `SORT` hoặc dùng itab kiểu SORTED. Chỉ đổi khi thứ tự chỉ để hiển thị/xuất.

**CTE:** `WITH +cte AS ( SELECT ... ) SELECT ... FROM +cte` được SyntaxCheck chấp nhận (S19, 7.56), kể cả có `INNER JOIN @itab` bên trong CTE. Tool `RunQuery` của MCP từ chối câu bắt đầu bằng `WITH` — CTE chỉ dùng trong code ABAP, không dùng trong file `.sql` đưa user chạy console.

- Use `UP TO n ROWS` when you only need limited results.

- Use subqueries where they simplify logic, or as an alternative to `INNER JOIN @itab` when the filter values come directly from another DB table rather than an internal table:
  ```abap
  SELECT matnr, maktx FROM mara
    WHERE matnr IN ( SELECT matnr FROM marc WHERE werks = @plant )
    INTO TABLE @DATA(plant_materials).
  ```

### CDS Views

- **Prefer CDS views** for complex data models. They are the primary code pushdown mechanism on HANA.
- CDS views are reusable, testable, and automatically optimized by HANA.
- Use CDS for: complex joins, calculated fields, aggregations, associations, access control.
- Consume CDS views in ABAP via `SELECT FROM zcds_view`.

### AMDP (ABAP-Managed Database Procedures)

- Use AMDP for very complex calculations that must run entirely on HANA.
- AMDP gives you access to full SQLScript (HANA's procedural SQL language).
- Use when: complex multi-step transformations, heavy string processing, graph operations, or when CDS is insufficient.
- AMDP is NOT portable to other DBs — use only when you're certain the system stays on HANA.

### Avoiding Redundant DB Access

- Never SELECT the same data twice. Read once, reuse.
- Use `READ TABLE` on internal table buffer instead of `SELECT SINGLE` in a loop:
  ```abap
  SELECT matnr, maktx FROM makt WHERE spras = @sy-langu INTO TABLE @DATA(texts).
  " later:
  READ TABLE texts WITH KEY matnr = current_matnr INTO DATA(text_line).
  ```

- On HANA, even redundant DB access is faster than on traditional DBs — but it's still wasteful and adds network overhead.

### Table Buffering

Buffering matters **less** on HANA than ECC because HANA is in-memory. But it still helps for:
- Reducing network round-trips between app server and DB server
- Avoiding query parsing overhead for tiny lookups

- Use `SELECT SINGLE` on buffered tables — reads from buffer. `UP TO 1 ROWS` bypasses buffer.
  ```abap
  " good — uses buffer
  SELECT SINGLE * FROM t001 WHERE bukrs = @bukrs INTO @DATA(company).
  " bad — bypasses buffer
  SELECT * FROM t001 UP TO 1 ROWS WHERE bukrs = @bukrs INTO @DATA(company).
  ```

- JOINs, aggregates, GROUP BY, ORDER BY, subqueries **bypass the buffer**.

---

## Internal Tables

### Table Type Selection

Same rules as any ABAP system — this is ABAP runtime, not DB:
- **HASHED**: O(1) lookup. Large tables, unique key, read-heavy, filled once.
- **SORTED**: O(log n) lookup. Non-unique key, range access, incremental fill.
- **STANDARD**: O(n) unless sorted + binary search. Small tables or sequential.

```abap
" good — O(1) lookup
DATA materials TYPE HASHED TABLE OF mara WITH UNIQUE KEY matnr.
READ TABLE materials WITH TABLE KEY matnr = input INTO DATA(mat).
```

### Loop Optimization

- Use `ASSIGNING FIELD-SYMBOL(<fs>)` for fastest loop processing.
- Use `WHERE` on LOOP — especially on SORTED tables.
- Avoid nested loops O(n*m). Use HASHED lookup for inner data.
- Use `FILTER` for extracting subsets from SORTED/HASHED tables:
  ```abap
  DATA(subset) = FILTER #( sorted_table WHERE status = 'A' ).
  ```

### Bulk Operations

- `INSERT lines_of` for bulk inserts.
- `VALUE #( FOR ... )` and `REDUCE` for functional transformations.
- `CORRESPONDING #( )` for structure mapping.

### HANA-Specific: Consider Pushing to SQL

Before writing a complex ABAP loop with aggregation, filtering, or transformation — ask: **can this be a SQL statement instead?**

```abap
" ABAP way (acceptable for small data)
LOOP AT sales ASSIGNING FIELD-SYMBOL(<s>).
  AT NEW kunnr.
    total = 0.
  ENDAT.
  total += <s>-netwr.
  AT END OF kunnr.
    APPEND VALUE #( kunnr = <s>-kunnr total = total ) TO totals.
  ENDAT.
ENDLOOP.

" HANA way (better for large data)
SELECT kunnr, SUM( netwr ) AS total
  FROM vbak
  WHERE erdat >= @from_date
  GROUP BY kunnr
  INTO TABLE @DATA(totals).
```

---

## String Operations

- Use string templates `| |` instead of CONCATENATE.
- Avoid repeated string concatenation in loops — build a string table:
  ```abap
  DATA lines TYPE string_table.
  LOOP AT data INTO DATA(d).
    APPEND |{ d-field1 };{ d-field2 }| TO lines.
  ENDLOOP.
  DATA(csv) = concat_lines_of( table = lines sep = cl_abap_char_utilities=>cr_lf ).
  ```

- **HANA-specific:** For heavy string assembly from DB data, consider doing it in SQL with `CONCAT` or `STRING_AGG` (via CDS/AMDP).

---

## Authorization Checks

- Check authority **before** expensive data retrieval:
  ```abap
  AUTHORITY-CHECK OBJECT 'M_MATE_WRK' ID 'WERKS' FIELD plant.
  IF sy-subrc <> 0. RAISE EXCEPTION NEW zcx_no_auth( ). ENDIF.
  SELECT ... " now fetch
  ```

- On S/4HANA, consider CDS access control (DCL) for row-level authorization built into the data model.

---

## ALV / UI Performance

- Pass data by reference.
- Use `CL_SALV_TABLE` for read-only display.
- For very large result sets, consider pagination.
- On S/4HANA: consider Fiori/RAP for UI instead of classical ALV.

---

## Parallel Processing

- `aRFC` for independent parallel tasks.
- `SPTA` framework for parallelized mass processing.
- Background jobs for very long tasks.
- **HANA-specific:** Before parallelizing in ABAP, check if the work can be pushed to HANA — a single efficient SQL may outperform parallel ABAP tasks.

---

## Diagnostic & Verification Tools

Trước khi kết luận một đoạn code là "đã tối ưu", verify bằng công cụ thực tế thay vì chỉ dựa vào nguyên tắc:

| Tool | Mục đích |
|---|---|
| **ST05** (SQL Trace) | Xem số lần DB call thực tế, phát hiện SELECT lặp trong loop, kiểm tra JOIN có push down đúng không |
| **SAT** (Runtime Analysis) | Đo thời gian CPU/memory theo từng câu lệnh ABAP, phát hiện hotspot trong xử lý internal table |
| **ST12** (Single Transaction Analysis) | Kết hợp ABAP trace + SQL trace trong 1 lần chạy — phù hợp khi cần debug end-to-end một giao dịch cụ thể |
| **DBACOCKPIT** | Xem Expensive Statements Trace, PlanViz trên HANA — xác định câu SQL nào tốn tài nguyên nhất trên DB |
| **SWNC** (Workload Monitor) | Theo dõi tải hệ thống theo transaction/thời gian, hữu ích khi so sánh trước/sau tối ưu ở mức production |

Nguyên tắc: sửa code theo best practice ở trên, sau đó **verify lại bằng ST05/SAT/DBACOCKPIT** để có số liệu cụ thể (số DB call giảm, thời gian response giảm) trước khi báo cáo là đã tối ưu.

---

## HANA Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `SELECT *` | Select only needed fields |
| SELECT in a LOOP | JOINs (HANA handles complex JOINs well) |
| Aggregating in ABAP loops | SUM/COUNT/AVG in SQL with GROUP BY |
| Filtering in ABAP what SQL can filter | Push WHERE to SQL |
| Multiple SELECTs that could be one JOIN | Combine into single JOIN statement |
| `FOR ALL ENTRIES` from an internal table | `INNER JOIN @itab AS k ON ...`; `JOIN` if both sides are DB tables; `IN @itab` chỉ với range table |
| `FOR ALL ENTRIES` với SELECT list thiếu trường khoá (rủi ro auto-DISTINCT làm mất dòng thật) | Thêm đủ trường khoá bảng nguồn vào SELECT list, hoặc tránh hẳn bằng `INNER JOIN @itab`/JOIN |
| `SELECT` xong rồi `SORT` / `DELETE ADJACENT DUPLICATES` (khi thứ tự chỉ để xuất/hiển thị) | `ORDER BY` / `SELECT DISTINCT` trong câu SELECT |
| Nested LOOPs on STANDARD tables | HASHED lookup for inner data |
| Complex ABAP transformations on large data | CDS view or AMDP |
| String concat in loops with `&&` | Build string table, or push to SQL |
| Ignoring CDS views | Use CDS for reusable data models |
| `UP TO 1 ROWS` on buffered table | `SELECT SINGLE` to use buffer |
| Authority check after data retrieval | Check before SELECT, or use CDS DCL |
| Writing ABAP for what SQL can express | Push to database — always ask "can SQL do this?" |

---

## Khác biệt trên S/4HANA Public Cloud (ABAP Cloud)

Nguyên tắc code pushdown, JOIN thay `FOR ALL ENTRIES`, internal table, string ở trên giữ nguyên. Khi nền tảng là Public Cloud, các điểm sau thay thế phần tương ứng:

| Chủ đề | On-Premise (phần trên) | Public Cloud |
|---|---|---|
| Nguồn dữ liệu | SELECT bảng chuẩn (`MARA`, `MAKT`, `MARC`, `T001`...) | SELECT từ CDS view released (`I_Product`, `I_CompanyCode`...); bảng Z của dự án SELECT trực tiếp bình thường |
| Ngôn ngữ / ngày giờ trong SQL | `@sy-langu`, `@sy-datum` | Lấy trước vào biến qua `cl_abap_context_info=>get_user_language_abap_format( )` / `=>get_system_date( )`; trong CDS dùng `$session.system_language`, `$session.system_date` |
| Table buffering | `SELECT SINGLE` trên bảng buffered (`T001`) | Không SELECT trực tiếp bảng chuẩn được → đọc 1 lần từ CDS view vào HASHED table, sau đó `READ TABLE` / `line_exists( )` |
| AMDP | Dùng cho tính toán phức tạp | Ưu tiên CDS view entity; AMDP chỉ khi CDS không đủ, SQLScript chỉ truy cập object released/Z, verify bằng SyntaxCheck/activate trên tenant |
| Authorization | `AUTHORITY-CHECK` object chuẩn (`M_MATE_WRK`...) | DCL trên CDS là cơ chế chính; `AUTHORITY-CHECK` dùng với authorization object released hoặc Z (`Z##_AO_`) |
| UI / dữ liệu lớn | `CL_SALV_TABLE`, ALV | Fiori elements trên RAP/custom entity; custom entity tự xử lý phân trang qua `io_request->get_paging( )`, filter/sort đẩy xuống SELECT |
| Xử lý song song / chạy nền | aRFC, SPTA, background job SM36 | Application Job (APJ); framework khác (bgPF...) kiểm tra release state trước khi dùng |
| Đo đạc | ST05, SAT, ST12, DBACOCKPIT, SWNC | Không có SAP GUI transaction. Đo bằng ABAP Profiler trong Eclipse ADT (nếu tenant cho phép) hoặc nhờ user đo trên tenant; công cụ nào xác nhận dùng được thì ghi vào file ghi chú theo CLAUDE.md |
