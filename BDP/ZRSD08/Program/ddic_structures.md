# DDIC cần tạo/sửa cho ZRSD08 (theo FS mới, 14/10/2026)

> **Cập nhật 14/10/2026: toàn bộ object trong tài liệu này đã được tạo/sửa + activate trên DEV/100 qua MCP, vào TR `DEVK900197`
> (task `DEVK900198`).** Không cần làm lại bằng SE11 trên DEV/100. Giữ tài liệu để tham khảo cấu trúc và để dựng lại trên hệ khác (QAS/PRD import theo TR).

Chương trình và Smart Form dùng các object DDIC dưới đây. **Làm SE11 xong, activate hết, rồi mới upload form và cập nhật include** — nếu không form báo `Type ... is unknown` và include báo field không tồn tại.

Trạng thái trên DEV/100 (đã kiểm bằng MCP 14/10/2026):

| Object | Hiện có trên hệ | Việc cần làm |
|---|---|---|
| `ZST_RSD08_HEAD` | có (bản cũ) | **sửa** — mục 2 |
| `ZST_RSD08_ITEM` | có (bản cũ) | **sửa** — mục 3 |
| `ZTT_RSD08_ITEM` | có | giữ nguyên, activate lại sau khi sửa structure |
| `ZST_RSD08_TAX` | chưa có | **tạo mới** — mục 4 |
| `ZTT_RSD08_TAX` | chưa có | **tạo mới** — mục 5 |
| `ZDE_TAXRATE` (DEC 5,2) | có | dùng lại |
| `ZDE_EINV_AMOUNT_IN_WORDS` (CHAR 255, "Thành tiền bằng chữ") | có (package `ZPK_BDP`) | dùng lại |
| `STCEG`, `STCD1` (chuẩn SAP) | có | dùng lại |
| `ZDE_CADDR`, `ZDE_NHATHUOCNM` | chưa có | **tạo mới** — mục 1 |

Thứ tự: (1) 2 data element mới → (2) `ZST_RSD08_ITEM` → (3) `ZST_RSD08_TAX` → (4) `ZTT_RSD08_TAX` → (5) `ZST_RSD08_HEAD` → (6) activate lại `ZTT_RSD08_ITEM`.

---

## 1. Data element mới

SE11 → radio **Data type** → gõ tên → **Create** → chọn **Data element** → Enter.

| Data element | Short Description | Data Type | Length | Field Label (Short / Medium / Long / Heading) |
|---|---|---|---|---|
| `ZDE_CADDR` | `Địa chỉ công ty` | CHAR | 120 | `Địa chỉ CT` / `Địa chỉ công ty` / `Địa chỉ công ty` / `Địa chỉ công ty` |
| `ZDE_NHATHUOCNM` | `Tên nhà thuốc bán lẻ` | CHAR | 120 | `Tên NT` / `Tên nhà thuốc` / `Tên nhà thuốc bán lẻ` / `Tên nhà thuốc` |

Các bước (làm cho từng data element):

1. Ô **Short Description**: điền theo cột *Short Description*.
2. Tab **Data Type**: radio **Predefined Type** → **Data Type** `CHAR`, **Length** `120`.
3. Tab **Field Label**: điền 4 ô theo cột *Field Label*. Bắt buộc — bỏ trống thì field không có nhãn trên màn hình.
4. Save → Package `ZPK_BDP` → chọn TR → Activate (Ctrl+F3).

---

## 2. Structure `ZST_RSD08_HEAD` (sửa)

SE11 → radio **Data type** → `ZST_RSD08_HEAD` → **Change**.

Danh sách component sau khi sửa (cột *Việc làm* chỉ rõ chỗ thêm/xoá):

| Component | Component type | Chỉ tiêu FS | Việc làm |
|---|---|---|---|
| BUKRS | BUKRS | — | giữ |
| LOGO | `ZDE_LOGO` | (1) | giữ |
| CNAME | `ZDE_CNAME` | (2) | giữ |
| CADDR | `ZDE_CADDR` | (2.1) | **thêm** sau CNAME |
| CTAXNO | `STCEG` | (2.2) | **thêm** sau CADDR |
| NHATHUOC | `ZDE_NHATHUOC` | (3) | giữ |
| NHATHUOCNM | `ZDE_NHATHUOCNM` | (3.1) | **thêm** sau NHATHUOC |
| DATE_FR | SYDATUM | (4) | giữ |
| DATE_TO | SYDATUM | (5) | giữ |
| FKART | FKART | (6) | giữ |
| FKARTX | VTXTK | (7) | giữ |
| PAYERNM | `ZDE_PAYERNM` | (8) | giữ |
| PAYERTAX | `STCD1` | (8.1) | **thêm** sau PAYERNM |
| PAYERAD | `ZDE_PAYERAD` | (9) | giữ |
| TOTAL | NETWR_FP | (17) | giữ |
| DISCOUNT | — | (18) | **xoá** (FS mới bỏ chỉ tiêu 18) |
| TAXRATE | — | — | **xoá** (thuế suất chuyển sang `ZST_RSD08_ITEM` và `ZST_RSD08_TAX`) |
| TAXAMT | NETWR_FP | (19) | giữ — nay là **tổng cộng tiền thuế** |
| AMTPAY | NETWR_FP | (21) | giữ |
| AMTWORD | `ZDE_EINV_AMOUNT_IN_WORDS` | (21.1) | **thêm** sau AMTPAY |
| PRTDATE | SYDATUM | (22) | giữ |
| WAERK | WAERK | — | giữ |

Tab **Currency/quantity fields** sau khi sửa — 3 field tiền đều trỏ về `WAERK` trong chính structure:

| Field | Reference table | Ref. field |
|---|---|---|
| TOTAL | `ZST_RSD08_HEAD` | `WAERK` |
| TAXAMT | `ZST_RSD08_HEAD` | `WAERK` |
| AMTPAY | `ZST_RSD08_HEAD` | `WAERK` |

(Xoá 2 dòng của DISCOUNT và TAXRATE khỏi tab này trước khi xoá component, nếu không activate báo lỗi.)

Save → Activate.

---

## 3. Structure `ZST_RSD08_ITEM` (sửa)

SE11 → `ZST_RSD08_ITEM` → **Change**.

| Component | Component type | Chỉ tiêu FS | Việc làm |
|---|---|---|---|
| POSNR | POSNR_VF | — | giữ |
| VBELN | VBELN_VF | — | giữ |
| STT | `ZDE_STT` | (10) | giữ |
| MATNR | MATNR | — | giữ |
| MAKTX | MAKTX | (11) | giữ |
| MEINS | MEINS | (12) | giữ |
| MENGE | FKIMG | (13) | giữ |
| KBETR | KBETR | (14) | giữ |
| NETWR | NETWR_FP | (15) | giữ |
| GHICHU | — | — | **xoá** (cột 16 nay là Thuế suất GTGT) |
| TAXRATE | `ZDE_TAXRATE` | (16) | **thêm** sau NETWR |
| WAERK | WAERK | — | giữ |

Tab **Currency/quantity fields** — giữ nguyên:

| Field | Reference table | Ref. field |
|---|---|---|
| MENGE | `ZST_RSD08_ITEM` | `MEINS` |
| KBETR | `ZST_RSD08_ITEM` | `WAERK` |
| NETWR | `ZST_RSD08_ITEM` | `WAERK` |

Save → Activate.

---

## 4. Structure `ZST_RSD08_TAX` (tạo mới) — 1 dòng cho mỗi mức thuế suất

SE11 → radio **Data type** → `ZST_RSD08_TAX` → **Create** → **Structure**.

**Short description:** `Tổng hợp tiền thuế GTGT theo thuế suất`

| Component | Component type | Chỉ tiêu FS | Short description |
|---|---|---|---|
| TAXRATE | `ZDE_TAXRATE` | (19.1) | `Thuế suất GTGT` |
| TAXAMT | NETWR_FP | (20) | `Tiền thuế GTGT` |
| WAERK | WAERK | — | `Currency Key` |

Tab **Currency/quantity fields**:

| Field | Reference table | Ref. field |
|---|---|---|
| TAXAMT | `ZST_RSD08_TAX` | `WAERK` |

Menu **Extras → Enhancement Category** → chọn *Can Be Enhanced (Deep)* (tránh warning khi activate). Save → Package `ZPK_BDP` → Activate.

---

## 5. Table type `ZTT_RSD08_TAX` (tạo mới)

SE11 → radio **Data type** → `ZTT_RSD08_TAX` → **Create** → **Table type**.

| Thuộc tính | Giá trị |
|---|---|
| Short description | `Bảng tổng hợp tiền thuế theo thuế suất` |
| Line Type | `ZST_RSD08_TAX` |
| Access | Standard Table |
| Key definition | Not specified |
| Key category | Non-unique |

Save → Package `ZPK_BDP` → Activate.

---

## Smart Form

Interface của form `ZSF_SD_BKBLHHDV` cần thêm **Tables** parameter: `IT_TAX TYPE ZTT_RSD08_TAX` (chương trình truyền `IT_TAX = GT_TAX`; thiếu tham số này thì `CALL FUNCTION` dump). Bố cục form theo mẫu FS mới: đầu form thêm địa chỉ + MST công ty, `Nhà thuốc: mã – tên`, dòng `MST` của đơn vị mua hàng; cột 7 của bảng hàng là **Thuế suất GTGT** (`GS_ITEM-TAXRATE`, in kèm `%`); khối cộng lặp theo `IT_TAX` (mỗi dòng: `Thuế suất GTGT` / `n %` / `Tiền thuế GTGT` / số tiền), rồi `Tổng cộng tiền thuế` (`TAXAMT`), `Tổng cộng tiền thanh toán` (`AMTPAY`), `Số tiền bằng chữ` (`AMTWORD`). Dòng `(18) Chiết khấu sau` bỏ khỏi form.

## Lưu ý khi tạo

- Field CURR/QUAN bắt buộc khai tab Currency/quantity fields, nếu không activate báo `Field ... needs a reference field`.
- Smart Form tìm field tham chiếu currency/quantity **trong cùng structure** của work area — vì vậy `ZST_RSD08_ITEM` và `ZST_RSD08_TAX` đều có `WAERK` riêng.
- Message class `ZMC_SD` đã có trên DEV/100 (message `001` = `&1 &2 &3 &4`); Tcode `ZRSD08` đã có.
- Logo: SE78 → nhóm `GRAPHICS`, loại `BMAP`, màu `BCOL`, tên `ZLOGO_<mã công ty>`.
